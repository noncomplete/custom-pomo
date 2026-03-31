# Squeekboard Toggle

A [Noctalia](https://github.com/noctalia) plugin / bar widget that adds a bar widget to toggle the [Squeekboard](https://gitlab.gnome.org/World/Phosh/squeekboard) on-screen keyboard. Works with 2-in-1 Linux devices.

### Features

- **One-click toggle** — Left-click the widget to show/hide Squeekboard
- **Visual indicator** — Icon reflects current keyboard state (active/hidden)
- **Live state sync** — Monitors gsettings changes from external sources (tablet mode, accessibility settings)
- **Tooltip support** — Hover to see keyboard status
- **Non-intrusive** — Works alongside automated tablet-mode switching without conflicts

### How it works

The widget uses `gsettings` to read and write the GNOME accessibility setting `org.gnome.desktop.a11y.applications screen-keyboard-enabled`, which controls Squeekboard's visibility. It continuously monitors this setting, so manual toggles and automated tablet-mode events stay in sync.

### Requirements

- **Squeekboard** installed and running
- **gsettings** available (GNOME accessibility settings)
- **Noctalia** ≥ 4.4.3 (for bar widget support)

### Tested on

- **Niri** window manager with `switch-events` configured

### Tablet Mode (2-in-1 Laptops)

This widget **complements** automated tablet-mode switching. Configure Niri's `switch-events` in `~/.config/niri/config.kdl` to auto-toggle the keyboard:

```kdl
switch-events {
    tablet-mode-on { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
    tablet-mode-off { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
}
```

The widget will **reflect these changes in real-time** without conflicts. Manual toggles via the widget work independently of tablet-mode automation.

### License

MIT
