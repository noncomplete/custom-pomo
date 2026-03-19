import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets
import "../lib/Ui.js" as Ui

NIconButtonHot {
  id: root

  property ShellScreen screen
  property var pluginApi

  readonly property var service: root.pluginApi?.mainInstance
  readonly property bool actionBusy: root.service?.actionBusy ?? false
  readonly property bool obsRunning: root.service?.obsRunning ?? false
  readonly property bool websocket: root.service?.websocket ?? false
  readonly property bool recording: root.service?.recording ?? false
  readonly property bool replayBuffer: root.service?.replayBuffer ?? false
  readonly property bool streaming: root.service?.streaming ?? false
  readonly property bool connected: root.obsRunning && root.websocket
  readonly property string primaryActionText: root.service?.primaryActionText ?? root.pluginApi?.tr("actions.primary.open_controls") ?? ""
  readonly property string obsLogoSource: root.pluginApi ? `file://${root.pluginApi.pluginDir}/assets/obs-logo.svg` : ""
  readonly property var outputState: ({
    recording: root.recording,
    replayBuffer: root.replayBuffer,
    streaming: root.streaming,
    recordDurationMs: 0,
    streamDurationMs: 0,
  })

  readonly property var activeOutputs: Ui.activeOutputs(root.pluginApi, root.outputState)
  readonly property bool hasActiveOutput: Ui.hasActiveOutputs(root.outputState)
  readonly property string currentIconName: Ui.primaryIcon(root.outputState)

  icon: ""
  hot: root.hasActiveOutput
  colorBgHot: Ui.accentBackgroundColor(root.outputState, Color, Color.mSecondary)
  colorFgHot: Ui.accentForegroundColor(root.outputState, Color, Color.mOnSecondary)
  tooltipText: Ui.controlCenterTooltip(root.pluginApi, root.outputState, root.connected, root.obsRunning, root.primaryActionText)

  NIcon {
    anchors.centerIn: parent
    visible: root.currentIconName !== ""
    icon: root.currentIconName
    pointSize: Math.max(1, Math.round(root.width * 0.48))
    color: {
      if ((root.enabled && root.hovering) || root.pressed) {
        return Color.mOnHover
      }

      return Ui.accentForegroundColor(root.outputState, Color, Color.mOnSecondary)
    }
  }

  Image {
    anchors.centerIn: parent
    visible: root.currentIconName === ""
    source: root.obsLogoSource
    sourceSize.width: Math.round(root.width * 0.56)
    sourceSize.height: Math.round(root.height * 0.56)
    width: Math.round(root.width * 0.56)
    height: Math.round(root.height * 0.56)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: true
    opacity: ((root.enabled && root.hovering) || root.pressed) ? 0.96 : 0.9
  }

  onClicked: {
    if (!root.service || !root.screen || root.actionBusy) {
      return
    }

    root.service.runPrimaryAction(root.screen, root)
  }

  onRightClicked: {
    if (!root.service || root.actionBusy) {
      return
    }

    root.service.runSecondaryAction()
  }

  onMiddleClicked: {
    if (!root.service || root.actionBusy) {
      return
    }

    root.service.runMiddleAction()
  }

  Rectangle {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.marginXS
    visible: root.activeOutputs.length > 1
    width: Math.max(14, Math.round(root.width * 0.3))
    height: width
    radius: width / 2
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

    NText {
      anchors.centerIn: parent
      text: String(root.activeOutputs.length)
      pointSize: Math.max(1, Math.round(Style.fontSizeXS))
      font.weight: Style.fontWeightBold
      color: Color.mOnSurface
    }
  }
}
