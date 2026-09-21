import QtQuick
import QtQuick.Controls
import "../bar"
Button {
    id: root
    property bool primary: false
    property bool danger: false
    // Rail glyphs rest unboxed; interaction uses the same cap as every button.
    property bool quiet: false
    readonly property color ink: primary ? Colors.textOnAccent : danger ? Colors.error : checked ? Colors.accent : Colors.textOnBackground
    implicitHeight: Math.max(36, implicitContentHeight + topPadding + bottomPadding + 2)
    implicitWidth: Math.max(36, implicitContentWidth + leftPadding + rightPadding + 4)
    padding: 10
    topPadding: padding + (down ? 2 : 0)
    bottomPadding: padding - (down ? 2 : 0)
    hoverEnabled: true
    font.family: "Cozette"
    font.pixelSize: Settings.bodySize
    contentItem: PixelText {
        id: label
        text: root.text; font: root.font
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        color: root.ink
        opacity: root.enabled ? 1 : .45
    }
    background: ConsoleSurface {
        visible: !root.quiet || root.hovered || root.down || root.checked || root.visualFocus
        fillColor: root.primary ? Colors.accent : root.checked ? Colors.surfaceContainerHigh : root.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
        edgeColor: root.visualFocus || root.checked ? Colors.accent : root.danger && root.hovered ? Colors.error : Colors.outlineVariant
        pressed: root.down || root.checked
        lit: root.hovered || root.visualFocus
        opacity: root.enabled ? 1 : .4
    }
}
