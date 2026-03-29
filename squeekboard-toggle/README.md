# Squeekboard Toggle

A [Noctalia](https://github.com/noctalia) plugin that adds a bar widget to toggle the [Squeekboard](https://gitlab.gnome.org/World/Phosh/squeekboard) on-screen keyboard.

## Features

- **One-click toggle** — Left-click the widget to show/hide Squeekboard
- **Visual indicator** — Icon reflects the current keyboard state (active/hidden)
- **Adaptive layout** — Automatically adjusts for horizontal and vertical bar positions
- **Works with niri's tablet mode** — Stays in sync when tablet mode automatically enables/disables the keyboard

## How it works

The plugin uses `gsettings` to read and write the GNOME accessibility setting `org.gnome.desktop.a11y.applications screen-keyboard-enabled`, which controls Squeekboard's visibility. 

## Requirements

- **Noctalia** ≥ 4.4.3
- **Squeekboard** installed and running

Tested with squeekboard in mind. If other onscreen-keyboards also use `gsettings, it should also work.

### 2in1 Laptops 

Tested with **Niri** `switch-events` configured in `~/.config/niri/config.kdl`:
  
```kdl
switch-events {
    tablet-mode-on { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
    tablet-mode-off { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
}
```

## Licenses
MIT
