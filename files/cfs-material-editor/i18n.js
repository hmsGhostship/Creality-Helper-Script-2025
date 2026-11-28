(function(){
  const I18N = {
    de: {"K1C CFS-C Material Database Editor": "K1C CFS-C Materialdatenbank-Editor", "+ New Filament": "+ Neues Filament", "Add Selection to DB": "Auswahl zur DB hinzufügen", "Import / Export ▾": "Import / Export ▾", "Import OrcaSlicer JSON(s)...": "OrcaSlicer JSON(s) importieren...", "Download Windows Sender (.bat)": "Windows Sender (.bat) herunterladen", "Download Database Backup (.json)": "Datenbank-Backup (.json) herunterladen", "⚙ Settings": "⚙ Einstellungen", "Spoolman: Select & Push": "Spoolman: Auswahl & Push", "Search by brand, name, type or ID...": "Nach Marke, Name, Typ oder ID suchen...", "All Brands": "Alle Marken", "All Types": "Alle Typen", "All Entries": "Alle Einträge", "Custom Only (90001+)": "Nur Eigene (90001+)", "Stock Only": "Nur Werkseinträge", "Brand": "Marke", "Type": "Typ", "Nozzle": "Düse", "Bed": "Bett", "Actions": "Aktionen", "Edit": "Bearbeiten", "Clone": "Klonen", "Delete": "Löschen", "Remove": "Entfernen", "Cancel": "Abbrechen", "Save": "Speichern", "Save Settings": "Einstellungen speichern", "Editor Settings": "Editor-Einstellungen", "Include abrasive CF/GF materials": "Abrasive CF/GF-Materialien zulassen", "Allow editing stock profiles (Creality / Generic)": "Bearbeiten von Werksprofilen erlauben", "Spoolman External Database": "Externe Spoolman-Datenbank", "Sync Behavior": "Sync-Verhalten", "Select & Push (Manual selection)": "Auswahl & Push (Manuelle Auswahl)", "AutoPush (Add & Edit)": "AutoPush (Hinzufügen & Bearbeiten)", "AutoSync (Add, Edit & Delete)": "AutoSync (Hinzufügen, Bearbeiten & Löschen)", "Database Maintenance": "Datenbank-Wartung", "Restore Factory Original (.bak)": "Werkszustand wiederherstellen (.bak)", "New Filament": "Neues Filament", "Edit Filament": "Filament bearbeiten", "Clone Filament": "Filament klonen", "Material Type": "Materialtyp", "Brand / Vendor": "Marke / Hersteller", "Profile Name": "Profilname", "Add Selected": "Ausgewählte hinzufügen", "Push Selected to Spoolman": "Ausgewählte an Spoolman senden", "Remove Filament": "Filament entfernen", "Also remove from Spoolman": "Auch aus Spoolman entfernen", "In Spoolman": "In Spoolman", "Ready": "Bereit", "Custom": "Eigenes", "Stock": "Werk", "Active": "Aktiv", "Pending Reboot": "Neustart nötig"},
    fr: {"+ New Filament":"+ Nouveau filament","Add Selection to DB":"Ajouter la sélection","⚙ Settings":"⚙ Paramètres","Spoolman: Select & Push":"Spoolman : Sélection & Push","All Brands":"Toutes les marques","All Types":"Tous les types","All Entries":"Toutes les entrées","Custom Only (90001+)":"Personnalisés (90001+)","Stock Only":"Origine uniquement","Brand":"Marque","Nozzle":"Buse","Bed":"Plateau","Edit":"Modifier","Clone":"Dupliquer","Delete":"Supprimer","Remove":"Retirer","Cancel":"Annuler","Save":"Enregistrer","Save Settings":"Enregistrer","Editor Settings":"Paramètres de l'éditeur","New Filament":"Nouveau filament","Edit Filament":"Modifier le filament","Also remove from Spoolman":"Supprimer aussi de Spoolman","Ready":"Prêt","Custom":"Perso","Stock":"Origine","Active":"Actif"},
    es: {"+ New Filament":"+ Nuevo filamento","Add Selection to DB":"Añadir selección","⚙ Settings":"⚙ Ajustes","Spoolman: Select & Push":"Spoolman: Seleccionar y enviar","All Brands":"Todas las marcas","All Types":"Todos los tipos","All Entries":"Todas las entradas","Custom Only (90001+)":"Solo personalizados (90001+)","Stock Only":"Solo fábrica","Brand":"Marca","Nozzle":"Boquilla","Bed":"Cama","Edit":"Editar","Clone":"Clonar","Delete":"Eliminar","Remove":"Quitar","Cancel":"Cancelar","Save":"Guardar","Save Settings":"Guardar ajustes","Editor Settings":"Ajustes del editor","New Filament":"Nuevo filamento","Edit Filament":"Editar filamento","Also remove from Spoolman":"Eliminar también de Spoolman","Ready":"Listo","Custom":"Pers.","Stock":"Fábrica","Active":"Activo"},
    it: {"+ New Filament":"+ Nuovo filamento","Add Selection to DB":"Aggiungi selezione","⚙ Settings":"⚙ Impostazioni","Spoolman: Select & Push":"Spoolman: Seleziona e invia","All Brands":"Tutte le marche","All Types":"Tutti i tipi","All Entries":"Tutte le voci","Custom Only (90001+)":"Solo personalizzati (90001+)","Stock Only":"Solo fabbrica","Brand":"Marca","Nozzle":"Ugello","Bed":"Piatto","Edit":"Modifica","Clone":"Duplica","Delete":"Elimina","Remove":"Rimuovi","Cancel":"Annulla","Save":"Salva","Save Settings":"Salva impostazioni","Editor Settings":"Impostazioni editor","New Filament":"Nuovo filamento","Edit Filament":"Modifica filamento","Also remove from Spoolman":"Rimuovi anche da Spoolman","Ready":"Pronto","Custom":"Pers.","Stock":"Fabbrica","Active":"Attivo"},
    nl: {"+ New Filament":"+ Nieuw filament","Add Selection to DB":"Selectie toevoegen","⚙ Settings":"⚙ Instellingen","Spoolman: Select & Push":"Spoolman: Selecteren & pushen","All Brands":"Alle merken","All Types":"Alle types","All Entries":"Alle items","Custom Only (90001+)":"Alleen aangepast (90001+)","Stock Only":"Alleen standaard","Brand":"Merk","Nozzle":"Mondstuk","Bed":"Bed","Edit":"Bewerken","Clone":"Klonen","Delete":"Verwijderen","Remove":"Verwijderen","Cancel":"Annuleren","Save":"Opslaan","Save Settings":"Opslaan","Editor Settings":"Editor-instellingen","New Filament":"Nieuw filament","Edit Filament":"Filament bewerken","Also remove from Spoolman":"Ook uit Spoolman verwijderen","Ready":"Gereed","Custom":"Eigen","Stock":"Standaard","Active":"Actief"},
    pl: {"+ New Filament":"+ Nowy filament","Add Selection to DB":"Dodaj wybrane","⚙ Settings":"⚙ Ustawienia","Spoolman: Select & Push":"Spoolman: Wybierz i wyślij","All Brands":"Wszystkie marki","All Types":"Wszystkie typy","All Entries":"Wszystkie wpisy","Custom Only (90001+)":"Tylko własne (90001+)","Stock Only":"Tylko fabryczne","Brand":"Marka","Nozzle":"Dysza","Bed":"Stół","Edit":"Edytuj","Clone":"Klonuj","Delete":"Usuń","Remove":"Usuń","Cancel":"Anuluj","Save":"Zapisz","Save Settings":"Zapisz ustawienia","Editor Settings":"Ustawienia edytora","New Filament":"Nowy filament","Edit Filament":"Edytuj filament","Also remove from Spoolman":"Usuń również ze Spoolman","Ready":"Gotowy","Custom":"Własny","Stock":"Fabryczny","Active":"Aktywny"},
    cs: {"+ New Filament":"+ Nový filament","Add Selection to DB":"Přidat výběr","⚙ Settings":"⚙ Nastavení","All Brands":"Všechny značky","All Types":"Všechny typy","All Entries":"Všechny položky","Brand":"Značka","Nozzle":"Tryska","Bed":"Podložka","Edit":"Upravit","Clone":"Klonovat","Delete":"Smazat","Remove":"Odebrat","Cancel":"Zrušit","Save":"Uložit","Save Settings":"Uložit nastavení","Editor Settings":"Nastavení editoru","Also remove from Spoolman":"Odebrat také ze Spoolman","Ready":"Připraveno","Custom":"Vlastní","Stock":"Výchozí","Active":"Aktivní"},
    sk: {"+ New Filament":"+ Nový filament","Add Selection to DB":"Pridať výber","⚙ Settings":"⚙ Nastavenia","All Brands":"Všetky značky","All Types":"Všetky typy","All Entries":"Všetky položky","Brand":"Značka","Nozzle":"Tryska","Bed":"Podložka","Edit":"Upraviť","Clone":"Klonovať","Delete":"Zmazať","Remove":"Odstrániť","Cancel":"Zrušiť","Save":"Uložiť","Save Settings":"Uložiť nastavenia","Editor Settings":"Nastavenia editora","Also remove from Spoolman":"Odstrániť aj zo Spoolman","Ready":"Pripravené","Custom":"Vlastné","Stock":"Predvolené","Active":"Aktívne"},
    sl: {"+ New Filament":"+ Nov filament","Add Selection to DB":"Dodaj izbor","⚙ Settings":"⚙ Nastavitve","All Brands":"Vse znamke","All Types":"Vse vrste","All Entries":"Vsi vnosi","Brand":"Znamka","Nozzle":"Šoba","Bed":"Miza","Edit":"Uredi","Clone":"Kloniraj","Delete":"Izbriši","Remove":"Odstrani","Cancel":"Prekliči","Save":"Shrani","Save Settings":"Shrani nastavitve","Editor Settings":"Nastavitve urejevalnika","Also remove from Spoolman":"Odstrani tudi iz Spoolman","Ready":"Pripravljeno","Custom":"Po meri","Stock":"Tovarniško","Active":"Aktivno"},
    hu: {"+ New Filament":"+ Új filament","Add Selection to DB":"Kijelölés hozzáadása","⚙ Settings":"⚙ Beállítások","All Brands":"Összes márka","All Types":"Összes típus","All Entries":"Összes elem","Brand":"Márka","Nozzle":"Fúvóka","Bed":"Tárgyasztal","Edit":"Szerkesztés","Clone":"Klónozás","Delete":"Törlés","Remove":"Eltávolítás","Cancel":"Mégse","Save":"Mentés","Save Settings":"Beállítások mentése","Editor Settings":"Szerkesztő beállításai","Also remove from Spoolman":"Eltávolítás a Spoolmanból is","Ready":"Kész","Custom":"Egyéni","Stock":"Gyári","Active":"Aktív"}
  };
  window.__CFS_I18N_MAP = I18N;
})();
(function(){
  const M = window.__CFS_I18N_MAP || {};
  Object.assign(M, {
    pt: {"+ New Filament":"+ Novo filamento","Add Selection to DB":"Adicionar seleção","⚙ Settings":"⚙ Configurações","All Brands":"Todas as marcas","All Types":"Todos os tipos","All Entries":"Todas as entradas","Brand":"Marca","Nozzle":"Bico","Bed":"Mesa","Edit":"Editar","Clone":"Clonar","Delete":"Excluir","Remove":"Remover","Cancel":"Cancelar","Save":"Salvar","Save Settings":"Salvar configurações","Editor Settings":"Configurações do editor","Also remove from Spoolman":"Remover também do Spoolman","Ready":"Pronto","Custom":"Pers.","Stock":"Padrão","Active":"Ativo"},
    ca: {"+ New Filament":"+ Nou filament","Add Selection to DB":"Afegeix selecció","⚙ Settings":"⚙ Configuració","All Brands":"Totes les marques","All Types":"Tots els tipus","All Entries":"Totes les entrades","Brand":"Marca","Nozzle":"Broquet","Bed":"Llit","Edit":"Edita","Clone":"Clona","Delete":"Suprimeix","Remove":"Elimina","Cancel":"Cancel·la","Save":"Desa","Save Settings":"Desa la configuració","Editor Settings":"Configuració de l'editor","Also remove from Spoolman":"Elimina també de Spoolman","Ready":"Llest","Custom":"Pers.","Stock":"Fàbrica","Active":"Actiu"},
    da: {"+ New Filament":"+ Nyt filament","Add Selection to DB":"Tilføj valgte","⚙ Settings":"⚙ Indstillinger","All Brands":"Alle mærker","All Types":"Alle typer","All Entries":"Alle poster","Brand":"Mærke","Nozzle":"Dyse","Bed":"Byggeplade","Edit":"Rediger","Clone":"Klon","Delete":"Slet","Remove":"Fjern","Cancel":"Annuller","Save":"Gem","Save Settings":"Gem indstillinger","Editor Settings":"Editorindstillinger","Also remove from Spoolman":"Fjern også fra Spoolman","Ready":"Klar","Custom":"Brugerdef.","Stock":"Standard","Active":"Aktiv"},
    sv: {"+ New Filament":"+ Nytt filament","Add Selection to DB":"Lägg till valda","⚙ Settings":"⚙ Inställningar","All Brands":"Alla märken","All Types":"Alla typer","All Entries":"Alla poster","Brand":"Märke","Nozzle":"Munstycke","Bed":"Bädd","Edit":"Redigera","Clone":"Klona","Delete":"Ta bort","Remove":"Ta bort","Cancel":"Avbryt","Save":"Spara","Save Settings":"Spara inställningar","Editor Settings":"Redigerarinställningar","Also remove from Spoolman":"Ta även bort från Spoolman","Ready":"Redo","Custom":"Anpassad","Stock":"Standard","Active":"Aktiv"},
    tr: {"+ New Filament":"+ Yeni Filament","Add Selection to DB":"Seçilenleri Ekle","⚙ Settings":"⚙ Ayarlar","All Brands":"Tüm Markalar","All Types":"Tüm Türler","All Entries":"Tüm Kayıtlar","Brand":"Marka","Nozzle":"Nozül","Bed":"Tabla","Edit":"Düzenle","Clone":"Kopyala","Delete":"Sil","Remove":"Kaldır","Cancel":"İptal","Save":"Kaydet","Save Settings":"Ayarları Kaydet","Editor Settings":"Düzenleyici Ayarları","Also remove from Spoolman":"Spoolman'dan da kaldır","Ready":"Hazır","Custom":"Özel","Stock":"Fabrika","Active":"Aktif"},
    ru: {"+ New Filament":"+ Новый филамент","Add Selection to DB":"Добавить выбранное","⚙ Settings":"⚙ Настройки","All Brands":"Все бренды","All Types":"Все типы","All Entries":"Все записи","Brand":"Бренд","Nozzle":"Сопло","Bed":"Стол","Edit":"Изменить","Clone":"Клонировать","Delete":"Удалить","Remove":"Удалить","Cancel":"Отмена","Save":"Сохранить","Save Settings":"Сохранить настройки","Editor Settings":"Настройки редактора","Also remove from Spoolman":"Также удалить из Spoolman","Ready":"Готово","Custom":"Свой","Stock":"Завод.","Active":"Активен"},
    uk: {"+ New Filament":"+ Новий філамент","Add Selection to DB":"Додати вибране","⚙ Settings":"⚙ Налаштування","All Brands":"Усі бренди","All Types":"Усі типи","All Entries":"Усі записи","Brand":"Бренд","Nozzle":"Сопло","Bed":"Стіл","Edit":"Редагувати","Clone":"Клонувати","Delete":"Видалити","Remove":"Видалити","Cancel":"Скасувати","Save":"Зберегти","Save Settings":"Зберегти налаштування","Editor Settings":"Налаштування редактора","Also remove from Spoolman":"Також видалити зі Spoolman","Ready":"Готово","Custom":"Власний","Stock":"Завод.","Active":"Активний"},
    zh: {"+ New Filament":"+ 新建耗材","Add Selection to DB":"添加所选预设","⚙ Settings":"⚙ 设置","Spoolman: Select & Push":"Spoolman: 选择并推送","All Brands":"所有品牌","All Types":"所有类型","All Entries":"所有条目","Custom Only (90001+)":"仅自定义 (90001+)","Stock Only":"仅出厂预设","Brand":"品牌","Nozzle":"喷嘴","Bed":"热床","Edit":"编辑","Clone":"克隆","Delete":"删除","Remove":"移除","Cancel":"取消","Save":"保存","Save Settings":"保存设置","Editor Settings":"编辑器设置","Also remove from Spoolman":"同时从 Spoolman 移除","Ready":"就绪","Custom":"自定义","Stock":"出厂","Active":"已激活"},
    ja: {"+ New Filament":"+ 新規フィラメント","Add Selection to DB":"選択項目を追加","⚙ Settings":"⚙ 設定","All Brands":"すべてのブランド","All Types":"すべてのタイプ","All Entries":"すべての項目","Brand":"ブランド","Nozzle":"ノズル","Bed":"ベッド","Edit":"編集","Clone":"複製","Delete":"削除","Remove":"削除","Cancel":"キャンセル","Save":"保存","Save Settings":"設定を保存","Editor Settings":"エディター設定","Also remove from Spoolman":"Spoolmanからも削除","Ready":"準備完了","Custom":"カスタム","Stock":"標準","Active":"有効"},
    ko: {"+ New Filament":"+ 새 필라멘트","Add Selection to DB":"선택 항목 추가","⚙ Settings":"⚙ 설정","All Brands":"모든 브랜드","All Types":"모든 유형","All Entries":"모든 항목","Brand":"브랜드","Nozzle":"노즐","Bed":"베드","Edit":"편집","Clone":"복제","Delete":"삭제","Remove":"제거","Cancel":"취소","Save":"저장","Save Settings":"설정 저장","Editor Settings":"편집기 설정","Also remove from Spoolman":"Spoolman에서도 제거","Ready":"준비됨","Custom":"사용자","Stock":"기본","Active":"활성"}
  });
  M.cz = M.cs; M.se = M.sv; M.cn = M.zh;
  let activeLang = "en";
  const norm = v => { const b = String(v || "").trim().toLowerCase().split(/[-_]/)[0]; return M[b] ? b : (b === "en" ? "en" : ""); };

  async function detectLang() {
    const pref = localStorage.getItem("cfs_editor_lang") || "auto";
    const sel = document.getElementById("s_lang");
    if (sel) sel.value = pref;
    if (pref !== "auto") {
      const target = norm(pref) || "en";
      if (activeLang !== target) { activeLang = target; apply(); }
      return;
    }

    try {
      const r = await fetch("api/ui_lang", { cache: "no-store" });
      if (r.ok) {
        const d = await r.json();
        const isFluiddRef = /4408/.test(document.referrer || "");
        const picked = isFluiddRef ? (d.fluidd || d.mainsail) : (d.mainsail || d.fluidd);
        const n = norm(picked);
        if (n) {
          if (activeLang !== n) { activeLang = n; apply(); }
          return;
        }
      }
    } catch (_) {}

    const fallback = norm(navigator.language) || "en";
    if (activeLang !== fallback) { activeLang = fallback; apply(); }
  }

  function apply() {
    const dict = M[activeLang] || {};
    document.querySelectorAll("input[placeholder]").forEach(el => {
      if (!el.dataset.origPh) el.dataset.origPh = el.placeholder;
      el.placeholder = dict[el.dataset.origPh] || el.dataset.origPh;
    });
    const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null);
    let n;
    while ((n = w.nextNode())) {
      const p = n.parentElement;
      if (!p || p.tagName === "SCRIPT" || p.tagName === "STYLE" || p.tagName === "CODE") continue;
      const raw = n.nodeValue, tr = raw.trim();
      if (!tr || /^[0-9.,:%°/\s+-]+$/.test(tr)) continue;
      if (!n.__origText) n.__origText = tr;
      const target = dict[n.__origText] || n.__origText;
      if (tr !== target) n.nodeValue = raw.replace(tr, target);
    }
  }

  window.setEditorLang = function(val) {
    localStorage.setItem("cfs_editor_lang", val || "auto");
    detectLang();
  };

  new MutationObserver(() => apply()).observe(document.body, { childList: true, subtree: true });
  detectLang();
  setInterval(detectLang, 2500);
})();
