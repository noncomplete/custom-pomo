import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

import "utils/gistSync.js" as GistSync
import "utils/storage.js" as Storage

Item {
  id: root

  property var pluginApi: null
  property bool syncInProgress: false
  property bool lastSyncOk: false
  property string lastSyncMessage: ""
  property double lastSyncAt: 0
  property var expandedScreen: null
  property string expandedNoteId: ""
  property string expandedContent: ""
  property string expandedColor: ""
  property string expandedModifiedStr: ""
  property double expandedModified: 0
  signal notesChanged()

  function formatAbsoluteDate(timestamp) {
    if (!timestamp) {
      return "";
    }

    var d = new Date(timestamp);
    var pad = function(value) { return value < 10 ? "0" + value : "" + value; };
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
      + " " + pad(d.getHours()) + ":" + pad(d.getMinutes());
  }

  function withCurrentScreen(callback) {
    if (!pluginApi) {
      Logger.w("StickyNotes", "Plugin API not available for IPC request");
      return;
    }

    pluginApi.withCurrentScreen(function(screen) {
      if (!screen) {
        Logger.w("StickyNotes", "No active screen available for IPC request");
        return;
      }

      callback(screen);
    });
  }

  function loadStoredNotes() {
    if (!pluginApi)
      return [];

    var stored = pluginApi.pluginSettings.notes;
    if (!stored || stored.length === 0)
      return [];

    try {
      var parsed = JSON.parse(stored);
      return Array.isArray(parsed) ? parsed : [];
    } catch (e) {
      Logger.e("StickyNotes", "Failed to parse notes for sync: " + e);
      return [];
    }
  }

  function getDisplayNotes() {
    var notes = loadStoredNotes();
    for (var i = 0; i < notes.length; i++) {
      var note = notes[i];
      if (!note.color || note.color === "") {
        note.color = Storage.pickRandomColor();
      }
      note.noteColor = note.color;
      note.modifiedStr = Storage.formatDate(new Date(note.modified), root.pluginApi);
    }
    return notes;
  }

  function persistNotes(notes) {
    if (!pluginApi) {
      return;
    }

    pluginApi.pluginSettings.notes = JSON.stringify(notes);
    pluginApi.saveSettings();

    notesChanged();
    syncNotesToGist(notes, true);
  }

  function saveNote(noteId, content, saveColor) {
    var notes = loadStoredNotes();
    var now = Date.now();
    var isNew = (!noteId || noteId.length === 0);

    if (isNew) {
      noteId = Storage.generateNoteId();
    }

    var finalColor = saveColor;
    var foundIndex = -1;
    for (var i = 0; i < notes.length; i++) {
      if (notes[i].noteId === noteId) {
        finalColor = notes[i].color || finalColor;
        foundIndex = i;
        break;
      }
    }

    var note = {
      noteId: noteId,
      content: content,
      modified: now,
      color: finalColor || Storage.pickRandomColor()
    };

    if (foundIndex >= 0) {
      notes.splice(foundIndex, 1);
    }
    notes.unshift(note);

    persistNotes(notes);

    if (expandedNoteId === noteId) {
      expandedContent = content;
      expandedColor = note.color;
      expandedModifiedStr = Storage.formatDate(new Date(now), root.pluginApi);
      expandedModified = now;
    }

    Logger.i("StickyNotes", "Note saved: " + noteId);
    return note;
  }

  function deleteNote(noteId) {
    var notes = loadStoredNotes();
    for (var i = 0; i < notes.length; i++) {
      if (notes[i].noteId === noteId) {
        notes.splice(i, 1);
        break;
      }
    }

    persistNotes(notes);

    if (expandedNoteId === noteId) {
      closeExpandedNote();
    }

    Logger.i("StickyNotes", "Note deleted: " + noteId);
  }

  function openExpandedNote(screen, noteId, content, noteColor, modifiedStr, modified) {
    expandedScreen = screen;
    expandedNoteId = noteId;
    expandedContent = content;
    expandedColor = noteColor || "#FFF9C4";
    expandedModifiedStr = modifiedStr || "";
    expandedModified = modified || 0;
    expandedWindow.openFor(screen, noteId, content, noteColor || "#FFF9C4", modifiedStr || "", modified || 0);
  }

  function closeExpandedNote() {
    expandedWindow.closeWindow();
    expandedScreen = null;
    expandedNoteId = "";
    expandedContent = "";
    expandedColor = "";
    expandedModifiedStr = "";
    expandedModified = 0;
  }

  function hasSyncToken() {
    if (!pluginApi || !pluginApi.pluginSettings) {
      return false;
    }

    return ((pluginApi.pluginSettings.githubToken || "").trim().length > 0);
  }

  function syncNotesToGist(notes, silent) {
    if (!pluginApi) {
      return;
    }

    if (syncInProgress) {
      Logger.w("StickyNotes", "Sync skipped because another sync is already running");
      return;
    }

    var syncEnabled = pluginApi.pluginSettings.syncEnabled === true;
    if (!syncEnabled && silent !== false) {
      return;
    }

    if (!hasSyncToken()) {
      lastSyncOk = false;
      lastSyncMessage = pluginApi.tr("sync.errors.missing-token") || "GitHub token is required before syncing.";
      lastSyncAt = Date.now();

      if (silent === true) {
        Logger.w("StickyNotes", "Auto sync skipped because GitHub token is empty");
        return;
      }
    }

    var syncNotes = notes;
    if (!Array.isArray(syncNotes)) {
      syncNotes = loadStoredNotes();
    }

    syncInProgress = true;
    lastSyncMessage = pluginApi.tr("sync.syncing") || "Syncing notes to GitHub Gist...";

    GistSync.syncNotes(pluginApi, syncNotes, function(success, message) {
      syncInProgress = false;
      lastSyncOk = success;
      lastSyncMessage = message || (success ? "Sync completed" : "Sync failed");
      lastSyncAt = Date.now();

      if (success) {
        Logger.i("StickyNotes", lastSyncMessage);
        if (silent !== true) {
          ToastService.showNotice(lastSyncMessage);
        }
      } else {
        Logger.e("StickyNotes", lastSyncMessage);
        ToastService.showError(lastSyncMessage);
      }
    });
  }

  function manualSync() {
    syncNotesToGist(loadStoredNotes(), false);
  }

  IpcHandler {
    target: "plugin:sticky-notes"

    function toggle() {
      root.withCurrentScreen(function(screen) {
        root.pluginApi.togglePanel(screen);
      });
    }
  }

  ExpandedPanelWindow {
    id: expandedWindow
    pluginApi: root.pluginApi

    onSaveRequested: function(noteId, content, noteColor) {
      root.saveNote(noteId, content, noteColor);
    }

    onClosed: {
      root.expandedScreen = null;
      root.expandedNoteId = "";
      root.expandedContent = "";
      root.expandedColor = "";
      root.expandedModifiedStr = "";
      root.expandedModified = 0;
    }
  }
}
