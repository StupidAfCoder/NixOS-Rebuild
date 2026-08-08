pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool shown: false
    property bool hoverZone: false
    property bool hoverPanel: false

    property Timer hideTimer: Timer {
        interval: 260
        onTriggered: {
            if (!root.hoverZone && !root.hoverPanel)
                root.shown = false;
        }
    }

    onHoverZoneChanged: evaluate()
    onHoverPanelChanged: evaluate()

    function evaluate() {
        if (hoverZone || hoverPanel) {
            hideTimer.stop();
            shown = true;
        } else {
            hideTimer.restart();
        }
    }
}
