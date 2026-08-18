# A blast of the aqua past

Bring the bright, glossy feel of an OSX-inspired desktop from the 2008–2013 era to XFCE on your Linux system :)

![An OSXfce desktop with the Lion-inspired wallpaper, menu bar, and dock](assets/screenshots/desktop-preview.png)

## Get started

> [!WARNING]
> Back up your existing XFCE configuration and any files you care about before
> continuing. The installer creates a backup of the XFCE files it replaces, but
> it also installs packages, downloads third-party projects, and changes your
> desktop configuration. Run it only if you understand and accept those changes;
> you use it at your own risk.

From this folder, run:

```sh
./install.sh
```

The installer fetches the theme, icons, fonts, dock, notification applet, and the included XFCE profile. It will ask whether to use normal 1x or HiDPI/Retina 2x window scaling and may ask for your password to install the required Arch packages. The 2x option keeps the display at its native resolution while scaling GTK, the panel, window decorations, and the initial dock size together. When it finishes, log out and back in to enjoy the full effect.

On laptops, the installer detects the system battery and adds XFCE's power
manager indicator using Lion-style charge artwork. It also sizes the
NetworkManager notification-area icon to match the menu bar.

It also installs a lightweight session guard. At login and once per minute it
checks the GTK, icon, cursor, font, and window-decoration selections and restores
them if XFCE resets them. To inspect the current state without making changes,
run `~/.local/bin/osxfce-theme-guard --check`.

For options such as skipping package installation or choosing another profile, see:

```sh
./install.sh --help
```

## Built with

OSXfce brings a few lovely projects together. The dock and notification experience are powered by projects from [pruefsumme](https://github.com/pruefsumme):

- [OSDockX](https://github.com/pruefsumme/osdockx) — the dock.
- [OSNotificationX](https://github.com/pruefsumme/OSNotificationX) — the notification applet.

## A few more looks

Your desktop can keep the aqua details while getting on with real work.

![OSXfce with a terminal, Eclipse, and Thunar](assets/screenshots/desktop-in-use.png)

![OSXfce about dialog over a working desktop](assets/screenshots/about-desktop.png)

## Independent project

OSXfce is an independent XFCE customization project. It is not affiliated with, endorsed by, or sponsored by Apple Inc. Apple, Mac, and Mac OS X are trademarks of Apple Inc.

## License

The code and configuration files in this repository are licensed under the
[MIT License](LICENSE). Third-party themes, icons, fonts, and other projects
installed by this project remain subject to their respective licenses. This
license provides the software "as is" and does not guarantee that using the
project will be free of legal, compatibility, or other issues.
