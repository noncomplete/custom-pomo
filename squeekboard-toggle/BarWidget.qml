import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var mainInstance: pluginApi?.mainInstance
    property bool keyboardActive: mainInstance?.keyboardActive ?? false

    icon: keyboardActive ? "keyboard" : "keyboard-off"
    tooltipText: keyboardActive ? pluginApi?.tr("tooltip.active") : pluginApi?.tr("tooltip.hidden")
    tooltipDirection: BarService.getTooltipDirection(screen?.name)
    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    applyUiScale: false
    customRadius: Style.radiusL
    colorBg: Style.capsuleColor
    colorFg: keyboardActive ? Color.mPrimary : Color.mOnSurfaceVariant
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    onClicked: mainInstance?.toggleKeyboard()

    onRightClicked: {
        PanelService.showContextMenu(contextMenu, root, screen);
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi?.tr("menu.settings"),
                "action": "widget-settings",
                "icon": "settings"
            },
        ]

        onTriggered: function(action) {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "widget-settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            }
        }
    }
}
