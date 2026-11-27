import Qt.labs.folderlistmodel
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
        if (Date.now() - lastDiscovery > 2000 && !discovery.active) {
            lastDiscovery = Date.now()
            discovery.active = true
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
        discovery.active = false
        if (tracking) {
            lastMove = Date.now()
            schedule(1)
        }
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
    // Only inspect instance lock files on transport failure. The second
    // line identifies the Wayland display (also used by hyprctl instances).
    Loader {
        id: discovery
        active: false
        sourceComponent: Item {
            id: scan
            function selectInstance() {
                if (folders.status !== FolderListModel.Ready) return
                const display = Quickshell.env("WAYLAND_DISPLAY").split("/").pop()
                let best = null
                for (let i = 0; i < folders.count; i++) {
                    const name = folders.get(i, "fileName")
                    if (name === tracker.instance) continue
                    reader.path = folders.get(i, "filePath") + "/hyprland.lock"
                    const lines = reader.text().trim().split("\n")
                    if (lines.length < 2 || lines[1].trim() !== display) continue
                    const pid = lines[0].trim()
                    if (!/^[1-9][0-9]*$/.test(pid)) continue
                    reader.path = "/proc/" + pid + "/comm"
                    const live = reader.text().trim() === "Hyprland"
                    const stamp = /_(\d+)_(\d+)$/.exec(name)
                    const seconds = stamp ? Number(stamp[1]) : 0
                    const fraction = stamp ? Number(stamp[2]) : 0
                    if (!best || live > best.live || (live === best.live &&
                            (seconds > best.seconds || (seconds === best.seconds && fraction > best.fraction)))) {
                        best = {name, live, seconds, fraction}
                    }
                }
                if (best) tracker.instance = best.name
                discovery.active = false
            }
            FileView { id: reader; preload: false; blockAllReads: true; printErrors: false }
            FolderListModel {
                id: folders
                folder: "file://" + Quickshell.env("XDG_RUNTIME_DIR") + "/hypr"
                showFiles: false
                showDotAndDotDot: false
                onStatusChanged: if (status === FolderListModel.Ready) Qt.callLater(scan.selectInstance)
                Component.onCompleted: if (status === FolderListModel.Ready) Qt.callLater(scan.selectInstance)
            }
            // Release the scan even if the runtime directory disappears.
            Timer { interval: 500; running: true; onTriggered: discovery.active = false }
        }
    }
}
