window.openMapAndPrintModal = async function(prefillPath = "") {
  const ex = document.getElementById("cfs-map-print-modal");
  if (ex) ex.remove();
  const ov = document.createElement("div");
  ov.id = "cfs-map-print-modal";
  ov.style.cssText = "position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:99999;display:flex;align-items:center;justify-content:center;padding:16px;";
  const box = document.createElement("div");
  box.style.cssText = "background:#1e2028;color:#f3f4f6;border:1px solid #374151;border-radius:12px;width:100%;max-width:600px;overflow:hidden;";
  box.innerHTML = [
    '<div style="display:flex;justify-content:space-between;padding:14px 20px;border-bottom:1px solid #2d313d;background:#181a20;font-weight:700;">',
    '<span>Map Filaments & Start Print</span><button id="cfs-mp-close" style="background:none;border:none;color:#9ca3af;font-size:20px;cursor:pointer;">&times;</button></div>',
    '<div style="padding:18px 20px;display:flex;flex-direction:column;gap:12px;">',
    '<select id="cfs-mp-file" style="width:100%;padding:9px;border-radius:8px;background:#13151a;color:#f3f4f6;border:1px solid #374151;"></select>',
    '<div style="font-size:13px;color:#d1d5db;">Bitte wählen Sie den CFS-Slot aus, der den Verbrauchsmaterialien entspricht:</div>',
    '<div id="cfs-mp-warn" style="display:none;color:#ef4444;font-size:13px;font-weight:600;background:rgba(239,68,68,0.12);border:1px solid rgba(239,68,68,0.35);padding:8px 12px;border-radius:8px;">',
    'Es gibt Verbrauchsmaterialien ohne Zuordnung – Drucken nicht möglich.</div>',
    '<div id="cfs-mp-cards" style="display:flex;flex-wrap:wrap;gap:12px;min-height:105px;"></div>',
    '<label style="display:flex;align-items:center;gap:8px;font-size:13px;background:#262934;padding:10px;border-radius:8px;cursor:pointer;">',
    '<input type="checkbox" id="cfs-mp-auto"><span>Auto-open this mapping dialog when a print starts</span></label>',
    '<div style="display:flex;justify-content:flex-end;gap:10px;">',
    '<button id="cfs-mp-cancel" style="padding:8px 16px;border-radius:8px;background:#2d313d;color:#fff;border:1px solid #3f4454;cursor:pointer;">Cancel</button>',
    '<button id="cfs-mp-start" style="padding:8px 18px;border-radius:8px;background:#4f7df3;color:#fff;border:none;cursor:pointer;font-weight:700;">Apply & Print</button></div></div>'
  ].join("");
  ov.appendChild(box); document.body.appendChild(ov);
  const close = () => ov.remove();
  box.querySelector("#cfs-mp-close").onclick = close;
  box.querySelector("#cfs-mp-cancel").onclick = close;
  const autoCb = box.querySelector("#cfs-mp-auto");
  autoCb.checked = localStorage.getItem("cfs_auto_map_modal") !== "0";
  autoCb.onchange = () => localStorage.setItem("cfs_auto_map_modal", autoCb.checked ? "1" : "0");
  const fileSel = box.querySelector("#cfs-mp-file");
  const cardsEl = box.querySelector("#cfs-mp-cards");
  const warnEl = box.querySelector("#cfs-mp-warn");
  const startBtn = box.querySelector("#cfs-mp-start");
  const normMat = (m) => String(m || "").trim().toUpperCase().replace(/[^A-Z0-9+-]/g, "");
  const rgbToHex = (c) => {
    if (!c) return "";
    const s = String(c).trim();
    if (s.startsWith("#")) return s.replace(/^#/, "").toUpperCase().slice(0, 6);
    const m = s.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/i);
    if (!m) return "";
    return [m[1], m[2], m[3]].map((x) => parseInt(x, 10).toString(16).padStart(2, "0")).join("").toUpperCase();
  };
  let reqs = [], assigns = [];

  function getLoadedSlots() {
    const out = [], seen = new Set();
    document.querySelectorAll("*").forEach((el) => {
      if (el.children.length > 4 || (el.innerText.match(/CHANNEL\s+\d+[A-D]/gi) || []).length !== 1) return;
      const txt = (el.innerText || "").trim();
      const m = txt.match(/CHANNEL\s+(\d+[A-D])\s*\n+\s*([^\n]+)/i);
      if (!m) return;
      const id = m[1].toUpperCase(), mat = m[2].trim();
      if (seen.has(id)) return;
      seen.add(id);
      if (!mat || mat.toLowerCase() === "empty" || mat === "---") return;
      let hex = "9CA3AF";
      el.querySelectorAll("div,span,svg,circle").forEach((sub) => {
        const bg = getComputedStyle(sub).backgroundColor;
        const h = rgbToHex(bg);
        if (h && h !== "000000" && bg !== "rgba(0, 0, 0, 0)" && sub.offsetWidth >= 14 && sub.offsetWidth <= 48) hex = h;
      });
      if (hex === "9CA3AF") {
        el.querySelectorAll("div,span").forEach((sub) => {
          const bg = getComputedStyle(sub).backgroundColor;
          if (bg === "rgb(0, 0, 0)" && sub.offsetWidth >= 14 && sub.offsetWidth <= 48) hex = "111111";
        });
      }
      out.push({ id, mat, nm: normMat(mat), col: `#${hex}`, nc: hex });
    });
    return out.sort((a, b) => a.id.localeCompare(b.id));
  }

  function validate() {
    const bad = reqs.length > 0 && assigns.some((a) => !a);
    warnEl.style.display = bad ? "block" : "none";
    startBtn.disabled = bad;
    startBtn.style.opacity = bad ? "0.45" : "1";
    startBtn.style.cursor = bad ? "not-allowed" : "pointer";
  }
  function render(list, slots) {
    reqs = list;
    assigns = reqs.map((r) => {
      const ex = slots.find((s) => s.nm === r.nm && r.nc && s.nc === r.nc);
      if (ex) return ex.id;
      const mo = slots.find((s) => s.nm === r.nm);
      return mo ? mo.id : "";
    });
    cardsEl.innerHTML = "";
    reqs.forEach((r, idx) => {
      const card = document.createElement("div");
      card.style.cssText = "flex:1 1 130px;max-width:170px;background:#16181f;border:1px solid #2d313d;border-radius:10px;padding:10px;display:flex;flex-direction:column;gap:8px;align-items:center;";
      const top = document.createElement("div");
      top.style.cssText = `width:100%;padding:8px;border-radius:6px;background:${r.col};color:${r.tc};font-weight:700;font-size:14px;text-align:center;border:1px solid rgba(255,255,255,0.2);`;
      top.textContent = r.mat;
      card.appendChild(top);
      const pill = document.createElement("div");
      const sel = document.createElement("select");
      sel.style.cssText = "width:100%;padding:6px;border-radius:6px;background:#232733;color:#f3f4f6;border:1px solid #3f4454;font-size:12px;";
      const o0 = document.createElement("option");
      o0.value = ""; o0.textContent = "-- Leer --";
      sel.appendChild(o0);
      slots.forEach((s) => {
        const o = document.createElement("option");
        o.value = s.id; o.textContent = `${s.id} / ${s.mat}`;
        sel.appendChild(o);
      });
      sel.value = assigns[idx] || "";
      const drawPill = () => {
        const ch = slots.find((s) => s.id === sel.value);
        if (!ch) {
          pill.style.cssText = "width:100%;padding:7px;border-radius:6px;background:#1f222b;border:1px dashed #ef4444;color:#9ca3af;font-size:13px;text-align:center;";
          pill.textContent = "--";
        } else {
          pill.style.cssText = "width:100%;padding:7px;border-radius:6px;background:#232733;border:1px solid #374151;color:#f3f4f6;font-size:13px;text-align:center;font-weight:600;";
          pill.innerHTML = `<span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${ch.col};margin-right:6px;border:1px solid rgba(255,255,255,0.35);"></span>${ch.id} / ${ch.mat}`;
        }
      };
      drawPill();
      sel.onchange = () => { assigns[idx] = sel.value; drawPill(); validate(); };
      card.appendChild(pill); card.appendChild(sel); cardsEl.appendChild(card);
    });
    validate();
  }

  async function loadGcode(path) {
    cardsEl.innerHTML = '<div style="color:#9ca3af;font-size:13px;">Reading G-Code...</div>';
    warnEl.style.display = "none"; startBtn.disabled = true;
    try {
      let types = [], cols = [];
      try {
        const mr = await fetch(`/server/files/metadata?filename=${encodeURIComponent(path)}`);
        const mj = await mr.json();
        const meta = mj.result || {};
        if (meta.filament_type) types = String(meta.filament_type).split(/[;,]+/).map((x) => x.trim()).filter(Boolean);
        if (Array.isArray(meta.filament_colors)) cols = meta.filament_colors;
        else if (meta.filament_colors) cols = String(meta.filament_colors).split(/[;,]+/).map((x) => x.trim()).filter(Boolean);
      } catch (e) {}

      const url = `/server/files/gcodes/${encodeURIComponent(path)}`;
      const r1 = await fetch(url, { headers: { Range: "bytes=0-65535" } });
      const t1 = await r1.text();
      const cr = r1.headers.get("Content-Range") || "";
      const tot = parseInt(cr.split("/").slice(1, 2).join("") || "0", 10);
      let t2 = "";
      if (tot > 65536) {
        const r2 = await fetch(url, { headers: { Range: `bytes=${Math.max(0, tot - 65536)}-${tot - 1}` } });
        t2 = await r2.text();
      }
      const txt = t1 + "\n" + t2;
      if (!types.length) {
        const tm = txt.match(/^;\s*filament_type\s*=\s*(.+)$/m);
        if (tm) types = tm.slice(1, 2).join("").split(/[;,]+/).map((x) => x.trim()).filter(Boolean);
      }
      if (!cols.length) {
        const cm = txt.match(/^;\s*filament_colour\s*=\s*(.+)$/m) || txt.match(/^;\s*default_filament_colour\s*=\s*(.+)$/m);
        if (cm) cols = cm.slice(1, 2).join("").split(/[;,]+/).map((x) => x.trim()).filter(Boolean);
      }
      const usedMatch = txt.match(/^;\s*filament_used_g\s*=\s*(.+)$/m) || txt.match(/^;\s*filament used \[g\]\s*=\s*(.+)$/m);
      const usedArr = usedMatch ? usedMatch.slice(1, 2).join("").split(/[;,]+/).map((x) => parseFloat(x.trim()) || 0) : [];

      const count = Math.max(types.length, cols.length, usedArr.length, 1);
      const fnm = path.match(/(?:_|\b)(PLA-CF|PETG-CF|PA-CF|ASA|ABS|PETG|TPU|PLA|PA|PC)(?:_|\b)/i);
      const fb = fnm ? fnm.slice(1, 2).join("").toUpperCase() : "PLA";

      const toolIds = [];
      for (let i = 0; i < count; i++) {
        if (usedArr.length && usedArr.slice(i, i + 1).pop() <= 0 && count > 1) continue;
        toolIds.push(i);
      }
      if (!toolIds.length) toolIds.push(0);

      const list = toolIds.map((t) => {
        const mat = types.slice(t, t + 1).join("") || types.slice(0, 1).join("") || fb;
        const rawC = cols.slice(t, t + 1).join("") || cols.slice(0, 1).join("") || "#374151";
        const col = rawC.startsWith("#") ? rawC : `#${rawC}`;
        const h = rgbToHex(col);
        const tc = h.length === 6 && (parseInt(h.slice(0,2),16)*299 + parseInt(h.slice(2,4),16)*587 + parseInt(h.slice(4,6),16)*114)/1000 > 145 ? "#111827" : "#ffffff";
        return { t, mat, nm: normMat(mat), col, nc: h, tc };
      });
      render(list, getLoadedSlots());
    } catch (err) {
      cardsEl.innerHTML = `<div style="color:#ef4444;font-size:13px;">Fehler: ${err.message}</div>`;
    }
  }

  const r = await fetch("/server/files/list?root=gcodes");
  const j = await r.json();
  const files = (j.result || []).sort((a, b) => (b.modified || 0) - (a.modified || 0));
  files.forEach((f) => { const o = document.createElement("option"); o.value = f.path; o.textContent = f.path; fileSel.appendChild(o); });
  const initF = prefillPath || files.slice(0, 1).map((x) => x.path).join("");
  if (initF) { fileSel.value = initF; await loadGcode(initF); }
  fileSel.onchange = () => { if (fileSel.value) loadGcode(fileSel.value); };
  startBtn.onclick = async () => {
    if (startBtn.disabled) return;
    const cmds = reqs.map((rq, i) => assigns[i] ? `CFS_MAP_TOOL T=${rq.t} SLOT=${assigns[i]}` : "").filter(Boolean);
    const script = [...cmds, `SDCARD_PRINT_FILE FILENAME="${fileSel.value}"`].join("\n");
    close();
    await fetch("/printer/gcode/script", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ script }) });
  };
};
