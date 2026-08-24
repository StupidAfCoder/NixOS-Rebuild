import QtQuick
import "../bar"

Item {
    id: root
    width: 16
    height: 16

    readonly property color loadColor: {
        const worst = Math.max(SysStatsBackend.cpuPct, SysStatsBackend.ramPct, SysStatsBackend.gpuPct);
        if (worst >= 85)
            return Colors.error;
        if (worst >= 60)
            return Colors.warning;
        return Colors.accent;
    }

    ColoredIcon {
        anchors.centerIn: parent
        width: 14
        height: 14
        iconName: "cpu.svg"
        tint: root.loadColor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: SysStatsPanel.toggle()
    }
}
