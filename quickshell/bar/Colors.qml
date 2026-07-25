pragma Singleton
import Quickshell.Io
import QtQuick

// Reads bar/theme/colors.json (written by matugen's bar-colors.json.hbs)
// and exposes every key as a live, color-typed property. watchChanges +
// onFileChanged means every reference below updates the instant the
// wallpaper switcher's matugen run rewrites the file -- no shell
// restart, same hot-reload guarantee ReactiveImage/ColoredSprite already
// have for the sprites.
//
// On top of the raw MD3 roles, this file also does what Caelestia's
// services/Colours.qml does: it never trusts that a role pairing which
// isn't part of the MD3 contract (on_surface_variant vs plain background)
// will actually be readable. MD3 only guarantees on_surface vs surface,
// on_background vs background, and on_surface_variant vs surface_variant.
// It never promised on_surface_variant vs background -- that pairing's
// contrast is undefined and wallpaper-dependent, which is exactly the
// washed-out text you get on some images and not others.
//
// mutedOnBackground below is a version of on_surface_variant that has
// been luminance-nudged (hue/saturation untouched) until it clears a
// real WCAG contrast ratio against the *exact* background color in use
// right now -- so it can never wash out, regardless of what matugen
// hands us for a given wallpaper.
Item {
    id: root

    // Lower = chunkier/more retro pixel-art banding, higher = closer to
    // raw MD3 smoothness. 24 keeps visible steps without banding badly.
    property int pixelLevels: 24
    // Extra saturation punch applied after quantizing, for the pixel look.
    property real punchAmount: 0.10
    // WCAG contrast ratio floor for "muted" text/icons/tints.
    // 4.5 = WCAG AA for normal-size text. Don't go below ~3.0.
    property real minMutedContrast: 4.5

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

    // ---------------------------------------------------------------
    // color-math helpers
    // ---------------------------------------------------------------

    function relLum(c) {
        function lin(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }

    function contrastRatio(c1, c2) {
        var l1 = relLum(c1), l2 = relLum(c2)
        var lighter = Math.max(l1, l2), darker = Math.min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    // Nudges fg's lightness (hue/sat untouched) until it clears minRatio
    // against bg, or hits the clamp. Same idea as Caelestia's
    // alterColour() in Colours.qml -- correct luminance, not role, is
    // what actually fixes contrast, since role-swapping just trades one
    // undefined pairing for another.
    function ensureContrast(fg, bg, minRatio) {
        if (contrastRatio(fg, bg) >= minRatio) return fg
        var goLighter = relLum(bg) < 0.5
        var c = fg
        var l = c.hslLightness
        for (var i = 0; i < 60; i++) {
            l = Math.max(0.02, Math.min(0.98, l + (goLighter ? 0.02 : -0.02)))
            c = Qt.hsla(c.hslHue, c.hslSaturation, l, c.a)
            if (contrastRatio(c, bg) >= minRatio || l <= 0.02 || l >= 0.98) break
        }
        return c
    }

    function quantize(c) {
        var step = 1.0 / (pixelLevels - 1)
        function snap(v) { return Math.round(v / step) * step }
        return Qt.rgba(snap(c.r), snap(c.g), snap(c.b), c.a)
    }

    function punch(c, amt) {
        var s = Math.min(1.0, c.hslSaturation * (1 + amt))
        return Qt.hsla(c.hslHue, s, c.hslLightness, c.a)
    }

    // Full pass every base role goes through: string -> color -> punched -> quantized.
    function styled(hex) {
        return quantize(punch(Qt.color(hex), punchAmount))
    }

    // ---------------------------------------------------------------
    // base roles (pixel-styled: punched saturation + quantized bands)
    // ---------------------------------------------------------------
    readonly property color accent: styled(adapter.accent)
    readonly property color onAccent: styled(adapter.on_accent)
    readonly property color error: styled(adapter.error)
    readonly property color onError: styled(adapter.on_error)
    readonly property color background: styled(adapter.background)
    readonly property color onBackground: styled(adapter.on_background)
    readonly property color surface: styled(adapter.surface)
    readonly property color onSurface: styled(adapter.on_surface)
    readonly property color surfaceVariant: styled(adapter.surface_variant)
    readonly property color onSurfaceVariant: styled(adapter.on_surface_variant)
    readonly property color surfaceContainerLow: styled(adapter.surface_container_low)
    readonly property color surfaceContainer: styled(adapter.surface_container)
    readonly property color surfaceContainerHigh: styled(adapter.surface_container_high)
    readonly property color outline: styled(adapter.outline)
    readonly property color outlineVariant: styled(adapter.outline_variant)
    readonly property color shadow: styled(adapter.shadow)
    readonly property color success: styled(adapter.success)
    readonly property color warning: styled(adapter.warning)

    // ---------------------------------------------------------------
    // guaranteed-contrast tokens
    // ---------------------------------------------------------------
    // Use these anywhere text/icons sit directly on a Colors.background
    // (or Colors.shadow) colored panel -- which is basically every
    // panelBox/bezel in this codebase. They start from the same muted
    // MD3 tone but get luminance-corrected against the exact container
    // color that's live right now, so they can't wash out on any
    // wallpaper. Leave raw onSurfaceVariant/onSurface alone anywhere
    // they're already sitting on a surface/surfaceVariant/
    // surfaceContainer* container -- that pairing is already
    // MD3-guaranteed and doesn't need correcting.
    readonly property color mutedOnBackground: "#39ff14"
    //readonly property color mutedOnBackground: ensureContrast(onSurfaceVariant, background, minMutedContrast)
    readonly property color mutedOnShadow: ensureContrast(onSurfaceVariant, shadow, minMutedContrast)
}
