#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${OSXFCE_BUILD_ROOT:-"${XDG_CACHE_HOME:-"$HOME/.cache"}/osxfce-build"}"
PROFILE_DIR="$ROOT_DIR/profile/default"
INSTALL_APPMENU=1
SKIP_PACMAN=0
SKIP_PROFILE=0
WINDOW_SCALE=1x

usage() {
    cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --profile DIR       Apply a different profile directory.
  --no-profile        Install dependencies/assets only; do not apply XFCE config.
  --skip-appmenu      Do not build/install Vala AppMenu AUR packages.
  --skip-pacman       Do not install Arch package dependencies with pacman.
  -h, --help          Show this help.

Default behavior installs upstream dependencies, builds the custom dock and
notification applet, attempts the appmenu plugin, and applies profile/default.

The installer will ask whether XFCE4 is running at 1x or 2x window scaling so
the panel background uses the correct asset. On a non-interactive run it
defaults to 1x; you can re-run from a TTY to be prompted.
USAGE
}

log() {
    printf '\n==> %s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

clone_or_update() {
    local url="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    if [ -d "$dest/.git" ]; then
        git -C "$dest" fetch --depth 1 origin
        git -C "$dest" reset --hard FETCH_HEAD
    else
        git clone --depth 1 "$url" "$dest"
    fi
}

sync_dir() {
    local src="$1"
    local dest="$2"

    rm -rf "$dest"
    mkdir -p "$dest"
    rsync -a --delete --exclude '.git' "$src"/ "$dest"/
}

install_arch_deps() {
    if [ "$SKIP_PACMAN" -eq 1 ]; then
        warn "skipping pacman dependency install"
        return
    fi

    if ! command -v pacman >/dev/null 2>&1; then
        warn "pacman not found; install dependencies manually for this distro"
        return
    fi

    log "Installing Arch package dependencies"
    sudo pacman -S --needed \
        base-devel git rsync sudo fontconfig pkgconf gtk-update-icon-cache \
        gtk3 gtk4 glib2 glib2-devel gobject-introspection python-setuptools \
        sqlite rust meson ninja cmake vala appmenu-gtk-module libdbusmenu-glib libdbusmenu-gtk3 \
        xfce4-panel xfconf xfce4-settings xfdesktop xfwm4 xfce4-appfinder \
        xfce4-pulseaudio-plugin xfce4-weather-plugin xfce4-notes-plugin xfce4-notifyd \
        network-manager-applet
}

install_lucida_fonts() {
    local repo="$BUILD_ROOT/src/lucida-fonts"
    local dest="${XDG_DATA_HOME:-"$HOME/.local/share"}/fonts/lucida-fonts"

    log "Installing Lucida fonts with checksum verification"
    clone_or_update "https://github.com/witt-bit/lucida-fonts.git" "$repo"
    (
        cd "$repo"
        sha256sum -c <<'LUCIDA_SHA256'
cd30436e06ad45a05e24c22f4f97f1b5c632a534f95d2f800467f78042d46f9e  Lucida MAC-Regular.ttf
6ddf64ee896d24cf9908f115ae220a7cfa18dc034bc4a68e4db68dcd57c71512  Lucida Console-Seml Condensed.ttf
1e47e725bb5f9d69341139e84f185ac897f039ea04cfd4f01c8f79a947c2216b  Lucida Grande-Deml Bold.ttf
bc4635730c1b172305c013173abd64703d996d058cceeb85b868cee9bd869c89  Lucida Grande-Medium.ttf
97226e81f19eff8c8fb191745748bab920472c005d3ec4e23d9a50a12c471d92  Lucida Sans Unicode-Regular.ttf
eb3f949ba0f1368698e69396259e667d9fb913ebfde3c742d493aae5dd57141e  Lucida Sans/Lucida Sans-Regular.ttf
ca117345d190cda8ad6c7a41af1d6d43c475d0fdc99c97b8d325986309597f7a  Lucida Sans/Lucida Sans-Italic.ttf
76160ce9cd774532131cf4902b810a2d02c94f225da238ff8c04e25875eb66c5  Lucida Sans/Lucida Sans-Deml Bold.ttf
eb2d865bdadbdd19dacd2aa6f1a0d4e93263b3dac13de536106286e809abc238  Lucida Sans/Lucida Sans-Deml Bold Italic.ttf
fc908259013b90f1cbc597a510c6dd7855bf9e7830abe3fc3612ab4092edcde2  Lucida Sans Typewriter/Lucida Sans Typewriter-Bold.ttf
993b8ad78909d2b9d67ea0001112cac238fb65c6b31f6729fdb0b86c24e2b8ab  Lucida Sans Typewriter/Lucida Sans Typewriter-Deml Bold⁄Seml Condensed.ttf
187f363e9c2e328409938b4413027fe8f0c55423913ba66ea66d3f0d7fd5c74e  Lucida Sans Typewriter/Lucida Sans Typewriter-Deml Bold⁄Seml Condensed⁄Oblique.ttf
6cb152c64882e12e88b42a8f41b3b9ef32b3c3849423547edf70554f1d835a01  Lucida Sans Typewriter/Lucida Sans Typewriter-Regular.ttf
b700d1bc51a11c77ca7b119b0677a9cd4dc1e61fe43a7130bc2044cd7dc9b116  Lucida Sans Typewriter/Lucida Sans Typewriter-Seml Condensed.ttf
980e0ce5a0f4c407e90c72a16da2a259b7fc2a0ea48d1faf048028b2735fa941  Lucida Sans Typewriter/Lucida Sans Typewriter-Seml Condensed⁄Oblique.ttf
LUCIDA_SHA256
    )

    rm -rf "$dest"
    mkdir -p "$dest"
    while IFS= read -r -d '' font; do
        cp -a "$font" "$dest/"
    done < <(find "$repo" -type f -name '*.ttf' -print0)
    fc-cache -f "$dest"
}

install_xfce_theme() {
    local repo="$BUILD_ROOT/src/orchyn-XFCE"

    log "Installing OSX-Lion GTK/Xfwm theme"
    clone_or_update "https://github.com/orchyn/XFCE.git" "$repo"
    sync_dir "$repo/OSX-Lion" "$HOME/.themes/OSX-Lion"
}

install_icon_theme() {
    local repo="$BUILD_ROOT/src/Mac-OS-X-Lion"
    local dest="${XDG_DATA_HOME:-"$HOME/.local/share"}/icons/Mac-OS-X-Lion"

    log "Installing Mac OS X Lion icon theme"
    clone_or_update "https://github.com/B00merang-Artwork/Mac-OS-X-Lion.git" "$repo"
    sync_dir "$repo" "$dest"
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f "$dest" >/dev/null 2>&1 || true
    fi
}

install_cursor_theme() {
    local repo="$BUILD_ROOT/src/WhiteSur-cursors"

    log "Installing WhiteSur cursor theme"
    clone_or_update "https://github.com/vinceliuice/WhiteSur-cursors.git" "$repo"
    (cd "$repo" && ./install.sh)
}

install_osdockx() {
    local repo="$BUILD_ROOT/src/osdockx"

    log "Installing OSDockX"
    clone_or_update "https://github.com/pruefsumme/osdockx.git" "$repo"
    (cd "$repo" && ./install.sh)
}

install_osdockx_autostart() {
    local autostart_dir="$HOME/.config/autostart"
    local autostart_file="$autostart_dir/dev.pruefsumme.OSDockX.desktop"
    local system_file="/usr/share/applications/dev.pruefsumme.OSDockX.desktop"

    # Resolve the osdockx binary robustly. The OSDockX installer drops the
    # binary at $XDG_BIN_HOME or $HOME/.local/bin, which is not always on
    # $PATH for non-interactive scripts (e.g. when the installer is run
    # from a fresh login TTY). The bare "osdockx" name in the autostart
    # .desktop file would then be unresolvable on next login too.
    local osdockx_bin=""
    if command -v osdockx >/dev/null 2>&1; then
        osdockx_bin="$(command -v osdockx)"
    elif [ -x "${XDG_BIN_HOME:-}/osdockx" ]; then
        osdockx_bin="${XDG_BIN_HOME:-}/osdockx"
    elif [ -x "$HOME/.local/bin/osdockx" ]; then
        osdockx_bin="$HOME/.local/bin/osdockx"
    fi

    if [ -z "$osdockx_bin" ]; then
        warn "osdockx binary not found; skipping OSDockX autostart"
        return
    fi

    log "Enabling OSDockX autostart for the current user"
    mkdir -p "$autostart_dir"
    if [ -f "$system_file" ]; then
        cp -a "$system_file" "$autostart_file"
    else
        printf '%s\n' \
            '[Desktop Entry]' \
            'Type=Application' \
            'Name=OSDockX' \
            'Comment=A lightweight OSX-inspired dock for Linux/X11' \
            "Exec=$osdockx_bin" \
            'Terminal=false' \
            'Categories=Utility;' \
            'StartupNotify=false' \
            > "$autostart_file"
    fi

    # Use the full path in Exec= so XFCE can launch the dock on next login
    # even if $HOME/.local/bin is not on the session's PATH.
    perl -0pi -e "s#^Exec=.*\$#Exec=$osdockx_bin#m" "$autostart_file"
    grep -q '^X-GNOME-Autostart-enabled=' "$autostart_file" ||
        printf '%s\n' 'X-GNOME-Autostart-enabled=true' >> "$autostart_file"

    # Start OSDockX in this session right away, so the user doesn't have to
    # do it manually. nohup + disown keeps the dock alive after the install
    # script exits (otherwise the backgrounded process gets SIGHUP'd).
    if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        if ! pgrep -u "$(id -u)" -x osdockx >/dev/null 2>&1; then
            nohup "$osdockx_bin" >/dev/null 2>&1 &
            disown
        fi
    fi
}

install_osnotificationx() {
    local repo="$BUILD_ROOT/src/OSNotificationX"

    log "Installing OSNotificationX"
    clone_or_update "https://github.com/pruefsumme/OSNotificationX.git" "$repo"
    (cd "$repo" && ./install-update.sh)
}

install_appmenu() {
    local repo="$BUILD_ROOT/aur/vala-panel-appmenu"
    local conflicts=(
        appmenu-glib-translator
        appmenu-glib-translator-git
        vala-panel-appmenu
        vala-panel-appmenu-budgie
        vala-panel-appmenu-budgie-git
        vala-panel-appmenu-common-git
        vala-panel-appmenu-jayatana
        vala-panel-appmenu-jayatana-git
        vala-panel-appmenu-locale
        vala-panel-appmenu-locale-git
        vala-panel-appmenu-mate
        vala-panel-appmenu-mate-git
        vala-panel-appmenu-registrar
        vala-panel-appmenu-registrar-git
        vala-panel-appmenu-valapanel
        vala-panel-appmenu-valapanel-git
        vala-panel-appmenu-xfce
        vala-panel-appmenu-xfce-git
    )
    local installed=()
    local packages=()

    if [ "$INSTALL_APPMENU" -eq 0 ]; then
        warn "skipping Vala AppMenu; panel layout still contains an appmenu slot"
        return
    fi

    log "Installing Vala AppMenu AUR package"
    warn "Using the stable vala-panel-appmenu package; stable and -git AppMenu packages conflict."

    if command -v pacman >/dev/null 2>&1; then
        mapfile -t installed < <(pacman -Qq "${conflicts[@]}" 2>/dev/null || true)
        if [ "${#installed[@]}" -gt 0 ]; then
            warn "Removing installed AppMenu packages before rebuilding: ${installed[*]}"
            sudo pacman -Rns "${installed[@]}"
        fi
    fi

    clone_or_update "https://aur.archlinux.org/vala-panel-appmenu.git" "$repo"
    if (
        cd "$repo"
        built_packages=()
        export _build_mate=false
        export _build_xfce=true
        export _build_vala=false
        export _build_budgie=false
        export _build_registrar=true
        export _build_translator=true

        makepkg -sr

        mapfile -t packages < <(makepkg --packagelist)
        for package in "${packages[@]}"; do
            case "$(basename "$package")" in
                *-debug-*.pkg.tar.*) continue ;;
            esac
            [ -f "$package" ] && built_packages+=("$package")
        done
        [ "${#built_packages[@]}" -gt 0 ]
        sudo pacman -U "${built_packages[@]}"
    ); then
        return
    fi

    warn "Vala AppMenu failed to build/install; continuing without aborting the OSXfce install."
    warn "The rest of the theme will still be applied. You can retry later by running ./install.sh again."
}

apply_profile() {
    local files_dir="$PROFILE_DIR/files"
    local backup_dir="$HOME/.local/share/osxfce/backups/$(date +%Y%m%d-%H%M%S)"
    local account_name
    local gecos

    if [ "$SKIP_PROFILE" -eq 1 ]; then
        warn "skipping XFCE profile application"
        return
    fi

    [ -d "$files_dir" ] || die "profile files not found: $files_dir"

    log "Backing up existing matching config to $backup_dir"
    mkdir -p "$backup_dir"
    for path in .config/xfce4 .config/osdockx/themes .config/autostart/dev.pruefsumme.OSDockX.desktop .local/share/osxfce/icons; do
        if [ -e "$HOME/$path" ]; then
            mkdir -p "$backup_dir/$(dirname "$path")"
            cp -a "$HOME/$path" "$backup_dir/$path"
        fi
    done

    if command -v xfce4-panel >/dev/null 2>&1; then
        xfce4-panel --quit >/dev/null 2>&1 || true
    fi
    if command -v pkill >/dev/null 2>&1; then
        pkill -u "$(id -un)" xfconfd >/dev/null 2>&1 || true
    fi

    log "Applying sanitized XFCE profile"
    cp -a "$files_dir/." "$HOME/"

    account_name="$(id -un)"
    if command -v getent >/dev/null 2>&1; then
        gecos="$(getent passwd "$account_name" | cut -d: -f5 | cut -d, -f1 || true)"
        [ -n "$gecos" ] && account_name="$gecos"
    fi
    export OSXFCE_USER_NAME="$account_name"

    placeholder_roots=()
    [ -d "$HOME/.config/xfce4" ] && placeholder_roots+=("$HOME/.config/xfce4")
    [ -d "$HOME/.config/osdockx" ] && placeholder_roots+=("$HOME/.config/osdockx")
    if [ "${#placeholder_roots[@]}" -gt 0 ]; then
        find "${placeholder_roots[@]}" -type f -print0 |
            xargs -0r perl -0pi -e 's#\@HOME\@#$ENV{HOME}#g; s#\@USER_NAME\@#$ENV{OSXFCE_USER_NAME}#g'
    fi

    if command -v xfconf-query >/dev/null 2>&1; then
        xfconf-query -c xsettings -p /Net/ThemeName -s OSX-Lion 2>/dev/null || true
        xfconf-query -c xsettings -p /Net/IconThemeName -s Mac-OS-X-Lion 2>/dev/null || true
        xfconf-query -c xsettings -p /Gtk/CursorThemeName -s WhiteSur-cursors 2>/dev/null || true
        xfconf-query -c xsettings -p /Gtk/FontName -s "Lucida Sans Unicode 11" 2>/dev/null || true
        xfconf-query -c xfwm4 -p /general/theme -s OSX-Lion 2>/dev/null || true
    fi
}

# Ask the user whether XFCE4 is running at 1x or 2x window scaling so the
# panel background uses the correct asset. The OSX-Lion theme ships a 16 px
# tall panel-bg.png which tiles on HiDPI/2x displays; the 32 px version in
# $HOME/.local/share/osxfce/panel-bg-32px/panel-bg.png (installed by
# apply_profile) is a drop-in replacement for 2x users.
prompt_window_scale() {
    if [ ! -t 0 ]; then
        warn "not running on a TTY; defaulting window scale to 1x (re-run from a terminal to be prompted)"
        WINDOW_SCALE=1x
        return
    fi

    local response
    printf '\nXFCE4 window scaling:\n'
    printf '  1) 1x  (default — standard DPI)\n'
    printf '  2) 2x  (HiDPI / 4K / Retina)\n'
    read -r -p "Choice [1]: " response
    case "$response" in
        2|2x|2X) WINDOW_SCALE=2x ;;
        *)       WINDOW_SCALE=1x ;;
    esac
    log "Window scale: $WINDOW_SCALE"
}

# For 2x users, overwrite the OSX-Lion theme's panel-bg.png with the 32 px
# version. The xfce4-panel.xml in profile/default already points at this
# path, so no XML change is required.
apply_panel_background() {
    local theme_dir="$HOME/.themes/OSX-Lion"
    local src="$HOME/.local/share/osxfce/panel-bg-32px/panel-bg.png"
    local dest="$theme_dir/panel-bg.png"

    if [ "$WINDOW_SCALE" != "2x" ]; then
        log "Keeping 1x panel background from OSX-Lion theme"
        return
    fi

    if [ ! -f "$src" ]; then
        warn "32 px panel background not found at $src; skipping override"
        return
    fi
    if [ ! -d "$theme_dir" ]; then
        warn "OSX-Lion theme directory not found at $theme_dir; skipping panel background override"
        return
    fi

    log "Installing 32 px panel background for 2x window scaling"
    cp -f "$src" "$dest"
}

offer_logout() {
    if [ ! -t 0 ]; then
        return
    fi

    local response
    printf '\nThe new panel layout will not appear until you log out and back in.\n'
    read -r -p "Log out now? [y/N] " response
    case "$response" in
        [yY]|[yY][eE][sS])
            if [ -z "${DISPLAY:-}" ] || ! command -v xfce4-session-logout >/dev/null 2>&1; then
                warn "Cannot log out automatically; please log out via the XFCE session menu when you're ready"
                return
            fi
            log "Logging out of XFCE so the new layout appears on next login"
            xfce4-session-logout --logout || warn "Logout failed; please log out via the XFCE session menu when you're ready"
            ;;
    esac
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --profile)
            shift
            [ "$#" -gt 0 ] || die "--profile needs a directory"
            PROFILE_DIR="$1"
            ;;
        --no-profile)
            SKIP_PROFILE=1
            ;;
        --skip-appmenu)
            INSTALL_APPMENU=0
            ;;
        --skip-pacman)
            SKIP_PACMAN=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac
    shift
done

need git
need cp
need find
need perl
need rsync
need sha256sum

mkdir -p "$BUILD_ROOT"
install_arch_deps
install_lucida_fonts
install_xfce_theme
install_icon_theme
install_cursor_theme
install_osdockx
install_osnotificationx
install_appmenu
prompt_window_scale
apply_profile
apply_panel_background
install_osdockx_autostart
offer_logout

log "Done. Log out via the XFCE session menu to see the new layout."
