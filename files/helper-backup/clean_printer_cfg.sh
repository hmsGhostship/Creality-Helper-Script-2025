#!/bin/sh

CFG_PATH="/usr/data/printer_data/config/printer.cfg"

if [ ! -f "$CFG_PATH" ]; then
    echo "Error: printer.cfg not found at $CFG_PATH!"
    exit 1
fi

echo "Starting safe configuration cleanup..."
cp "$CFG_PATH" "${CFG_PATH}.bak"

python3 - "$CFG_PATH" << 'PYEOF'
import sys, re, os

cfg_path = sys.argv
with open(cfg_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

header_marker = "#*# <---------------------- SAVE_CONFIG ---------------------->"
first_idx = None
for i, line in enumerate(lines):
    if line.startswith(header_marker):
        first_idx = i
        break

if first_idx is None:
    print("No SAVE_CONFIG block found. Nothing to clean.")
    sys.exit(0)

main_lines = lines[:first_idx]
save_lines = lines[first_idx:]

sections = {}
section_order = []
current_sec = None

for line in save_lines:
    s = line.strip()
    if not s or s == "#*#" or s.startswith("#*# <---") or s.startswith("#*# DO NOT EDIT"):
        continue
    m = re.match(r"^#\*#\s*\[([^\]]+)\]\s*$", s)
    if m:
        current_sec = m.group(1).strip()
        if current_sec not in sections:
            section_order.append(current_sec)
            sections[current_sec] = []
        else:
            if current_sec != "serial_can":
                sections[current_sec] = []
        continue
    if current_sec is not None and s.startswith("#*#"):
        if current_sec == "serial_can" and "=" in s:
            key = s.split("=", 1).strip()
            sections[current_sec] = [l for l in sections[current_sec] if l.split("=", 1).strip() != key]
        sections[current_sec].append(line if line.endswith("\n") else line + "\n")

out = list(main_lines)
if out and out[-1].strip() != "":
    out.append("\n")
out.append("#*# <---------------------- SAVE_CONFIG ---------------------->\n")
out.append("#*# DO NOT EDIT THIS BLOCK OR BELOW. The contents are auto-generated.\n")

for sec in section_order:
    if sections[sec]:
        out.append("#*#\n")
        out.append(f"#*# [{sec}]\n")
        out.extend(sections[sec])

tmp_path = cfg_path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    f.writelines(out)

os.replace(tmp_path, cfg_path)
print(f"Cleaned SAVE_CONFIG successfully! Deduplicated {len(section_order)} section(s): {', '.join(section_order)}")
PYEOF

echo "Backup saved to ${CFG_PATH}.bak"
echo "NOTE: Please restart Klipper manually in Mainsail/Fluidd now."
