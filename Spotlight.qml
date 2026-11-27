import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons as Commons

Item {
    id: root
    readonly property string pluginId: "grainfire.privacy-spotlight"
    property var settings: ({})
    property point pointer: Qt.point(-999999, -999999)
    property double lastMove: 0
    property double lastNotice: 0
    readonly property real radius: bounded(settings.radius, 120, 4, 2048)
    readonly property real feather: bounded(settings.feather, 32, 0, 1024)
    readonly property real outer: radius + Math.max(0.01, feather)
    readonly property bool band: settings.shape === "band"

    function bounded(value, fallback, low, high) {
        return typeof value === "number" && Number.isFinite(value)
            ? Math.min(high, Math.max(low, value)) : fallback
    }

    Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
    function notify(key) {
        Quickshell.execDetached(["omarchy-notification-send", "--transient", "-t", "2800",
                                 strings.t("title"), strings.t(key)])
    }
    function open(payload) { notify("shareWarning") }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "screencast" && event.data.split(",")[0] === "1"
                    && Date.now() - root.lastNotice > 10000) {
                root.lastNotice = Date.now()
                root.notify("captureStarted")
            }
        }
    }

    FileView {
        id: config
        path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.settings = (JSON.parse(text()).plugins || []).find(entry => entry.id === root.pluginId) || {}
            } catch (error) {
                console.warn("Privacy Spotlight settings:", error)
            }
        }
    }

    Socket {
        id: socket
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket.sock"
        onConnectionStateChanged: if (connected) { write("j/cursorpos"); flush() }
        parser: SplitParser {
            splitMarker: "}"
            onRead: data => {
                const {x, y} = JSON.parse(data + "}")
                socket.connected = false
                if (x !== root.pointer.x || y !== root.pointer.y) {
                    root.pointer = Qt.point(x, y)
                    root.lastMove = Date.now()
                    poll.interval = 17
                } else if (Date.now() - root.lastMove > 1000) {
                    poll.interval = 125
                }
            }
        }
    }
    Timer {
        id: poll
        interval: 17
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!socket.connected) socket.connected = true
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "privacy-spotlight"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}
            readonly property real px: root.pointer.x - modelData.x
            readonly property real py: root.pointer.y - modelData.y
            readonly property bool hit: px >= 0 && py >= 0 && px < width && py < height
            color: "transparent"
            Rectangle { anchors.fill: parent; color: "black"; visible: !win.hit }

            Shape {
                id: field
                anchors.fill: parent
                visible: win.hit
                ShapePath {
                    strokeWidth: -1
                    fillGradient: root.band ? strip : circle
                    property RadialGradient circle: RadialGradient {
                        centerX: win.px; centerY: win.py
                        focalX: centerX; focalY: centerY
                        centerRadius: root.outer
                        GradientStop { position: root.radius / root.outer; color: "transparent" }
                        GradientStop { position: 1; color: "black" }
                    }
                    property LinearGradient strip: LinearGradient {
                        x1: 0; x2: 0
                        y1: win.py - root.outer; y2: win.py + root.outer
                        GradientStop { position: 0; color: "black" }
                        GradientStop { position: (1 - root.radius / root.outer) / 2; color: "transparent" }
                        GradientStop { position: (1 + root.radius / root.outer) / 2; color: "transparent" }
                        GradientStop { position: 1; color: "black" }
                    }
                    PathLine { x: field.width; y: 0 }
                    PathLine { x: field.width; y: field.height }
                    PathLine { x: 0; y: field.height }
                    PathLine { x: 0; y: 0 }
                }
            }
        }
    }
}
