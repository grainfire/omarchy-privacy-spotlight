# Privacy Spotlight

A privacy overlay for [Omarchy](https://omarchy.org). It blacks out your screens except for a soft circle (or a horizontal reading band) that follows your mouse pointer, so people looking over your shoulder can't read what's on your screen.

- Clicks, scrolling and typing pass straight through to your apps.
- Covers every monitor. Notifications still show on top.
- Uses nothing while it's off: no processes, timers or watchers.
- On an OLED screen, the blacked-out area is fully off.

## Requirements

- Omarchy 4.6 or later (Hyprland)

## Install

```sh
omarchy plugin add https://github.com/grainfire/omarchy-privacy-spotlight.git --enable
```

The installer asks which bar section should hold the icon, with the right section pre-selected. Add `--yes` to use the right section without being asked. To re-add a missing icon on the right, run:

```sh
omarchy bar put grainfire.privacy-spotlight --section right
```

To move an existing icon to the right, run `omarchy bar move grainfire.privacy-spotlight --section right`.

### Keyboard shortcut (optional)

Add a binding to `~/.config/hypr/bindings.lua`, using any key combination that's free on your system, for example:

```lua
o.bind("SUPER + CTRL + ALT + SHIFT + P", "Privacy Spotlight", "omarchy-shell shell toggle grainfire.privacy-spotlight '{}'")
```

The plugin is enabled by its bar icon. If you remove the icon from the bar, the shortcut stops working too. To use the shortcut without the icon, add an entry to the top-level `plugins` array in `~/.config/omarchy/shell.json`. It can hold your settings too. For example, this entry opens a reading band with a half-height of 150 logical pixels:

```json
{ "id": "grainfire.privacy-spotlight", "shape": "band", "radius": 150 }
```

If both entries exist, the spotlight uses the bar entry.

## Use

| Action | What it does |
|---|---|
| Left-click the icon | Turn the spotlight on or off |
| Right-click the icon | Choose **Circle** or **Band** and a size (S, M, L, XL) |
| Scroll on the icon | Make it bigger or smaller, whether it's on or off |
| Your shortcut | Turn it on or off |

The icon is bright while the spotlight is on and dimmed while it's off.

| Size | S | M | L | XL |
|---|---:|---:|---:|---:|
| Circle radius (px) | 120 | 180 | 240 | 320 |
| Band half-height (px) | 60 | 100 | 150 | 200 |

Sizes are in logical pixels, so they look the same at any display scale.

## Update and remove

```sh
omarchy plugin update grainfire.privacy-spotlight
omarchy plugin remove grainfire.privacy-spotlight
```

## Settings

Your choices are saved in the plugin's bar entry in `~/.config/omarchy/shell.json`. The right-click menu covers everything most people need; you can also edit them by hand:

| Key | Meaning | Default | Values |
|---|---|---|---|
| `shape` | Shape of the clear area | `circle` | `circle`, `band` |
| `radius` | Circle radius or band half-height, in logical pixels | `120` | 4–2048 |
| `feather` | Width of the soft edge, in logical pixels | `32` | 0–1024 |

## Battery use

- **Off:** nothing runs. Only the bar icon exists, inside the Omarchy shell.
- **On:** the plugin asks Hyprland for the pointer position about 60 times a second while you move the mouse, and about 8 times a second after it has been still for one second.
- **After 10 seconds without any input** (reading, locked screen, display off), it stops checking completely and starts again the moment you touch the mouse or keyboard.

## Limitations

- It's a deterrent, not real security: someone behind you can still read what's inside the circle.
- The overlay shows up in screen shares and screenshots. Turn it off before you share your screen.
- The circle is drawn on the monitor the pointer is on; near the edge of a monitor it's cut off there.

## Development

Clone the repository anywhere and edit it there. `dev-sync.sh` copies the plugin's files into `~/.config/omarchy/plugins/grainfire.privacy-spotlight/`, where the shell watches for plugin changes:

```sh
./dev-sync.sh          # sync once
./dev-sync.sh --watch  # sync runtime file changes (needs inotify-tools)
```

It also builds `SpotlightLabels.qml` from the translation files in `i18n/`, runs `omarchy plugin validate`, and removes files from the installed copy that are no longer in the repository. If you installed with `omarchy plugin add`, remove that copy first (`omarchy plugin remove grainfire.privacy-spotlight`).

## License

MIT. See [LICENSE](LICENSE).
