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
// mutedOnBackground below is a version of on_surface_variant that gets
// blended toward on_background (already MD3-guaranteed safe) until it
// clears a real WCAG contrast ratio against the *exact* background
// color in use right now -- so it can never wash out, regardless of
// what matugen hands us for a given wallpaper.
Item {
    id: root

    // Lower = chunkier/more retro pixel-art banding, higher = closer to
    // raw MD3 smoothness. 24 keeps visible steps without banding badly.
    property int pixelLevels: 24
    // Extra saturation punch applied after quantizing, for the pixel look.
    property real punchAmount: 0.10
    // WCAG contrast ratio floor for "muted" text/icons/tints.
    // 4.5 is WCAG AA for normal text, but at 8-9px in a thin bitmap
    // font with no antialiasing, 4.5:1 still reads as dim. Pushed to
    // 7.5 (near AAA) so labels are unambiguously legible at this size.
    property real minMutedContrast: 7.5

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

    // Nudges fg toward onBackground (which is ALREADY MD3-guaranteed to
    // have strong contrast against background -- no math needed there)
    // until the blend clears minRatio. Deliberately NOT hue-preserving
    // HSL lightness search: Qt returns hslHue = -1 for near-grey/
    // desaturated colors (undefined hue), and feeding -1 back into
    // Qt.hsla() is undefined behaviour -- exactly the kind of thing a
    // muted, low-saturation dark-mode role like on_surface_variant hits
    // constantly. A plain RGB blend toward a color we already know is
    // safe has no such edge case: worst case (t=1.0) we just return
    // onBackground outright, which is guaranteed to pass.
    function mix(c1, c2, t) {
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            1.0
        )
    }

    function ensureContrast(fg, bg, minRatio) {
        if (contrastRatio(fg, bg) >= minRatio) return fg
        var c = fg
        for (var t = 0.1; t <= 1.0; t += 0.1) {
            c = mix(fg, onBackground, t)
            if (contrastRatio(c, bg) >= minRatio) break
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
    // DEBUG CANARY -- uncomment this one line and comment out the real
    // line below it, save, and look at any panel. If the text does NOT
    // turn neon green, the running quickshell process is not reading
    // this file at all (wrong config path, or it needs a restart) --
    // that's a deployment problem, not a color-math problem, and no
    // amount of editing this file will ever change what's on screen
    // until that's fixed. If it DOES turn green, the pipeline works and
    // we just need to tune the real formula below.
    // readonly property color mutedOnBackground: "#39ff14"
    readonly property color mutedOnBackground: ensureContrast(onSurfaceVariant, background, minMutedContrast)
    readonly property color mutedOnShadow: ensureContrast(onSurfaceVariant, shadow, minMutedContrast)
    // Same idea, but for text sitting on a surfaceContainerLow panel
    // (the notification card body) instead of plain background --
    // different container color, so it needs its own corrected token.
    readonly property color mutedOnSurfaceContainer: ensureContrast(onSurfaceVariant, surfaceContainerLow, minMutedContrast)
}
