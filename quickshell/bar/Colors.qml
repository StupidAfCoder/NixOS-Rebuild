pragma Singleton
import Quickshell.Io
import QtQuick
import "../common"

Item {
    id: root

    property real minMutedContrast: Settings.contrast >= 0.5 ? 7 : 4.5

    FileView {
        path: Settings.themeFile
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string accent: "#bbbbbb"
            property string on_accent: "#000000"
            property string error: "#ffb4ab"
            property string on_error: "#380000"
            property string background: "#000000"
            property string on_background: "#f1f1ec"
            property string surface: "#0b0b0b"
            property string on_surface: "#f1f1ec"
            property string surface_variant: "#282828"
            property string on_surface_variant: "#bcbcb7"
            property string surface_container_low: "#111111"
            property string surface_container: "#181818"
            property string surface_container_high: "#1f1f1f"
            property string outline: "#777777"
            property string outline_variant: "#303030"
            property string shadow: "#000000"
            property string accent_secondary: "#bbbbbb"
            property string on_accent_secondary: "#000000"
        }
    }

    function relLum(c) {
        if (typeof c === "string") c = Qt.color(c);
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
    readonly property color outline: Qt.color(adapter.outline)
    readonly property color accentSecondary: accent
    readonly property color textOnAccentSecondary: Qt.color(adapter.on_accent_secondary)

    readonly property bool isLight: relLum(background) > 0.5
    readonly property color success: ensureContrast(Qt.hsla(0.36, 0.55, accent.hslLightness, 1), background, minMutedContrast)
    readonly property color warning: ensureContrast(Qt.hsla(0.11, 0.55, accent.hslLightness, 1), background, minMutedContrast)

    readonly property color mutedOnBackground: on(background)
    readonly property color mutedOnShadow: on(shadow)
    readonly property color mutedOnSurfaceContainer: on(surfaceContainerLow)
}
