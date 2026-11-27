#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
dst="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/grainfire.privacy-spotlight"
case "${1-}" in ''|--watch) ;; *) echo 'Usage: dev-sync.sh [--watch]' >&2; exit 2;; esac
[[ ! -L "$dst" && ! -L "$dst/i18n" ]] || { echo 'Plugin destination must be a plain directory.' >&2; exit 1; }
sync_plugin() {
    omarchy plugin validate "$PWD"
    mkdir -p -- "$dst"
    # No backups: git is the history. Only top-level runtime files and
    # translation catalogs sync; anything else in the destination is removed.
    rsync -rc --delete \
        --include='/manifest.json' --include='/settings.schema.json' \
        --include='/*.qml' --include='/i18n/' --include='/i18n/*.json' --exclude='*' ./ "$dst/"
    omarchy plugin validate "$dst"
}
sync_plugin
if [[ ${1-} == --watch ]]; then
    while inotifywait -qq -e close_write,create,delete,moved_from,moved_to . i18n; do
        sleep 0.2
        sync_plugin || echo 'Sync failed. Waiting for the next edit.' >&2
    done
fi
