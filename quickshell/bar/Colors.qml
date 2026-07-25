pragma Singleton
import Quickshell.Io
import QtQuick

Item {
    id: root

    property real minMutedContrast: 7.5

    FileView {
        path: "/home/swami/.nixos_dotfiles/quickshell/bar/theme/colors.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
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
            property string accent_secondary: "#7aa2f7"
            property string on_accent_secondary: "#1a1b26"
        }
    }

    function relLum(c) {
        function lin(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }
    function contrastRatio(c1, c2) {
        var l1 = relLum(c1), l2 = relLum(c2)
        var hi = Math.max(l1, l2), lo = Math.min(l1, l2)
        return (hi + 0.05) / (lo + 0.05)
    }
    function mix(c1, c2, t) {
        return Qt.rgba(c1.r + (c2.r - c1.r) * t, c1.g + (c2.g - c1.g) * t, c1.b + (c2.b - c1.b) * t, 1.0)
    }
    // NOTE: blends toward textOnBackground, NOT onBackground -- QML
    // reserves any property name starting with "on" + uppercase for
    // signal handlers, so a property literally named onBackground
    // silently never evaluates its binding (stays black). This was
    // the actual bug behind every "nothing has contrast" symptom.
    function ensureContrast(fg, bg, minRatio) {
        if (contrastRatio(fg, bg) >= minRatio) return fg
        var c = fg
        for (var t = 0.1; t <= 1.0; t += 0.1) {
            c = mix(fg, textOnBackground, t)
            if (contrastRatio(c, bg) >= minRatio) break
        }
        return c
    }
    function on(bg, minRatio) {
        return ensureContrast(textOnSurfaceVariant, bg, minRatio || minMutedContrast)
    }

    readonly property color accent: Qt.color(adapter.accent)
    readonly property color textOnAccent: Qt.color(adapter.on_accent)
    readonly property color background: Qt.color(adapter.background)
    readonly property color textOnBackground: Qt.color(adapter.on_background)
    readonly property color surface: Qt.color(adapter.surface)
    readonly property color textOnSurface: Qt.color(adapter.on_surface)
    readonly property color surfaceVariant: Qt.color(adapter.surface_variant)
    readonly property color textOnSurfaceVariant: Qt.color(adapter.on_surface_variant)
    readonly property color surfaceContainerLow: Qt.color(adapter.surface_container_low)
    readonly property color surfaceContainer: Qt.color(adapter.surface_container)
    readonly property color surfaceContainerHigh: Qt.color(adapter.surface_container_high)
    readonly property color outlineVariant: Qt.color(adapter.outline_variant)
    readonly property color shadow: Qt.color(adapter.shadow)
    readonly property color error: ensureContrast(Qt.color(adapter.error), background, minMutedContrast)
    readonly property color textOnError: Qt.color(adapter.on_error)
    readonly property color outline: ensureContrast(Qt.color(adapter.outline), background, minMutedContrast)
    readonly property color accentSecondary: ensureContrast(Qt.color(adapter.accent_secondary), background, minMutedContrast)
    readonly property color textOnAccentSecondary: Qt.color(adapter.on_accent_secondary)

    readonly property bool isLight: relLum(background) > 0.5
    readonly property color success: ensureContrast(Qt.hsla(0.36, 0.55, accent.hslLightness, 1), background, minMutedContrast)
    readonly property color warning: ensureContrast(Qt.hsla(0.11, 0.55, accent.hslLightness, 1), background, minMutedContrast)

    readonly property color mutedOnBackground: on(background)
    readonly property color mutedOnShadow: on(shadow)
    readonly property color mutedOnSurfaceContainer: on(surfaceContainerLow)
}