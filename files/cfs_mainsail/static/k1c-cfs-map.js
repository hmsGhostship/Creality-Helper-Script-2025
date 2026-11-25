window.openMapAndPrintModal = async function(prefillPath = "", fromAutoTrigger = false) {
  const ex = document.getElementById("cfs-map-print-modal");
  if (ex) ex.remove();
  const ov = document.createElement("div");
  ov.id = "cfs-map-print-modal";
  ov.style.cssText = "position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:99999;display:flex;align-items:center;justify-content:center;padding:16px;overscroll-behavior:contain;";
  const box = document.createElement("div");
  box.style.cssText = "background:#1e2028;color:#f3f4f6;border:1px solid #374151;border-radius:12px;width:100%;max-width:600px;overflow:visible;";
  box.innerHTML = [
    '<div style="display:flex;justify-content:space-between;padding:14px 20px;border-bottom:1px solid #2d313d;background:#181a20;font-weight:700;">',
    '<span>Map Filaments & Start Print</span><button id="cfs-mp-close" style="background:none;border:none;color:#9ca3af;font-size:20px;cursor:pointer;">&times;</button></div>',
    '<div style="padding:18px 20px;display:flex;flex-direction:column;gap:12px;">',
    '<select id="cfs-mp-file" style="width:100%;padding:9px;border-radius:8px;background:#13151a;color:#f3f4f6;border:1px solid #374151;"></select>',
    '<div style="font-size:13px;color:#d1d5db;">Please select the CFS slot matching each filament:</div>',
    '<div id="cfs-mp-warn" style="display:none;color:#ef4444;font-size:13px;font-weight:600;background:rgba(239,68,68,0.12);border:1px solid rgba(239,68,68,0.35);padding:8px 12px;border-radius:8px;">',
    'Unassigned filaments remaining – printing disabled.</div>',
    '<div id="cfs-mp-cards" style="display:flex;flex-wrap:wrap;gap:12px;min-height:105px;"></div>',
    '<div style="display:flex;justify-content:flex-end;gap:10px;">',
    '<button id="cfs-mp-cancel" style="padding:8px 16px;border-radius:8px;background:#2d313d;color:#fff;border:1px solid #3f4454;cursor:pointer;">Cancel</button>',
    '<button id="cfs-mp-start" style="padding:8px 18px;border-radius:8px;background:#4f7df3;color:#fff;border:none;cursor:pointer;font-weight:700;">Apply & Print</button></div></div>'
  ].join("");
  ov.appendChild(box); document.body.appendChild(ov);
  const close = () => { ov.remove(); window.__cfsAutoMapOpenFor = ""; };
  const cancelAuto = async () => {
    close();
    if (fromAutoTrigger) {
      await fetch("/printer/gcode/script", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ script: "_CFS_CANCEL_MAP" })
      });
    }
  };
  box.querySelector("#cfs-mp-close").onclick = cancelAuto;
  box.querySelector("#cfs-mp-cancel").onclick = cancelAuto;
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
    const parseColorAny = (raw) => {
      if (!raw) return "";
      const str = String(raw).trim();
      if (str.startsWith("#")) {
        let h = str.replace(/^#/, "").toUpperCase();
        if (h.length === 3) h = h.split("").map((c) => c + c).join("");
        return h.slice(0, 6);
      }
      const m = str.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i);
      if (!m) return "";
      return [m.slice(1,2).join(""), m.slice(2,3).join(""), m.slice(3,4).join("")]
        .map((x) => parseInt(x, 10).toString(16).padStart(2, "0")).join("").toUpperCase();
    };

    document.querySelectorAll(".k1c-cfs-item:not(.empty)").forEach((item) => {
      const chEl = item.querySelector(".k1c-cfs-channel");
      const tpEl = item.querySelector(".k1c-cfs-type");
      const spEl = item.querySelector(".k1c-cfs-spool") || item;
      const chTxt = String((chEl && chEl.textContent) || item.innerText || "").trim();
      const m = chTxt.match(/(\d+[A-D])/i);
      if (!m) return;
      const id = m.slice(1, 2).join("").toUpperCase();
      const mat = String((tpEl && tpEl.textContent) || "").trim();
      if (!mat || mat.toLowerCase() === "empty" || mat === "---" || seen.has(id)) return;
      seen.add(id);

      const rawVar = getComputedStyle(spEl).getPropertyValue("--spool-color")
        || getComputedStyle(item).getPropertyValue("--spool-color")
        || getComputedStyle(spEl).backgroundColor;
      const hex = parseColorAny(rawVar) || "9CA3AF";
      const rem = (item.dataset && item.dataset.rfidRem) ? item.dataset.rfidRem : "";
      out.push({ id, mat, rem, nm: normMat(mat), col: `#${hex}`, nc: hex });
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
    const fgFor = (hex) => {
      const h = String(hex || "").replace(/^#/, "");
      if (h.length !== 6) return "#ffffff";
      const lum = (parseInt(h.slice(0, 2), 16) * 299 + parseInt(h.slice(2, 4), 16) * 587 + parseInt(h.slice(4, 6), 16) * 114) / 1000;
      return lum > 145 ? "#111827" : "#ffffff";
    };
    reqs = list;
    const baseMat = (m) => {
      const u = String(m || "").toUpperCase().replace(/[^A-Z0-9]/g, "");
      if (u.startsWith("PLACF")) return "PLACF";
      if (u.startsWith("PETGCF")) return "PETGCF";
      if (u.startsWith("PACF")) return "PACF";
      if (u.startsWith("PLA")) return "PLA";
      if (u.startsWith("PETG")) return "PETG";
      if (u.startsWith("ABS")) return "ABS";
      if (u.startsWith("ASA")) return "ASA";
      if (u.startsWith("TPU")) return "TPU";
      return u;
    };
    const colDist = (h1, h2) => {
      if (!h1 || !h2 || h1.length !== 6 || h2.length !== 6) return 999999;
      const dr = parseInt(h1.slice(0,2),16) - parseInt(h2.slice(0,2),16);
      const dg = parseInt(h1.slice(2,4),16) - parseInt(h2.slice(2,4),16);
      const db = parseInt(h1.slice(4,6),16) - parseInt(h2.slice(4,6),16);
      return dr*dr + dg*dg + db*db;
    };
    const usedIds = new Set();
    assigns = reqs.map((r) => {
      const rBase = baseMat(r.nm);
      const compat = slots.filter((x) => baseMat(x.nm) === rBase);
      if (!compat.length) return "";
      const scored = compat.map((x) => {
        const exactMat = x.nm === r.nm ? 0 : 5000;
        const reused = usedIds.has(x.id) ? 200000 : 0;
        return { id: x.id, score: colDist(r.nc, x.nc) + exactMat + reused };
      }).sort((x, y) => x.score - y.score);
      const best = scored.slice(0, 1).pop();
      if (best) { usedIds.add(best.id); return best.id; }
      return "";
    });
    cardsEl.innerHTML = "";
    reqs.forEach((r, idx) => {
      const card = document.createElement("div");
      card.style.cssText = "flex:1 1 140px;max-width:180px;background:#16181f;border:1px solid #2d313d;border-radius:10px;padding:10px;display:flex;flex-direction:column;gap:8px;align-items:center;";
      const top = document.createElement("div");
      top.style.cssText = `width:100%;padding:8px;border-radius:6px;background:${r.col};color:${r.tc};font-weight:700;font-size:14px;text-align:center;border:1px solid rgba(255,255,255,0.22);`;
      top.textContent = r.mat;
      card.appendChild(top);

      const ddWrap = document.createElement("div");
      ddWrap.style.cssText = "position:relative;width:100%;";
      const ddBtn = document.createElement("button");
      ddBtn.type = "button";
      const ddMenu = document.createElement("div");
      ddMenu.style.cssText = "display:none;position:absolute;left:0;right:0;top:calc(100% + 4px);z-index:100001;background:#181a20;border:1px solid #4b5563;border-radius:8px;padding:4px;box-shadow:0 12px 28px rgba(0,0,0,0.65);flex-direction:column;gap:4px;max-height:175px;overflow-y:auto;overscroll-behavior:contain;";

      let curVal = assigns.slice(idx, idx + 1).join("") || "";
      const updateBtn = () => {
        const ch = slots.find((x) => x.id === curVal);
        if (!ch) {
          ddBtn.style.cssText = "width:100%;padding:8px;border-radius:6px;background:#1f222b;border:1px dashed #ef4444;color:#9ca3af;font-size:13px;font-weight:700;text-align:center;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:6px;";
          ddBtn.innerHTML = '<span>-- Empty --</span><span style="font-size:10px;opacity:0.8;">▼</span>';
        } else {
          ddBtn.style.cssText = `width:100%;padding:8px;border-radius:6px;background:${ch.col};border:1px solid rgba(255,255,255,0.28);color:${fgFor(ch.col)};font-size:13px;font-weight:700;text-align:center;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:6px;`;
          const subLine = ch.rem ? `<span style="font-size:11px;font-weight:600;opacity:0.88;">${ch.rem}</span>` : "";
          ddBtn.innerHTML = `<span style="display:flex;flex-direction:column;align-items:center;line-height:1.2;"><span>${ch.id} / ${ch.mat}</span>${subLine}</span><span style="font-size:10px;opacity:0.8;">▼</span>`;
        }
      };

      const buildItems = () => {
        ddMenu.innerHTML = "";
        const items = [{ id: "", label: "-- Empty --", rem: "", bg: "#1f222b", fg: "#9ca3af", dashed: true }].concat(
          slots.map((x) => ({ id: x.id, label: `${x.id} / ${x.mat}`, rem: x.rem || "", bg: x.col, fg: fgFor(x.col), dashed: false }))
        );
        items.forEach((it) => {
          const item = document.createElement("button");
          item.type = "button";
          const active = it.id === curVal;
          item.style.cssText = `width:100%;padding:7px 8px;border-radius:6px;background:${it.bg};color:${it.fg};font-size:13px;font-weight:700;text-align:center;cursor:pointer;border:${active ? "2px solid #4f7df3" : it.dashed ? "1px dashed #6b7280" : "1px solid rgba(255,255,255,0.2)"};`;
          item.innerHTML = it.rem ? `<div style="line-height:1.2;"><div>${it.label}</div><div style="font-size:11px;font-weight:600;opacity:0.88;">${it.rem}</div></div>` : it.label;
          item.onclick = (ev) => {
            ev.stopPropagation();
            curVal = it.id;
            assigns.splice(idx, 1, curVal);
            updateBtn();
            ddMenu.style.display = "none";
            validate();
          };
          ddMenu.appendChild(item);
        });
      };

      ddBtn.onclick = (ev) => {
        ev.stopPropagation();
        const openNow = ddMenu.style.display === "flex";
        document.querySelectorAll(".cfs-dd-menu").forEach((m) => { m.style.display = "none"; });
        if (!openNow) { buildItems(); ddMenu.style.display = "flex"; }
      };
      ddMenu.className = "cfs-dd-menu";
      document.addEventListener("click", () => { ddMenu.style.display = "none"; });

      updateBtn();
      ddWrap.appendChild(ddBtn);
      ddWrap.appendChild(ddMenu);
      
      card.appendChild(ddWrap);
      cardsEl.appendChild(card);
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
        if (meta.filament_type) types = String(meta.filament_type).replace(/[\[\]"]/g, "").split(/[;,]+/).map((x) => x.trim()).filter(Boolean);
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
        const mat = (types.slice(t, t + 1).join("") || types.slice(0, 1).join("") || fb).replace(/[\[\]"]/g, "").trim();
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
    const slotToTn = (id) => {
      const m = String(id || "").match(/^(\d+)([A-D])$/i);
      return m ? (parseInt(m.slice(1,2).join(""), 10) - 1) * 4 + (m.slice(2,3).join("").toUpperCase().charCodeAt(0) - 65) : 0;
    };
    const cmds = reqs.map((rq, i) => {
      const sid = assigns.slice(i, i + 1).join("");
      return sid ? `BOX_MODIFY_TN T${rq.t}=T${slotToTn(sid)}` : "";
    }).filter(Boolean);
    const tail = fromAutoTrigger ? "_CFS_CONFIRM_MAP" : `SDCARD_PRINT_FILE FILENAME="${fileSel.value}"`;
    const script = [...cmds, tail].join("\n");
    close();
    await fetch("/printer/gcode/script", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ script }) });
  };
};


(function(){
  if (window.__cfsOrcaGatePoller) return;
  window.__cfsOrcaGatePoller = true;
  setInterval(async function(){
    try {
      if (document.getElementById("cfs-map-print-modal")) return;
      const r = await fetch("/cfs-gate/pending", { cache: "no-store" });
      if (!r.ok) return;
      const d = await r.json();
      if (d && d.filename) {
        await fetch("/cfs-gate/clear", { method: "POST" });
        if (typeof window.openMapAndPrintModal === "function") {
          window.openMapAndPrintModal(d.filename, false);
        }
      }
    } catch (e) {}
  }, 1500);
})();
