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

The installer will ask whether XFCE4 should use 1x or 2x window scaling. The
2x option configures GTK/XFCE, installs a HiDPI Xfwm theme, and uses Retina-
appropriate panel and dock sizing. On a non-interactive run it defaults to 1x;
you can re-run from a TTY to be prompted.
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
    local origin

    mkdir -p "$(dirname "$dest")"
    if [ -d "$dest/.git" ]; then
        origin="$(git -C "$dest" remote get-url origin 2>/dev/null || true)"
        if [ "$origin" != "$url" ]; then
            die "cached repository at $dest has unexpected origin '${origin:-<none>}' (expected '$url')"
        fi
        git -C "$dest" fetch --depth 1 origin
        git -C "$dest" reset --hard FETCH_HEAD
    elif [ -e "$dest" ]; then
        die "build path exists but is not a Git repository: $dest"
    else
        git clone --depth 1 "$url" "$dest"
    fi
}

sync_dir() {
    local src="$1"
    local dest="$2"

    [ -d "$src" ] || die "source directory not found: $src"
    [ -n "$dest" ] && [ "$dest" != "/" ] || die "refusing unsafe sync destination: ${dest:-<empty>}"
    rm -rf -- "$dest"
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

    command -v sudo >/dev/null 2>&1 || die "sudo is required to install Arch packages"
    log "Installing Arch package dependencies"
    sudo pacman -S --needed \
        base-devel git rsync sudo fontconfig perl pkgconf gtk-update-icon-cache imagemagick \
        gtk3 gtk4 glib2 glib2-devel gobject-introspection python-setuptools \
        sqlite rust meson ninja cmake vala appmenu-gtk-module libdbusmenu-glib libdbusmenu-gtk3 \
        xfce4-panel xfconf xfce4-settings xfdesktop xfwm4 xfce4-appfinder xfce4-power-manager \
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
    local theme_dir="$HOME/.themes/OSX-Lion"
    local panel_css="$theme_dir/gtk-3.0/osxfce-panel.css"
    local gtk_css="$theme_dir/gtk-3.0/gtk.css"

    log "Installing OSX-Lion GTK/Xfwm theme"
    clone_or_update "https://github.com/orchyn/XFCE.git" "$repo"
    [ -f "$ROOT_DIR/assets/theme/osxfce-panel.css" ] ||
        die "panel theme override not found in $ROOT_DIR/assets/theme"
    [ -f "$repo/OSX-Lion/gtk-3.0/gtk.css" ] ||
        die "upstream OSX-Lion GTK theme is incomplete"
    sync_dir "$repo/OSX-Lion" "$theme_dir"
    install -m 0644 "$ROOT_DIR/assets/theme/osxfce-panel.css" "$panel_css"
    if ! grep -Fq '@import url("osxfce-panel.css");' "$gtk_css"; then
        perl -0pi -e 's#\z#\n\@import url("osxfce-panel.css");\n#' "$gtk_css"
    fi
}

install_lion_battery_icon() {
    local status_dir="$1"
    local source_name="$2"
    local target_name="$3"

    if [ ! -f "$status_dir/${source_name}.svg" ]; then
        die "Lion battery source icon not found: $status_dir/${source_name}.svg"
    fi

    rm -f -- "$status_dir/${target_name}.svg" "$status_dir/${target_name}.png"
    if command -v magick >/dev/null 2>&1; then
        # Remove the original SVG padding without changing its proportions.
        # The GTK theme gives the plugin a larger, unclipped paint area.
        if magick -background none "$status_dir/${source_name}.svg" \
            -trim +repage -resize '32x20>' \
            -gravity center -extent 32x24 "$status_dir/${target_name}.png"; then
            return
        fi
        warn "could not render ${target_name}.png; using the source SVG instead"
        rm -f -- "$status_dir/${target_name}.png"
    fi
    ln -s "${source_name}.svg" "$status_dir/${target_name}.svg"
}

install_icon_theme() {
    local repo="$BUILD_ROOT/src/Mac-OS-X-Lion"
    local dest="${XDG_DATA_HOME:-"$HOME/.local/share"}/icons/Mac-OS-X-Lion"
    local status_dir
    local level
    local lion_level

    log "Installing Mac OS X Lion icon theme"
    clone_or_update "https://github.com/B00merang-Artwork/Mac-OS-X-Lion.git" "$repo"
    [ -f "$repo/index.theme" ] || die "upstream Mac OS X Lion icon theme is incomplete"
    sync_dir "$repo" "$dest"
    # The upstream theme ships Lion battery and network icons here but omits
    # the directory from its index, causing GTK to fall back to hicolor icons.
    perl -0pi -e '
        s/^(Directories=(?![^\r\n]*24x24\/status)[^\r\n]*)(\r?)$/$1,24x24\/status$2/m
    ' "$dest/index.theme"
    grep -q '^Directories=.*24x24/status' "$dest/index.theme" ||
        die "could not register 24x24/status in the Lion icon theme index"
    # Xfce 4.20 requests freedesktop battery-level-* names, while this older
    # Lion theme uses battery-{000,020,...,100}. Provide theme-local aliases so
    # the panel does not fall back to the green hicolor battery artwork.
    status_dir="$dest/24x24/status"
    [ -d "$status_dir" ] || die "upstream Lion status icons are missing"
    for level in 0 10 20 30 40 50 60 70 80 90 100; do
        case "$level" in
            0) lion_level=000 ;;
            10|20) lion_level=020 ;;
            30|40) lion_level=040 ;;
            50|60) lion_level=060 ;;
            70|80) lion_level=080 ;;
            90|100) lion_level=100 ;;
        esac
        install_lion_battery_icon "$status_dir" "battery-${lion_level}" \
            "battery-level-${level}-symbolic"
        install_lion_battery_icon "$status_dir" "battery-${lion_level}-charging" \
            "battery-level-${level}-charging-symbolic"
    done
    install_lion_battery_icon "$status_dir" battery-charged \
        battery-level-100-charged-symbolic
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
    local user_bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"

    # Resolve the osdockx binary robustly. The OSDockX installer drops the
    # binary at $XDG_BIN_HOME or $HOME/.local/bin, which is not always on
    # $PATH for non-interactive scripts (e.g. when the installer is run
    # from a fresh login TTY). The bare "osdockx" name in the autostart
    # .desktop file would then be unresolvable on next login too.
    local osdockx_bin=""
    if command -v osdockx >/dev/null 2>&1; then
        osdockx_bin="$(command -v osdockx)"
    elif [ -x "$user_bin_dir/osdockx" ]; then
        osdockx_bin="$user_bin_dir/osdockx"
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
            "Exec=\"$osdockx_bin\"" \
            'Terminal=false' \
            'Categories=Utility;' \
            'StartupNotify=false' \
            > "$autostart_file"
    fi

    # Use the full path in Exec= so XFCE can launch the dock on next login
    # even if $HOME/.local/bin is not on the session's PATH.
    OSXFCE_DESKTOP_EXEC="$osdockx_bin" perl -0pi -e '
        s#^Exec=.*$#Exec="$ENV{OSXFCE_DESKTOP_EXEC}"#m
    ' "$autostart_file"
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

install_theme_guard() {
    local bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
    local guard="$bin_dir/osxfce-theme-guard"
    local autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
    local autostart_file="$autostart_dir/osxfce-theme-guard.desktop"

    log "Installing OSXfce theme integrity guard"
    [ -f "$ROOT_DIR/scripts/osxfce-theme-guard.sh" ] ||
        die "theme guard source not found in $ROOT_DIR/scripts"
    mkdir -p "$bin_dir" "$autostart_dir"
    install -m 0755 "$ROOT_DIR/scripts/osxfce-theme-guard.sh" "$guard"
    printf '%s\n' \
        '[Desktop Entry]' \
        'Type=Application' \
        'Name=OSXfce Theme Guard' \
        'Comment=Restore OSXfce appearance settings if they drift' \
        "Exec=\"$guard\" --watch" \
        'Terminal=false' \
        'OnlyShowIn=XFCE;' \
        'X-GNOME-Autostart-enabled=true' \
        > "$autostart_file"

    # Repair the current session immediately when the XFCE settings service is
    # reachable. The autostart watcher retries on the next login otherwise.
    "$guard" --repair || warn "theme guard could not repair this session; it will retry at next XFCE login"
}

install_osnotificationx() {
    local repo="$BUILD_ROOT/src/OSNotificationX"

    log "Installing OSNotificationX"
    clone_or_update "https://github.com/pruefsumme/OSNotificationX.git" "$repo"
    if (cd "$repo" && ./install-update.sh); then
        return
    fi

    warn "OSNotificationX failed to build/install; continuing with the OSXfce theme repair."
    warn "If its build cache has the wrong owner, fix the ownership shown above and retry later."
}

install_appmenu() {
    local repo="$BUILD_ROOT/aur/vala-panel-appmenu"
    local packages=()

    if [ "$INSTALL_APPMENU" -eq 0 ]; then
        warn "skipping Vala AppMenu; panel layout still contains an appmenu slot"
        return
    fi
    if ! command -v pacman >/dev/null 2>&1 || ! command -v makepkg >/dev/null 2>&1; then
        warn "pacman/makepkg not found; skipping the Arch-specific Vala AppMenu build"
        return
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        warn "sudo not found; skipping the Vala AppMenu build"
        return
    fi

    log "Installing Vala AppMenu AUR package"
    warn "Using the stable vala-panel-appmenu package; stable and -git AppMenu packages conflict."

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

        # Let pacman resolve conflicting AppMenu variants in the install
        # transaction. If the transaction fails, the current packages remain.
        sudo pacman -U "${built_packages[@]}"
    ); then
        return
    fi

    warn "Vala AppMenu failed to build/install; continuing without aborting the OSXfce install."
    warn "The rest of the theme will still be applied. You can retry later by running ./install.sh again."
}

apply_profile() {
    local files_dir="$PROFILE_DIR/files"
    local backup_root="$HOME/.local/share/osxfce/backups"
    local backup_dir
    local account_name
    local gecos
    local -a placeholder_roots=()

    if [ "$SKIP_PROFILE" -eq 1 ]; then
        warn "skipping XFCE profile application"
        return
    fi

    [ -d "$files_dir" ] || die "profile files not found: $files_dir"

    mkdir -p "$backup_root"
    backup_dir="$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S)-XXXXXX")"
    log "Backing up existing matching config to $backup_dir"
    for path in .config/xfce4 .config/osdockx/themes .config/autostart/dev.pruefsumme.OSDockX.desktop .config/autostart/nm-applet.desktop .local/share/osxfce/icons; do
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

# Ask the user whether XFCE4 should render at normal or HiDPI scale. The
# selection is applied after the profile has been copied so the profile cannot
# overwrite it.
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
    read -r -p "Choice [1]: " response || response=""
    case "$response" in
        2|2x|2X) WINDOW_SCALE=2x ;;
        *)       WINDOW_SCALE=1x ;;
    esac
    log "Window scale: $WINDOW_SCALE"
}

# For 2x users, overwrite the OSX-Lion theme's 35x24 panel texture with the
# 70x48 version. The panel is 24 logical pixels high, so GTK renders this asset
# at its native size when the window scale is 2x.
apply_panel_background() {
    local theme_dir="$HOME/.themes/OSX-Lion"
    local src="$HOME/.local/share/osxfce/panel-bg-2x/panel-bg.png"
    local dest="$theme_dir/panel-bg.png"

    if [ "$WINDOW_SCALE" != "2x" ]; then
        log "Keeping 1x panel background from OSX-Lion theme"
        return
    fi

    if [ ! -f "$src" ]; then
        warn "2x panel background not found at $src; skipping override"
        return
    fi
    if [ ! -d "$theme_dir" ]; then
        warn "OSX-Lion theme directory not found at $theme_dir; skipping panel background override"
        return
    fi

    log "Installing 2x panel background"
    cp -f "$src" "$dest"
}

install_hidpi_xfwm_theme() {
    local src="$HOME/.themes/OSX-Lion/xfwm4"
    local theme_dir="$HOME/.themes/OSX-Lion-hidpi"
    local dest="$theme_dir/xfwm4"

    if [ "$WINDOW_SCALE" != "2x" ]; then
        return
    fi
    if [ ! -d "$src" ]; then
        warn "OSX-Lion Xfwm theme not found at $src; keeping the 1x window theme"
        return
    fi
    if ! command -v magick >/dev/null 2>&1; then
        warn "ImageMagick not found; keeping the 1x Xfwm theme"
        return
    fi

    log "Generating OSX-Lion-hidpi Xfwm theme"
    rm -rf "$theme_dir"
    mkdir -p "$theme_dir"
    cp -a "$src" "$dest"
    find "$dest" -maxdepth 1 -type f \( -name '*.png' -o -name '*.xpm' \) -print0 |
        xargs -0r magick mogrify -filter point -resize 200%

    # Xfwm does not scale these theme metrics with GTK's window scale.
    perl -0pi -e '
        s/^(button_offset|maximized_offset|button_spacing)=(\d+)$/"$1=" . ($2 * 2)/gem
    ' "$dest/themerc"
}

set_xfconf_value() {
    local channel="$1"
    local property="$2"
    local type="$3"
    local value="$4"

    if xfconf-query -c "$channel" -p "$property" >/dev/null 2>&1; then
        xfconf-query -c "$channel" -p "$property" -s "$value"
    else
        xfconf-query -c "$channel" -p "$property" -n -t "$type" -s "$value"
    fi
}

configure_systray_icon_size() {
    local icon_size="$1"
    local id
    local -a plugin_ids=()

    mapfile -t plugin_ids < <(
        xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null |
            sed -n '/^[0-9][0-9]*$/p'
    )
    for id in "${plugin_ids[@]}"; do
        if [ "$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}" 2>/dev/null || true)" = "systray" ]; then
            set_xfconf_value xfce4-panel "/plugins/plugin-${id}/icon-size" int "$icon_size" ||
                warn "could not set the Notification Area icon size"
            return
        fi
    done
    warn "could not find the Notification Area plugin; Wi-Fi icon size was not changed"
}

has_system_battery() {
    local supply

    for supply in /sys/class/power_supply/*; do
        if [ -r "$supply/type" ] && [ "$(cat "$supply/type")" = "Battery" ]; then
            return 0
        fi
    done
    return 1
}

configure_battery_plugin() {
    local plugin_id=""
    local candidate=12
    local id
    local plugin_type
    local previous_id=""
    local previous_type=""
    local insertion_anchor=""
    local candidate_in_use
    local inserted=0
    local -a current_ids=()
    local -a updated_ids=()
    local -a set_args=()

    if ! has_system_battery; then
        log "No system battery detected; leaving the power-manager panel plugin disabled"
        return
    fi
    if ! command -v xfconf-query >/dev/null 2>&1; then
        warn "Battery detected, but xfconf-query is unavailable"
        return
    fi

    log "Battery detected; enabling the Lion-styled power-manager panel plugin"
    mapfile -t current_ids < <(
        xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null |
            sed -n '/^[0-9][0-9]*$/p'
    )
    if [ "${#current_ids[@]}" -eq 0 ]; then
        warn "could not read the panel plugin list; leaving it unchanged"
        return
    fi

    # Reuse an existing power plugin when possible. Also locate the systray
    # and its leading separator so the battery lands beside the Wi-Fi icon
    # without relying on profile-specific plugin IDs.
    for id in "${current_ids[@]}"; do
        plugin_type="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}" 2>/dev/null || true)"
        if [ "$plugin_type" = "power-manager-plugin" ] && [ -z "$plugin_id" ]; then
            plugin_id="$id"
        fi
        if [ "$plugin_type" = "systray" ] && [ -z "$insertion_anchor" ]; then
            insertion_anchor="$id"
            if [ -n "$previous_id" ] && [ "$previous_type" = "separator" ]; then
                insertion_anchor="$previous_id"
            fi
        fi
        previous_id="$id"
        previous_type="$plugin_type"
    done

    if [ -z "$plugin_id" ]; then
        while :; do
            candidate_in_use=0
            for id in "${current_ids[@]}"; do
                if [ "$id" -eq "$candidate" ]; then
                    candidate_in_use=1
                    break
                fi
            done
            if [ "$candidate_in_use" -eq 0 ] &&
                ! xfconf-query -c xfce4-panel -p "/plugins/plugin-${candidate}" >/dev/null 2>&1; then
                plugin_id="$candidate"
                break
            fi
            candidate=$((candidate + 1))
            if [ "$candidate" -gt 10000 ]; then
                warn "could not find an unused XFCE panel plugin ID for the battery"
                return
            fi
        done
    fi

    set_xfconf_value xfce4-panel "/plugins/plugin-${plugin_id}" string power-manager-plugin || {
        warn "could not configure the power-manager panel plugin"
        return
    }

    for id in "${current_ids[@]}"; do
        if [ "$id" -eq "$plugin_id" ]; then
            inserted=1
        elif [ -n "$insertion_anchor" ] && [ "$id" -eq "$insertion_anchor" ] && [ "$inserted" -eq 0 ]; then
            updated_ids+=("$plugin_id")
            inserted=1
        fi
        updated_ids+=("$id")
    done
    if [ "$inserted" -eq 0 ]; then
        updated_ids+=("$plugin_id")
    fi

    set_args=(-c xfce4-panel -p /panels/panel-1/plugin-ids -a)
    for id in "${updated_ids[@]}"; do
        set_args+=(-t int -s "$id")
    done
    xfconf-query "${set_args[@]}" || warn "could not add the battery plugin to the panel"
    set_xfconf_value xfce4-power-manager /xfce4-power-manager/show-panel-label int 1 ||
        warn "could not enable the battery percentage label"
}

apply_window_scale() {
    local factor=1
    local cursor_size=24
    local systray_icon_size=20
    local xfwm_theme="OSX-Lion"

    if [ "$WINDOW_SCALE" = "2x" ]; then
        factor=2
        cursor_size=48
        if [ -d "$HOME/.themes/OSX-Lion-hidpi/xfwm4" ]; then
            xfwm_theme="OSX-Lion-hidpi"
        fi
    fi

    if ! command -v xfconf-query >/dev/null 2>&1; then
        warn "xfconf-query not found; select ${factor}x window scaling manually"
        return
    fi

    log "Applying ${factor}x XFCE window scaling"
    set_xfconf_value xsettings /Gdk/WindowScalingFactor int "$factor" ||
        warn "could not set XFCE window scaling"
    set_xfconf_value xsettings /Gtk/CursorThemeSize int "$cursor_size" ||
        warn "could not set the cursor size"
    set_xfconf_value xfwm4 /general/theme string "$xfwm_theme" ||
        warn "could not select Xfwm theme $xfwm_theme"
    # Xfwm scales the title font with the UI factor even though it does not
    # scale legacy decoration assets. Doubling the point size clips the title.
    set_xfconf_value xfwm4 /general/title_font string "Lucida Grande Bold 9" ||
        warn "could not set the Xfwm title font"

    # Keep legacy tray icons large enough to match the Lion menu-bar artwork.
    configure_systray_icon_size "$systray_icon_size"
}

configure_nm_applet() {
    local system_file="/etc/xdg/autostart/nm-applet.desktop"
    local autostart_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/autostart"
    local autostart_file="$autostart_dir/nm-applet.desktop"
    local exec_line="Exec=nm-applet"

    if [ ! -f "$system_file" ]; then
        return
    fi
    if [ "$WINDOW_SCALE" = "2x" ]; then
        exec_line="Exec=nm-applet --indicator"
    fi

    if [ -e "$autostart_file" ] && ! grep -q '^X-OSXfce-Managed=true$' "$autostart_file"; then
        warn "preserving existing NetworkManager autostart file at $autostart_file"
        return
    fi

    log "Configuring NetworkManager Applet for ${WINDOW_SCALE} window scaling"
    mkdir -p "$autostart_dir"
    if [ ! -e "$autostart_file" ]; then
        cp -a "$system_file" "$autostart_file"
    fi
    perl -0pi -e "s#^Exec=.*\$#$exec_line#m" "$autostart_file"
    grep -q '^X-OSXfce-Managed=' "$autostart_file" ||
        printf '%s\n' 'X-OSXfce-Managed=true' >> "$autostart_file"
}

initialize_osdockx_scale() {
    local config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/osdockx"
    local config_file="$config_dir/config.toml"

    if [ "$WINDOW_SCALE" != "2x" ] || [ -e "$config_file" ]; then
        return
    fi

    log "Initializing OSDockX sizing for 2x window scaling"
    mkdir -p "$config_dir"
    printf '%s\n' \
        '[dock]' \
        'icon_size = 64' \
        '' \
        '[startup]' \
        'autostart = true' \
        'prompt_seen = true' \
        > "$config_file"
}

offer_logout() {
    if [ ! -t 0 ]; then
        return
    fi

    local response
    printf '\nThe new panel layout will not appear until you log out and back in.\n'
    read -r -p "Log out now? [y/N] " response || response=""
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

main() {
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
                return
                ;;
            *)
                die "unknown option: $1"
                ;;
        esac
        shift
    done

    if [ "$(id -u)" -eq 0 ]; then
        die "run this installer as your desktop user, not as root (it uses sudo when needed)"
    fi

    mkdir -p "$BUILD_ROOT"
    install_arch_deps
    need cp
    need fc-cache
    need find
    need git
    need install
    need mktemp
    need perl
    need rsync
    need sha256sum
    install_lucida_fonts
    install_xfce_theme
    install_icon_theme
    install_cursor_theme
    install_osdockx
    install_osnotificationx
    install_appmenu

    if [ "$SKIP_PROFILE" -eq 1 ]; then
        warn "skipping XFCE profile, session autostarts, and live appearance changes"
        log "Done. Dependencies and assets were installed without changing the XFCE session."
        return
    fi

    prompt_window_scale
    apply_profile
    apply_panel_background
    install_hidpi_xfwm_theme
    apply_window_scale
    configure_battery_plugin
    initialize_osdockx_scale
    configure_nm_applet
    install_osdockx_autostart
    install_theme_guard
    offer_logout

    log "Done. Log out via the XFCE session menu to see the new layout."
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
