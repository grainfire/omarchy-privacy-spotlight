# Privacy Spotlight

An Omarchy shell plugin that blacks out every monitor except a soft-edged circle (or a horizontal reading band) around the mouse pointer, so people looking over your shoulder can't read the screen. Clicks, scrolling and typing pass straight through to your apps.

## Install

Place this folder at `~/.config/omarchy/plugins/grainfire.privacy-spotlight/`, then:

```bash
omarchy plugin enable grainfire.privacy-spotlight
```

## Use

Toggle it with:

```bash
omarchy-shell shell toggle grainfire.privacy-spotlight '{}'
```

Example Hyprland binding (`~/.config/hypr/bindings.lua`):

```lua
o.bind("SUPER + CTRL + ALT + SHIFT + P", "Privacy Spotlight", "omarchy-shell shell toggle grainfire.privacy-spotlight '{}'")
```

## Settings

In the plugin's entry in `~/.config/omarchy/shell.json`:

| Key | Values | Default |
|---|---|---|
| `shape` | `circle` or `band` | `circle` |
| `radius` | clear radius (or band half-height), logical px | `120` |
| `feather` | fade width, logical px | `32` |

## How it works

Quickshell can't see the global pointer position, so while the spotlight is on it polls Hyprland's IPC socket (`cursorpos`): every 17 ms while the pointer moves, every 125 ms after a second of no movement. When it's off, nothing runs.

## Known limitations

- The overlay appears in screen shares and screenshots. A screencast starting only shows a notification; it doesn't turn the spotlight off.
- It's a deterrent, not real security: the bright area is still readable.
