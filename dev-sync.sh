#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
dst="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/grainfire.privacy-spotlight"
case "${1-}" in ''|--watch) ;; *) echo 'Usage: dev-sync.sh [--watch]' >&2; exit 2;; esac
[[ ! -L "$dst" && ! -L "$dst/i18n" ]] || { echo 'Plugin destination must be a plain directory.' >&2; exit 1; }
sync_plugin() {
    # Compile translations into a static QML value. Commons.Translations
    # installs file watchers on each bar instance, even when it is closed.
    local catalogs generated
    catalogs=$(jq -n 'reduce inputs as $c ({}; .[input_filename | split("/")[-1] | rtrimstr(".json")] = $c)' i18n/*.json) || return 1
    generated=$(printf '%s\n' \
        '// Generated from i18n/*.json by dev-sync.sh.' \
        'import QtQml' 'QtObject {' "    readonly property var catalogs: ($catalogs)" '}')
    if [[ ! -f SpotlightLabels.qml || $(<SpotlightLabels.qml) != "$generated" ]]; then
        printf '%s\n' "$generated" > SpotlightLabels.qml || return 1
    fi
    omarchy plugin validate "$PWD" || return 1
    mkdir -p -- "$dst"
    # No backups: git is the history. Only top-level runtime files and
    # translation catalogs sync; anything else in the destination is removed.
    rsync -rc --delete --delete-excluded \
        --include='/manifest.json' --include='/settings.schema.json' \
        --include='/*.qml' --include='/i18n/' --include='/i18n/*.json' --exclude='*' ./ "$dst/" || return 1
    omarchy plugin validate "$dst"
}
if [[ ${1-} != --watch ]]; then
    sync_plugin
    exit
fi

# The monitor stays subscribed while validation or rsync is running. Its
# pipe queues those events for the next batch. Watch before initial sync.
coproc EVENTS { exec inotifywait -m -q -e close_write,create,delete,moved_from,moved_to \
    --include '^(\./(manifest\.json|settings\.schema\.json|[^/.][^/]*\.qml)|i18n/[^/.][^/]*\.json)$' \
    --format '%w%f' . i18n; }
monitor_pid=$EVENTS_PID
exec {events_fd}<&"${EVENTS[0]}"
trap 'kill "$monitor_pid" 2>/dev/null || true' EXIT
sync_plugin
while IFS= read -r -u "$events_fd" event; do
    [[ $event == ./SpotlightLabels.qml ]] && continue
    while IFS= read -r -t 0.2 -u "$events_fd"; do :; done
    sync_plugin || echo 'Sync failed. Waiting for the next edit.' >&2
done
