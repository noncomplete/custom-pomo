import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

import "components" as Components

PanelWindow {
  id: root

  property ShellScreen screen: null
  property var pluginApi: null
  property string noteId: ""
  property string content: ""
  property string noteColor: "#FFF9C4"
  property string modifiedStr: ""
  property double modified: 0

  signal saveRequested(string noteId, string content, string noteColor)
  signal closed()

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true
  visible: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "noctalia-sticky-notes-expanded-" + (screen?.name || "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  function openFor(targetScreen, targetNoteId, targetContent, targetColor, targetModifiedStr, targetModified) {
    screen = targetScreen;
    noteId = targetNoteId;
    content = targetContent;
    noteColor = targetColor || "#FFF9C4";
    modifiedStr = targetModifiedStr || "";
    modified = targetModified || 0;
    visible = true;
  }

  function closeWindow() {
    contentItem.editing = false;
    visible = false;
    closed();
  }

  Components.ExpandedNoteWindow {
    id: contentItem
    anchors.fill: parent
    visible: root.visible
    noteId: root.noteId
    content: root.content
    noteColor: root.noteColor
    modifiedStr: root.modifiedStr
    absoluteModifiedStr: root.pluginApi?.mainInstance?.formatAbsoluteDate(root.modified) || ""
    pluginApi: root.pluginApi

    onSaveRequested: function(noteId, content, noteColor) {
      root.content = content;
      root.noteColor = noteColor || root.noteColor;
      root.saveRequested(noteId, content, noteColor);
      root.modifiedStr = pluginApi?.mainInstance?.expandedModifiedStr || root.modifiedStr;
      root.modified = pluginApi?.mainInstance?.expandedModified || root.modified;
    }

    onClosed: root.closeWindow()
  }
}
