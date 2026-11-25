(function(){
  if (window.__k1cI18n) return;
  const D = {
    en: {map_title:"Map Filaments & Start Print",map_select_hint:"Please select the CFS slot matching each filament:",map_warn_unassigned:"Unassigned filaments remaining – printing disabled.",map_empty:"-- Empty --",map_auto_main:"Always open before starting a print",map_auto_sub:"When unchecked, opens only if matching filament is missing in CFS-C",map_cancel:"Cancel",map_apply:"Apply & Print",map_reading:"Reading G-Code...",empty:"Empty",external:"External",spool_holder:"Spool Holder",loaded:"Loaded",feed:"Feed",retract:"Retract",map_print:"Map & Print",material_db:"Material DB",edit:"Edit",close:"Close",cancel:"Cancel",save:"Save",saving:"Saving",color:"COLOR",type:"Type",vendor:"Vendor",name:"Name",min_temp:"Min Temp",max_temp:"Max Temp",edit_material:"Edit Material",purge_config:"Purge Config",purge_settings:"Purge Settings",humidity:"Humidity ",temp:"Temp ",assign_screen:"Please assign in Screen",unknown:"Unknown",ready:"Ready",printing:"Printing",running:"Running"},
    de: {map_title:"Filamente zuordnen & Druck starten",map_select_hint:"Bitte wählen Sie den CFS-Slot aus, der dem jeweiligen Filament entspricht:",map_warn_unassigned:"Es gibt Filamente ohne Zuordnung – Drucken nicht möglich.",map_empty:"-- Leer --",map_auto_main:"Immer vor dem Druckstart öffnen",map_auto_sub:"Ohne Haken öffnet sich der Dialog nur, wenn passendes Filament im CFS-C fehlt",map_cancel:"Abbrechen",map_apply:"Übernehmen & Drucken",map_reading:"Lese G-Code...",empty:"Leer",external:"Extern",spool_holder:"Spulenhalter",loaded:"Geladen",feed:"Einziehen",retract:"Zurückziehen",map_print:"Map & Print",material_db:"Material-DB",edit:"Bearbeiten",close:"Schließen",cancel:"Abbrechen",save:"Speichern",saving:"Speichere",color:"FARBE",type:"Typ",vendor:"Hersteller",name:"Name",min_temp:"Min. Temp",max_temp:"Max. Temp",edit_material:"Material bearbeiten",purge_config:"Spül-Konfig",purge_settings:"Spüleinstellungen",humidity:"Luftfeuchte ",temp:"Temp. ",assign_screen:"Bitte am Display zuweisen"
    fr: {map_title:"Associer les filaments et démarrer l'impression",map_select_hint:"Veuillez sélectionner l'emplacement CFS correspondant à chaque filament :",map_warn_unassigned:"Filaments non attribués – impression impossible.",map_empty:"-- Vide --",map_auto_main:"Toujours ouvrir avant de démarrer l'impression",map_auto_sub:"Si décoché, s'ouvre uniquement si un filament manque dans le CFS-C",map_cancel:"Annuler",map_apply:"Appliquer et imprimer",map_reading:"Lecture du G-Code...",empty:"Vide",external:"Externe",spool_holder:"Support bobine",loaded:"Chargé",feed:"Charger",retract:"Rétracter",map_print:"Map & Print",material_db:"Base matériaux",edit:"Modifier",close:"Fermer",cancel:"Annuler",save:"Enregistrer",saving:"Enregistrement",color:"COULEUR",type:"Type",vendor:"Marque",name:"Nom",min_temp:"Temp. min",max_temp:"Temp. max",edit_material:"Modifier le matériau",purge_config:"Config purge",purge_settings:"Paramètres de purge",humidity:"Humidité ",temp:"Temp. ",assign_screen:"Attribuer s
    es: {map_title:"Asignar filamentos e iniciar impresión",map_select_hint:"Seleccione la ranura CFS correspondiente a cada filamento:",map_warn_unassigned:"Hay filamentos sin asignar – no se puede imprimir.",map_empty:"-- Vacío --",map_auto_main:"Abrir siempre antes de iniciar una impresión",map_auto_sub:"Si está desmarcado, solo se abre si falta el filamento en el CFS-C",map_cancel:"Cancelar",map_apply:"Aplicar e imprimir",map_reading:"Leyendo G-Code...",empty:"Vacío",external:"Externo",spool_holder:"Portabobinas",loaded:"Cargado",feed:"Cargar",retract:"Retraer",map_print:"Map & Print",material_db:"Base materiales",edit:"Editar",close:"Cerrar",cancel:"Cancelar",save:"Guardar",saving:"Guardando",color:"COLOR",type:"Tipo",vendor:"Marca",name:"Nombre",min_temp:"Temp. mín.",max_temp:"Temp. máx.",edit_material:"Editar material",purge_config:"Config. purga",purge_settings:"Ajustes de purga",humidity:"Humedad ",temp:"Temp. ",assign_screen:"Asignar en pantalla",unknown:"Desconocido",ready:"Listo",printi
    it: {map_title:"Assegna filamenti e avvia stampa",map_select_hint:"Seleziona lo slot CFS corrispondente a ciascun filamento:",map_warn_unassigned:"Filamenti non assegnati – stampa disabilitata.",map_empty:"-- Vuoto --",map_auto_main:"Apri sempre prima di avviare una stampa",map_auto_sub:"Se deselezionato, si apre solo se manca il filamento nel CFS-C",map_cancel:"Annulla",map_apply:"Applica e stampa",map_reading:"Lettura G-Code...",empty:"Vuoto",external:"Esterno",spool_holder:"Portabobina",loaded:"Caricato",feed:"Carica",retract:"Ritrai",map_print:"Map & Print",material_db:"DB Materiali",edit:"Modifica",close:"Chiudi",cancel:"Annulla",save:"Salva",saving:"Salvataggio",color:"COLORE",type:"Tipo",vendor:"Marca",name:"Nome",min_temp:"Temp. min",max_temp:"Temp. max",edit_material:"Modifica materiale",purge_config:"Config. spurgo",purge_settings:"Impostazioni spurgo",humidity:"Umidità ",temp:"Temp. ",assign_screen:"Assegna sullo schermo",unknown:"Sconosciuto",ready:"Pronto",printing:"In stampa",running:"I
    nl: {map_title:"Filamenten toewijzen & print starten",map_select_hint:"Selecteer het CFS-slot dat overeenkomt met elk filament:",map_warn_unassigned:"Niet-toegewezen filamenten – printen uitgeschakeld.",map_empty:"-- Leeg --",map_auto_main:"Altijd openen voor het starten van een print",map_auto_sub:"Indien uitgevinkt, opent alleen als passend filament ontbreekt in CFS-C",map_cancel:"Annuleren",map_apply:"Toepassen & printen",map_reading:"G-Code lezen...",empty:"Leeg",external:"Extern",spool_holder:"Spoelhouder",loaded:"Geladen",feed:"Invoeren",retract:"Terugtrekken",map_print:"Map & Print",material_db:"Materiaal-DB",edit:"Bewerken",close:"Sluiten",cancel:"Annuleren",save:"Opslaan",saving:"Opslaan...",color:"KLEUR",type:"Type",vendor:"Merk",name:"Naam",min_temp:"Min. temp",max_temp:"Max. temp",edit_material:"Materiaal bewerken",purge_config:"Spoelconfig",purge_settings:"Spoelinstellingen",humidity:"Luchtvochtigheid ",temp:"Temp. ",assign_screen:"Toewijzen op scherm",unknown:"Onbekend",ready:"Gereed",pr
  };
  let cur = "en";
  const norm = r => { const b = String(r||"").trim().toLowerCase().split(/[-_]/).shift(); return D[b] ? b : ""; };
  const det = () => {
    try {
      const h = norm(document.documentElement && document.documentElement.lang); if (h) return h;
      for (let i=0;i<localStorage.length;i++){const k=localStorage.key(i)||"";if(/locale|lang/i.test(k)){const v=localStorage.getItem(k)||"",m=v.match(/"locale"\s*:\s*"([a-zA-Z_-]+)"/)||v.match(/^"?([a-zA-Z_-]{2,5})"?$/),n=norm(m?m.pop():v);if(n)return n;}}
      const nv = norm(navigator.language||navigator.userLanguage); if (nv) return nv;
    } catch(e){}
    return "en";
  };
  async function sync(){
    for (const u of ["/server/database/item?namespace=mainsail&key=general","/server/database/item?namespace=fluidd&key=config"]){
      try{const r=await fetch(u);if(r.ok){const j=await r.json(),v=j&&j.result&&j.result.value,n=norm(v&&(v.locale||(v.uiSettings&&v.uiSettings.general&&v.uiSettings.general.locale)));if(n){cur=n;return;}}}catch(e){}
    }
    cur = det();
  }
  cur = det(); sync(); setInterval(sync, 4000);
  window.__k1cI18n = { t: k => (D[cur]&&D[cur][k]!==undefined)?D[cur][k]:(D.en[k]||k), lang: () => cur };
})();

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
    `<span>${__k1cI18n.t('map_title')}</span><button id="cfs-mp-close" style="background:none;border:none;color:#9ca3af;font-size:20px;cursor:pointer;">&times;</button></div>`,
    '<div style="padding:18px 20px;display:flex;flex-direction:column;gap:12px;">',
    '<select id="cfs-mp-file" style="width:100%;padding:9px;border-radius:8px;background:#13151a;color:#f3f4f6;border:1px solid #374151;"></select>',
    `<div style="font-size:13px;color:#d1d5db;">${__k1cI18n.t('map_select_hint')}</div>`,
    '<div id="cfs-mp-warn" style="display:none;color:#ef4444;font-size:13px;font-weight:600;background:rgba(239,68,68,0.12);border:1px solid rgba(239,68,68,0.35);padding:8px 12px;border-radius:8px;">',
    `${__k1cI18n.t('map_warn_unassigned')}</div>`,
    '<div id="cfs-mp-cards" style="display:flex;flex-wrap:wrap;gap:12px;min-height:105px;"></div>',
    '<label style="display:flex;align-items:center;gap:8px;font-size:13px;background:#262934;padding:10px;border-radius:8px;cursor:pointer;">',
    `<input type="checkbox" id="cfs-mp-auto"><span style="display:flex;flex-direction:column;line-height:1.25;"><span>${__k1cI18n.t('map_auto_main')}</span><span style="font-size:11px;color:#9ca3af;font-weight:400;">${__k1cI18n.t('map_auto_sub')}</span></span></label>`,
    '<div style="display:flex;justify-content:flex-end;gap:10px;">',
    `<button id="cfs-mp-cancel" style="padding:8px 16px;border-radius:8px;background:#2d313d;color:#fff;border:1px solid #3f4454;cursor:pointer;">${__k1cI18n.t('map_cancel')}</button>`,
    '<button id="cfs-mp-start" style="padding:8px 18px;border-radius:8px;background:#4f7df3;color:#fff;border:none;cursor:pointer;font-weight:700;">${__k1cI18n.t('map_apply')}</button></div></div>'
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
  const autoCb = box.querySelector("#cfs-mp-auto");
  autoCb.checked = localStorage.getItem("cfs_auto_map_modal") !== "0";
  const syncAutoVar = async (en) => {
    await fetch("/printer/gcode/script", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ script: `SAVE_VARIABLE VARIABLE=cfs_auto_map VALUE=${en ? 1 : 0}` })
    });
  };
  autoCb.onchange = () => {
    localStorage.setItem("cfs_auto_map_modal", autoCb.checked ? "1" : "0");
    syncAutoVar(autoCb.checked);
    fetch("/cfs-gate/enabled", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ enabled: autoCb.checked }) }).catch(()=>{});
  };
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
        const items = [{ id: "", label: __k1cI18n.t('map_empty'), rem: "", bg: "#1f222b", fg: "#9ca3af", dashed: true }].concat(
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
    cardsEl.innerHTML = '<div style="color:#9ca3af;font-size:13px;">${__k1cI18n.t('map_reading')}</div>';
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