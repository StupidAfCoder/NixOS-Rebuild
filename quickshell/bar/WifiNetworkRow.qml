import QtQuick
import QtQuick.Layouts

Item {
    id: row
    required property var modelData
    property color accent: Colors.accent
    property bool expanded: false
    property string passwordDraft: ""

    readonly property string ssid: modelData.ssid
    readonly property int signalPct: modelData.signal
    readonly property bool secured: modelData.secured
    readonly property bool inUse: modelData.inUse

    width: ListView.view ? ListView.view.width : 200
    height: expanded ? 66 : 26

    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    clip: true

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 26
        color: mainArea.containsMouse ? Colors.surfaceContainer : "transparent"
        antialiasing: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 6
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 4

            Text {
                text: "\u25b6"
                color: row.accent
                font.pixelSize: 8
                opacity: mainArea.containsMouse || row.expanded ? 1.0 : 0.0
                Layout.preferredWidth: 10
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            RowLayout {
                spacing: 1
                Layout.preferredWidth: 16
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        required property int index
                        width: 3
                        height: 4 + index * 3
                        Layout.alignment: Qt.AlignBottom
                        antialiasing: false
                        color: (row.signalPct >= (index + 1) * 25)
                            ? (row.inUse ? row.accent : Colors.mutedOnBackground)
                            : Colors.surfaceContainerHigh
                    }
                }
            }

            Text {
                text: row.ssid
                color: row.inUse ? row.accent : Colors.mutedOnBackground
                font.family: "Cozette"
                font.pixelSize: 9
                font.letterSpacing: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            ColoredIcon {
                visible: row.secured
                Layout.preferredWidth: 9
                Layout.preferredHeight: 9
                iconName: "lock.svg"
                tint: Colors.mutedOnBackground
            }

            Text {
                visible: row.inUse
                text: "\u2713"
                color: Colors.success
                font.pixelSize: 9
            }
        }

        Item {
            visible: row.expanded
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            RowLayout {
                anchors.fill: parent
                spacing: 4
                visible: !row.inUse

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    color: Colors.shadow
                    border.color: Colors.outlineVariant
                    border.width: 1
                    antialiasing: false
                    visible: row.secured

                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: Colors.onBackground
                        font.family: "Cozette"
                        font.pixelSize: 9
                        echoMode: TextInput.Password
                        clip: true
                        onTextChanged: row.passwordDraft = text
                        Keys.onReturnPressed: connectBtn.doConnect()
                    }
                }

                Rectangle {
                    id: connectBtn
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 20
                    color: connectArea.containsMouse ? row.accent : "transparent"
                    border.color: row.accent
                    border.width: 1
                    antialiasing: false

                    function doConnect() {
                        NetworkBackend.connectToNetwork(row.ssid, row.secured ? row.passwordDraft : "")
                        row.expanded = false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "LINK"
                        color: connectArea.containsMouse ? Colors.background : row.accent
                        font.family: "Cozette"
                        font.pixelSize: 8
                    }
                    MouseArea {
                        id: connectArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: connectBtn.doConnect()
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 4
                visible: row.inUse

                Text {
                    text: NetworkBackend.wifiIp !== "" ? NetworkBackend.wifiIp : "no ip"
                    color: Colors.mutedOnBackground
                    font.family: "Cozette"
                    font.pixelSize: 8
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 20
                    color: forgetArea.containsMouse ? Colors.error : "transparent"
                    border.color: Colors.error
                    border.width: 1
                    antialiasing: false

                    Text {
                        anchors.centerIn: parent
                        text: "FORGET"
                        color: forgetArea.containsMouse ? Colors.background : Colors.error
                        font.family: "Cozette"
                        font.pixelSize: 8
                    }
                    MouseArea {
                        id: forgetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkBackend.forgetNetwork(row.ssid)
                    }
                }
            }
        }
    }

    MouseArea {
        id: mainArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 26
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.expanded = !row.expanded
        z: 5
    }
}