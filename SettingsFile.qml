import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: config
    readonly property string pluginId: "grainfire.privacy-spotlight"
    property var injected: ({})
    property var saved: ({})
    readonly property var entry: Object.assign({}, saved, injected)
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
            const legacy = (json.plugins || []).find(e => e.id === pluginId)
            const widget = [].concat(...Object.values(json.bar?.layout || {})).find(e => e.id === pluginId)
            saved = Object.assign({}, legacy, widget)
        } catch (error) {
            console.warn("Privacy Spotlight settings:", error)
        }
    }
}
