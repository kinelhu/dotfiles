// Zotero user preferences
// Zotero reads this file at every startup and applies these prefs on top of prefs.js.
// Edit here — do NOT edit prefs.js directly (it gets overwritten by Zotero).
//
// Machine-specific paths are marked // [UPDATE ON NEW MACHINE]

// ---------------------------------------------------------------------------
// Data & attachments
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.useDataDir", true);
user_pref("extensions.zotero.dataDir", "/Users/kinelhu/Zotero"); // [UPDATE ON NEW MACHINE]
user_pref("extensions.zotero.baseAttachmentPath", "/Users/kinelhu/Library/CloudStorage/OneDrive-Personnel/Documents/Zotero PDF"); // [UPDATE ON NEW MACHINE]
user_pref("extensions.zotero.saveRelativeAttachmentPath", true);

// ---------------------------------------------------------------------------
// Sync account
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.sync.server.username", "kinelhu@hotmail.com");

// ---------------------------------------------------------------------------
// General behaviour
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.automaticTags", false);
user_pref("extensions.zotero.recursiveCollections", true);
user_pref("extensions.zotero.httpServer.localAPI.enabled", true);
user_pref("extensions.zotero.search.quicksearch-mode", "titleCreatorYear");
user_pref("extensions.zotero.firstRun2", false);
user_pref("extensions.zotero.firstRun.skipFirefoxProfileAccessCheck", true);

// ---------------------------------------------------------------------------
// Citation / export
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.cite.automaticJournalAbbreviations", false);
user_pref("extensions.zotero.export.lastLocale", "fr-FR");
user_pref("extensions.zotero.export.lastStyle", "http://www.zotero.org/styles/nature");

// ---------------------------------------------------------------------------
// Better BibTeX
// Note: auto-export paths are machine-specific and managed by BBT directly.
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.translators.better-bibtex.citekeyFormat", "auth.lower + year + title.select(n = 1).lower.skipwords");
user_pref("extensions.zotero.translators.better-bibtex.autoPinDelay", 1);
user_pref("extensions.zotero.translators.better-bibtex.baseAttachmentPath", "/Users/kinelhu/Library/CloudStorage/OneDrive-Personnel/Documents/Zotero PDF"); // [UPDATE ON NEW MACHINE]
user_pref("extensions.zotero.translators.better-bibtex.path.git", "/usr/bin/git");

// ---------------------------------------------------------------------------
// ZoteroAttanger
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.zoteroattanger.subfolderFormat", "{{year}}");

// ---------------------------------------------------------------------------
// ZoteroReference
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.zoteroreference.API.source", "SemanticsScholar");

// ---------------------------------------------------------------------------
// PMCID Fetcher
// ---------------------------------------------------------------------------
user_pref("extensions.zotero.pmcid.tags", true);

// ---------------------------------------------------------------------------
// Language / spellcheck
// ---------------------------------------------------------------------------
user_pref("intl.accept_languages", "fr, fr-fr, en-us, en");
user_pref("spellchecker.dictionary", "en-US,fr,");
