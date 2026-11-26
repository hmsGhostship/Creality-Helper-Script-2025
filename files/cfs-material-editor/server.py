
import re as _re, urllib.request as _ureq

_PENDING_ORCA_PRINT = {"filename": "", "enabled": True}


def _cfs_has_matching_materials(gcode_bytes):
    try:
        head = gcode_bytes[:65536].decode("utf-8", errors="ignore")
        types = []
        for line in head.splitlines():
            if line.startswith("; filament_type ="):
                types = [t.strip().upper().replace("-", "") for t in line.split("=", 1)[1].split(";") if t.strip()]
                break
        used = sorted({int(m.group(1)) for m in _re.finditer(r'(?m)^T([0-3])\b', gcode_bytes[:262144].decode("utf-8", errors="ignore"))})
        if not used:
            used = [0]
        req_mats = []
        for t in used:
            m = types[t] if t < len(types) else (types[0] if types else "")
            if m:
                req_mats.append(m)
        if not req_mats:
            return True
        con = sqlite3.connect("/usr/data/printer_data/database/nexusp-sql.db")
        row = con.execute("SELECT value FROM namespace_store WHERE namespace='color_box' AND key='box_info'").fetchone()
        con.close()
        if not row:
            return False
        slots = json.loads(row[0]).get("T1", {}).get("list", [])
        avail = [str(s.get("type", "")).strip().upper().replace("-", "") for s in slots if s.get("enable") == 1 and str(s.get("type", "")).strip()]
        pool = list(avail)
        for rm in req_mats:
            if rm in pool:
                pool.remove(rm)
            elif rm in avail:
                pass
            else:
                return False
        return True
    except Exception:
        return True

def _forward_upload_no_autoprint(handler, target_path="/server/files/upload"):
    from urllib.parse import parse_qs, urlencode, urlsplit, urlunsplit
    ctype = handler.headers.get("Content-Type", "")
    clen = int(handler.headers.get("Content-Length", "0") or "0")
    body = handler.rfile.read(clen)
    sp = urlsplit(handler.path or target_path)
    qs = parse_qs(sp.query, keep_blank_values=True)
    q_print = any(v.strip().lower() in ("true", "1", "yes") for v in qs.get("print", []))
    want_print = q_print
    uploaded_name = ""
    gcode_bytes = b""
    should_intercept = _PENDING_ORCA_PRINT.get("enabled", True)
    m = _re.search(r'boundary=([^;]+)', ctype)
    if m:
        boundary = m.group(1).strip().strip('"').encode("utf-8")
        delim = b"--" + boundary
        parts = body.split(delim)
        for part in parts:
            if b"\r\n\r\n" not in part:
                continue
            hdr_raw, val = part.split(b"\r\n\r\n", 1)
            hdr_str = hdr_raw.decode("utf-8", errors="ignore")
            fn_m = _re.search(r'filename="([^"]+)"', hdr_str)
            if fn_m:
                uploaded_name = fn_m.group(1)
                gcode_bytes = val[:-2] if val.endswith(b"\r\n") else val
            if 'name="print"' in hdr_str:
                if val.rstrip(b"\r\n").strip().lower() in (b"true", b"1", b"yes"):
                    want_print = True
        should_intercept = _PENDING_ORCA_PRINT.get("enabled", True) or (not _cfs_has_matching_materials(gcode_bytes))
        new_parts = []
        for part in parts:
            if b"\r\n\r\n" not in part:
                new_parts.append(part)
                continue
            hdr_raw, val = part.split(b"\r\n\r\n", 1)
            hdr_str = hdr_raw.decode("utf-8", errors="ignore")
            if 'name="print"' in hdr_str:
                if want_print and should_intercept:
                    val = b"false\r\n"
                new_parts.append(hdr_raw + b"\r\n\r\n" + val)
            else:
                new_parts.append(part)
        body = delim.join(new_parts)
    if q_print and should_intercept:
        qs["print"] = ["false"]
    fwd_path = urlunsplit(("", "", sp.path or target_path, urlencode(qs, doseq=True), ""))
    req = _ureq.Request("http://localhost:7126" + fwd_path, data=body, method="POST")
    if ctype:
        req.add_header("Content-Type", ctype)
    with _ureq.urlopen(req, timeout=60) as resp:
        st, rbody, rct = resp.status, resp.read(), resp.headers.get("Content-Type", "application/json")
    if want_print and st in (200, 201):
        try:
            rj = json.loads(rbody.decode("utf-8", errors="ignore"))
            fn = rj.get("item", {}).get("path") or uploaded_name
        except Exception:
            fn = uploaded_name
        if fn:
            _PENDING_ORCA_PRINT["filename"] = fn
    handler.send_response(st)
    handler.send_header("Content-Type", rct)
    handler.send_header("Content-Length", str(len(rbody)))
    handler.end_headers()
    handler.wfile.write(rbody)

#!/usr/bin/env python3
import copy, json, os, shutil, tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

DB_PATH = "/usr/data/creality/gui/config/material_database.json"
BACKUP_PATH = DB_PATH + ".bak"
WEB_ROOT = os.path.dirname(os.path.abspath(__file__))
PORT = 8088

PRESET_PACK_7 = [
    ("90001", "Sunlu",  "HighSpeed PLA",        "PLA",  "215", "220", "55",  "20",   1.24, 50, 6),
    ("90002", "Sunlu",  "HighSpeed Matte PETG", "PETG", "245", "245", "75",  "14",   1.23, 65, 6),
    ("90003", "Sunlu",  "PETG",                 "PETG", "245", "245", "75",  "10.5", 1.23, 65, 6),
    ("90004", "Sunlu",  "High Speed ABS",       "ABS",  "265", "265", "100", "18",   1.08, 80, 6),
    ("90005", "Jayo",   "HighSpeed Matte PETG", "PETG", "245", "245", "75",  "14",   1.23, 65, 6),
    ("90006", "Eryone", "HyperSpeed ABS",         "ABS",  "265", "265", "100", "18",   1.08, 80, 6),
    ("90007", "eSun",   "ABS+",                 "ABS",  "260", "260", "100", "15",   1.08, 80, 6),
]

def ensure_backup():
    if os.path.exists(DB_PATH) and not os.path.exists(BACKUP_PATH):
        shutil.copy2(DB_PATH, BACKUP_PATH)


import glob
APP_DB_PATHS = glob.glob("/usr/apps/etc/gui/resource/box/*CFS-C/material_database.json")
SQL_DBS = ["/usr/data/printer_data/database/nexusp-sql.db", "/usr/data/printer_data/database/moonraker-sql.db"]

def sync_all_targets(data):
    import sqlite3
    for ap in APP_DB_PATHS:
        if os.path.exists(ap):
            if not os.path.exists(ap + ".bak"):
                shutil.copy2(ap, ap + ".bak")
            shutil.copy2(DB_PATH, ap)
    brand_opts = {}
    mat_ids = {}
    brands = []
    for item in data.get("result", {}).get("list", []):
        b, kv = item.get("base", {}), item.get("kvParam", {})
        pid, brand, name, mtype = str(b.get("id", "")), b.get("brand", ""), b.get("name", ""), b.get("meterialType", "")
        if not pid or not brand or not name or not mtype:
            continue
        info = {"id": pid, "min_temp": int(b.get("minTemp", 190)), "max_temp": int(b.get("maxTemp", 260)), "pa": float(kv.get("pressure_advance", 0.04) or 0.04), "nozzle_temp": int(float(kv.get("nozzle_temperature", 220)))}
        mat_ids[pid] = dict(info, brand=brand, type=mtype, name=name)
        if brand not in brand_opts:
            brand_opts[brand] = {"options": ""}
            brands.append(brand)
        if mtype not in brand_opts[brand]:
            brand_opts[brand][mtype] = {"options": ""}
            brand_opts[brand]["options"] += mtype + "\n"
        brand_opts[brand][mtype][name] = info
        brand_opts[brand][mtype]["options"] += name + "\n"
    brand_opts["options"] = "\n".join(brands) + ("\n" if brands else "")
    for sdb in SQL_DBS:
        if os.path.exists(sdb):
            con = sqlite3.connect(sdb)
            cur = con.cursor()
            if cur.execute("SELECT 1 FROM namespace_store WHERE namespace='color_box' LIMIT 1").fetchone():
                cur.execute("INSERT OR REPLACE INTO namespace_store (namespace, key, value) VALUES ('color_box', 'brand_options', ?)", (json.dumps(brand_opts, separators=(",", ":")),))
                cur.execute("INSERT OR REPLACE INTO namespace_store (namespace, key, value) VALUES ('color_box', 'material_ids', ?)", (json.dumps(mat_ids, separators=(",", ":")),))
                con.commit()
            con.close()

SETTINGS_PATH = os.path.join(WEB_ROOT, "settings.json")
DEFAULT_SETTINGS = {"allow_cf": False, "allow_edit_stock": False}

PENDING_FILE = "/tmp/cfs_editor_pending.json"

def get_pending():
    if os.path.exists(PENDING_FILE):
        try:
            return set(json.load(open(PENDING_FILE, "r", encoding="utf-8")))
        except Exception:
            pass
    return set()

def mark_pending(ids):
    cur = get_pending()
    for i in ids:
        if i:
            cur.add(str(i))
    with open(PENDING_FILE, "w", encoding="utf-8") as f:
        json.dump(sorted(cur), f)

def load_settings():
    cfg = dict(DEFAULT_SETTINGS)
    if os.path.exists(SETTINGS_PATH):
        try:
            cfg.update(json.load(open(SETTINGS_PATH, "r", encoding="utf-8")))
        except Exception:
            pass
    return cfg

def save_settings(cfg):
    data = dict(DEFAULT_SETTINGS)
    data.update(cfg or {})
    with open(SETTINGS_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    return data

def load_db():
    with open(DB_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

def save_db(data):
    ensure_backup()
    fd, tmp_path = tempfile.mkstemp(prefix=".matdb_", suffix=".tmp", dir=os.path.dirname(DB_PATH))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        os.chmod(tmp_path, 0o644)
        os.replace(tmp_path, DB_PATH)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
    sync_all_targets(data)

def build_entry(tpl, pid, brand, name, mtype, t_nozzle, t_init, t_bed, mvol, dens=1.24, dry_t=55, dry_h=6):
    entry = copy.deepcopy(tpl)
    b, kv = entry["base"], entry["kvParam"]
    b["id"], b["brand"], b["name"], b["meterialType"] = str(pid).strip(), str(brand).strip(), str(name).strip(), str(mtype).strip()
    b["density"] = float(dens)
    b["minTemp"], b["maxTemp"] = int(float(t_nozzle)) - 20, int(float(t_nozzle)) + 15
    b["dryingTemp"], b["dryingTime"] = int(float(dry_t)), int(float(dry_h))
    b["dryingTempLow"], b["dryingTempHigh"] = int(float(dry_t)) - 5, int(float(dry_t)) + 5
    kv["filament_vendor"], kv["filament_type"], kv["filament_density"] = b["brand"], b["meterialType"], str(dens)
    kv["nozzle_temperature"], kv["nozzle_temperature_initial_layer"] = str(int(float(t_nozzle))), str(int(float(t_init)))
    kv["nozzle_temperature_range_low"], kv["nozzle_temperature_range_high"] = str(b["minTemp"]), str(b["maxTemp"])
    kv["textured_plate_temp"] = kv["textured_plate_temp_initial_layer"] = kv["hot_plate_temp"] = kv["hot_plate_temp_initial_layer"] = str(int(float(t_bed)))
    kv["filament_max_volumetric_speed"] = str(mvol)
    return entry

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

    def _send_json(self, code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if urlparse(self.path).path == "/cfs-gate/pending":
            fn = _PENDING_ORCA_PRINT.get("filename", "")
            self._send_json(200, {"filename": fn})
            return
        p = urlparse(self.path).path
        if p == "/api/materials":
            try:
                data = load_db()
                rows = []
                for item in data.get("result", {}).get("list", []):
                    b, kv = item.get("base", {}), item.get("kvParam", {})
                    pid = str(b.get("id", ""))
                    rows.append({
                        "id": pid, "brand": b.get("brand", ""), "name": b.get("name", ""),
                        "type": b.get("meterialType", ""), "nozzle_temp": kv.get("nozzle_temperature", ""),
                        "nozzle_init": kv.get("nozzle_temperature_initial_layer", kv.get("nozzle_temperature", "")),
                        "bed_temp": kv.get("textured_plate_temp", ""), "max_vol": kv.get("filament_max_volumetric_speed", ""),
                        "density": b.get("density", 1.24), "dry_temp": b.get("dryingTemp", 55),
                        "dry_time": b.get("dryingTime", 6), "custom": pid.isdigit() and int(pid) >= 90000, "pending": pid in get_pending()
                    })
                self._send_json(200, {"ok": True, "has_backup": os.path.exists(BACKUP_PATH), "pending_count": len(get_pending()), "settings": load_settings(), "items": rows})
            except Exception as e:
                self._send_json(500, {"ok": False, "error": str(e)})
            return
        if p == "/api/presets":
            data = load_db()
            by_id = {str(i.get("base", {}).get("id", "")): i for i in data.get("result", {}).get("list", [])}
            plist = []
            for r in PRESET_PACK_7:
                pid, brand, name, mtype, noz, ini, bed, mvol = r.__getitem__(0), r.__getitem__(1), r.__getitem__(2), r.__getitem__(3), r.__getitem__(4), r.__getitem__(5), r.__getitem__(6), r.__getitem__(7)
                ex = by_id.get(pid)
                if not ex:
                    plist.append({"id": pid, "brand": brand, "name": name, "type": mtype, "nozzle": noz, "bed": bed, "max_vol": mvol, "state": "new"})
                else:
                    eb, ekv = ex.get("base", {}), ex.get("kvParam", {})
                    if eb.get("brand") != brand or eb.get("name") != name or str(ekv.get("nozzle_temperature")) != str(noz) or str(ekv.get("textured_plate_temp")) != str(bed):
                        plist.append({"id": pid, "brand": brand, "name": name, "type": mtype, "nozzle": noz, "bed": bed, "max_vol": mvol, "state": "modified"})
            self._send_json(200, {"ok": True, "presets": plist})
            return
        if p == "/api/download_bat":
            host = (self.headers.get("Host") or "").partition(":").__getitem__(0).strip() or "127.0.0.1"
            with open(os.path.join(WEB_ROOT, "Send_Filament_to_K1C.bat"), "r", encoding="utf-8") as f:
                bat = f.read().replace("__IP__", host).replace("__ALLOW_CF__", "1" if load_settings().get("allow_cf") else "0").replace("\n", "\r\n").encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", 'attachment; filename="Send_Filament_to_K1C.bat"')
            self.send_header("Content-Length", str(len(bat)))
            self.end_headers()
            self.wfile.write(bat)
            return
        if p == "/api/export":
            with open(DB_PATH, "rb") as f: raw = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Disposition", 'attachment; filename="material_database.json"')
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)
            return
        idx = os.path.join(WEB_ROOT, "index.html")
        with open(idx, "rb") as f: html = f.read()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(html)))
        self.end_headers()
        self.wfile.write(html)

    def do_POST(self):
        _pp = urlparse(self.path).path
        if _pp in ("/server/files/upload", "/api/files/local"):
            _forward_upload_no_autoprint(self, _pp)
            return
        if _pp == "/cfs-gate/clear":
            _PENDING_ORCA_PRINT["filename"] = ""
            self._send_json(200, {"ok": True})
            return
        if _pp == "/cfs-gate/enabled":
            cl = int(self.headers.get("Content-Length", "0") or "0")
            body = json.loads(self.rfile.read(cl).decode("utf-8") or "{}")
            _PENDING_ORCA_PRINT["enabled"] = bool(body.get("enabled", True))
            self._send_json(200, {"ok": True, "enabled": _PENDING_ORCA_PRINT["enabled"]})
            return
        p = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length).decode("utf-8")) if length else {}
        try:
            data = load_db()
            items = data.get("result", {}).get("list", [])
            tpl = next((i for i in items if i.get("base", {}).get("id") == "01001"), items)
            if p == "/api/save":
                pid = str(body.get("id", "")).strip()
                if not pid:
                    nums = [int(i["base"]["id"]) for i in items if str(i["base"].get("id", "")).isdigit() and int(i["base"]["id"]) >= 90000]
                    pid = str(max(nums + [90000]) + 1)
                entry = build_entry(tpl, pid, (body.get("brand") or "").strip() or "Custom", (body.get("name") or "").strip() or "Custom", body.get("type","PLA"),
                                    body.get("nozzle_temp",215), body.get("nozzle_init",215), body.get("bed_temp",60),
                                    body.get("max_vol",15), body.get("density",1.24), body.get("dry_temp",55), body.get("dry_time",6))
                for idx, it in enumerate(items):
                    if str(it.get("base", {}).get("id", "")) == pid:
                        items[idx] = entry; break
                else:
                    items.append(entry)
                save_db(data)
                mark_pending((pid,))
                self._send_json(200, {"ok": True, "id": pid})
            elif p == "/api/delete":
                pid = str(body.get("id", "")).strip()
                if not (pid.isdigit() and int(pid) >= 90000):
                    self._send_json(400, {"ok": False, "error": "Stock entries are protected."}); return
                data["result"]["list"] = [i for i in items if str(i.get("base", {}).get("id", "")) != pid]
                save_db(data)
                self._send_json(200, {"ok": True})
            elif p == "/api/import_pack7":
                existing = {str(i.get("base", {}).get("id", "")) for i in items}
                added = sum(1 for r in PRESET_PACK_7 if r[0] not in existing and not items.append(build_entry(tpl, *r)))
                save_db(data)
                mark_pending(sel_ids)
                self._send_json(200, {"ok": True, "added": added})
            elif p == "/api/import_orca":
                files = body.get("files", [])
                cfg_s = load_settings()
                allow_cf = bool(body.get("allow_cf", False)) and bool(cfg_s.get("allow_cf", False))
                added, updated, skipped_cf = 0, 0, []
                def val(d, k, default):
                    v = d.get(k, default)
                    return next(iter(v)) if isinstance(v, list) and v else (v if v not in (None, "") else default)
                for raw_f in files:
                    try:
                        cfg = json.loads(raw_f) if isinstance(raw_f, str) else raw_f
                    except Exception:
                        continue
                    raw_name = str(val(cfg, "name", "")).partition("@").__getitem__(0).strip()
                    inh = str(val(cfg, "inherits", "")).partition("@").__getitem__(0).strip()
                    probe = f"{val(cfg, 'filament_type', '')} {raw_name} {inh}".upper()
                    if ("-CF" in probe or "-GF" in probe) and not allow_cf:
                        skipped_cf.append(raw_name or inh or "CF/GF Filament")
                        continue
                    mtype = str(val(cfg, "filament_type", "")).strip()
                    if not mtype:
                        for cand in ("PLA-CF", "PETG-CF", "PA-CF", "ASA", "ABS", "PETG", "TPU", "PA", "PC", "PLA"):
                            if cand in probe:
                                mtype = cand
                                break
                        else:
                            mtype = "PLA"
                    brand = str(val(cfg, "filament_vendor", "")).strip()
                    if not brand:
                        for known in ("Creality", "Sunlu", "Jayo", "Eryone", "eSun", "Bambu", "Polymaker", "Prusament", "Anycubic", "Elegoo"):
                            if known.lower() in f"{raw_name} {inh}".lower():
                                brand = known
                                break
                        else:
                            brand = "Custom"
                    full_name = raw_name or mtype
                    if full_name.lower().startswith(brand.lower() + " "):
                        full_name = full_name[len(brand)+1:].strip()
                    t_noz = val(cfg, "nozzle_temperature", "220")
                    t_ini = val(cfg, "nozzle_temperature_initial_layer", t_noz)
                    t_bed = val(cfg, "textured_plate_temp", val(cfg, "hot_plate_temp", "60"))
                    mvol = val(cfg, "filament_max_volumetric_speed", "15")
                    dens = val(cfg, "filament_density", "1.24")
                    dry_t = 80 if "ABS" in mtype.upper() or "ASA" in mtype.upper() else (65 if "PETG" in mtype.upper() else 50)
                    match = next((it for it in items if str(it.get("base", {}).get("id", "")).isdigit() and int(it["base"]["id"]) >= 90000 and it["base"].get("brand","").lower() == brand.lower() and it["base"].get("name","").lower() == full_name.lower()), None)
                    if match:
                        pid = match["base"]["id"]
                        idx = items.index(match)
                        items[idx] = build_entry(tpl, pid, brand, full_name, mtype, t_noz, t_ini, t_bed, mvol, dens, dry_t, 6)
                        updated += 1
                    else:
                        nums = [int(i["base"]["id"]) for i in items if str(i["base"].get("id", "")).isdigit() and int(i["base"]["id"]) >= 90000]
                        pid = str(max(nums or (90000,)) + 1)
                        items.append(build_entry(tpl, pid, brand, full_name, mtype, t_noz, t_ini, t_bed, mvol, dens, dry_t, 6))
                        added += 1
                save_db(data)
                mark_pending(tuple(str(i.get("base", {}).get("id", "")) for i in items if str(i.get("base", {}).get("id", "")).isdigit() and int(i["base"]["id"]) >= 90000))
                self._send_json(200, {"ok": True, "added": added, "updated": updated, "skipped_cf": skipped_cf})
            elif p == "/api/settings":
                self._send_json(200, {"ok": True, "settings": save_settings(body.get("settings", body))})
            elif p == "/api/restore_backup":
                shutil.copy2(BACKUP_PATH, DB_PATH)
                self._send_json(200, {"ok": True})
        except Exception as e:
            self._send_json(500, {"ok": False, "error": str(e)})

if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
