# OSXfce

OSXfce packages my XFCE4 setup as a pre-Mavericks OS X inspired desktop for a
fresh Arch Linux XFCE install.

The repository contains only sanitized dotfiles and the small local pieces that
must be shipped directly: the XFCE profile, OSDockX themes, and the custom XFCE
start menu icon.
Wallpapers are intentionally not included.

## Install

On a fresh Arch Linux XFCE setup:

```sh
git clone https://github.com/pruefsumme/OSXfce.git
cd OSXfce
./install.sh
```

The installer:

- installs Arch dependencies needed for the theme, XFCE plugins, common pinned
  dock apps, Rust dock, notification applet, and appmenu build
- clones and installs Lucida fonts from `witt-bit/lucida-fonts`, with embedded
  checksum verification
- clones and installs the `OSX-Lion` GTK/Xfwm theme from `orchyn/XFCE`
- clones and installs `Mac-OS-X-Lion` icons from B00merang
- clones and installs `WhiteSur-cursors`
- clones/builds/installs OSDockX and OSNotificationX
- builds the Vala AppMenu AUR packages with `makepkg`
- applies `profile/default` into the user's home directory

Use this if appmenu is giving trouble:

```sh
./install.sh --skip-appmenu
```

## What Gets Applied

`profile/default` contains the transferable XFCE setup:

- top panel position, size, lock state, plugin order, separators, appmenu slot,
  clocks, pulseaudio, systray, notification plugin, weather slot, and
  OSNotificationX slot
- appearance settings for `OSX-Lion`, `Mac-OS-X-Lion`, `WhiteSur-cursors`, and
  Lucida fonts
- Xfwm window-manager settings
- custom XFCE start menu icon
- OSDockX theme files

OSDockX installs its binary, default config, and launcher/autostart behavior
itself; this repo does not override those files.

The installer backs up existing matching config into:

```text
~/.local/share/osxfce/backups/
```

## Privacy/Sanitization

The committed profile removes personal machine details:

- no wallpapers
- no desktop icon positions
- no source-machine home paths
- no personal weather location or coordinates
- no panel user name/title
- no source-machine private icon image paths
- no remembered network/tray item names
