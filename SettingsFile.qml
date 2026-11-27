import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: config
    readonly property string pluginId: "grainfire.privacy-spotlight"
    property var entry: ({})
    readonly property real radius: bounded(entry.radius, 120, 4, 2048)
    readonly property real feather: bounded(entry.feather, 32, 0, 1024)
    readonly property string shape: entry.shape === "band" ? "band" : "circle"

    function bounded(value, fallback, low, high) {
        return Number.isFinite(value) ? Math.max(low, Math.min(high, value)) : fallback
    }

    path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/shell.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
        try {
            const json = JSON.parse(text())
            const entries = [].concat(...Object.values(json?.bar?.layout || {}))
            entry = entries.find(e => e?.id === pluginId) || {}
        } catch (error) {
            console.warn("Privacy Spotlight settings:", error)
        }
    }
}
