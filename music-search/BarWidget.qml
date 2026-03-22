import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool pillDirection: BarService.getPillDirection(root)
  readonly property string barPosition: Settings.data.bar.position || "top"
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"
  readonly property bool activePlayback: mainInstance?.isPlaying === true || mainInstance?.playbackStarting === true
  readonly property string trackTitle: (mainInstance?.currentTitle || "").trim()
  readonly property string pillText: activePlayback && trackTitle.length > 0 ? trackTitle : ""
  readonly property bool showHoverTrackTitle: pluginApi?.pluginSettings?.showBarHoverTrackTitle
      ?? pluginApi?.manifest?.metadata?.defaultSettings?.showBarHoverTrackTitle
      ?? true
  readonly property string tooltipText: activePlayback
      ? pluginApi?.tr("bar_widget.tooltipPlaying", {"title": trackTitle})
      : pluginApi?.tr("bar_widget.tooltipIdle")
  readonly property real maxHoverTextWidth: Math.round(240 * Style.uiScaleRatio)

  implicitWidth: isVerticalBar ? verticalPill.width : horizontalPill.width
  implicitHeight: isVerticalBar ? verticalPill.height : horizontalPill.height

  Item {
    id: verticalPill
    visible: root.isVerticalBar
    width: capsuleSize
    height: root.showHoverTrackTitle && root.pillText.length > 0 && verticalHoverArea.containsMouse ? expandedHeight : capsuleSize

    readonly property real capsuleSize: Style.capsuleHeight
    readonly property real pillOverlap: Math.round(capsuleSize * 0.5)
    readonly property bool openDownward: root.pillDirection
    readonly property bool openUpward: !openDownward
    readonly property real textBaseOffset: openDownward ? Style.marginXXS : -Style.marginXXS
    readonly property real titleHeightLimit: Math.max(0, Math.min(root.maxHoverTextWidth, verticalTitleText.implicitWidth + (Style.marginL * 2)))
    readonly property real expandedHeight: capsuleSize + Math.max(0, titleHeightLimit - pillOverlap)
    readonly property real availableTitleHeight: Math.max(0, verticalTitleClip.height - (Style.marginL * 2))
    readonly property real textOverflow: Math.max(0, verticalTitleText.implicitWidth - availableTitleHeight)
    readonly property bool needsScroll: root.showHoverTrackTitle && verticalHoverArea.containsMouse && root.pillText.length > 0 && textOverflow > 0 && availableTitleHeight > 0
    readonly property color backgroundColor: verticalHoverArea.containsMouse ? Color.mHover : Style.capsuleColor
    readonly property color foregroundColor: verticalHoverArea.containsMouse ? Color.mOnHover : Color.mOnSurface
    property real titleOffset: textBaseOffset

    function restartTitleScroll() {
      verticalTitleScroll.stop();
      titleOffset = textBaseOffset;

      if (needsScroll) {
        titleOffset = textBaseOffset + (textOverflow / 2);
        verticalTitleScroll.restart();
      }
    }

    onNeedsScrollChanged: restartTitleScroll()

    Connections {
      target: root

      function onPillTextChanged() {
        verticalPill.restartTitleScroll();
      }

      function onTooltipTextChanged() {
        if (verticalHoverArea.containsMouse) {
          TooltipService.updateText(root.tooltipText);
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: Style.radiusM
      color: verticalPill.backgroundColor
      border.color: Style.capsuleBorderColor
      border.width: Style.capsuleBorderWidth

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.InOutQuad
        }
      }
    }

    Item {
      id: verticalTitleClip
      width: verticalPill.capsuleSize
      height: root.showHoverTrackTitle && root.pillText.length > 0 && verticalHoverArea.containsMouse ? verticalPill.titleHeightLimit : 0
      x: 0
      y: verticalPill.openUpward ? 0 : Math.round(verticalPill.capsuleSize * 0.5)
      clip: true
      visible: height > 0

      NText {
        id: verticalTitleText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: verticalPill.titleOffset
        rotation: -90
        text: root.pillText
        family: Settings.data.ui.fontDefault
        pointSize: Style.barFontSize
        applyUiScale: false
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: verticalPill.foregroundColor
      }

      SequentialAnimation {
        id: verticalTitleScroll
        loops: Animation.Infinite
        running: false

        PauseAnimation {
          duration: 700
        }

        NumberAnimation {
          target: verticalPill
          property: "titleOffset"
          from: verticalPill.textBaseOffset + (verticalPill.textOverflow / 2)
          to: verticalPill.textBaseOffset - (verticalPill.textOverflow / 2)
          duration: Math.max(2200, Math.round(verticalPill.textOverflow * 18))
          easing.type: Easing.Linear
        }

        PauseAnimation {
          duration: 900
        }

        NumberAnimation {
          target: verticalPill
          property: "titleOffset"
          to: verticalPill.textBaseOffset
          duration: 280
          easing.type: Easing.OutQuad
        }
      }
    }

    Item {
      width: verticalPill.capsuleSize
      height: verticalPill.capsuleSize
      x: 0
      y: verticalPill.openUpward ? (verticalPill.height - height) : 0

      NIcon {
        anchors.centerIn: parent
        icon: activePlayback ? (mainInstance?.isPaused === true ? "player-pause-filled" : "disc") : "music"
        pointSize: Style.toOdd(verticalPill.capsuleSize * 0.48)
        applyUiScale: false
        color: verticalPill.foregroundColor
      }
    }

    MouseArea {
      id: verticalHoverArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor

      onEntered: {
        TooltipService.show(verticalPill, root.tooltipText, BarService.getTooltipDirection());
        verticalPill.restartTitleScroll();
      }

      onExited: {
        TooltipService.hide();
        verticalPill.restartTitleScroll();
      }

      onClicked: function (mouse) {
        if (mouse.button === Qt.LeftButton) {
          pluginApi?.togglePanel(root.screen, verticalPill);
          return;
        }

        if (mouse.button === Qt.RightButton) {
          PanelService.showContextMenu(contextMenu, verticalPill, root.screen);
        }
      }
    }
  }

  Item {
    id: horizontalPill
    visible: !root.isVerticalBar
    width: revealed ? expandedWidth : capsuleSize
    height: capsuleSize
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)

    readonly property real capsuleSize: Style.capsuleHeight
    readonly property bool revealed: root.showHoverTrackTitle && hoverArea.containsMouse && root.pillText.length > 0
    readonly property real textBaseX: Style.marginM
    readonly property real titleWidthLimit: Math.max(0, Math.min(root.maxHoverTextWidth, titleText.implicitWidth + (Style.marginL * 2)))
    readonly property real expandedWidth: capsuleSize + titleWidthLimit
    readonly property real availableTitleWidth: Math.max(0, titleClip.width - (Style.marginL * 2))
    readonly property bool needsScroll: revealed && titleText.implicitWidth > availableTitleWidth && availableTitleWidth > 0
    readonly property color backgroundColor: hoverArea.containsMouse ? Color.mHover : Style.capsuleColor
    readonly property color foregroundColor: hoverArea.containsMouse ? Color.mOnHover : Color.mOnSurface

    Behavior on width {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    onNeedsScrollChanged: restartTitleScroll()
    onRevealedChanged: restartTitleScroll()

    function restartTitleScroll() {
      titleScroll.stop();
      titleText.x = textBaseX;

      if (needsScroll && hoverArea.containsMouse) {
        titleScroll.restart();
      }
    }

    Connections {
      target: root

      function onPillTextChanged() {
        horizontalPill.restartTitleScroll();
      }

      function onTooltipTextChanged() {
        if (hoverArea.containsMouse) {
          TooltipService.updateText(root.tooltipText);
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: Style.radiusM
      color: horizontalPill.backgroundColor
      border.color: Style.capsuleBorderColor
      border.width: Style.capsuleBorderWidth

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.InOutQuad
        }
      }
    }

    Row {
      anchors.fill: parent
      layoutDirection: root.pillDirection ? Qt.LeftToRight : Qt.RightToLeft
      spacing: 0

      Item {
        width: horizontalPill.capsuleSize
        height: horizontalPill.capsuleSize

        NIcon {
          anchors.centerIn: parent
          icon: activePlayback ? (mainInstance?.isPaused === true ? "player-pause-filled" : "disc") : "music"
          pointSize: Style.toOdd(horizontalPill.capsuleSize * 0.48)
          applyUiScale: false
          color: horizontalPill.foregroundColor
        }
      }

      Item {
        id: titleClip
        width: horizontalPill.revealed ? horizontalPill.titleWidthLimit : 0
        height: horizontalPill.capsuleSize
        clip: true
        visible: width > 0

        NText {
          id: titleText
          anchors.verticalCenter: parent.verticalCenter
          x: horizontalPill.textBaseX
          text: root.pillText
          pointSize: Style.barFontSize
          applyUiScale: false
          color: horizontalPill.foregroundColor
        }

        SequentialAnimation {
          id: titleScroll
          loops: Animation.Infinite
          running: false

          PauseAnimation {
            duration: 700
          }

          NumberAnimation {
            target: titleText
            property: "x"
            from: horizontalPill.textBaseX
            to: horizontalPill.textBaseX - Math.max(0, titleText.implicitWidth - horizontalPill.availableTitleWidth)
            duration: Math.max(2200, Math.round((titleText.implicitWidth - horizontalPill.availableTitleWidth) * 18))
            easing.type: Easing.Linear
          }

          PauseAnimation {
            duration: 900
          }

          NumberAnimation {
            target: titleText
            property: "x"
            to: horizontalPill.textBaseX
            duration: 280
            easing.type: Easing.OutQuad
          }
        }
      }
    }

    MouseArea {
      id: hoverArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor

      onEntered: {
        TooltipService.show(horizontalPill, root.tooltipText, BarService.getTooltipDirection());
        horizontalPill.restartTitleScroll();
      }

      onExited: {
        TooltipService.hide();
        horizontalPill.restartTitleScroll();
      }

      onClicked: function (mouse) {
        if (mouse.button === Qt.LeftButton) {
          pluginApi?.togglePanel(root.screen, horizontalPill);
          return;
        }

        if (mouse.button === Qt.RightButton) {
          PanelService.showContextMenu(contextMenu, horizontalPill, root.screen);
        }
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("bar_widget.settings"),
        "action": "widget-settings",
        "icon": "settings",
        "enabled": true
      }
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(root.screen);

      if (action === "widget-settings") {
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
      }
    }
  }
}
