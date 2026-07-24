pragma Singleton
import Quickshell.Io
import QtQuick

// Reads bar/theme/colors.json (written by matugen's bar-colors.json.hbs)
// and exposes every key as a live, color-typed property. watchChanges +
// onFileChanged means every reference below updates the instant the
// wallpaper switcher's matugen run rewrites the file -- no shell
// restart, same hot-reload guarantee ReactiveImage/ColoredSprite already
// have for the sprites.
Item {
    id: root

    FileView {
        path: "/home/swami/.nixos_dotfiles/quickshell/bar/theme/colors.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            // Tokyo-Night-shaped fallbacks so the shell never renders
            // fully unstyled if colors.json is briefly missing/malformed.
            property string accent: "#7aa2f7"
            property string on_accent: "#1a1b26"
            property string error: "#f7768e"
            property string on_error: "#1a1b26"
            property string background: "#1a1b26"
            property string on_background: "#c0caf5"
            property string surface: "#1f2335"
            property string on_surface: "#c0caf5"
            property string surface_variant: "#292e42"
            property string on_surface_variant: "#a9b1d6"
            property string surface_container_low: "#16161e"
            property string surface_container: "#1f2335"
            property string surface_container_high: "#292e42"
            property string outline: "#565f89"
            property string outline_variant: "#414868"
            property string shadow: "#0f0f16"
            property string success: "#9ece6a"
            property string warning: "#e0af68"
        }
    }

    // camelCase, color-typed convenience names -- what the rest of the
    // bar actually binds against.
    readonly property color accent: adapter.accent
    readonly property color onAccent: adapter.on_accent
    readonly property color error: adapter.error
    readonly property color onError: adapter.on_error
    readonly property color background: adapter.background
    readonly property color onBackground: adapter.on_background
    readonly property color surface: adapter.surface
    readonly property color onSurface: adapter.on_surface
    readonly property color surfaceVariant: adapter.surface_variant
    readonly property color onSurfaceVariant: adapter.on_surface_variant
    readonly property color surfaceContainerLow: adapter.surface_container_low
    readonly property color surfaceContainer: adapter.surface_container
    readonly property color surfaceContainerHigh: adapter.surface_container_high
    readonly property color outline: adapter.outline
    readonly property color outlineVariant: adapter.outline_variant
    readonly property color shadow: adapter.shadow
    readonly property color success: adapter.success
    readonly property color warning: adapter.warning
}