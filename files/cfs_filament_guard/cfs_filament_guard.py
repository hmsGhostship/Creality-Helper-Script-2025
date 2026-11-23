#!/usr/bin/env python3
import os, re, sys, json, sqlite3, urllib.request, urllib.parse

GCODES_DIR = "/usr/data/printer_data/gcodes"
MOONRAKER_DB = "/usr/data/printer_data/database/moonraker-sql.db"
MAT_DB_PATHS = [
    "/usr/data/printer_data/config/material_database.json",
    "/usr/share/creality/material_database.json",
]

def cancel_klipper_print(reason):
    try:
        msg = urllib.parse.quote(f"RESPOND TYPE=error MSG=\"{reason}\"
CANCEL_PRINT")
        urllib.request.urlopen(f"http://127.0.0{msg}", timeout=2.5).read()
    except Exception:
        pass

def load_mat_lookup():
    lookup = {}
    for path in MAT_DB_PATHS:
        if not os.path.exists(path):
            continue
        try:
            data = json.load(open(path, "r", encoding="utf-8"))
            items = data.get("result", {}).get("list", []) if isinstance(data, dict) else []
            for it in items:
                base = it.get("base", {})
                mid = str(base.get("id", "")).strip()
                mtype = str(base.get("type", "")).strip().upper()
                if mid and mtype:
                    lookup[mid] = mtype
        except Exception:
            pass
    return lookup

def hex_to_rgb(h):
    h = str(h or "").strip().lstrip("#")
    if len(h) == 8:
        h = h[:6]
    if len(h) != 6:
        return None
    try:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    except Exception:
        return None

def int_color_to_rgb(c):
    try:
        v = int(c)
        if v < 0:
            return None
        return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
    except Exception:
        return None

def color_dist(c1, c2):
    if c1 is None or c2 is None:
        return 0
    return ((c1[0]-c2[0])**2 + (c1[1]-c2[1])**2 + (c1[2]-c2[2])**2) ** 0.5

def get_loaded_cfs_slots():
    if not os.path.exists(MOONRAKER_DB):
        return None
    con = sqlite3.connect(MOONRAKER_DB)
    row = con.execute("SELECT value FROM namespace_store WHERE namespace=? AND key=?", ("color_box", "box_info")).fetchone()
    con.close()
    if not row:
        return None
    info = json.loads(row[0])
    t1 = info.get("T1", {})
    mat_lookup = load_mat_lookup()
    slots = []
    for idx, item in enumerate(t1.get("list", [])):
        if int(item.get("enable", 0)) != 1:
            continue
        mid = str(item.get("material_id", "")).strip()
        mtype = str(item.get("type", "")).strip().upper()
        if not mtype or mtype in ("NONE", "-1"):
            mtype = mat_lookup.get(mid, "")
        rgb = int_color_to_rgb(item.get("color", -1))
        slots.append({"slot": f"1{chr(65+idx)}", "type": mtype, "rgb": rgb, "mid": mid})
    return slots

def parse_gcode_requirements(gcode_rel):
    path = os.path.join(GCODES_DIR, gcode_rel.lstrip("/"))
    if not os.path.isfile(path):
        return []
    ftypes = []
    fcolours = []
    used_tools = set()
    initial_tool = None

    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for i, line in enumerate(f):
            s = line.strip()
            if s.startswith("; filament_type ="):
                ftypes = [x.strip().upper() for x in s.split("=", 1)[1].split(";")]
            elif s.startswith("; filament_colour ="):
                fcolours = [x.strip() for x in s.split("=", 1)[1].split(";")]
            elif s.startswith("; initial_tool ="):
                try:
                    initial_tool = int(s.split("=", 1)[1].strip())
                except Exception:
                    pass
            else:
                m = re.match(r"^T([0-3])(?:\s|;|$)", s)
                if m:
                    used_tools.add(int(m.group(1)))
            if i > 12000 and used_tools and ftypes:
                break

    if not used_tools and initial_tool is not None:
        used_tools.add(initial_tool)
    if not used_tools and ftypes:
        used_tools.add(0)

    reqs = []
    for t in sorted(used_tools):
        mt = ftypes[t] if t < len(ftypes) else (ftypes[0] if ftypes else "")
        fc = fcolours[t] if t < len(fcolours) else ""
        if mt:
            reqs.append({"tool": f"T{t}", "type": mt, "hex": fc, "rgb": hex_to_rgb(fc)})
    return reqs

def main():
    gcode_file = sys.argv[1] if len(sys.argv) > 1 else ""
    check_color = (sys.argv[2] if len(sys.argv) > 2 else "1") != "0"
    if not gcode_file:
        sys.exit(0)
    slots = get_loaded_cfs_slots()
    if slots is None:
        sys.exit(0)
    reqs = parse_gcode_requirements(gcode_file)
    if not reqs:
        sys.exit(0)

    for req in reqs:
        type_matches = [s for s in slots if s["type"] == req["type"]]
        if not type_matches:
            msg = f"CFS-C Guard: Print canceled! Required material {req['type']} ({req['tool']}) is not loaded in CFS-C."
            print(msg)
            cancel_klipper_print(msg)
            sys.exit(2)
        if check_color and req["rgb"] is not None:
            best_dist = min(color_dist(req["rgb"], s["rgb"]) for s in type_matches)
            if best_dist > 95:
                msg = f"CFS-C Guard: Print canceled! No {req['type']} matching color {req['hex']} ({req['tool']}) is loaded in CFS-C."
                print(msg)
                cancel_klipper_print(msg)
                sys.exit(3)
    print("CFS-C Guard: All required filaments are loaded in CFS-C.")
    sys.exit(0)

if __name__ == "__main__":
    main()
