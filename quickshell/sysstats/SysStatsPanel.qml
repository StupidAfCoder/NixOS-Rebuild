pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool shown: false

    property Timer closeTimer: Timer {
        interval: 400   // was 220 — 2.5s grace after your cursor leaves
        onTriggered: root.shown = false
    }

    function show() {
        closeTimer.stop();
        root.shown = true;
    }
    function scheduleHide() {
        closeTimer.restart();
    }
    function cancelHide() {
        closeTimer.stop();
    }
    function hide() {
        closeTimer.stop();
        root.shown = false;
    }
    function toggle() {
        if (root.shown)
            hide();
        else
            show();
    }
}
