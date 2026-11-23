(function () {
  "use strict";

  if (window.__k1c_cfs_panel_loaded) return;
  window.__k1c_cfs_panel_loaded = true;

  const POLL_MS = 3000;
  const HEARTBEAT_MS = 10000;
  const RETRY_MS = 1200;
  const FLOAT_AFTER_MS = 20000;
  const ACTION_FALLBACK_MS = 90000;
  const SLOT_LETTERS = ["A", "B", "C", "D"];
  const WS_URL = String(window.K1C_CFS_WS_URL || ("ws://" + window.location.hostname + ":9999")).replace(/\/$/, "");
  const MATERIAL_TYPES = ["PLA", "PETG", "ABS", "ASA", "BVOH", "HIPS", "PA", "PA-CF", "PC", "PET", "PET-CF", "PETG-CF", "PLA-CF", "PP", "PPS", "PPS-CF", "PVA", "TPU", "OTHER"];
  const MATERIAL_PRESETS = {
    PLA: { db_id: "00001", rfid: "00001", vendor: "Generic", name: "Generic PLA", temp_min: "190", temp_max: "240", pressure: "0.04" },
    "PLA-SILK": { db_id: "00002", rfid: "00005", vendor: "Generic", name: "Generic PLA-Silk", temp_min: "190", temp_max: "240", pressure: "0.052" },
    PETG: { db_id: "00003", rfid: "00013", vendor: "Generic", name: "Generic PETG", temp_min: "220", temp_max: "270", pressure: "0.08" },
    ABS: { db_id: "00004", rfid: "00003", vendor: "Generic", name: "Generic ABS", temp_min: "240", temp_max: "280", pressure: "0.06" },
    ASA: { db_id: "00007", rfid: "00004", vendor: "Generic", name: "Generic ASA", temp_min: "240", temp_max: "280", pressure: "0.044" },
    BVOH: { db_id: "00010", rfid: "00007", vendor: "Generic", name: "Generic BVOH", temp_min: "200", temp_max: "220", pressure: "0.02" },
    HIPS: { db_id: "00012", rfid: "00010", vendor: "Generic", name: "Generic HIPS", temp_min: "220", temp_max: "250", pressure: "0.02" },
    PA: { db_id: "00008", rfid: "00012", vendor: "Generic", name: "Generic PA", temp_min: "240", temp_max: "260", pressure: "0.01" },
    "PA-CF": { db_id: "00009", rfid: "00008", vendor: "Generic", name: "Generic PA-CF", temp_min: "260", temp_max: "300", pressure: "0.01" },
    PC: { db_id: "00021", rfid: "00009", vendor: "Generic", name: "Generic PC", temp_min: "250", temp_max: "270", pressure: "0.05" },
    PET: { db_id: "00020", rfid: "00021", vendor: "Generic", name: "Generic PET", temp_min: "250", temp_max: "270", pressure: "0.02" },
    "PET-CF": { db_id: "00013", rfid: "00020", vendor: "Generic", name: "Generic PET-CF", temp_min: "280", temp_max: "320", pressure: "0.02" },
    "PETG-CF": { db_id: "00014", rfid: "00003", vendor: "Generic", name: "Generic PETG-CF", temp_min: "240", temp_max: "260", pressure: "0.02" },
    "PLA-CF": { db_id: "00006", rfid: "00001", vendor: "Generic", name: "Generic PLA-CF", temp_min: "190", temp_max: "240", pressure: "0.03" },
    "PA6-CF": { db_id: "00015", rfid: "", vendor: "Generic", name: "Generic PA6-CF", temp_min: "280", temp_max: "300", pressure: "0.02" },
    "PAHT-CF": { db_id: "00016", rfid: "", vendor: "Generic", name: "Generic PAHT-CF", temp_min: "300", temp_max: "320", pressure: "0.02" },
    PP: { db_id: "00019", rfid: "00006", vendor: "Generic", name: "Generic PP", temp_min: "220", temp_max: "260", pressure: "0.02" },
    PPS: { db_id: "00017", rfid: "00019", vendor: "Generic", name: "Generic PPS", temp_min: "320", temp_max: "350", pressure: "0.02" },
    "PPS-CF": { db_id: "00018", rfid: "00017", vendor: "Generic", name: "Generic PPS-CF", temp_min: "300", temp_max: "350", pressure: "0.02" },
    PVA: { db_id: "00011", rfid: "00005", vendor: "Generic", name: "Generic PVA", temp_min: "215", temp_max: "225", pressure: "0.02" },
    TPU: { db_id: "00005", rfid: "00011", vendor: "Generic", name: "Generic TPU", temp_min: "210", temp_max: "240", pressure: "0.02" },
    OTHER: { db_id: "", rfid: "", vendor: "Generic", name: "Generic Material", temp_min: "200", temp_max: "240", pressure: "0.04" },
  };
  const MATERIAL_NAME_OPTIONS = {
    PLA: ["Generic PLA", "Generic PLA-Silk"],
  };

  const CARD_ID = "k1c-cfs-card";
  const ROOT_ID = "k1c-cfs-panel";
  const FLOAT_ID = "k1c-cfs-float";
  const MODAL_ID = "k1c-cfs-modal";
  const STYLE_ID = "k1c-cfs-panel-style";

  let root = null;
  let gridEl = null;
  let humidityLabelEl = null;
  let tempLabelEl = null;
  let timer = null;
  let heartbeatTimer = null;
  let observer = null;
  let floatTimer = null;
  let ws = null;
  let reconnectTimer = null;
  let latestSlots = [];
  let hasCfsBox = false;
  let lllSensorInstalled = false;
  let lllFilamentDetected = false;
  let extFilamentDetected = false;
  let nexuspPaused = false;
  let latestConnected = false;
  let latestHumidity = null;
  let latestTemp = null;
  let latestFeedState = null;
  let latestFeedStateAt = 0;
  let previousFeedState = null;
  let selectedSlot = "";
  let savingSlot = "";
  let actionSlot = "";
  let pendingAction = null;
  let feedBtnEl = null;
  let retractBtnEl = null;
  let configBtnEl = null;
  let dbBtnEl = null;

  if (!document.getElementById(STYLE_ID)) {
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = [
      "#" + CARD_ID + "{overflow:hidden}",
      "#" + CARD_ID + " .k1c-cfs-card-body{padding:20px 18px 18px}",
      "#" + ROOT_ID + "{font-family:inherit;color:inherit}",
      "#" + ROOT_ID + " *{box-sizing:border-box;font-family:inherit}",
      ".k1c-cfs-shell{display:flex;flex-direction:column;gap:16px;padding:0;background:transparent;border:none;border-radius:0;box-shadow:none}",
      ".k1c-cfs-badge{display:flex;align-items:center;gap:8px;background:#242424;color:#ececec;padding:9px 16px;border-radius:8px;font-size:12px;font-weight:700;border:none;line-height:1}",
      ".k1c-cfs-badge svg{width:15px;height:15px;fill:currentColor;opacity:.95}",
      ".k1c-cfs-badge.humidity{color:#77a7ff;background:#232323;box-shadow:inset 0 1px 0 rgba(255,255,255,.02)}",
      ".k1c-cfs-badge.temperature{color:#f7b955;background:#232323;box-shadow:inset 0 1px 0 rgba(255,255,255,.02)}",
      ".k1c-cfs-holder-wrap{display:flex;justify-content:center;margin-top:10px;padding-top:10px;border-top:1px solid rgba(255,255,255,.08)}.k1c-cfs-holder-wrap .k1c-cfs-item{width:min(280px,100%)}.k1c-cfs-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px}",
      ".k1c-cfs-item{position:relative;background:#242424;border:1px solid #3a3a3a;border-radius:8px;padding:14px;display:flex;justify-content:space-between;align-items:center;gap:12px;cursor:pointer;transition:background .2s ease,border-color .2s ease}",
      ".k1c-cfs-item:hover{background:#2e2e2e}",
      ".k1c-cfs-item.active{background:#2a2a2a;border-color:var(--spool-color,#666)}",
      ".k1c-cfs-item.empty{background:#202020;border-color:#2d2d2d;opacity:.58}",
      ".k1c-cfs-item.empty:hover{background:#202020}",
      ".k1c-cfs-item.empty .k1c-cfs-spool{background:#4b5563;box-shadow:inset 0 0 0 3px rgba(255,255,255,.06),inset 0 0 10px rgba(0,0,0,.55)}",
      ".k1c-cfs-item.empty .k1c-cfs-spool::after{background:#202020}",
      ".k1c-cfs-item.empty .k1c-cfs-channel,.k1c-cfs-item.empty .k1c-cfs-type,.k1c-cfs-item.empty .k1c-cfs-edit-inline{color:#7b7b7b}",
      ".k1c-cfs-item.empty .k1c-cfs-edit-inline:hover{background:transparent;color:#7b7b7b}",
      ".k1c-cfs-loaded-dot{position:absolute;top:6px;right:6px;width:7px;height:7px;border-radius:50%;background:#22c55e;box-shadow:0 0 5px #22c55e;z-index:2}",
      ".k1c-cfs-loading-dot{position:absolute;top:4px;right:4px;width:11px;height:11px;border-radius:50%;background:#60a5fa;box-shadow:0 0 0 rgba(96,165,250,.45);animation:k1c-cfs-pulse 1s ease-in-out infinite;z-index:2}",
      "@keyframes k1c-cfs-pulse{0%{transform:scale(.75);opacity:.65;box-shadow:0 0 0 0 rgba(96,165,250,.45)}70%{transform:scale(1);opacity:1;box-shadow:0 0 0 6px rgba(96,165,250,0)}100%{transform:scale(.75);opacity:.65;box-shadow:0 0 0 0 rgba(96,165,250,0)}}",
      ".k1c-cfs-main{display:flex;align-items:center;gap:12px;min-width:0}",
      ".k1c-cfs-spool{width:44px;height:44px;border-radius:50%;background:var(--spool-color,#94a3b8);display:flex;align-items:center;justify-content:center;position:relative;flex-shrink:0;box-shadow:inset 0 0 0 3px rgba(255,255,255,.15),inset 0 0 10px rgba(0,0,0,.6),0 0 8px rgba(0,0,0,.3)}",
      ".k1c-cfs-spool::after{content:'';width:12px;height:12px;border-radius:50%;background:#1c1c1c;box-shadow:inset 0 2px 4px rgba(0,0,0,.8)}",
      ".k1c-cfs-info{display:flex;flex-direction:column;min-width:0}",
      ".k1c-cfs-channel{font-size:11px;color:#9e9e9e;font-weight:700;letter-spacing:.05em;text-transform:uppercase}",
      ".k1c-cfs-type{font-size:19px;font-weight:700;color:#ececec;line-height:1.05;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}",
      ".k1c-cfs-edit-inline{background:transparent;border:1px solid transparent;color:#9e9e9e;width:36px;height:36px;border-radius:6px;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:all .2s ease}",
      ".k1c-cfs-edit-inline:hover{background:#3a3a3a;color:#ececec}",
      ".k1c-cfs-edit-inline svg,.k1c-cfs-action svg{width:18px;height:18px;fill:currentColor}",
      ".k1c-cfs-controls{display:flex;flex-direction:column;gap:12px;padding-top:12px;border-top:1px solid #3a3a3a}",
      ".k1c-cfs-controls-row{display:flex;gap:12px}",
      ".k1c-cfs-controls-row .k1c-cfs-action{flex:1 1 0}",
      ".k1c-cfs-action{background:#2a2a2a;color:#ececec;border:1px solid #3a3a3a;padding:12px 14px;border-radius:8px;font-size:13px;font-weight:600;display:flex;align-items:center;justify-content:center;gap:8px;cursor:pointer;transition:all .2s ease}",
      ".k1c-cfs-action:hover:not(:disabled){background:#333;border-color:#555}",
      ".k1c-cfs-action:disabled{opacity:.35;cursor:not-allowed}",
      ".k1c-cfs-action-loading{display:inline-flex;align-items:center;gap:8px}",
      ".k1c-cfs-action-loading-dot{width:9px;height:9px;border-radius:50%;background:#60a5fa;box-shadow:0 0 0 rgba(96,165,250,.45);animation:k1c-cfs-pulse 1s ease-in-out infinite;flex-shrink:0}",
      "#" + MODAL_ID + "{position:fixed;inset:0;display:flex;align-items:center;justify-content:center;padding:24px;background:rgba(18,18,18,.72);z-index:10001;overflow:auto}",
      ".k1c-cfs-modal-card{width:min(680px,calc(100vw - 32px));max-height:calc(100vh - 48px);background:#1e1e1e;color:#ececec;border:1px solid rgba(255,255,255,.08);border-radius:8px;display:flex;flex-direction:column;overflow:hidden;box-shadow:0 24px 48px rgba(0,0,0,.45)}",
      ".k1c-cfs-modal-head{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:18px 20px;border-bottom:1px solid rgba(255,255,255,.08);background:#1f1f1f}",
      ".k1c-cfs-modal-title{font-size:16px;font-weight:600;color:#ececec}",
      ".k1c-cfs-color-wrap{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px}",
      ".k1c-cfs-color-avatar{width:80px;height:80px;border-radius:50%;position:relative;overflow:hidden;border:3px solid #2a2a2a;box-shadow:0 4px 15px rgba(0,0,0,.4),inset 0 0 10px rgba(0,0,0,.3);transition:transform .2s ease,border-color .2s ease}",
      ".k1c-cfs-color-avatar:hover{transform:scale(1.05);border-color:#555}",
      ".k1c-cfs-color-avatar input[type='color']{position:absolute;top:-50%;left:-50%;width:200%;height:200%;opacity:0;cursor:pointer;z-index:10}",
      ".k1c-cfs-color-overlay{position:absolute;inset:0;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;opacity:0;transition:opacity .2s ease;pointer-events:none;z-index:5}",
      ".k1c-cfs-color-avatar:hover .k1c-cfs-color-overlay{opacity:1}",
      ".k1c-cfs-color-overlay svg{width:28px;height:28px;fill:#fff}",
      ".k1c-cfs-color-label{font-size:12px;color:#9e9e9e;font-weight:600;letter-spacing:.05em}",
      ".k1c-cfs-modal-body{display:flex;flex-direction:column;padding:0 20px 8px;overflow:auto;min-height:0}",
      ".k1c-cfs-edit-grid{display:flex;flex-direction:column;gap:0}",
      ".k1c-cfs-field{display:grid;grid-template-columns:minmax(120px,180px) 1fr;align-items:center;gap:16px;padding:14px 0;border-bottom:1px solid rgba(255,255,255,.08)}",
      ".k1c-cfs-field.wide{grid-template-columns:minmax(120px,180px) 1fr}",
      ".k1c-cfs-field label{font-size:14px;color:#d0d0d0;font-weight:500}",
      ".k1c-cfs-field select,.k1c-cfs-field input{width:100%;appearance:none;border:1px solid rgba(255,255,255,.08);background:#121212;color:#ececec;border-radius:6px;padding:10px 12px;font-size:14px;outline:none}",
      ".k1c-cfs-field select option{background:#121212;color:#ececec}",
      ".k1c-cfs-field select:focus,.k1c-cfs-field input:focus{border-color:#6b6b6b}",
      ".k1c-cfs-modal-actions{display:flex;justify-content:flex-end;gap:12px;padding:16px 20px 18px;border-top:1px solid rgba(255,255,255,.08);background:#1f1f1f}",
      ".k1c-cfs-save-btn,.k1c-cfs-cancel-btn{appearance:none;border:1px solid rgba(255,255,255,.08);background:#2b2b2b;color:#ececec;border-radius:6px;padding:8px 16px;font-size:14px;font-weight:500;cursor:pointer;transition:all .2s ease}",
      ".k1c-cfs-save-btn:hover,.k1c-cfs-cancel-btn:hover{background:#343434;border-color:rgba(255,255,255,.16)}",
      ".k1c-cfs-save-btn{background:#2d5f3d;border-color:#3a7a4f;color:#f5fff8}",
      ".k1c-cfs-save-btn:hover{background:#367148;border-color:#4b9462}",
      "#" + FLOAT_ID + "{position:fixed;right:18px;bottom:18px;width:min(520px,calc(100vw - 24px));z-index:9999}",
      "#" + FLOAT_ID + " ." + CARD_ID + "-shell{box-shadow:0 20px 48px rgba(0,0,0,.36)}",
      "@media (max-width:640px){.k1c-cfs-controls-row{flex-direction:column}.k1c-cfs-field,.k1c-cfs-field.wide{grid-template-columns:1fr;gap:10px}}",
    ].join("");
    document.head.appendChild(style);
  }

  function createSvgPath(path) {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("viewBox", "0 0 24 24");
    const p = document.createElementNS("http://www.w3.org/2000/svg", "path");
    p.setAttribute("d", path);
    svg.appendChild(p);
    return svg;
  }

  function normalizeColor(value) {
    const raw = String(value || "").trim();
    return raw || "#94a3b8";
  }

  function normalizeColorHex(value) {
    const rawValue = String(value || "").trim().toLowerCase();
    if (!rawValue) return "";
    let raw = rawValue;
    if (raw.startsWith("0x")) raw = raw.slice(2);
    if (raw.startsWith("#")) raw = raw.slice(1);
    raw = raw.replace(/[^0-9a-f]/g, "");
    if (!raw) return "";
    if (raw.length === 7 && raw.charAt(0) === "0") raw = raw.slice(1);
    else if (raw.length === 8) raw = raw.slice(2);
    else if (raw.length > 8) raw = raw.slice(-6);
    if (raw.length !== 6) return "";
    return "#" + raw;
  }

  function printerColorValue(value) {
    const color = normalizeColorHex(value);
    if (!color) return "";
    return "#0" + color.slice(1);
  }

  function normalizeTemperatureValue(value) {
    if (value === null || value === undefined || value === "") return null;
    const temp = Number(value);
    if (!Number.isFinite(temp) || temp < 0) return null;
    return Math.round(temp * 100) / 100;
  }

  function presetMaterialType(presetKey) {
    return presetKey === "PLA-SILK" ? "PLA" : String(presetKey || "").trim().toUpperCase();
  }

  function normalizePresetKey(type, vendor, name) {
    return [
      String(type || "").trim().toUpperCase(),
      String(vendor || "").trim().toLowerCase(),
      String(name || "").trim().toLowerCase(),
    ].join("|");
  }

  function inferMaterialDbId(type, vendor, name) {
    const key = normalizePresetKey(type, vendor, name);
    let matchedId = "";
    Object.keys(MATERIAL_PRESETS).some(function (presetType) {
      const preset = MATERIAL_PRESETS[presetType];
      if (normalizePresetKey(presetMaterialType(presetType), preset.vendor, preset.name) !== key) return false;
      matchedId = String(preset.db_id || "");
      return true;
    });
    return matchedId;
  }

  let DB_PRESETS_BY_TYPE = null;
  let DB_ALLOW_CF = false;
  let DB_EDITOR_AVAILABLE = false;
  window.__k1c_reload_mat_db = function loadLiveMaterialDb() {
    var url = "http://" + window.location.hostname + ":8088/api/materials";
    fetch(url).then(function (r) { return r.json(); }).then(function (data) {
      if (!data || !data.ok || !Array.isArray(data.items)) return;
      DB_ALLOW_CF = !!(data.settings && data.settings.allow_cf);
      var grouped = {};
      data.items.forEach(function (it) {
        var t = String(it.type || "").trim().toUpperCase();
        if (!t) return;
        if (!DB_ALLOW_CF && (t.indexOf("-CF") !== -1 || t.indexOf("-GF") !== -1)) return;
        if (!grouped[t]) grouped[t] = [];
        var noz = parseInt(it.nozzle_temp, 10) || 215;
        grouped[t].push({
          db_id: String(it.id || ""),
          rfid: String(it.id || ""),
          vendor: String(it.brand || "Generic"),
          name: String(it.name || ""),
          display: (it.brand ? (it.brand + " - " + it.name) : it.name) + (it.custom ? " [Custom]" : ""),
          temp_min: String(Math.max(170, noz - 15)),
          temp_max: String(noz + 15),
          custom: !!it.custom
        });
      });
      Object.keys(grouped).forEach(function (k) {
        grouped[k].sort(function (a, b) {
          if (a.custom !== b.custom) return a.custom ? -1 : 1;
          return a.display.localeCompare(b.display);
        });
      });
      DB_PRESETS_BY_TYPE = grouped;
      DB_EDITOR_AVAILABLE = true;
      if (dbBtnEl) dbBtnEl.style.display = (hasCfsBox && DB_EDITOR_AVAILABLE) ? "" : "none";
    }).catch(function () { DB_EDITOR_AVAILABLE = false; if (dbBtnEl) dbBtnEl.style.display = "none"; });
  };
  window.__k1c_reload_mat_db();

  function listPresetsForType(type) {
    const normalizedType = String(type || "").trim().toUpperCase();
    if (DB_PRESETS_BY_TYPE && DB_PRESETS_BY_TYPE[normalizedType] && DB_PRESETS_BY_TYPE[normalizedType].length) {
      return DB_PRESETS_BY_TYPE[normalizedType];
    }
    return Object.keys(MATERIAL_PRESETS).filter(function (presetKey) {
      return presetMaterialType(presetKey) === normalizedType;
    }).map(function (presetKey) {
      return MATERIAL_PRESETS[presetKey];
    });
  }

  function findPresetByTypeAndName(type, name) {
    const normalizedName = String(name || "").trim().toLowerCase();
    const list = listPresetsForType(type);
    return list.find(function (p) {
      return String(p.name || "").trim().toLowerCase() === normalizedName || String(p.display || "").trim().toLowerCase() === normalizedName;
    }) || null;
  }

  function materialStatus(stateValue, present) {
    if (!present || stateValue === 0) return "empty";
    if (stateValue === 2) return "rfid";
    if (stateValue === 1) return "manual";
    return "loaded";
  }

  function emptySlot(label) {
    return {
      slot: label,
      box_id: 1,
      material_index: SLOT_LETTERS.indexOf(label.slice(-1)),
      state: 0,
      status: "empty",
      present: false,
      selected: false,
      rfid: "",
      type: "",
      name: "",
      vendor: "",
      manufacturer: "",
      material_db_id: "",
      color: "#d7dce4",
      temp_min: null,
      temp_max: null,
      used_material_length: null,
      raw: {},
    };
  }

  function coerceTemperatureFields(material) {
    let tempMin = material.minTemp;
    let tempMax = material.maxTemp;
    if (tempMin === undefined || tempMin === null) tempMin = material.nozzleTempMin;
    if (tempMax === undefined || tempMax === null) tempMax = material.nozzleTempMax;
    if (tempMin === undefined || tempMin === null) tempMin = material.minPrintTemp;
    if (tempMax === undefined || tempMax === null) tempMax = material.maxPrintTemp;
    return [tempMin, tempMax];
  }

  function extractSlots(payload) {
    const defaults = {};
    SLOT_LETTERS.forEach(function (letter) {
      defaults["1" + letter] = emptySlot("1" + letter);
    });

    const boxsInfo = payload && payload.boxsInfo ? payload.boxsInfo : {};
    const materialBoxes = Array.isArray(boxsInfo.materialBoxs) ? boxsInfo.materialBoxs : [];
    const firstCfsBox = materialBoxes.find(function (box) {
      return box && typeof box === "object" && box.type === 0;
    });

    if (firstCfsBox && typeof firstCfsBox === "object") {
      hasCfsBox = true;
    }
    if (!firstCfsBox || typeof firstCfsBox !== "object") {
      return {
        slots: SLOT_LETTERS.map(function (letter) { return defaults["1" + letter]; }),
        humidity: null,
        temp: null,
      };
    }

    const boxId = Number.isInteger(firstCfsBox.id) ? firstCfsBox.id : 1;

    (firstCfsBox.materials || []).forEach(function (material) {
      if (!material || typeof material !== "object") return;
      const materialIndex = material.id;
      if (!Number.isInteger(materialIndex) || materialIndex < 0 || materialIndex > 3) return;
      
      const label = String(boxId) + SLOT_LETTERS[materialIndex];
      const rawState = Number(material.state || 0);
      let name = String(material.name || "").trim();
      const vendor = String(material.vendor || "").trim();
      let materialType = String(material.type || "").trim().toUpperCase();
      const rfid = String(material.rfid || "").trim();
      
      // FIX: When rawState === 1 (Manual), a spool is physically loaded!
      const hardwareDetected = rawState === 1;
      
      const rfidMissing = ["", "0", "00", "000", "0000", "00000", "000000"].indexOf(rfid) >= 0;
      const emptyManualSignature = rawState === 1 && rfidMissing && !name && !vendor &&
        ["", "-", "OTHER", "N/A", "NA", "NONE"].indexOf(materialType) >= 0;
      
      let stateValue = emptyManualSignature ? 0 : rawState;
      
      // A spool is present if a valid state exists OR hardware presence is reported
      let present = stateValue > 0 || hardwareDetected;
      
      // Applies when a spool is present without an assigned filament type (e.g. Slot 1D)
      if (hardwareDetected && (stateValue === 0 || materialType === "" || materialType === "-1" || materialType === "NONE")) {
          materialType = "UNASSIGNED";
          name = "Please assign in Screen";
          stateValue = 1; // Zwingt das UI in den aktiven Status
          present = true;
      }

      const color = present ? normalizeColorHex(material.color) : "";
      const temps = coerceTemperatureFields(material);
      
      defaults[label] = {
        slot: label,
        box_id: boxId,
        material_index: materialIndex,
        state: stateValue,
        status: materialStatus(stateValue, present),
        present: present,
        selected: Number(material.selected || 0) === 1,
        rfid: rfid,
        type: materialType,
        name: name,
        vendor: vendor,
        manufacturer: String(material.vendor || "").trim(),
        material_db_id: inferMaterialDbId(materialType, vendor, name),
        color: color || "#d7dce4",
        temp_min: normalizeTemperatureValue(temps),
        temp_max: normalizeTemperatureValue(temps),
        used_material_length: normalizeTemperatureValue(material.usedMaterialLength),
        raw: material,
      };
    });

    const holderBox = materialBoxes.find(function (box) {
      return box && typeof box === "object" && box.type === 1;
    });
    const holderMat = holderBox && Array.isArray(holderBox.materials) && holderBox.materials ? holderBox.materials : {};
    let cachedHolder = null;
    try { cachedHolder = JSON.parse(window.localStorage.getItem("k1c_cfs_holder_cache") || "null"); } catch (e) {}
    const hTypeRaw = String(holderMat.type || (cachedHolder && cachedHolder.type) || "").trim().toUpperCase();
    const hNameRaw = String(holderMat.name || (cachedHolder && cachedHolder.name) || "").trim();
    const hVendorRaw = String(holderMat.vendor || (cachedHolder && cachedHolder.vendor) || "").trim();
    const hHasMat = hTypeRaw !== "" && hTypeRaw !== "NONE" && hTypeRaw !== "-1";
    const hColor = hHasMat ? normalizeColorHex(holderMat.color || (cachedHolder && cachedHolder.color)) : "";
    const hTemps = coerceTemperatureFields(holderMat);
    const hPresent = lllSensorInstalled ? lllFilamentDetected : true;
    const anyCfsSelected = SLOT_LETTERS.some(function (l) {
      const d = defaults[String(boxId) + l] || defaults["1" + l];
      return d && d.selected;
    });
    const hLoaded = hPresent && extFilamentDetected && !anyCfsSelected;
    const holderSlot = {
      slot: "EXT",
      display_label: "Spool Holder",
      is_holder: true,
      box_id: holderBox && Number.isInteger(holderBox.id) ? holderBox.id : 0,
      material_index: 0,
      state: hPresent ? 1 : 0,
      status: hPresent ? (hHasMat ? "Ready" : "Loaded") : "Empty",
      present: hPresent,
      selected: hLoaded || Number(holderMat.selected || 0) === 1,
      rfid: String(holderMat.rfid || ""),
      type: hPresent ? (hHasMat ? hTypeRaw : "External") : "Empty",
      name: hHasMat ? hNameRaw : "",
      vendor: hVendorRaw,
      manufacturer: hVendorRaw,
      material_db_id: hHasMat ? inferMaterialDbId(hTypeRaw, hVendorRaw, hNameRaw) : "",
      color: (hPresent && hColor) ? hColor : "#64748b",
      temp_min: normalizeTemperatureValue(hTemps),
      temp_max: normalizeTemperatureValue(hTemps),
      used_material_length: 0,
      raw: holderMat,
    };

    return {
      slots: [holderSlot].concat(SLOT_LETTERS.map(function (letter) {
        return defaults[String(boxId) + letter] || defaults["1" + letter];
      })),
      humidity: firstCfsBox.humidity,
      temp: firstCfsBox.temp,
    };
  }


  function sendJson(payload) {
    if (!ws || ws.readyState !== WebSocket.OPEN) return false;
    ws.send(JSON.stringify(payload));
    return true;
  }

  async function runKlipperCommand(script) {
    const response = await fetch("/printer/gcode/script", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ script: String(script || "").trim() }),
      credentials: "same-origin",
    });
    if (!response.ok) {
      throw new Error("HTTP " + response.status);
    }
    return response.json().catch(function () { return null; });
  }

  async function queryKlipperObject(query) {
    const response = await fetch("/printer/objects/query?" + String(query || ""), {
      method: "GET",
      credentials: "same-origin",
    });
    if (!response.ok) {
      throw new Error("HTTP " + response.status);
    }
    return response.json();
  }

  function requestBoxsInfo() {
    return sendJson({ method: "get", params: { boxsInfo: 1 } });
  }

  function connectWs() {
    if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) return;
    try {
      ws = new WebSocket(WS_URL);
    } catch (error) {
      latestConnected = false;
      render(latestSlots, latestConnected);
      return;
    }

    ws.onopen = function () {
      latestConnected = !!(ws && ws.readyState === WebSocket.OPEN);
      sendJson({ ModeCode: "heart_beat" });
      requestBoxsInfo();
      render(latestSlots, latestConnected);
    };

    ws.onmessage = function (event) {
      const message = event.data;
      let parsed = null;
      try {
        parsed = JSON.parse(message);
      } catch (error) {
        parsed = null;
      }

      if (typeof message === "string" && message.indexOf("heart_beat") >= 0) {
        if (ws && ws.readyState === WebSocket.OPEN) ws.send("ok");
        return;
      }
      if (message === "ok") return;

      if (parsed && typeof parsed === "object") {
        if (Object.prototype.hasOwnProperty.call(parsed, "feedState")) {
          previousFeedState = latestFeedState;
          latestFeedState = parsed.feedState;
          latestFeedStateAt = Date.now();
          if (!pendingAction && previousFeedState !== latestFeedState) {
            startExternalActionFromFeedState(latestFeedState);
          }
        }
        if (Object.prototype.hasOwnProperty.call(parsed, "boxsInfo")) {
          const extracted = extractSlots(parsed);
          latestHumidity = extracted.humidity;
          latestTemp = extracted.temp;
          latestSlots = extracted.slots;
          latestConnected = true;
          render(latestSlots, latestConnected);
        }
      }
    };


    ws.onerror = function () {
      latestConnected = false;
      render(latestSlots, latestConnected);
    };

    ws.onclose = function () {
      latestConnected = false;
      render(latestSlots, latestConnected);
      if (reconnectTimer) window.clearTimeout(reconnectTimer);
      reconnectTimer = window.setTimeout(function () {
        reconnectTimer = null;
        connectWs();
      }, RETRY_MS);
    };
  }

  function createField(labelText, inputEl) {
    const wrap = document.createElement("div");
    wrap.className = "k1c-cfs-field";
    const label = document.createElement("label");
    label.textContent = labelText;
    wrap.appendChild(label);
    wrap.appendChild(inputEl);
    return wrap;
  }

  function isDashboardRoute() {
    const path = String(window.location.pathname || "").replace(/\/+$/, "");
    const hash = String(window.location.hash || "").replace(/\?.*$/, "").replace(/\/+$/, "");
    return (!path || path === "/") && (!hash || hash === "#" || hash === "#/" || hash === "#!");
  }

  function detectFrontend() {
    if (document.querySelector(".collapsable-card")) return "fluidd";
    return "mainsail";
  }

  function unmountPanel() {
    const card = document.getElementById(CARD_ID);
    if (card) card.remove();
    const floatWrap = document.getElementById(FLOAT_ID);
    if (floatWrap) floatWrap.remove();
    closeModal();
  }

  function updateStatus() {}

  function updateHumidity(humidity, temp) {
    if (!humidityLabelEl) return;
    const humidityValue = humidity === null || humidity === undefined || humidity === "" ? "--" : Math.round(Number(humidity));
    const tempValue = temp === null || temp === undefined || temp === "" ? "--" : Math.round(Number(temp));
    humidityLabelEl.textContent = humidityValue + "%";
    if (tempLabelEl) {
      tempLabelEl.textContent = tempValue + "C";
    }
    if (humidityLabelEl.parentElement) {
      humidityLabelEl.parentElement.title = "Humidity " + humidityValue + "%";
    }
    if (tempLabelEl && tempLabelEl.parentElement) {
      tempLabelEl.parentElement.title = "Temp " + tempValue + "C";
    }
  }

  function startExternalActionFromFeedState(feedState) {
    if (pendingAction) return;
    if (typeof feedState !== "number" || feedState <= 0) return;

    const currentLoadedSlot = latestSlots.find(function (slot) { return slot.selected; });
    const previousSelectedSlot = currentLoadedSlot ? currentLoadedSlot.slot : "";

    if (feedState >= 111 && feedState <= 113) {
      pendingAction = {
        type: "retract",
        kind: "retract",
        targetSlot: "",
        previousSelectedSlot: previousSelectedSlot,
        startedAt: Date.now(),
        source: "machine",
      };
      actionSlot = previousSelectedSlot || "__machine__";
      render(latestSlots, latestConnected);
      return;
    }

    if (feedState >= 102 && feedState <= 107) {
      pendingAction = {
        type: "feed",
        kind: previousSelectedSlot ? "switch" : "feed",
        targetSlot: "",
        previousSelectedSlot: previousSelectedSlot,
        startedAt: Date.now(),
        source: "machine",
      };
      actionSlot = "__machine__";
      render(latestSlots, latestConnected);
    }
  }

  function closeModal() {
    const modal = document.getElementById(MODAL_ID);
    if (modal) modal.remove();
  }

  async function runSlotAction(slot, action, buttonEl) {
    if (!slot || !action || actionSlot) return;
    if (slot.is_holder) {
      actionSlot = slot.slot;
      if (buttonEl) buttonEl.disabled = true;
      render(latestSlots, latestConnected);
      try {
        const matKey = String(slot.type || "").trim().toUpperCase();
        const preset = findPresetByTypeAndName(slot.type, slot.name) || MATERIAL_PRESETS[matKey] || null;
        let purgeTemp = 0;
        try {
          const pData = await queryKlipperObject("cfs_material_db=purge_temps");
          const pTemps = (pData && pData.result && pData.result.status && pData.result.status.cfs_material_db && pData.result.status.cfs_material_db.purge_temps) || {};
          purgeTemp = Number(pTemps[matKey] || pTemps[String(slot.type || "").trim()] || 0) || 0;
        } catch (e) {}
        const targetTemp = purgeTemp || Number(slot.temp_max || slot.temp_min || (preset && preset.temp_max) || 240) || 240;
        if (action === "feed") {
          const gcode = [
            "RESPOND MSG=\"Spool Holder: Heating nozzle to " + targetTemp + "C & extruding 60mm...\"",
            "M109 S" + targetTemp,
            "M83",
            "G1 E60 F240",
            "G92 E0",
            "RESPOND MSG=\"Spool Holder: Feed / purge complete.\""
          ].join("\n");
          await runKlipperCommand(gcode);
        } else if (action === "retract") {
          const gcode = [
            "RESPOND MSG=\"Spool Holder: Heating nozzle to " + targetTemp + "C & retracting from extruder...\"",
            "M109 S" + targetTemp,
            "M83",
            "G1 E5 F200",
            "G1 E-85 F600",
            "G92 E0",
            "M104 S0",
            "RESPOND MSG=\"Spool Holder: Retracted from extruder! Press Retract once on FLY-LLL Plus to unload Bowden.\""
          ].join("\n");
          await runKlipperCommand(gcode);
        }
      } catch (error) {
        window.alert("Spool Holder " + action + " failed: " + (error.message || String(error)));
      } finally {
        actionSlot = "";
        render(latestSlots, latestConnected);
      }
      return;
    }
    const currentSelectedSlot = latestSlots.find(function (item) { return item.selected; });
    const previousSelectedSlot = currentSelectedSlot ? currentSelectedSlot.slot : "";
    const actionKind = action === "retract"
      ? "retract"
      : (previousSelectedSlot && previousSelectedSlot !== slot.slot ? "switch" : "feed");
    pendingAction = {
      type: action,
      kind: actionKind,
      targetSlot: slot.slot,
      previousSelectedSlot: previousSelectedSlot,
      startedAt: Date.now(),
    };
    actionSlot = slot.slot;
    if (buttonEl) buttonEl.disabled = true;
    try {
      const payload = {
        method: "set",
        params: {
          feedInOrOut: {
            boxId: typeof slot.box_id === "number" ? slot.box_id : 1,
            materialId: slot.material_index,
            isFeed: action === "feed" ? 1 : 0,
          },
        },
      };
      if (slot.is_holder) {
        try {
          window.localStorage.setItem("k1c_cfs_holder_cache", JSON.stringify({
            type: normalizedType, vendor: String(draft.vendor || "").trim(),
            name: String(draft.name || "").trim(), color: String(draft.color || "").trim()
          }));
        } catch (e) {}
      }
      if (!sendJson(payload)) {
        if (slot.is_holder) { closeModal(); return; }
        throw new Error("WebSocket not connected");
      }
      window.setTimeout(requestBoxsInfo, 300);
    } catch (error) {
      window.alert("Failed to run " + action + " on " + slot.slot + ": " + (error.message || String(error)));
      actionSlot = "";
      pendingAction = null;
    } finally {
      render(latestSlots, latestConnected);
    }
  }

  async function saveSlot(slot, draft, saveButton) {
    if (savingSlot) return;
    savingSlot = slot.slot;
    saveButton.disabled = true;
    saveButton.textContent = "Saving";
    try {
      const normalizedType = String(draft.type || "").trim().toUpperCase();
      const preset = findPresetByTypeAndName(normalizedType, draft.name) || MATERIAL_PRESETS[normalizedType] || null;
      const resolvedMinTemp = preset ? preset.temp_min : draft.temp_min;
      const resolvedMaxTemp = preset ? preset.temp_max : draft.temp_max;
      const resolvedRfid = preset && preset.rfid ? preset.rfid : String((slot.raw && slot.raw.rfid) || slot.rfid || "");
      const resolvedPressure = preset && preset.pressure ? preset.pressure : String((slot.raw && slot.raw.pressure) || "");
      const payload = {
        method: "set",
        params: {
          modifyMaterial: {
            boxId: typeof slot.box_id === "number" ? slot.box_id : 1,
            id: slot.material_index,
            rfid: resolvedRfid,
            type: normalizedType,
            vendor: String(draft.vendor || "").trim(),
            name: String(draft.name || "").trim(),
            color: printerColorValue(String(draft.color || "").trim()),
            minTemp: normalizeTemperatureValue(resolvedMinTemp),
            maxTemp: normalizeTemperatureValue(resolvedMaxTemp),
            pressure: resolvedPressure,
          },
        },
      };
      if (!sendJson(payload)) throw new Error("WebSocket not connected");
      closeModal();
      window.setTimeout(requestBoxsInfo, 350);
    } catch (error) {
      window.alert("Failed to save " + slot.slot + ": " + (error.message || String(error)));
    } finally {
      savingSlot = "";
      saveButton.disabled = false;
      saveButton.textContent = "Save";
    }
  }

  async function openMaterialConfigModal() {
    closeModal();

    const modal = document.createElement("div");
    modal.id = MODAL_ID;

    const card = document.createElement("div");
    card.className = "k1c-cfs-modal-card";
    const body = document.createElement("div");
    body.className = "k1c-cfs-modal-body";

    const head = document.createElement("div");
    head.className = "k1c-cfs-modal-head";
    const title = document.createElement("div");
    title.className = "k1c-cfs-modal-title";
    title.textContent = "Purge Config";
    head.appendChild(title);
    card.appendChild(head);

    function tempInput(value) {
      const input = document.createElement("input");
      input.type = "number";
      input.min = "0";
      input.step = "1";
      input.value = value == null ? "" : String(value);
      return input;
    }

    const purgeMaterials = [
      { type: "PLA", id: "00001", commandKey: "PLA", statusKey: "pla", def: 220 },
      { type: "PLA-Silk", id: "00002", commandKey: "PLA_SILK", statusKey: "pla_silk", def: 220 },
      { type: "PETG", id: "00003", commandKey: "PETG", statusKey: "petg", def: 245 },
      { type: "ABS", id: "00004", commandKey: "ABS", statusKey: "abs", def: 260 },
      { type: "TPU", id: "00005", commandKey: "TPU", statusKey: "tpu", def: 225 },
      { type: "PLA-CF", id: "00006", commandKey: "PLA_CF", statusKey: "pla_cf", def: 225 },
      { type: "ASA", id: "00007", commandKey: "ASA", statusKey: "asa", def: 260 },
      { type: "PA", id: "00008", commandKey: "PA", statusKey: "pa", def: 260 },
      { type: "PA-CF", id: "00009", commandKey: "PA_CF", statusKey: "pa_cf", def: 280 },
      { type: "BVOH", id: "00010", commandKey: "BVOH", statusKey: "bvoh", def: 215 },
      { type: "PVA", id: "00011", commandKey: "PVA", statusKey: "pva", def: 215 },
      { type: "HIPS", id: "00012", commandKey: "HIPS", statusKey: "hips", def: 240 },
      { type: "PET-CF", id: "00013", commandKey: "PET_CF", statusKey: "pet_cf", def: 290 },
      { type: "PETG-CF", id: "00014", commandKey: "PETG_CF", statusKey: "petg_cf", def: 255 },
      { type: "PA6-CF", id: "00015", commandKey: "PA6_CF", statusKey: "pa6_cf", def: 290 },
      { type: "PAHT-CF", id: "00016", commandKey: "PAHT_CF", statusKey: "paht_cf", def: 300 },
      { type: "PPS", id: "00017", commandKey: "PPS", statusKey: "pps", def: 320 },
      { type: "PPS-CF", id: "00018", commandKey: "PPS_CF", statusKey: "pps_cf", def: 320 },
      { type: "PP", id: "00019", commandKey: "PP", statusKey: "pp", def: 240 },
      { type: "PET", id: "00020", commandKey: "PET", statusKey: "pet", def: 255 },
      { type: "PC", id: "00021", commandKey: "PC", statusKey: "pc", def: 270 },
    ];

    const grid = document.createElement("div");
    grid.className = "k1c-cfs-edit-grid";
    const purgeInputs = {};

    purgeMaterials.forEach(function (entry) {
      const input = tempInput("");
      purgeInputs[entry.type] = input;
      grid.appendChild(createField(entry.type, input));
    });

    body.appendChild(grid);
    card.appendChild(body);

    const actions = document.createElement("div");
    actions.className = "k1c-cfs-modal-actions";
    const cancel = document.createElement("button");
    cancel.type = "button";
    cancel.className = "k1c-cfs-cancel-btn";
    cancel.textContent = "Cancel";
    cancel.onclick = closeModal;

    const save = document.createElement("button");
    save.type = "button";
    save.className = "k1c-cfs-save-btn";
    save.textContent = "Save";
    save.onclick = async function () {
      save.disabled = true;
      save.textContent = "Saving";
      try {
        var commandParts = ["CFS_SET_MATERIAL_DB_TEMPS"];
        for (var i = 0; i < purgeMaterials.length; i += 1) {
          var entry = purgeMaterials[i];
          var value = String((purgeInputs[entry.type] && purgeInputs[entry.type].value) || "").trim();
          if (!value) continue;
          commandParts.push(entry.commandKey + "=" + value);
        }
        if (commandParts.length === 1) throw new Error("No values to save");
        await runKlipperCommand(commandParts.join(" "));
        closeModal();
      } catch (error) {
        window.alert("Failed to save material config: " + (error.message || String(error)));
      } finally {
        save.disabled = false;
        save.textContent = "Save";
      }
    };

    const resetBtn = document.createElement("button");
    resetBtn.type = "button";
    resetBtn.className = "k1c-cfs-cancel-btn";
    resetBtn.textContent = "Load Defaults";
    resetBtn.onclick = function () {
      purgeMaterials.forEach(function (entry) { if (purgeInputs[entry.type]) purgeInputs[entry.type].value = String(entry.def); });
    };
    actions.appendChild(resetBtn);
    actions.appendChild(cancel);
    actions.appendChild(save);
    card.appendChild(actions);

    modal.appendChild(card);
    modal.addEventListener("click", function (event) {
      if (event.target === modal) closeModal();
    });
    document.body.appendChild(modal);

    try {
      const data = await queryKlipperObject("cfs_material_db=purge_temps");
      const status = data && data.result && data.result.status && data.result.status.cfs_material_db;
      const temps = status && status.purge_temps ? status.purge_temps : {};
      purgeMaterials.forEach(function (entry) {
        var input = purgeInputs[entry.type];
        if (!input) return;
        var v = temps[entry.statusKey]; input.value = (v == null || v === "" || Number(v) <= 0) ? String(entry.def) : String(v);
      });
    } catch (error) {
      closeModal();
      window.alert("Failed to load material config: " + (error.message || String(error)));
    }
  }

  function openMaterialDbModal() {
    closeModal();
    const modal = document.createElement("div");
    modal.id = MODAL_ID;
    const card = document.createElement("div");
    card.className = "k1c-cfs-modal-card";
    card.style.width = "min(1280px, 95vw)";
    card.style.maxWidth = "95vw";
    card.style.height = "88vh";
    card.style.display = "flex";
    card.style.flexDirection = "column";
    const head = document.createElement("div");
    head.className = "k1c-cfs-modal-head";
    const title = document.createElement("div");
    title.className = "k1c-cfs-modal-title";
    title.textContent = "Material Database Editor";
    const closeBtn = document.createElement("button");
    closeBtn.type = "button";
    closeBtn.className = "k1c-cfs-cancel-btn";
    closeBtn.textContent = "Close";
    const onDone = function () {
      closeModal();
      if (typeof window.__k1c_reload_mat_db === "function") window.__k1c_reload_mat_db();
    };
    closeBtn.onclick = onDone;
    head.appendChild(title);
    head.appendChild(closeBtn);
    card.appendChild(head);
    const frame = document.createElement("iframe");
    frame.src = "http://" + window.location.hostname + ":8088/";
    frame.style.width = "100%";
    frame.style.flex = "1";
    frame.style.border = "none";
    frame.style.background = "#121212";
    card.appendChild(frame);
    modal.appendChild(card);
    modal.addEventListener("click", function (event) {
      if (event.target === modal) onDone();
    });
    document.body.appendChild(modal);
  }

  let latestBoxInfoList = [];
  function computeSlotRemaining(slot) {
    if (!slot || !slot.present || slot.is_holder) return null;
    var idx = Number(slot.material_index);
    var bi = (Array.isArray(latestBoxInfoList) && idx >= 0 && idx < latestBoxInfoList.length) ? latestBoxInfoList[idx] : null;
    if (!bi || Number(bi.editable) !== 0 || Number(bi.total_len || 0) <= 0) return null;

    var raw = slot.raw || {};
    var totalLen = Number(bi.total_len || raw.total_len || raw.totalMaterialLength || 0);
    var usedLen = Number(slot.used_material_length || raw.usedMaterialLength || 0);
    var pct = bi.percent != null ? Number(bi.percent) : (raw.percent != null ? Number(raw.percent) : null);

    if (totalLen > 0 && usedLen > 0) {
      pct = Math.max(0, Math.min(100, Math.round(((totalLen - usedLen) / totalLen) * 100)));
    }
    if (pct == null || isNaN(pct) || pct <= 0) return null;
    pct = Math.max(0, Math.min(100, Math.round(pct)));

    var totalMeters = totalLen > 5000 ? (totalLen / 1000.0) : totalLen;
    var estTotalGrams = Math.round(totalMeters * 2.98);
    var grams = estTotalGrams > 0 ? Math.max(0, Math.round(estTotalGrams * (pct / 100.0))) : null;
    return { pct: pct, grams: grams, hasRfid: true };
  }

  function openEditModal(slot) {
    closeModal();

    const modal = document.createElement("div");
    modal.id = MODAL_ID;

    const card = document.createElement("div");
    card.className = "k1c-cfs-modal-card";
    modal.appendChild(card);
    const body = document.createElement("div");
    body.className = "k1c-cfs-modal-body";

    const head = document.createElement("div");
    head.className = "k1c-cfs-modal-head";
    const title = document.createElement("div");
    title.className = "k1c-cfs-modal-title";
    title.textContent = slot.slot + " Edit Material";
    const closeBtn = document.createElement("button");
    closeBtn.type = "button";
    closeBtn.className = "k1c-cfs-cancel-btn";
    closeBtn.textContent = "Close";
    closeBtn.onclick = closeModal;
    head.appendChild(title);
    head.appendChild(closeBtn);
    card.appendChild(head);

    const colorWrap = document.createElement("div");
    colorWrap.className = "k1c-cfs-color-wrap";
    const colorAvatar = document.createElement("div");
    colorAvatar.className = "k1c-cfs-color-avatar";
    colorAvatar.style.backgroundColor = normalizeColor(slot.color);
    const colorInput = document.createElement("input");
    colorInput.type = "color";
    colorInput.value = normalizeColor(slot.color);
    const colorOverlay = document.createElement("div");
    colorOverlay.className = "k1c-cfs-color-overlay";
    colorOverlay.appendChild(createSvgPath("M3 17.2v4.5h4.5l11-11.1-4.5-4.5L3 17.2zm18.7-10.3c.4-.4.4-1 0-1.4l-3.1-3.1c-.4-.4-1-.4-1.4 0l-2.2 2.2 4.5 4.5 2.2-2.2z"));
    colorInput.addEventListener("input", function () {
      colorAvatar.style.backgroundColor = colorInput.value;
    });
    colorAvatar.appendChild(colorInput);
    colorAvatar.appendChild(colorOverlay);
    const colorLabel = document.createElement("span");
    colorLabel.className = "k1c-cfs-color-label";
    colorLabel.textContent = "COLOR";
    colorWrap.appendChild(colorAvatar);
    colorWrap.appendChild(colorLabel);
    body.appendChild(colorWrap);

    const select = document.createElement("select");
    MATERIAL_TYPES.filter(function (m) { return DB_ALLOW_CF || (m.indexOf("-CF") === -1 && m.indexOf("-GF") === -1); }).forEach(function (material) {
      const option = document.createElement("option");
      option.value = material;
      option.textContent = material;
      if ((slot.type || "PLA") === material) option.selected = true;
      select.appendChild(option);
    });

    const vendorInput = document.createElement("input");
    vendorInput.type = "text";
    vendorInput.value = slot.vendor || "";

    const nameSelect = document.createElement("select");

    const tempMinInput = document.createElement("input");
    tempMinInput.type = "number";
    tempMinInput.min = "0";
    tempMinInput.step = "1";
    tempMinInput.value = slot.temp_min == null ? "" : String(slot.temp_min);
    tempMinInput.disabled = true;

    const tempMaxInput = document.createElement("input");
    tempMaxInput.type = "number";
    tempMaxInput.min = "0";
    tempMaxInput.step = "1";
    tempMaxInput.value = slot.temp_max == null ? "" : String(slot.temp_max);
    tempMaxInput.disabled = true;

    let materialDbId = String(slot.material_db_id || inferMaterialDbId(slot.type, slot.vendor, slot.name) || "");

    function syncNameOptions(materialType, preferredName) {
      const presets = listPresetsForType(materialType);
      const currentName = String(preferredName || slot.name || "").trim();
      nameSelect.innerHTML = "";
      presets.forEach(function (preset) {
        const option = document.createElement("option");
        option.value = preset.name;
        option.textContent = preset.display || preset.name;
        if (currentName && currentName === preset.name) option.selected = true;
        nameSelect.appendChild(option);
      });
      if (!nameSelect.value && presets[0]) nameSelect.value = presets[0].name;
    }

    function applyPreset(materialType, preferredName) {
      syncNameOptions(materialType, preferredName);
      const preset = findPresetByTypeAndName(materialType, nameSelect.value) || listPresetsForType(materialType)[0];
      if (!preset) return;
      materialDbId = String(preset.db_id || "");
      vendorInput.value = preset.vendor;
      nameSelect.value = preset.name;
      tempMinInput.value = preset.temp_min;
      tempMaxInput.value = preset.temp_max;
    }

    select.addEventListener("change", function () {
      applyPreset(select.value, "");
    });

    nameSelect.addEventListener("change", function () {
      applyPreset(select.value, nameSelect.value);
    });

    syncNameOptions(select.value, slot.name || "");
    if (nameSelect.value) applyPreset(select.value, nameSelect.value);

    const grid = document.createElement("div");
    grid.className = "k1c-cfs-edit-grid";
    grid.appendChild(createField("Type", select));
    grid.appendChild(createField("Vendor", vendorInput));
    const nameField = createField("Name", nameSelect);
    nameField.classList.add("wide");
    grid.appendChild(nameField);
    grid.appendChild(createField("Min Temp", tempMinInput));
    grid.appendChild(createField("Max Temp", tempMaxInput));
    body.appendChild(grid);
    card.appendChild(body);

    const actions = document.createElement("div");
    actions.className = "k1c-cfs-modal-actions";
    const cancel = document.createElement("button");
    cancel.type = "button";
    cancel.className = "k1c-cfs-cancel-btn";
    cancel.textContent = "Cancel";
    cancel.onclick = closeModal;
    const save = document.createElement("button");
    save.type = "button";
    save.className = "k1c-cfs-save-btn";
    save.textContent = "Save";
    save.onclick = function () {
      saveSlot(
        slot,
        {
          material_db_id: materialDbId || inferMaterialDbId(select.value, vendorInput.value, nameSelect.value),
          type: select.value,
          vendor: vendorInput.value,
          name: nameSelect.value,
          temp_min: tempMinInput.value,
          temp_max: tempMaxInput.value,
          color: colorInput.value,
        },
        save
      );
    };
    actions.appendChild(cancel);
    actions.appendChild(save);
    card.appendChild(actions);

    modal.addEventListener("click", function (event) {
      if (event.target === modal) closeModal();
    });

    document.body.appendChild(modal);
  }

  function buildRoot() {
    root = document.createElement("div");
    root.id = ROOT_ID;

    const shell = document.createElement("div");
    shell.className = "k1c-cfs-shell";
    root.appendChild(shell);

    gridEl = document.createElement("div");
    gridEl.className = "k1c-cfs-grid";
    shell.appendChild(gridEl);

    const holderWrap = document.createElement("div");
    holderWrap.id = "k1c-cfs-holder-wrap";
    holderWrap.className = "k1c-cfs-holder-wrap";
    shell.appendChild(holderWrap);

    const controls = document.createElement("div");
    controls.className = "k1c-cfs-controls";
    const controlsRow = document.createElement("div");
    controlsRow.className = "k1c-cfs-controls-row";

    const feedBtn = document.createElement("button");
    feedBtn.type = "button";
    feedBtn.className = "k1c-cfs-action";
    feedBtn.disabled = true;
    feedBtn.appendChild(createSvgPath("M11 4v11.2l-3.6-3.6-1.4 1.4 6 6 6-6-1.4-1.4-3.6 3.6V4h-2z"));
    const feedText = document.createElement("span");
    feedText.textContent = "Feed";
    feedBtn.appendChild(feedText);
    feedBtn.onclick = function () {
      const slot = latestSlots.find(function (item) { return item.slot === selectedSlot; });
      if (!slot) return;
      const action = slot.selected ? "feed" : "feed";
      runSlotAction(slot, action, feedBtn);
    };
    feedBtnEl = feedBtn;

    const configBtn = document.createElement("button");
    configBtn.type = "button";
    configBtn.className = "k1c-cfs-action";
    configBtn.appendChild(createSvgPath("M19.4 13a7.8 7.8 0 0 0 .1-1 7.8 7.8 0 0 0-.1-1l2.1-1.6-2-3.4-2.5 1a7.2 7.2 0 0 0-1.7-1l-.4-2.7h-4l-.4 2.7a7.2 7.2 0 0 0-1.7 1l-2.5-1-2 3.4L4.6 11a7.8 7.8 0 0 0-.1 1 7.8 7.8 0 0 0 .1 1l-2.1 1.6 2 3.4 2.5-1a7.2 7.2 0 0 0 1.7 1l.4 2.7h4l.4-2.7a7.2 7.2 0 0 0 1.7-1l2.5 1 2-3.4-2.1-1.6zM12 15.5A3.5 3.5 0 1 1 12 8a3.5 3.5 0 0 1 0 7.5z"));
    const configText = document.createElement("span");
    configText.textContent = "Purge Settings";
    configBtn.appendChild(configText);
    configBtn.title = "Config";
    configBtn.onclick = function () {
      openMaterialConfigModal();
    };
    configBtnEl = configBtn;

    const retractBtn = document.createElement("button");
    retractBtn.type = "button";
    retractBtn.className = "k1c-cfs-action";
    retractBtn.disabled = true;
    retractBtn.appendChild(createSvgPath("M13 20V8.8l3.6 3.6 1.4-1.4-6-6-6 6 1.4 1.4 3.6-3.6V20h2z"));
    const retractText = document.createElement("span");
    retractText.textContent = "Retract";
    retractBtn.appendChild(retractText);
    retractBtn.onclick = function () {
      const slot = latestSlots.find(function (item) { return item.slot === selectedSlot; });
      if (!slot) return;
      runSlotAction(slot, "retract", retractBtn);
    };
    retractBtnEl = retractBtn;

    controlsRow.appendChild(feedBtn);
    controlsRow.appendChild(retractBtn);
    controls.appendChild(controlsRow);
    const dbBtn = document.createElement("button");
    dbBtn.type = "button";
    dbBtn.className = "k1c-cfs-action";
    dbBtn.appendChild(createSvgPath("M12 3C7.58 3 4 4.79 4 7v10c0 2.21 3.58 4 8 4s8-1.79 8-4V7c0-2.21-3.58-4-8-4zm0 2c3.87 0 6 .9 6 2s-2.13 2-6 2-6-.9-6-2 2.13-2 6-2zm0 14c-3.87 0-6-.9-6-2v-2.23c1.61.78 3.72 1.23 6 1.23s4.39-.45 6-1.23V17c0 1.1-2.13 2-6 2zm0-5c-3.87 0-6-.9-6-2V9.77C7.61 10.55 9.72 11 12 11s4.39-.45 6-1.23V12c0 1.1-2.13 2-6 2z"));
    const dbText = document.createElement("span");
    dbText.textContent = "Material DB";
    dbBtn.appendChild(dbText);
    dbBtn.title = "Open Material Database Editor";
    dbBtn.onclick = function () { openMaterialDbModal(); };
    dbBtnEl = dbBtn;

    const mapBtn = document.createElement("button");
    mapBtn.type = "button";
    mapBtn.className = "k1c-cfs-action";
    mapBtn.appendChild(createSvgPath("M4 6h10v2H4V6zm0 5h10v2H4v-2zm0 5h7v2H4v-2zm13-9l4 4-4 4v-3h-2v-2h2V7z"));
    const mapText = document.createElement("span");
    mapText.textContent = "Map & Print";
    mapBtn.appendChild(mapText);
    mapBtn.title = "Map G-Code filament types/colors to CFS-C slots and start print";
    window.__k1cOpenMapModal = async function (forcedFile, isResumeMode) {
      closeModal();
      const overlay = document.createElement("div");
      overlay.id = MODAL_ID;
      overlay.setAttribute("style", "position:fixed;inset:0;background:rgba(0,0,0,0.82);z-index:99999;display:flex;align-items:center;justify-content:center;padding:16px;");
      overlay.onclick = function (ev) { if (ev.target === overlay && !isResumeMode) closeModal(); };
      const card = document.createElement("div");
      card.setAttribute("style", "width:min(540px,94vw);background:#1b1d23;color:#f3f5f8;border:1px solid #353a46;border-radius:14px;padding:20px;box-shadow:0 24px 60px rgba(0,0,0,0.85);display:flex;flex-direction:column;gap:14px;font-family:inherit;");
      card.innerHTML = "<div style='display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #2e333e;padding-bottom:10px;'><span style='font-size:16px;font-weight:700;color:#fff;'>" + (isResumeMode ? "Confirm Slot Mapping & Resume Print" : "Map Filaments & Start Print") + "</span><button type='button' id='k1c-mp-x' style='background:none;border:none;color:#b8c0cc;font-size:22px;cursor:pointer;'>×</button></div><select id='k1c-mp-f' style='width:100%;padding:10px;border-radius:8px;background:#13151a;color:#fff;border:1px solid #3a404d;font-size:13px;'></select><div id='k1c-mp-l' style='display:flex;flex-direction:column;gap:8px;color:#e6ebf2;'>Loading G-Code files...</div><label style='display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:8px;background:#23262f;border:1px solid #323744;font-size:12.5px;color:#e6ebf2;cursor:pointer;'><input type='checkbox' id='k1c-mp-auto' style='width:16px;height:16px;accent-color:#4f8cff;'> Auto-open mapping dialog when a pri
      overlay.appendChild(card); document.body.appendChild(overlay);
      const fSel = card.querySelector("#k1c-mp-f"), mList = card.querySelector("#k1c-mp-l"), sBtn = card.querySelector("#k1c-mp-s"), autoChk = card.querySelector("#k1c-mp-auto");
      const abortOrClose = function () { if (isResumeMode) runKlipperCommand("SET_GCODE_VARIABLE MACRO=_CFS_MAP_STATE VARIABLE=awaiting VALUE=0\nCANCEL_PRINT"); closeModal(); };
      card.querySelector("#k1c-mp-x").onclick = abortOrClose; card.querySelector("#k1c-mp-c").onclick = abortOrClose;
      try { const sv = await queryKlipperObject("save_variables"); const vars = (sv && sv.result && sv.result.status && sv.result.status.save_variables && sv.result.status.save_variables.variables) || {}; autoChk.checked = Number(vars.cfs_auto_map || 0) === 1; } catch (e) {}
      autoChk.onchange = function () { runKlipperCommand("SET_CFS_AUTO_MAP ENABLE=" + (autoChk.checked ? "1" : "0")); };
      const slots = (latestSlots || []).filter(function (x) { return x && x.present && !x.is_holder; }); let reqs = [];
      async function loadGcode(fn) {
        mList.textContent = "Reading G-Code..."; const enc = fn.split("/").map(encodeURIComponent).join("/");
        const txt = await fetch("/server/files/gcodes/" + enc, { headers: { Range: "bytes=0-131071" } }).then(function (r) { return r.text(); });
        let ft = [], fc = []; const ts = new Set();
        txt.split("\n").forEach(function (rawLine) {
          const line = rawLine.trim();
          if (line.indexOf("; filament_type =") === 0) ft = line.split("=").slice(1).join("=").split(";").map(function (x) { return x.trim().toUpperCase(); });
          else if (line.indexOf("; filament_colour =") === 0) fc = line.split("=").slice(1).join("=").split(";").map(function (x) { return x.trim(); });
          else if (/^T[0-3](\s|;|$)/.test(line)) ts.add(Number(line.charAt(1)));
        });
        if (!ts.size) ts.add(0);
        reqs = Array.from(ts).sort().map(function (t) { return { t: t, type: (ft[t] || ft || "PLA"), hex: (fc[t] || fc || "#FFFFFF") }; });
        mList.innerHTML = "";
        reqs.forEach(function (q) {
          const row = document.createElement("div"); row.setAttribute("style", "display:flex;justify-content:space-between;align-items:center;padding:10px 12px;background:#252831;border:1px solid #343946;border-radius:8px;color:#fff;");
          row.innerHTML = "<div style='display:flex;align-items:center;gap:10px;'><span style='width:16px;height:16px;border-radius:50%;background:" + normalizeColor(q.hex) + ";border:1px solid rgba(255,255,255,0.45);display:inline-block;'></span><b style='font-size:13.5px;color:#fff;'>T" + q.t + " · " + q.type + " (" + q.hex + ")</b></div>";
          const sel = document.createElement("select"); sel.dataset.t = String(q.t); sel.setAttribute("style", "padding:7px 10px;border-radius:7px;background:#13151a;color:#fff;border:1px solid #3e4452;font-size:12.5px;");
          slots.forEach(function (sl) { const o = document.createElement("option"); o.value = String(sl.material_index); o.textContent = (sl.display_label || ("Slot " + sl.slot)) + " (" + (sl.type || "?") + ")"; if (String(sl.type || "").toUpperCase() === q.type) o.selected = true; sel.appendChild(o); });
          row.appendChild(sel); mList.appendChild(row);
        });
        sBtn.disabled = !slots.length;
      }
      sBtn.onclick = async function () {
        sBtn.disabled = true; sBtn.textContent = isResumeMode ? "Resuming..." : "Starting...";
        const sels = mList.querySelectorAll("select[data-t]");
        for (let i = 0; i < sels.length; i++) {
          const q = reqs.find(function (x) { return x.t === Number(sels[i].dataset.t); }), sl = slots.find(function (x) { return x.material_index === Number(sels[i].value); });
          if (q && sl) { const c = parseInt(String(q.hex || "").replace("#", "").slice(0, 6), 16) || 0; sendJson({ method: "set", params: { setMaterialInfo: { boxId: typeof sl.box_id === "number" ? sl.box_id : 1, materialId: sl.material_index, type: q.type, color: c, name: sl.name || q.type, vendor: sl.vendor || "Generic" } } }); }
        }
        await new Promise(function (r) { window.setTimeout(r, 450); });
        if (isResumeMode) await runKlipperCommand("_CFS_CONFIRM_MAP"); else await fetch("/printer/print/start?filename=" + encodeURIComponent(fSel.value), { method: "POST" });
        closeModal();
      };
      if (forcedFile) { const o = document.createElement("option"); o.value = forcedFile; o.textContent = forcedFile; fSel.appendChild(o); fSel.disabled = true; await loadGcode(forcedFile); }
      else {
        const res = await fetch("/server/files/list?root=gcodes").then(function (r) { return r.json(); });
        const files = ((res && res.result) || []).filter(function (f) { return f && f.path && f.path.toLowerCase().endsWith(".gcode"); }).sort(function (a, b) { return Number(b.modified || 0) - Number(a.modified || 0); }).slice(0, 15);
        files.forEach(function (f) { const o = document.createElement("option"); o.value = f.path; o.textContent = f.path; fSel.appendChild(o); });
        fSel.onchange = function () { loadGcode(fSel.value); };
        if (files.length) await loadGcode(files.path); else mList.textContent = "No G-Code files found.";
      }
    };
    mapBtn.onclick = function () { window.__k1cOpenMapModal("", false); };
    if (!window.__k1cMapWatcher) { window.__k1cMapWatcher = window.setInterval(async function () { try { if (document.getElementById(MODAL_ID)) return; const st = await queryKlipperObject("gcode_macro%20_CFS_MAP_STATE"); const ms = (st && st.result && st.result.status && st.result.status["gcode_macro _CFS_MAP_STATE"]) || {}; if (Number(ms.awaiting || 0) === 1 && ms.filename) window.__k1cOpenMapModal(String(ms.filename), true); } catch (e) {} }, 1500); }
    controls.appendChild(configBtn);
    controls.appendChild(dbBtn);
    controls.appendChild(mapBtn);
    shell.appendChild(controls);
    return root;
  }

  function buildPanelCard() {
    const frontend = detectFrontend();
    const card = document.createElement("div");
    card.id = CARD_ID;
    card.className = frontend === "fluidd"
      ? "mb-2 mb-md-4 v-card v-sheet theme--dark rounded-md collapsable-card k1c-cfs-panel-card"
      : "v-card v-sheet theme--dark panel k1c-cfs-panel-card mb-3 mb-md-6";

    const toolbar = document.createElement("header");
    let content;
    if (frontend === "fluidd") {
      toolbar.className = "v-card__title collapsable-card-title card-heading";
      content = document.createElement("div");
      content.className = "row flex-nowrap no-gutters align-center";
      content.style.width = "100%";
      content.style.margin = "0";
    } else {
      toolbar.className = "panel-toolbar v-sheet theme--dark v-toolbar v-toolbar--dense v-toolbar--flat collapsible";
      toolbar.style.paddingTop = "3px";
      toolbar.style.paddingBottom = "3px";
      content = document.createElement("div");
      content.className = "v-toolbar__content d-flex align-center justify-space-between";
      content.style.padding = "0 18px 0 20px";
      content.style.minHeight = "46px";
    }
    const title = document.createElement("div");
    if (frontend === "fluidd") {
      title.className = "text-no-wrap col align-self-center";
      title.innerHTML = '<span class="font-weight-light">CFS</span>';
    } else {
      title.className = "v-toolbar__title d-flex align-center";
      title.textContent = "CFS";
    }
    content.appendChild(title);

    const humidityBadge = document.createElement("div");
    humidityBadge.className = "k1c-cfs-badge humidity";
    humidityBadge.appendChild(createSvgPath("M12 21.5c-3.5 0-6.5-2.8-6.5-6.2 0-2.8 2.6-6.6 5.8-10.9.3-.4.8-.4 1.2 0 3.2 4.3 5.8 8.1 5.8 10.9 0 3.4-3 6.2-6.3 6.2zm0-14.7C9.3 10.5 7 13.5 7 15.3c0 2.5 2.2 4.7 5 4.7s5-2.2 5-4.7c0-1.8-2.3-4.8-5-8.5z"));
    humidityLabelEl = document.createElement("span");
    humidityLabelEl.className = "k1c-cfs-humidity-label";
    humidityLabelEl.textContent = "--%";
    humidityBadge.appendChild(humidityLabelEl);

    const tempBadge = document.createElement("div");
    tempBadge.className = "k1c-cfs-badge temperature";
    tempBadge.appendChild(createSvgPath("M14 14.76V5a2 2 0 0 0-4 0v9.76a4 4 0 1 0 4 0zM12 20a2 2 0 0 1-1-3.73V5a1 1 0 0 1 2 0v11.27A2 2 0 0 1 12 20z"));
    tempLabelEl = document.createElement("span");
    tempLabelEl.className = "k1c-cfs-temp-label";
    tempLabelEl.textContent = "--C";
    tempBadge.appendChild(tempLabelEl);
    const right = document.createElement("div");
    right.style.display = "flex";
    right.style.gap = "8px";
    right.style.alignItems = "center";
    if (frontend === "fluidd") {
      right.className = "col col-auto align-self-center";
    } else {
      right.className = "d-flex align-center";
    }
    right.appendChild(humidityBadge);
    right.appendChild(tempBadge);
    content.appendChild(right);

    toolbar.appendChild(content);

    const body = document.createElement("div");
    body.className = frontend === "fluidd" ? "v-card__text k1c-cfs-card-body" : "k1c-cfs-card-body";
    body.appendChild(buildRoot());

    card.appendChild(toolbar);
    card.appendChild(body);
    return card;
  }

  function buildStandaloneHolderSlot() {
    let cachedHolder = null;
    try { cachedHolder = JSON.parse(window.localStorage.getItem("k1c_cfs_holder_cache") || "null"); } catch (e) {}
    const hTypeRaw = String((cachedHolder && cachedHolder.type) || "").trim().toUpperCase();
    const hNameRaw = String((cachedHolder && cachedHolder.name) || "").trim();
    const hVendorRaw = String((cachedHolder && cachedHolder.vendor) || "").trim();
    const hHasMat = hTypeRaw !== "" && hTypeRaw !== "NONE" && hTypeRaw !== "-1";
    const hColor = hHasMat ? normalizeColorHex(cachedHolder && cachedHolder.color) : "";
    const hPresent = lllSensorInstalled ? lllFilamentDetected : true;
    const anyCfsSelected = latestSlots.some(function (x) { return !x.is_holder && x.selected; });
    const hLoaded = hPresent && extFilamentDetected && !anyCfsSelected;
    return {
      slot: "EXT",
      display_label: "Spool Holder",
      is_holder: true,
      box_id: 0,
      material_index: 0,
      state: hPresent ? 1 : 0,
      status: hPresent ? (hHasMat ? "Ready" : "Loaded") : "Empty",
      present: hPresent,
      selected: hLoaded,
      rfid: "",
      type: hPresent ? (hHasMat ? hTypeRaw : "External") : "Empty",
      name: hHasMat ? hNameRaw : "",
      vendor: hVendorRaw,
      manufacturer: hVendorRaw,
      material_db_id: hHasMat ? inferMaterialDbId(hTypeRaw, hVendorRaw, hNameRaw) : "",
      color: (hPresent && hColor) ? hColor : "#64748b",
      temp_min: 0,
      temp_max: 0,
      used_material_length: 0,
      raw: {},
    };
  }

  function render(slots, connected) {
    if (!gridEl) return;

    let incoming = Array.isArray(slots) ? slots.slice() : [];
    if (!incoming.some(function (x) { return x && x.is_holder; })) {
      const prevHolder = latestSlots.find(function (x) { return x && x.is_holder; });
      incoming = [prevHolder || buildStandaloneHolderSlot()].concat(incoming);
    }
    if (!connected) {
      incoming = incoming.map(function (x) {
        return x.is_holder ? x : Object.assign({}, x, { present: false, selected: false, type: "Empty" });
      });
    }
    latestSlots = incoming;
    latestConnected = !!connected;

    if (!selectedSlot || !latestSlots.some(function (slot) { return slot.slot === selectedSlot; })) {
      const active = latestSlots.find(function (slot) { return slot.selected; });
      selectedSlot = active ? active.slot : (latestSlots[0] ? latestSlots[0].slot : "");
    }

    const selectedSlotData = latestSlots.find(function (s) { return s.slot === selectedSlot; });
    const currentLoadedSlot = latestSlots.find(function (s) { return s.selected; });
    const currentLoadedSlotName = currentLoadedSlot ? currentLoadedSlot.slot : "";
    const targetSlotState = pendingAction
      ? latestSlots.find(function (s) { return s.slot === pendingAction.targetSlot; })
      : null;
    const previousSlotState = pendingAction && pendingAction.previousSelectedSlot
      ? latestSlots.find(function (s) { return s.slot === pendingAction.previousSelectedSlot; })
      : null;
    let actionLocked = !!pendingAction;

    if (pendingAction) {
      let completed = false;
      if (pendingAction.kind === "retract") {
        completed = !!previousSlotState && !previousSlotState.selected;
      } else if (!pendingAction.targetSlot && pendingAction.source === "machine") {
        const anySelectedSlot = latestSlots.find(function (s) { return s.selected; });
        if (pendingAction.previousSelectedSlot) {
          completed = !!anySelectedSlot && anySelectedSlot.slot !== pendingAction.previousSelectedSlot;
        } else {
          completed = !!anySelectedSlot;
        }
      } else {
        completed = !!targetSlotState && targetSlotState.selected;
      }
      if (completed) {
        actionSlot = "";
        pendingAction = null;
        actionLocked = false;
      }
    }

    gridEl.innerHTML = "";
    if (hasCfsBox) {
      if (nexuspPaused) {
        const holderItem = latestSlots.find(function (x) { return x.is_holder; });
        if (holderItem) selectedSlot = holderItem.slot;
      } else if (selectedSlot === "HOLDER" || !latestSlots.some(function (x) { return x.slot === selectedSlot && x.present; })) {
        const bestCfs = latestSlots.find(function (x) { return !x.is_holder && x.selected && x.present; })
          || latestSlots.find(function (x) { return !x.is_holder && x.present; })
          || latestSlots.find(function (x) { return !x.is_holder; });
        if (bestCfs) selectedSlot = bestCfs.slot;
      }
    }
    gridEl.style.display = hasCfsBox ? "" : "none";
    const holderWrapEl = document.getElementById("k1c-cfs-holder-wrap");
    if (holderWrapEl) {
      holderWrapEl.innerHTML = "";
      holderWrapEl.style.marginTop = hasCfsBox ? "10px" : "0";
      holderWrapEl.style.paddingTop = hasCfsBox ? "10px" : "0";
      holderWrapEl.style.borderTop = hasCfsBox ? "1px solid rgba(255,255,255,.08)" : "none";
    }
    const cardEl = document.getElementById(CARD_ID);
    if (cardEl) {
      cardEl.querySelectorAll(".k1c-cfs-badge").forEach(function (b) {
        b.style.display = hasCfsBox ? "" : "none";
      });
      const titleEl = cardEl.querySelector(".v-card__title span, .v-toolbar__title");
      if (titleEl && !hasCfsBox) titleEl.textContent = "Spool Holder";
    }
    if (configBtnEl) configBtnEl.style.display = hasCfsBox ? "" : "none";
    if (dbBtnEl) dbBtnEl.style.display = hasCfsBox ? "" : "none";

    latestSlots.forEach(function (slot) {
      const item = document.createElement("div");
      item.className = "k1c-cfs-item" + (selectedSlot === slot.slot ? " active" : "") + (!slot.present ? " empty" : "");
      item.style.setProperty("--spool-color", normalizeColor(slot.color));
      if (slot.present) {
        item.onclick = function () {
          selectedSlot = slot.slot;
          render(latestSlots, latestConnected);
        };
      }

      const main = document.createElement("div");
      main.className = "k1c-cfs-main";

      const spool = document.createElement("div");
      spool.className = "k1c-cfs-spool";
      main.appendChild(spool);

      const info = document.createElement("div");
      info.className = "k1c-cfs-info";
      const channel = document.createElement("span");
      channel.className = "k1c-cfs-channel";
      channel.textContent = slot.display_label || ("Channel " + slot.slot);
      const type = document.createElement("span");
      type.className = "k1c-cfs-type";
      type.textContent = slot.is_holder ? String(slot.type || "Empty") : (slot.present ? String(slot.type || "Unknown") : "Empty");
      info.appendChild(channel);
      info.appendChild(type);
      var rem = computeSlotRemaining(slot);
      if (rem) {
        var remWrap = document.createElement("div");
        remWrap.style.cssText = "display:flex;align-items:center;gap:6px;margin-top:4px;font-size:11px;color:#b8c0cc;";
        var bar = document.createElement("div");
        bar.style.cssText = "flex:1;max-width:64px;height:4px;border-radius:999px;background:rgba(255,255,255,.12);overflow:hidden;";
        var fill = document.createElement("div");
        fill.style.cssText = "height:100%;width:" + rem.pct + "%;background:" + (rem.pct <= 15 ? "#ff6b6b" : normalizeColor(slot.color)) + ";";
        bar.appendChild(fill);
        var lbl = document.createElement("span");
        lbl.textContent = (rem.hasRfid ? "RFID · " : "") + rem.pct + "%" + (rem.grams != null ? " (~" + rem.grams + "g)" : "");
        remWrap.appendChild(bar);
        remWrap.appendChild(lbl);
        info.appendChild(remWrap);
      }
      main.appendChild(info);

      const edit = document.createElement("button");
      edit.type = "button";
      edit.className = "k1c-cfs-edit-inline";
      edit.title = "Edit";
      edit.disabled = !slot.present;
      edit.appendChild(createSvgPath("M3 17.2v4.5h4.5l11-11.1-4.5-4.5L3 17.2zm18.7-10.3c.4-.4.4-1 0-1.4l-3.1-3.1c-.4-.4-1-.4-1.4 0l-2.2 2.2 4.5 4.5 2.2-2.2z"));
      edit.onclick = function (event) {
        event.stopPropagation();
        if (!slot.present) return;
        openEditModal(slot);
      };

      item.appendChild(main);
      const slotIsPending = actionLocked && !!pendingAction && (pendingAction.targetSlot === slot.slot || pendingAction.previousSelectedSlot === slot.slot);
      if (slotIsPending) {
        const spinner = document.createElement("div");
        spinner.className = "k1c-cfs-loading-dot";
        spinner.title = "Running";
        item.appendChild(spinner);
      } else if (slot.selected) {
        const dot = document.createElement("div");
        dot.className = "k1c-cfs-loaded-dot";
        dot.title = "Loaded";
        item.appendChild(dot);
      }
      item.appendChild(edit);
      if (slot.is_holder && holderWrapEl) {
        holderWrapEl.appendChild(item);
      } else {
        gridEl.appendChild(item);
      }
    });
    const isLoaded = !!(selectedSlotData && selectedSlotData.selected);
    const isPresent = !!(selectedSlotData && selectedSlotData.present);
    const isHolderSelected = !!(selectedSlotData && selectedSlotData.is_holder);
    const col1CollisionLock = !!(lllSensorInstalled && !nexuspPaused && lllFilamentDetected && !extFilamentDetected);
    const holderReady = lllSensorInstalled
      ? !!(isHolderSelected && nexuspPaused && lllFilamentDetected && extFilamentDetected)
      : !!(isHolderSelected && nexuspPaused && extFilamentDetected);
    const matrixBlock = isHolderSelected ? !holderReady : col1CollisionLock;
    if (feedBtnEl) {
      const allowHolderFeed = holderReady;
      feedBtnEl.disabled = actionLocked || !!actionSlot || matrixBlock || (!allowHolderFeed && isLoaded) || !isPresent;
      var feedIconEl = feedBtnEl.querySelector("svg");
      var feedTextEl = feedBtnEl.querySelector("span");
      var externalFeedPending = !!pendingAction
        && pendingAction.source === "machine"
        && pendingAction.kind !== "retract"
        && !pendingAction.targetSlot;
      if (feedIconEl) feedIconEl.style.display = externalFeedPending ? "none" : "";
      if (feedTextEl) {
        if (externalFeedPending) {
          feedTextEl.innerHTML = '<span class="k1c-cfs-action-loading"><span class="k1c-cfs-action-loading-dot"></span><span>Loading</span></span>';
        } else {
          feedTextEl.textContent = (selectedSlotData && selectedSlotData.is_holder) ? "Feed" : ((isPresent && currentLoadedSlotName && !isLoaded) ? "Switch" : "Feed");
        }
      }
    }
    if (configBtnEl) configBtnEl.disabled = actionLocked;
    if (dbBtnEl) dbBtnEl.disabled = actionLocked;
    if (retractBtnEl) retractBtnEl.disabled = actionLocked || !!actionSlot || matrixBlock || !isPresent;

    updateStatus(connected);
    updateHumidity(latestHumidity, latestTemp);
  }

  async function pollHolderSensors() {
    try {
      const res = await queryKlipperObject("filament_switch_sensor%20lll_plus_sensor&filament_switch_sensor%20filament_sensor&gcode_macro%20_LLL_WATCHER_STATE");
      const st = (res && res.result && res.result.status) || {};
      const hasLll = Object.prototype.hasOwnProperty.call(st, "filament_switch_sensor lll_plus_sensor");
      const lllDet = hasLll ? !!st["filament_switch_sensor lll_plus_sensor"].filament_detected : false;
      const extDet = Object.prototype.hasOwnProperty.call(st, "filament_switch_sensor filament_sensor")
        ? !!st["filament_switch_sensor filament_sensor"].filament_detected
        : false;
      const hasWatcher = Object.prototype.hasOwnProperty.call(st, "gcode_macro _LLL_WATCHER_STATE");
      const nPaused = hasWatcher
        ? (Number(st["gcode_macro _LLL_WATCHER_STATE"].nexusp_paused) === 1)
        : true;
      if (hasLll !== lllSensorInstalled || lllDet !== lllFilamentDetected || extDet !== extFilamentDetected || nPaused !== nexuspPaused) {
        const wasPaused = nexuspPaused;
        lllSensorInstalled = hasLll;
        lllFilamentDetected = lllDet;
        extFilamentDetected = extDet;
        nexuspPaused = nPaused;
        if (wasPaused && !nexuspPaused && selectedSlot === "HOLDER") {
          const firstCfs = latestSlots.find(function (x) { return !x.is_holder && x.present; }) || latestSlots.find(function (x) { return !x.is_holder; });
          if (firstCfs) selectedSlot = firstCfs.slot;
        }
        let cachedHolder = null;
        try { cachedHolder = JSON.parse(window.localStorage.getItem("k1c_cfs_holder_cache") || "null"); } catch (e) {}
        const cType = String((cachedHolder && cachedHolder.type) || "").trim().toUpperCase();
        const cColor = cType ? normalizeColorHex(cachedHolder && cachedHolder.color) : "";
        const baseList = latestSlots.some(function (x) { return x.is_holder; })
          ? latestSlots
          : [buildStandaloneHolderSlot()].concat(latestSlots);
        latestSlots = baseList.map(function (item) {
          if (!item.is_holder) return item;
          const hPresent = lllSensorInstalled ? lllFilamentDetected : true;
          const anyCfs = baseList.some(function (x) { return !x.is_holder && x.selected; });
          const hLoaded = hPresent && extFilamentDetected && !anyCfs;
          const knownType = (item.type && item.type !== "Empty" && item.type !== "External") ? item.type : cType;
          const hasMat = knownType !== "";
          return Object.assign({}, item, {
            present: hPresent,
            state: hPresent ? 1 : 0,
            status: hPresent ? (hasMat ? "Ready" : "Loaded") : "Empty",
            selected: hLoaded,
            type: hPresent ? (hasMat ? knownType : "External") : "Empty",
            color: (hPresent && (cColor || (item.color && item.color !== "#64748b"))) ? (cColor || item.color) : "#64748b",
          });
        });
        render(latestSlots, latestConnected);
      }
    } catch (e) {}
  }

  function poll() {
    pollHolderSensors();
    if (latestConnected) requestBoxsInfo();
    else connectWs();
  }

  function startPolling() {
    if (timer) return;
    connectWs();
    poll();
    timer = window.setInterval(poll, POLL_MS);
    heartbeatTimer = window.setInterval(function () {
      if (latestConnected) sendJson({ ModeCode: "heart_beat" });
    }, HEARTBEAT_MS);

    // ADD THIS LINE HERE: Starts the CFS-C polling loop in the background
    window.setInterval(pollCfsCStatus, 2000);
  }


  function stopPolling() {
    if (!timer) return;
    window.clearInterval(timer);
    timer = null;
    if (heartbeatTimer) {
      window.clearInterval(heartbeatTimer);
      heartbeatTimer = null;
    }
    if (reconnectTimer) {
      window.clearTimeout(reconnectTimer);
      reconnectTimer = null;
    }
    if (ws) {
      try { ws.close(); } catch (error) {}
      ws = null;
    }
  }

  function ensurePanelCard() {
    let card = document.getElementById(CARD_ID);
    if (card) {
      root = document.getElementById(ROOT_ID) || root;
      gridEl = root ? root.querySelector(".k1c-cfs-grid") : gridEl;
      humidityLabelEl = card.querySelector(".k1c-cfs-humidity-label") || humidityLabelEl;
      tempLabelEl = card.querySelector(".k1c-cfs-temp-label") || tempLabelEl;
      return card;
    }
    return buildPanelCard();
  }

  function findDashboardColumn() {
    // 1. MAINSAlL PFAD: Sucht die bekannte Klasse
    const mainsailTemp = document.querySelector("main .temperature-panel");
    if (mainsailTemp) {
      const col = mainsailTemp.closest(".col");
      if (col) return { column: col, after: mainsailTemp };
    }

    // 2. FLUIDD PATH: Search for EVERY card on the dashboard that contains a chart.
    // Da die Temperaturen die einzige Karte mit einem Diagramm im Hauptbereich sind, greift das unfehlbar!
    const fluiddChartCard = document.querySelector("main .f-card:has(.apexcharts-canvas)") || 
                            document.querySelector("main .v-card:has(canvas)") ||
                            document.querySelector("main .f-card:has(canvas)");
                            
    if (fluiddChartCard) {
      const col = fluiddChartCard.closest(".col, .v-col, .flex-column, [class*='col']");
      if (col) return { column: col, after: fluiddChartCard };
    }

    // 3. BOMBENFESTER FALLBACK: Die mittlere/erste Spalte im Grid
    const firstColumn = document.querySelector("main .col, main .v-col");
    if (firstColumn) {
      return { column: firstColumn, after: null };
    }

    return null;
  }

  function mountInDashboard() {
    if (!isDashboardRoute()) {
      unmountPanel();
      return false;
    }
    const target = findDashboardColumn();
    if (!target || !target.column) return false;
    const card = ensurePanelCard();
    if (card.parentElement !== target.column) {
      if (target.after && target.after.parentElement === target.column) {
        target.after.insertAdjacentElement("afterend", card);
      } else {
        target.column.appendChild(card);
      }
    }
    const floatWrap = document.getElementById(FLOAT_ID);
    if (floatWrap) floatWrap.remove();
    return true;
  }

  function showFloatingFallback() {
    if (!isDashboardRoute()) {
      unmountPanel();
      return;
    }
    if (mountInDashboard()) return;
    let wrap = document.getElementById(FLOAT_ID);
    const card = ensurePanelCard();
    if (!wrap) {
      wrap = document.createElement("div");
      wrap.id = FLOAT_ID;
      const shell = document.createElement("div");
      shell.className = CARD_ID + "-shell";
      wrap.appendChild(shell);
      document.body.appendChild(wrap);
    }
    const shell = wrap.firstElementChild;
    if (shell && card.parentElement !== shell) shell.appendChild(card);
  }

  function ensureMounted() {
    if (!isDashboardRoute()) {
      unmountPanel();
      return false;
    }
    return mountInDashboard();
  }

  function watchLayout() {
    if (observer) observer.disconnect();
    observer = new MutationObserver(function () {
      ensureMounted();
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }

  function scheduleFallback() {
    if (floatTimer) window.clearTimeout(floatTimer);
    floatTimer = window.setTimeout(function () {
      if (!ensureMounted()) showFloatingFallback();
    }, FLOAT_AFTER_MS);
  }

  function init() {
    ensurePanelCard();
    ensureMounted();
    watchLayout();
    scheduleFallback();
    startPolling();
    window.setInterval(function () {
      ensureMounted();
    }, RETRY_MS);
  }

  window.setTimeout(init, 800);
  window.addEventListener("beforeunload", function () {
    stopPolling();
    closeModal();
  });

  // =========================================================================
  // CORRECTLY POSITIONED: The CFS-C Live Status Bar (Globally accessible)
  // =========================================================================
  let cfsIsMoving = false;

  function pollCfsCStatus() {
    const urlDb = "/server/database/item?namespace=color_box&key=box_info";
    const urlKlipper = "/printer/objects/query?idle_timeout";

    Promise.all([
      fetch(urlDb).then(r => r.json()),
      fetch(urlKlipper).then(r => r.json())
    ])
    .then(([dbData, klipperData]) => {
      if (!dbData.result || !dbData.result.value || !dbData.result.value.T1) return;
      if (Array.isArray(dbData.result.value.T1.list)) latestBoxInfoList = dbData.result.value.T1.list;
      if (!hasCfsBox) {
        hasCfsBox = true;
        render(latestSlots, latestConnected);
      }
      if (!klipperData.result || !klipperData.result.status || !klipperData.result.status.idle_timeout) return;

      // -> REACTIVE FIX FOR VUE.JS: 
      // Whenever new live data arrives, enforce the card title!
      // This permanently overrides the stubborn Vue template value.
      const panelTitle = document.querySelector(".k1c-cfs-panel-card .v-card__title span, .k1c-cfs-panel-card .v-toolbar__title, .k1c-cfs-panel-card h2");
      if (panelTitle && panelTitle.textContent !== "CFS-C") {
        panelTitle.textContent = "CFS-C";
      }

      const boxes = dbData.result.value;
      const currentFilamentState = boxes.T1.filament || "";
      const klipperState = klipperData.result.status.idle_timeout.state || "";

      latestHumidity = boxes.T1.humidity || 0;
      latestTemp = boxes.T1.temperature || 0;
      latestConnected = true;

      // 1. MOTION DETECTION (Once Klipper is operational)
      if (klipperState === "Printing") {
        cfsIsMoving = true;
      }

      // 2. COMPLETION TRIGGER (Once Klipper returns to a stable "Ready" state)
      if (cfsIsMoving && klipperState === "Ready") {
        
        // We determine whether the action was successful, based on the original state of the add-on
        // pendingAction keeps track of whether we pressed "feed" or "retract"
        const currentAction = (pendingAction && pendingAction.type) ? pendingAction.type : "";
        let isActionDone = false;

        if (currentAction === "feed") {
          // During loading, the filament must be present (i.e., not None)
          if (currentFilamentState !== "None" && currentFilamentState !== "") {
            isActionDone = true;
          }
        } else if (currentAction === "retract") {
          // When unloading, the filament MUST be completely removed (i.e., set to None)
          if (currentFilamentState === "None" || currentFilamentState === "") {
            isActionDone = true;
          }
        } else {
          // Fallback for machine-triggered changes
          isActionDone = true;
        }

        if (isActionDone) {
          console.log("-> TRIGGER SUCCESSFUL: CFS-C " + currentAction + " finished! Unlock UI.");
          cfsIsMoving = false;
          pendingAction = null;     
          actionSlot = "";          
          latestFeedState = 0;      
          latestFeedStateAt = Date.now();
          
          if (typeof render === "function") {
            render(latestSlots || [], true);
          }
        }
      }
    })
    .catch(err => {});
  }
})();
var _ms=document.createElement("script");_ms.src="k1c-cfs-map.js";document.head.appendChild(_ms);
