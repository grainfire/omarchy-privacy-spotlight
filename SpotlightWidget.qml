import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
    id: root
    readonly property string pluginId: "grainfire.privacy-spotlight"
    readonly property bool lit: bar?.shell?.isPluginOpen(pluginId) ?? false
    property bool editing: false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    function close() { editing = false }
    function save(key, value) {
        // Host performs the merge and persists only the requested field.
        Quickshell.execDetached(["omarchy", "bar", "set", pluginId, key, JSON.stringify(value), "--json"])
    }

    Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
    SettingsFile { id: config; injected: root.settings }
    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰓈"
        dimmed: !root.lit
        tooltipText: strings.t(root.lit ? "on" : "off")
        onPressed: mouseButton => {
            if (mouseButton === Qt.RightButton) root.editing = !root.editing
            if (mouseButton === Qt.LeftButton) {
                root.close()
                root.bar?.shell?.toggle(root.pluginId, "{}")
            }
        }
    }
    PopupCard {
        id: card
        anchorItem: root
        bar: root.bar
        owner: root
        open: root.editing
        contentWidth: fittedContentWidth(Style.space(264))
        contentHeight: fittedContentHeight(column.implicitHeight)
        Column {
            id: column
            width: parent.width
            spacing: Style.space(6)
            ButtonGroup {
                options: [{value:"circle", label:strings.t("circle")}, {value:"band", label:strings.t("band")}]
                value: config.shape
                onChanged: value => root.save("shape", value)
            }
            component Caption: Text {
                textFormat: Text.PlainText
                color: Commons.Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body
            }
            Caption { text: strings.t(config.shape === "band" ? "height" : "radius").arg(Commons.I18n.formatNumber(radiusSlider.liveValue)) }
            PanelSlider {
                id: radiusSlider
                width: parent.width
                bar: root.bar
                minimum: 4; maximum: Math.max(512, config.radius); integer: true; step: 8
                value: config.radius
                onReleased: value => root.save("radius", value)
            }
            Caption { text: strings.t("feather").arg(Commons.I18n.formatNumber(featherSlider.liveValue)) }
            PanelSlider {
                id: featherSlider
                width: parent.width
                bar: root.bar
                minimum: 0; maximum: Math.max(128, config.feather); integer: true; step: 4
                value: config.feather
                onReleased: value => root.save("feather", value)
            }
        }
    }
}
