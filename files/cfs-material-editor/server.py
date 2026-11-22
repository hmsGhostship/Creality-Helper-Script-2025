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
DEFAULT_SETTINGS = {"allow_cf": False}

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
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
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
                        "dry_time": b.get("dryingTime", 6), "custom": pid.isdigit() and int(pid) >= 90000
                    })
                self._send_json(200, {"ok": True, "has_backup": os.path.exists(BACKUP_PATH), "settings": load_settings(), "items": rows})
            except Exception as e:
                self._send_json(500, {"ok": False, "error": str(e)})
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
                entry = build_entry(tpl, pid, body.get("brand","Custom"), body.get("name","Custom"), body.get("type","PLA"),
                                    body.get("nozzle_temp",215), body.get("nozzle_init",215), body.get("bed_temp",60),
                                    body.get("max_vol",15), body.get("density",1.24), body.get("dry_temp",55), body.get("dry_time",6))
                for idx, it in enumerate(items):
                    if str(it.get("base", {}).get("id", "")) == pid:
                        items[idx] = entry; break
                else:
                    items.append(entry)
                save_db(data)
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
