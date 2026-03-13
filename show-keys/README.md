# Show Keys

A floating OSD plugin for Noctalia Shell that displays keyboard input in real-time via `evtest`.

![Preview](preview.png)

## Features

* **Real-Time Capture**: Reads raw keyboard input events directly from your device for instantaneous tracking.
* **Multi-Monitor OSD**: Select exactly which monitors display the overlay with zero memory overhead for disabled screens.
* **Visual Customization**: Dynamically override Noctalia's native theme colors (`mPrimary`/`mSurface`) with custom text and background colors for the key pills.
* **Flexible Placement**: Anchor the display to the top or bottom edge of your monitor and fine-tune the margin distance.
* **Smart Auto-Hide**: The OSD fades out gracefully after a custom amount of idle time.
* **Quick Toggle**: Turn the capture process on or off instantly using shell IPC commands.

## Prerequisites

This plugin relies on `evtest` to read hardware input directly. You must install it and configure user permissions to allow your shell to read the even.

1.  **Install evtest** (for Arch Linux):
    ```bash
    sudo pacman -S evtest
    ```

2.  **Grant input group permissions**:
    Add your user to the `input` group so the plugin can read inputs without requiring root access:
    ```bash
    sudo usermod -aG input $USER
    ```
    *(Note: You must log out and log back in, or reboot, for this group change to take effect.)*

3.  **Find your keyboard device path**:
    Run the following command to list all input devices:
    ```bash
    sudo evtest
    ```
    Identify your primary keyboard from the list and note its event path (e.g., `/dev/input/event3`).

## Configuration & Usage

1.  Open your Noctalia Shell settings and navigate to the **Show Keys** plugin.
2.  Enter your keyboard's device path in the **Device Path** setting.
3.  Restart `noctalia-shell` to apply the changes and start the capture process.

### Keybinding / IPC Command

You can toggle the OSD visibility and capture state using Noctalia's IPC handler. Bind the following command to a custom shortcut in your Wayland compositor (e.g., `niri`) to easily show or hide the overlay:

```bash
qs -c noctalia-shell ipc call plugin:show-keys toggle
```

## License

MIT