import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    SettingsFile { id: config }
    SessionVisibility { id: session }
    CursorTracker { id: tracker; tracking: session.awake }
    readonly property point pointer: tracker.pointer
    readonly property real radius: config.radius
    readonly property real feather: config.feather
    readonly property real outer: radius + Math.max(0.01, feather)
    readonly property bool band: config.shape === "band"

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
