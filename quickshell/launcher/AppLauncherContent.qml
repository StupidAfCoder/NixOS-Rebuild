import QtQuick
import QtQuick.Layouts
import Quickshell
import "../bar" as Bar

Item {
    id: content

    property int rowHeight: 48
    property int visibleRows: 6
    property int iconSize: 26
    property int headerHeight: 40
    property int panelWidth: 440
    property int dockGap: 10

    readonly property int listHeight: rowHeight * visibleRows

    property int selectedIndex: -1
    property int totalAppsCount: 0

    // PROXY PROPERTY FOR LAYOUT ENGINE ANIMATION
    property int currentBottomMargin: AppLauncher.shown ? dockGap : -(bezel.height + 40)

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: currentBottomMargin
    implicitWidth: bezel.width
    implicitHeight: bezel.height
    opacity: AppLauncher.shown ? 1 : 0
    visible: opacity > 0.01
    z: 6

    Behavior on currentBottomMargin {
        NumberAnimation {
            duration: 340
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(function () {
                searchField.forceActiveFocus();
            });
    }

    Connections {
        target: AppLauncher
        function onShownChanged() {
            if (AppLauncher.shown) {
                searchField.text = "";
                content.refreshApps();
            }
        }
    }

    // stable identity for diffing
    function keyFor(e) {
        return (e && e.id !== undefined && e.id !== "") ? e.id : (e ? e.name : "");
    }

    ListModel {
        id: appsModel
    }

    function refreshApps() {
        var all = [...DesktopEntries.applications.values].filter(function (e) {
            return e && e.name && !e.noDisplay;
        }).sort(function (a, b) {
            return a.name.localeCompare(b.name);
        });

        content.totalAppsCount = all.length;

        var q = searchField.text.trim().toLowerCase();
        var result;
        if (q.length === 0) {
            result = all;
        } else {
            result = all.filter(function (e) {
                var name = (e.name || "").toLowerCase();
                var comment = (e.comment || "").toLowerCase();
                var generic = (e.genericName || "").toLowerCase();
                return name.indexOf(q) !== -1 || comment.indexOf(q) !== -1 || generic.indexOf(q) !== -1;
            }).sort(function (a, b) {
                var an = a.name.toLowerCase().indexOf(q) === 0 ? 0 : 1;
                var bn = b.name.toLowerCase().indexOf(q) === 0 ? 0 : 1;
                if (an !== bn)
                    return an - bn;
                return a.name.localeCompare(b.name);
            });
        }

        var resultKeys = result.map(keyFor);

        for (var i = appsModel.count - 1; i >= 0; i--) {
            if (resultKeys.indexOf(appsModel.get(i).key) === -1)
                appsModel.remove(i);
        }

        for (var j = 0; j < result.length; j++) {
            var key = resultKeys[j];
            var curIndex = -1;
            for (var k = 0; k < appsModel.count; k++) {
                if (appsModel.get(k).key === key) {
                    curIndex = k;
                    break;
                }
            }
            if (curIndex === -1) {
                appsModel.insert(j, {
                    key: key,
                    appRef: result[j]
                });
            } else if (curIndex !== j) {
                appsModel.move(curIndex, j, 1);
            }
        }

        content.selectedIndex = appsModel.count > 0 ? 0 : -1;
        listView.positionViewAtIndex(0, ListView.Beginning);
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        AppLauncher.hide();
    }

    function moveSelection(delta) {
        if (appsModel.count === 0)
            return;
        var next = content.selectedIndex < 0 ? 0 : content.selectedIndex + delta;
        next = Math.max(0, Math.min(appsModel.count - 1, next));
        content.selectedIndex = next;
        listView.positionViewAtIndex(next, ListView.Contain);
    }

    Rectangle {
        id: bezel
        width: panelBox.width + 12
        height: panelBox.height + 12
        color: Bar.Colors.shadow
        antialiasing: false

        Repeater {
            model: [
                {
                    x: 3,
                    y: 3
                },
                {
                    x: bezel.width - 5,
                    y: 3
                },
                {
                    x: 3,
                    y: bezel.height - 5
                },
                {
                    x: bezel.width - 5,
                    y: bezel.height - 5
                }
            ]
            delegate: Rectangle {
                x: modelData.x
                y: modelData.y
                width: 2
                height: 2
                color: Bar.Colors.outline
                antialiasing: false
            }
        }

        Rectangle {
            id: panelBox
            anchors.centerIn: parent
            width: content.panelWidth
            height: content.headerHeight + content.listHeight + 40
            color: Qt.rgba(Bar.Colors.background.r, Bar.Colors.background.g, Bar.Colors.background.b, 0.72)
            antialiasing: false
            clip: true

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Bar.Colors.outlineVariant
            }
            Rectangle {
                anchors.left: parent.left
                height: parent.height
                width: 1
                color: Bar.Colors.outlineVariant
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Bar.Colors.outlineVariant
            }
            Rectangle {
                anchors.right: parent.right
                height: parent.height
                width: 1
                color: Bar.Colors.outlineVariant
            }

            Column {
                anchors.fill: parent
                spacing: 2
                Repeater {
                    model: Math.ceil(panelBox.height / 3)
                    delegate: Rectangle {
                        width: panelBox.width
                        height: 1
                        color: Bar.Colors.textOnBackground
                        opacity: 0.02
                    }
                }
            }

            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                height: content.headerHeight
                z: 4

                Rectangle {
                    id: searchBox
                    anchors.fill: parent
                    color: Bar.Colors.surfaceContainer
                    antialiasing: false

                    SequentialAnimation {
                        id: searchFlickerAnim
                        NumberAnimation {
                            target: searchBox
                            property: "opacity"
                            to: 0.55
                            duration: 35
                        }
                        NumberAnimation {
                            target: searchBox
                            property: "opacity"
                            to: 1.0
                            duration: 90
                        }
                    }

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: 1
                        color: Bar.Colors.outlineVariant
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Bar.Colors.outlineVariant
                    }
                    Rectangle {
                        anchors.left: parent.left
                        height: parent.height
                        width: 1
                        color: Bar.Colors.outlineVariant
                    }
                    Rectangle {
                        anchors.right: parent.right
                        height: parent.height
                        width: 1
                        color: Bar.Colors.outlineVariant
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Bar.ColoredIcon {
                            Layout.preferredWidth: 10
                            Layout.preferredHeight: 10
                            iconName: "search.svg"
                            tint: Bar.Colors.mutedOnBackground
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Bar.Colors.textOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            clip: true
                            selectByMouse: true
                            focus: true

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "SEARCH FROM " + content.totalAppsCount + " APPS"
                                font: searchField.font
                                color: Bar.Colors.mutedOnBackground
                                opacity: 0.5
                                visible: searchField.text.length === 0
                            }

                            onTextChanged: {
                                content.refreshApps();
                                searchFlickerAnim.restart();
                            }

                            // FIXED SIGNAL HANDLER: standard block execution
                            Keys.onPressed: {
                                if (event.key === Qt.Key_Escape) {
                                    AppLauncher.hide();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (content.selectedIndex >= 0)
                                        content.launch(appsModel.get(content.selectedIndex).appRef);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    content.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    content.moveSelection(-1);
                                    event.accepted = true;
                                }
                            }

                            cursorVisible: false
                            Rectangle {
                                x: searchField.positionToRectangle(searchField.cursorPosition).x
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                height: 11
                                color: Bar.Colors.accent
                                visible: searchField.activeFocus
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 0.0
                                        duration: 500
                                    }
                                    NumberAnimation {
                                        to: 1.0
                                        duration: 500
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.top: header.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: 1
                color: Bar.Colors.surfaceContainerHigh
                antialiasing: false
                z: 4
            }

            Text {
                anchors.centerIn: listView
                visible: appsModel.count === 0
                text: "NO APPS FOUND"
                font.family: "Cozette"
                font.pixelSize: 10
                font.letterSpacing: 1
                color: Bar.Colors.mutedOnBackground
                z: 4
                opacity: visible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            ListView {
                id: listView
                anchors.top: header.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                height: content.listHeight
                clip: true
                model: appsModel
                spacing: 2
                z: 3

                add: Transition {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: Math.min(ViewTransition.index * 12, 120)
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 140
                            }
                            NumberAnimation {
                                property: "x"
                                from: 24
                                to: 0
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 110
                        }
                        NumberAnimation {
                            property: "x"
                            from: 0
                            to: -24
                            duration: 130
                            easing.type: Easing.InCubic
                        }
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                delegate: Item {
                    id: row
                    width: listView.width
                    height: content.rowHeight
                    property var app: model.appRef
                    property bool isSelected: index === content.selectedIndex
                    property bool active: rowArea.containsMouse || row.isSelected

                    property real blinkOpacity: 1

                    // FIXED SCOPE: Animation is attached correctly to the Item scope
                    SequentialAnimation on blinkOpacity {
                        running: row.isSelected
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.35
                            duration: 280
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 280
                        }
                        onStopped: row.blinkOpacity = 1
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: Bar.Colors.accent
                        antialiasing: false
                        visible: row.active
                        // BINDING: Dynamically pull the animated property from the parent scope
                        opacity: row.isSelected ? row.blinkOpacity : 1
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 12

                        Item {
                            Layout.preferredWidth: content.iconSize + 10
                            Layout.preferredHeight: content.iconSize + 10

                            Rectangle {
                                anchors.fill: parent
                                color: row.active ? Bar.Colors.surfaceContainerHigh : Bar.Colors.surfaceContainer
                                border.width: 1
                                border.color: Bar.Colors.outlineVariant
                                antialiasing: false
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            Bar.CornerAccent {
                                corner: "topLeft"
                                thickness: 1
                                sizeScale: 2
                                color: row.active ? Bar.Colors.accent : Bar.Colors.outline
                                anchors.top: parent.top
                                anchors.left: parent.left
                            }
                            Bar.CornerAccent {
                                corner: "topRight"
                                thickness: 1
                                sizeScale: 2
                                color: row.active ? Bar.Colors.accent : Bar.Colors.outline
                                anchors.top: parent.top
                                anchors.right: parent.right
                            }
                            Bar.CornerAccent {
                                corner: "bottomLeft"
                                thickness: 1
                                sizeScale: 2
                                color: row.active ? Bar.Colors.accent : Bar.Colors.outline
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                            }
                            Bar.CornerAccent {
                                corner: "bottomRight"
                                thickness: 1
                                sizeScale: 2
                                color: row.active ? Bar.Colors.accent : Bar.Colors.outline
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                            }

                            PixelAppIcon {
                                anchors.centerIn: parent
                                width: content.iconSize
                                height: content.iconSize
                                iconSource: row.app ? Quickshell.iconPath(row.app.icon, "application-x-executable") : ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: row.app ? row.app.name : ""
                                color: row.active ? Bar.Colors.accent : Bar.Colors.textOnBackground
                                font.family: "Cozette"
                                font.pixelSize: 10
                                font.letterSpacing: 1
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: row.app ? (row.app.genericName || row.app.comment || "") : ""
                                color: Bar.Colors.mutedOnBackground
                                opacity: 0.65
                                font.family: "Cozette"
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: content.selectedIndex = index
                        onClicked: content.launch(row.app)
                    }
                }
            }
        }
    }
}
