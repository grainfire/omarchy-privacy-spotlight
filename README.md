# Privacy Spotlight

Privacy Spotlight 2.0 for Omarchy keeps a soft-edged circle or a horizontal reading band clear around the pointer. Every other output stays black. Clicks, scrolling and typing reach the app underneath. Notifications remain visible and display captures include the overlay.

## Install or update

From this checkout run `./dev-sync.sh`, then place the widget on the bar:

```sh
omarchy bar put grainfire.privacy-spotlight --section right --after stappmus.activity-monitor
```

The sync script validates the source and installed copy, backs up replaced runtime files beside them, and removes obsolete QML and catalog files. Use `./dev-sync.sh --watch` for local development.

## Controls

Left-click the spotlight icon to toggle. Full brightness means on. Right-click for Circle or Reading band and the size and feather sliders. A slider saves on release or a wheel step. The bar, shortcut and IPC share the shell's overlay-open state.

```sh
omarchy-shell shell toggle grainfire.privacy-spotlight '{}'
```

Example Hyprland binding:

```lua
o.bind("SUPER + CTRL + ALT + SHIFT + P", "Privacy Spotlight", "omarchy-shell shell toggle grainfire.privacy-spotlight '{}'")
```

## Settings

The popup uses Omarchy's bar settings writer. Values live in the widget's entry in `bar.layout` in `$XDG_CONFIG_HOME/omarchy/shell.json` (default `~/.config/omarchy/shell.json`). A bar value overrides the same key in a v1 `plugins[]` entry. Existing v1 overrides continue to apply to other keys.

| Key | Meaning | Default | Accepted values |
|---|---|---|---|
| shape | Clear region | circle | circle, band |
| radius | Circle radius or band half-height in logical pixels | 120 | 4–2048 |
| feather | Additional edge fade in logical pixels | 32 | 0–1024 |

## Tracking

While open and visible, the overlay requests logical pointer coordinates from Hyprland's IPC socket. It waits 17 ms between successful requests, increasing to 125 ms after one second without movement. Invalid or stalled requests reset the transport, black out the last opening and retry. On failure it rediscovers the Hyprland instance for the current Wayland display.

An event-driven Python 3 standard-library listener subscribes to Hyprland lock notifications and Wayland output power changes. The cursor timer and connection stop while locked or while every output is off. Closing the spotlight unloads the overlay and listener. The bar icon stays available.

## License

MIT. See [LICENSE](LICENSE).
