# Privacy Spotlight

A click-through privacy overlay for Omarchy. A feathered circle or horizontal band follows the pointer. Other outputs stay black. Notifications remain visible, and screen captures include the spotlight.

## Install

Run these commands from the repository:

```sh
./dev-sync.sh
omarchy bar put grainfire.privacy-spotlight --section right
```

The script compiles the translation catalogs into static QML, validates the source, mirrors the runtime files to the plugin directory and validates the installed copy. It deletes stale files there. For development, `./dev-sync.sh --watch` batches runtime-file changes and queues saves made during a sync.

The bar entry enables the plugin. Removing the icon also disables its shortcut unless you keep an entry such as `{"id": "grainfire.privacy-spotlight"}` in the top-level `plugins[]` array of `shell.json`. Add that entry to use the keyboard shortcut without a bar icon.

## Controls

Left-click the bar icon to toggle. Right-click for **Circle** or **Band** and four sizes. Scroll up or down on the icon to change size even when the overlay is off. The popup shows the actual radius or half-height in logical pixels. A custom value highlights the nearest size (the smaller size wins a tie). Opening the popup preserves the value. Clicking the highlighted size explicitly selects its preset.

| Size | S | M | L | XL |
|---|---:|---:|---:|---:|
| Circle radius | 120 | 180 | 240 | 320 |
| Band half-height | 60 | 100 | 150 | 200 |

Shape changes preserve the numeric size until you choose a preset or scroll. The shell saves changes in-process to the widget's bar-layout entry. The icon follows the same open state as IPC and the keyboard shortcut.

```sh
omarchy-shell shell toggle grainfire.privacy-spotlight '{}'
```

Example Hyprland binding:

```lua
o.bind("SUPER + CTRL + ALT + SHIFT + P", "Privacy Spotlight", "omarchy-shell shell toggle grainfire.privacy-spotlight '{}'")
```

## Settings

In the widget's entry in `bar.layout` in `$XDG_CONFIG_HOME/omarchy/shell.json` (default `~/.config/omarchy/shell.json`):

| Key | Meaning | Default | Accepted values |
|---|---|---|---|
| shape | Clear region | circle | circle, band |
| radius | Circle radius or band half-height in logical pixels | 120 | 4–2048, including custom values |
| feather | Advanced setting for edge fade in logical pixels | 32 | 0–1024 |

## Tracking and idle

The overlay polls Hyprland's cursor socket every 17 ms during motion and every 125 ms after a second without movement. After 10 seconds without seat input, Quickshell's Wayland IdleMonitor stops the timer and releases the socket. The opening stays in place for reading. Input resumes tracking immediately. Idle inhibitors from video players do not delay suspension. Typing on a lock screen can briefly resume polling.

Turning the spotlight off unloads its overlay, IdleMonitor, cursor tracker and settings reader. The bar icon uses the settings supplied by the host. The plugin starts no helper processes.

## License

MIT. See [LICENSE](LICENSE).
