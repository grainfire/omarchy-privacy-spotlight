import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: tracker
    required property bool tracking
    property string instance: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string socketPath: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + instance + "/.socket.sock"
    property point pointer: Qt.point(-999999, -999999)
    property double lastMove: 0
    property double lastDiscovery: 0
    property bool waiting: false

    function cancel() {
        next.stop()
        deadline.stop()
        waiting = false
        // Destroy a failed parser as well as its socket. SplitParser can hold
        // an unterminated fragment which must never prefix the next response.
        transport.active = false
    }

    function failed() {
        if (!waiting) return
        cancel()
        pointer = Qt.point(-999999, -999999)
        if (!tracking) return
        if (Date.now() - lastDiscovery > 2000 && !discover.running) {
            lastDiscovery = Date.now()
            discover.running = true
        }
        schedule(125)
    }

    function schedule(delay) {
        next.interval = delay
        next.restart()
    }

    function request() {
        if (!tracking || waiting) return
        transport.active = true
        waiting = true
        deadline.restart()
        transport.item.connected = true
    }

    function received(data) {
        if (!waiting) return
        try {
            const pos = JSON.parse(data + "}")
            if (!Number.isFinite(pos.x) || !Number.isFinite(pos.y)) throw Error("Invalid position")
            if (pos.x !== pointer.x || pos.y !== pointer.y) {
                pointer = Qt.point(pos.x, pos.y)
                lastMove = Date.now()
            }
        } catch (error) {
            failed()
            return
        } finally {
            if (transport.item) transport.item.connected = false
        }
        waiting = false
        deadline.stop()
        schedule(Date.now() - lastMove > 1000 ? 125 : 17)
    }

    onTrackingChanged: {
        cancel()
        pointer = Qt.point(-999999, -999999)
        if (tracking) schedule(1)
    }
    Component.onCompleted: if (tracking) schedule(1)
    Timer { id: next; onTriggered: tracker.request() }
    Timer { id: deadline; interval: 250; onTriggered: tracker.failed() }

    Loader {
        id: transport
        active: false
        sourceComponent: Socket {
            path: tracker.socketPath
            onConnectionStateChanged: if (connected) { write("j/cursorpos"); flush() }
            parser: SplitParser { splitMarker: "}"; onRead: data => tracker.received(data) }
        }
    }
    Process {
        id: discover
        command: ["hyprctl", "-j", "instances"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const display = Quickshell.env("WAYLAND_DISPLAY").split("/").pop()
                    const match = JSON.parse(text).find(row => row.wl_socket === display)
                    if (match && /^[a-zA-Z0-9_-]+$/.test(match.instance)) tracker.instance = match.instance
                } catch (error) { /* Compositor may still be starting. */ }
            }
        }
    }
}
