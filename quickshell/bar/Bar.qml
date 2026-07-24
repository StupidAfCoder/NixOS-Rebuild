import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Effects
import "pathgen.js" as PathGen
import "."
import "../bar"

Item {
    id: root
    property int barWidth: 32

    width: barWidth

    readonly property string iconBasePath: "file:///home/swami/.local/share/pixelarticons/svg/"
    readonly property string defaultWsIcon: "app-windows.svg"

    // Ordered rules: first substring match on the window class wins.
    // Run `hyprctl clients | grep class` to see your real class names
    // and add more rows here for anything not covered.
    readonly property var classIconRules: [
        { match: ["firefox", "librewolf", "zen", "chromium", "chrome", "brave"], icon: "globe.svg" },
        { match: ["kitty", "alacritty", "foot", "wezterm", "konsole", "xterm", "gnome-terminal"], icon: "terminal.svg" },
        { match: ["discord", "telegram", "slack", "whatsapp", "element", "signal"], icon: "message.svg" },
        { match: ["spotify", "mpv", "vlc", "rhythmbox"], icon: "music.svg" },
        { match: ["code", "codium", "jetbrains", "idea", "pycharm", "clion", "sublime", "neovide", "nvim"], icon: "braces.svg" },
        { match: ["thunar", "nautilus", "dolphin", "pcmanfm", "files"], icon: "folder.svg" },
        { match: ["steam"], icon: "gamepad.svg" },
        { match: ["obsidian", "notion"], icon: "notebook.svg" },
        { match: ["gimp", "inkscape", "krita" , "aseprite"], icon: "brush.svg" }
    ]

    function iconForClass(cls) {
        if (!cls) return root.defaultWsIcon
        const c = cls.toLowerCase()
        for (let i = 0; i < root.classIconRules.length; i++) {
            const rule = root.classIconRules[i]
            for (let j = 0; j < rule.match.length; j++) {
                if (c.indexOf(rule.match[j]) !== -1) return rule.icon
            }
        }
        return root.defaultWsIcon
    }

    // lastIpcObject (used below for window class) doesn't update on its
    // own -- Quickshell's docs are explicit about this. Refresh on window
    // open/close immediately, and on an interval as a safety net for
    // anything that changes the "current app" without an open/close event.
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland.toplevels
        function onObjectInsertedPost() { Hyprland.refreshToplevels() }
        function onObjectRemovedPost() { Hyprland.refreshToplevels() }
    }

    BarShell {
        id: shell
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        anchors.rightMargin: 4
        spacing: 8

        // --- NixOS logo / power button ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 24
            height: 24

            Image {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: "file:///home/swami/.nixos_dotfiles/quickshell/bar/assets/NixOS.svg"
                smooth: false
            }

            MouseArea {
                anchors.fill: parent
                onClicked: console.log("power button clicked")
            }
        }

        // --- Workspace indicators ---
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Repeater {
                model: 5

                Item {
                    id: wsPill
                    required property int index
                    property int wsId: index + 1
                    property var wsData: Hyprland.workspaces.values.find(w => w.id === wsId)
                    property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                    property bool isOccupied: !!wsData && wsData.toplevels.values.length > 0

                    // Which window "represents" this workspace's icon: prefer the
                    // globally focused window if it's in this workspace, else fall
                    // back to the most recently opened one here.
                    property var topWindow: {
                        if (!wsPill.wsData || wsPill.wsData.toplevels.values.length === 0) return null
                        const tls = wsPill.wsData.toplevels.values
                        for (let i = 0; i < tls.length; i++) {
                            if (tls[i].activated) return tls[i]
                        }
                        return tls[tls.length - 1]
                    }

                    readonly property string windowClass: (wsPill.topWindow && wsPill.topWindow.lastIpcObject)
                        ? (wsPill.topWindow.lastIpcObject.class || "") : ""
                    readonly property string wsIcon: root.iconForClass(wsPill.windowClass)

                    width: 20
                    height: 20

                    readonly property var staticDots: [
                        {x: 1, y: 2}, {x: 14, y: 1}, {x: 4, y: 15},
                        {x: 16, y: 12}, {x: 9, y: 8}, {x: 2, y: 10}
                    ]

                    Repeater {
                        model: (!wsPill.isActive && !wsPill.isOccupied) ? wsPill.staticDots : []
                        delegate: Rectangle {
                            required property var modelData
                            x: wsPill.width / 2 - 9 + modelData.x
                            y: wsPill.height / 2 - 9 + modelData.y
                            width: 2
                            height: 2
                            color: Colors.warning
                            opacity: 0.85
                            antialiasing: false
                        }
                    }

                    // Active pill background
                    Shape {
                        anchors.fill: parent
                        antialiasing: false
                        visible: wsPill.isActive
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: Colors.accent
                            strokeColor: "transparent"
                            PathSvg { path: PathGen.chamferedRectPath(20, 20, 6) }
                        }
                    }

                    // Colorized via the same ColoredIcon component your other tray
                    // icons use -- reads the SVG text and swaps currentColor for the
                    // tint, no MultiEffect/layer plumbing involved.
                    ColoredIcon {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        visible: wsPill.isActive || wsPill.isOccupied
                        iconName: (wsPill.isActive || wsPill.isOccupied) ? wsPill.wsIcon : ""
                        tint: wsPill.isActive ? Colors.onAccent : Colors.onBackground
                        opacity: wsPill.isActive ? 1.0 : 0.9
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + wsPill.wsId + '" })')
                        }
                    }
                }
            }
        }

        BarDivider { Layout.alignment: Qt.AlignHCenter; barWidth: 32 }

        Item {
            id: middleZone
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            width: 24

            // Pinned to the actual top of the zone — depends on nothing else
            ColumnLayout {
                id: clockBlock
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 1
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clockTimer.now, "hh")
                        color: Colors.onBackground; font.family: "Pixel Operator"; font.pixelSize: 14; font.bold: true
                        renderType: Text.NativeRendering; horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clockTimer.now, "mm")
                        color: Colors.onBackground; font.family: "Pixel Operator"; font.pixelSize: 14; font.bold: true
                        renderType: Text.NativeRendering; horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 16; height: 1; color: Colors.outlineVariant; antialiasing: false
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clockTimer.now, "dd")
                        color: Colors.onBackground; font.family: "Cozette"; font.pixelSize: 9
                        renderType: Text.NativeRendering; horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clockTimer.now, "MM")
                        color: Colors.onBackground; font.family: "Cozette"; font.pixelSize: 9
                        renderType: Text.NativeRendering; horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clockTimer.now, "yy")
                        color: Colors.onBackground; font.family: "Cozette"; font.pixelSize: 9
                        renderType: Text.NativeRendering; horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Timer {
                id: clockTimer
                property var now: new Date()
                interval: 1000
                running: true
                repeat: true
                onTriggered: now = new Date()
            }

            // Dead center of the WHOLE zone — independent of the clock's
            // height. This is also the application launcher trigger.
            Item {
                id: launcherIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: 24
                height: 24
                z: 2

                ReactiveImage {
                    anchors.fill: parent
                    visible: !launcherArea.containsMouse
                    path: "/home/swami/.cache/quickshell/wizard-idle.png"
                }

                ColoredSprite {
                    anchors.fill: parent
                    visible: launcherArea.containsMouse
                    accentSource: "/home/swami/.cache/quickshell/launcher-accent-spritesheet.png"
                    hoverSource: "/home/swami/.cache/quickshell/launcher-hover-spritesheet.png"
                    frameW: 24
                    frameH: 24
                    chargeFrameCount: 5
                    hoverFrameCount: 5
                    loopHover: true
                    fps: 8
                    hovered: launcherArea.containsMouse
                }

                MouseArea {
                    id: launcherArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: console.log("launcher trigger clicked")
                }
            }

            MediaBarWidget {
                anchors.top: launcherIcon.bottom
                anchors.topMargin: 14
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        BarDivider { Layout.alignment: Qt.AlignHCenter; barWidth: 32 }

    // --- System tray ---
        SystemTray {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
