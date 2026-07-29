import Quickshell
import Quickshell.Wayland
import QtQuick
import "."
import "../wallpaper"
import "../launcher"

Scope {
    id: manager

    property int barWidth: 32
    property int borderThickness: 4
    property color frameColor: Colors.background
    property color accentColor: Colors.outline

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Item {
                id: screenRoot
                required property var modelData

                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-left"
                    anchors {
                        top: true
                        bottom: true
                        left: true
                    }
                    implicitWidth: manager.barWidth
                    exclusiveZone: manager.barWidth
                    color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-top"
                    anchors {
                        top: true
                        left: true
                        right: true
                    }
                    margins.left: manager.barWidth
                    implicitHeight: manager.borderThickness
                    exclusiveZone: manager.borderThickness
                    color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-bottom"
                    anchors {
                        bottom: true
                        left: true
                        right: true
                    }
                    margins.left: manager.barWidth
                    implicitHeight: manager.borderThickness
                    exclusiveZone: manager.borderThickness
                    color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-right"
                    anchors {
                        top: true
                        bottom: true
                        right: true
                    }
                    implicitWidth: manager.borderThickness
                    exclusiveZone: manager.borderThickness
                    color: "transparent"
                }

                PanelWindow {
                    id: frame
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:frame"
                    exclusionMode: ExclusionMode.Ignore
                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }
                    color: "transparent"

                    property bool anyPanelShown: WallpaperLauncher.shown || AppLauncher.shown || PowerMenu.shown || WifiPanel.shown || BatteryPanel.shown || TrayMenu.shown || MediaPanel.shown || BluetoothPanel.shown

                    WlrLayershell.keyboardFocus: anyPanelShown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                    mask: Region {
                        Region {
                            item: barArea
                        }
                        Region {
                            item: bluetoothPanelContent
                        }
                        Region {
                            item: dimScrim
                        }
                        Region {
                            item: powerMenuContent
                        }
                        Region {
                            item: wifiPanelContent
                        }
                        Region {
                            item: wifiClickCatcher
                        }
                        Region {
                            item: batteryPanelContent
                        }
                        Region {
                            item: batteryClickCatcher
                        }
                        Region {
                            item: trayMenuContent
                        }
                        Region {
                            item: trayMenuClickCatcher
                        }
                        Region {
                            item: mediaPanelContent
                        }
                        Region {
                            item: mediaClickCatcher
                        }
                        Region {
                            item: wallpaperLauncherContent
                        }
                        Region {
                            item: wallpaperClickCatcher
                        }
                        Region {
                            item: appLauncherContent
                        }
                        Region {
                            item: appLauncherDimScrim
                        }
                        Region {
                            item: appLauncherClickCatcher
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: manager.borderThickness
                        color: manager.frameColor
                        antialiasing: false
                    }
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: manager.borderThickness
                        color: manager.frameColor
                        antialiasing: false
                        z: 5
                    }
                    Rectangle {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                        }
                        width: manager.borderThickness
                        color: manager.frameColor
                        antialiasing: false
                        z: 5
                    }

                    Rectangle {
                        id: dimScrim
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: PowerMenu.shown ? parent.width : 0
                        height: PowerMenu.shown ? parent.height : 0
                        color: "black"
                        opacity: PowerMenu.shown ? 0.55 : 0
                        visible: PowerMenu.shown
                        antialiasing: false
                        z: 3

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: PowerMenu.hide()
                        }
                    }

                    Rectangle {
                        id: batteryClickCatcher
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: BatteryPanel.shown ? parent.width : 0
                        height: BatteryPanel.shown ? parent.height : 0
                        color: "transparent"
                        antialiasing: false
                        z: 3
                        MouseArea {
                            anchors.fill: parent
                            onClicked: BatteryPanel.hide()
                        }
                    }

                    Rectangle {
                        id: wifiClickCatcher
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: WifiPanel.shown ? parent.width : 0
                        height: WifiPanel.shown ? parent.height : 0
                        color: "transparent"
                        antialiasing: false
                        z: 3

                        MouseArea {
                            anchors.fill: parent
                            onClicked: WifiPanel.hide()
                        }
                    }

                    Rectangle {
                        id: trayMenuClickCatcher
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: TrayMenu.shown ? parent.width : 0
                        height: TrayMenu.shown ? parent.height : 0
                        color: "transparent"
                        antialiasing: false
                        z: 9
                        MouseArea {
                            anchors.fill: parent
                            onClicked: TrayMenu.hide()
                        }
                    }

                    Rectangle {
                        id: mediaClickCatcher
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: MediaPanel.shown ? parent.width : 0
                        height: MediaPanel.shown ? parent.height : 0
                        color: "transparent"
                        antialiasing: false
                        z: 3
                        MouseArea {
                            anchors.fill: parent
                            onClicked: MediaPanel.hide()
                        }
                    }

                    Rectangle {
                        id: wallpaperClickCatcher
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: WallpaperLauncher.shown ? parent.width : 0
                        height: WallpaperLauncher.shown ? parent.height : 0
                        color: "transparent"
                        antialiasing: false
                        z: 3
                        MouseArea {
                            anchors.fill: parent
                            onClicked: WallpaperLauncher.hide()
                        }
                    }

                    Bar {
                        id: barArea
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        barWidth: manager.barWidth
                    }

                    // 4. new scrim + click catcher + content instance — insert right before `Bar { id: barArea ... }`
                    Rectangle {
                        id: appLauncherDimScrim
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: AppLauncher.shown ? parent.width : 0
                        height: AppLauncher.shown ? parent.height : 0
                        color: "black"
                        opacity: AppLauncher.shown ? 0.55 : 0
                        visible: AppLauncher.shown
                        antialiasing: false
                        z: 3

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: AppLauncher.hide()
                        }
                    }

                    Rectangle {
                        id: appLauncherClickCatcher
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: AppLauncher.shown ? parent.width : 0
                        height: AppLauncher.shown ? parent.height : 0
                        color: "transparent"
                        antialiasing: false
                        z: 3
                        MouseArea {
                            anchors.fill: parent
                            onClicked: AppLauncher.hide()
                        }
                    }

                    BluetoothPanelContent {
                        id: bluetoothPanelContent
                    }

                    PowerMenuContent {
                        id: powerMenuContent
                    }

                    WifiPanelContent {
                        id: wifiPanelContent
                    }

                    BatteryPanelContent {
                        id: batteryPanelContent
                    }

                    MediaPanelContent {
                        id: mediaPanelContent
                    }

                    WallpaperLauncherContent {
                        id: wallpaperLauncherContent
                        topOffset: manager.borderThickness
                    }

                    // also add the content instance, right after WallpaperLauncherContent { ... }
                    AppLauncherContent {
                        id: appLauncherContent
                    }

                    CornerAccent {
                        corner: "topLeft"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: manager.barWidth
                        anchors.topMargin: manager.borderThickness
                        z: 10
                    }
                    CornerAccent {
                        corner: "bottomLeft"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: manager.barWidth
                        anchors.bottomMargin: manager.borderThickness
                        z: 10
                    }
                    CornerAccent {
                        corner: "topRight"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: manager.borderThickness
                        anchors.topMargin: manager.borderThickness
                        z: 10
                    }
                    CornerAccent {
                        corner: "bottomRight"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: manager.borderThickness
                        anchors.bottomMargin: manager.borderThickness
                        z: 10
                    }

                    TrayMenuContent {
                        id: trayMenuContent
                    }

                    Item {
                        id: keyCatcher
                        anchors.fill: parent

                        Connections {
                            target: frame
                            function onAnyPanelShownChanged() {
                                if (frame.anyPanelShown)
                                    keyCatcher.forceActiveFocus();
                            }
                        }

                        Keys.onEscapePressed: {
                            if (WallpaperLauncher.shown)
                                WallpaperLauncher.hide();
                            else if (AppLauncher.shown)
                                AppLauncher.hide();
                            else if (PowerMenu.shown)
                                PowerMenu.hide();
                            else if (WifiPanel.shown)
                                WifiPanel.hide();
                            else if (BatteryPanel.shown)
                                BatteryPanel.hide();
                            else if (TrayMenu.shown)
                                TrayMenu.hide();
                            else if (MediaPanel.shown)
                                MediaPanel.hide();
                            else if (BluetoothPanel.shown)
                                BluetoothPanel.hide();
                        }
                    }
                }
            }
        }
    }
}
