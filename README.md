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

The installer fetches the theme, icons, fonts, dock, notification applet, and the included XFCE profile. It will ask about your window scale and may ask for your password to install the required Arch packages. When it finishes, log out and back in to enjoy the full effect.

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
