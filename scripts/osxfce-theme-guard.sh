#!/usr/bin/env bash
set -u

INTERVAL="${OSXFCE_THEME_CHECK_INTERVAL:-60}"
case "$INTERVAL" in
    ''|0|*[!0-9]*) INTERVAL=60 ;;
esac

# ~/.themes is where the installer places the GTK and Xfwm theme. Keep the
# expression separate from XDG_DATA_HOME because the latter may be customized.
THEME_DIR="$HOME/.themes/OSX-Lion"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/Mac-OS-X-Lion"
CURSOR_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/WhiteSur-cursors"

log() {
    printf 'osxfce-theme-guard: %s\n' "$*" >&2
}

usage() {
    cat <<'USAGE'
Usage: osxfce-theme-guard [--check | --repair | --watch]

  --check   Report drift without changing XFCE settings.
  --repair  Restore drifted XFCE theme settings once (default).
  --watch   Check at login and periodically repair later changes.
USAGE
}

asset_checks() {
    local failed=0

    if [ ! -f "$THEME_DIR/gtk-3.0/gtk.css" ] || [ ! -f "$THEME_DIR/xfwm4/themerc" ]; then
        log "missing OSX-Lion theme assets in $THEME_DIR; rerun the OSXfce installer"
        failed=1
    fi
    if [ ! -f "$ICON_DIR/index.theme" ]; then
        log "missing Mac-OS-X-Lion icons in $ICON_DIR; rerun the OSXfce installer"
        failed=1
    fi
    if [ ! -f "$CURSOR_DIR/index.theme" ]; then
        log "missing WhiteSur cursor assets in $CURSOR_DIR; rerun the OSXfce installer"
        failed=1
    fi

    return "$failed"
}

ensure_setting() {
    local repair="$1"
    local channel="$2"
    local property="$3"
    local type="$4"
    local expected="$5"
    local current

    current="$(xfconf-query -c "$channel" -p "$property" 2>/dev/null)" || current=""
    if [ "$current" = "$expected" ]; then
        return 0
    fi

    if [ "$repair" -eq 0 ]; then
        log "$channel $property is '${current:-<unset>}' (expected '$expected')"
        return 1
    fi

    if xfconf-query -c "$channel" -p "$property" -s "$expected" 2>/dev/null; then
        log "restored $channel $property to '$expected'"
        return 0
    fi
    if xfconf-query -c "$channel" -p "$property" -n -t "$type" -s "$expected" 2>/dev/null; then
        log "created $channel $property as '$expected'"
        return 0
    fi

    log "could not restore $channel $property"
    return 1
}

ensure_systray_icon_size() {
    local repair="$1"
    local id
    local -a plugin_ids=()

    mapfile -t plugin_ids < <(
        xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null |
            sed -n '/^[0-9][0-9]*$/p'
    )
    for id in "${plugin_ids[@]}"; do
        if [ "$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}" 2>/dev/null || true)" = "systray" ]; then
            ensure_setting "$repair" xfce4-panel "/plugins/plugin-${id}/icon-size" int 20
            return
        fi
    done

    return 0
}

check_once() {
    local repair="$1"
    local failed=0
    local scale
    local xfwm_theme="OSX-Lion"

    command -v xfconf-query >/dev/null 2>&1 || {
        log "xfconf-query is unavailable"
        return 1
    }
    asset_checks || failed=1

    scale="$(xfconf-query -c xsettings -p /Gdk/WindowScalingFactor 2>/dev/null)" || scale=1
    if [ "$scale" = 2 ] && [ -f "$HOME/.themes/OSX-Lion-hidpi/xfwm4/themerc" ]; then
        xfwm_theme="OSX-Lion-hidpi"
    fi

    if [ -f "$THEME_DIR/gtk-3.0/gtk.css" ]; then
        ensure_setting "$repair" xsettings /Net/ThemeName string OSX-Lion || failed=1
    fi
    if [ -f "$ICON_DIR/index.theme" ]; then
        ensure_setting "$repair" xsettings /Net/IconThemeName string Mac-OS-X-Lion || failed=1
    fi
    if [ -f "$CURSOR_DIR/index.theme" ]; then
        ensure_setting "$repair" xsettings /Gtk/CursorThemeName string WhiteSur-cursors || failed=1
    fi
    ensure_setting "$repair" xsettings /Gtk/FontName string "Lucida Sans Unicode 11" || failed=1
    if [ -f "$HOME/.themes/$xfwm_theme/xfwm4/themerc" ]; then
        ensure_setting "$repair" xfwm4 /general/theme string "$xfwm_theme" || failed=1
    fi
    ensure_systray_icon_size "$repair" || failed=1

    return "$failed"
}

watch() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
    local lock_dir="$runtime_dir/osxfce-theme-guard-${UID}.lock"

    if ! mkdir "$lock_dir" 2>/dev/null; then
        exit 0
    fi
    trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT INT TERM

    while :; do
        check_once 1 || true
        sleep "$INTERVAL"
    done
}

main() {
    local mode="${1:---repair}"

    case "$mode" in
        --check) check_once 0 ;;
        --repair) check_once 1 ;;
        --watch) watch ;;
        -h|--help) usage ;;
        *) usage >&2; return 2 ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
