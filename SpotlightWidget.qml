import QtQuick
import QtQuick.Controls as Controls
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "grainfire.privacy-spotlight"
    readonly property string pluginId: "grainfire.privacy-spotlight"
    readonly property bool lit: bar?.shell?.isPluginOpen(pluginId) ?? false
    readonly property string shape: setting("shape", "circle") === "band" ? "band" : "circle"
    readonly property real radius: Number.isFinite(setting("radius", 120)) ? setting("radius", 120) : 120
    readonly property var steps: shape === "band" ? [60, 100, 150, 200] : [120, 180, 240, 320]
    readonly property int nearest: {
        let index = 0
        for (let i = 1; i < steps.length; i++)
            if (Math.abs(steps[i] - radius) < Math.abs(steps[index] - radius)) index = i
        return index
    }
    property bool editing: false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    function close() { editing = false }
    function save(key, value) {
        const entry = Object.assign({}, settings)
        entry[key] = value
        bar?.shell?.updateEntryInline(pluginId, entry)
    }
    SpotlightLabels { id: labels }
    function t(key) {
        const locale = Commons.I18n.language
        return labels.catalogs[locale]?.[key] ?? labels.catalogs[locale.split("-")[0]]?.[key] ?? labels.catalogs.en[key]
    }
    Item {
        anchors.fill: parent
        opacity: root.lit ? 1 : 0.45
        WidgetButton {
            id: button
            anchors.fill: parent
            bar: root.bar
            // Keep the host's click target and tooltip; paint the glyph
            // directly so a theme change cannot start a color animation.
            text: "󰓈"
            foreground: "transparent"
            labelVisible: false
            fixedWidth: Style.bar.iconSlot
            OpticalGlyph {
                anchors.centerIn: parent
                width: Style.bar.iconCanvas
                height: width
                text: button.text
                fontFamily: button.fontFamily
                fontSize: button.fontSize
                paintedSize: Style.bar.iconSize
                color: root.bar ? root.bar.barForeground : Commons.Color.foreground
            }
            pressFeedbackButtons: Qt.NoButton
            tooltipText: root.t(root.lit ? "on" : "off")
            onPressed: mouseButton => {
                if (mouseButton === Qt.RightButton) root.editing = !root.editing
                if (mouseButton === Qt.LeftButton) {
                    root.close()
                    root.bar?.shell?.toggle(root.pluginId, "{}")
                }
            }
            onWheelMoved: delta => {
                if (!delta) return
                const index = Math.max(0, Math.min(3, root.nearest + Math.sign(delta)))
                if (index !== root.nearest) root.save("radius", root.steps[index])
            }
        }
    }
    Loader {
        active: root.editing
        sourceComponent: PopupCard {
            id: card
            anchorItem: root
            bar: root.bar
            owner: root
            open: true
            Component.onDestruction: if (root.bar?.activePopout === root) root.bar.releasePopout(root)
            contentWidth: fittedContentWidth(Math.max(Style.space(220), choices.implicitWidth, sizes.implicitWidth, caption.implicitWidth) + 2 * padding + Style.space(6))
            contentHeight: fittedContentHeight(column.implicitHeight)
            // The shell's ButtonGroup animates chip presses and selection.
            // These ordinary keyboard-accessible buttons switch immediately.
            component Choices: Row {
                id: group
                required property var options
                required property string value
                signal changed(string value)
                spacing: Style.spacing.md
                Repeater {
                    model: group.options
                    Controls.AbstractButton {
                        id: choice
                        required property var modelData
                        readonly property bool selected: modelData.value === group.value
                        text: modelData.label
                        Accessible.role: Accessible.RadioButton
                        Accessible.checked: selected
                        implicitWidth: Math.max(Style.space(34), contentItem.implicitWidth + 2 * Style.spacing.md)
                        implicitHeight: Style.spacing.controlHeight
                        hoverEnabled: true
                        onClicked: group.changed(modelData.value)
                        background: Rectangle {
                            color: choice.selected ? Commons.Color.popups.text : Commons.Color.popups.background
                            border.color: Commons.Color.popups.border
                            border.width: choice.visualFocus || choice.hovered ? 2 : 1
                        }
                        contentItem: Text {
                            text: choice.text
                            textFormat: Text.PlainText
                            font.family: Style.font.family
                            font.pixelSize: Style.font.body
                            color: choice.selected ? Commons.Color.popups.background : Commons.Color.popups.text
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
            Column {
                id: column
                spacing: Style.space(6)
                Choices {
                    id: choices
                    options: [{value: "circle", label: root.t("circle")}, {value: "band", label: root.t("band")}]
                    value: root.shape
                    onChanged: value => root.save("shape", value)
                }
                Text {
                    id: caption
                    textFormat: Text.PlainText
                    color: Commons.Color.popups.text
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                    text: root.t(root.shape === "band" ? "height" : "radius").arg(Commons.I18n.formatNumber(root.radius))
                }
                Choices {
                    id: sizes
                    options: ["S", "M", "L", "XL"].map((key, i) => ({value: String(i), label: root.t(key)}))
                    value: String(root.nearest)
                    onChanged: value => root.save("radius", root.steps[Number(value)])
                }
            }
        }
    }
}
