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

    // LAYOUT PROXY ANIMATION
    property int currentBottomMargin: AppLauncher.shown ? dockGap : -(bezel.height + 40)

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: currentBottomMargin
    implicitWidth: bezel.width
    implicitHeight: bezel.height

    // MASSIVE Z-INDEX: Forces it above ShellFrame's dimScrim (z:3) and corners (z:10)
    z: 100

    // CRT Power-on Animation
    visible: opacity > 0.01
    opacity: AppLauncher.shown ? 1 : 0
    scale: AppLauncher.shown ? 1.0 : 0.90
    transformOrigin: Item.Bottom

    Behavior on currentBottomMargin {
        NumberAnimation {
            duration: 340
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }
    }

    // FOCUS STEALER: Overrides the keyCatcher in your ShellFrame
    Timer {
        id: focusStealer
        interval: 50
        running: false
        onTriggered: searchField.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible)
            focusStealer.start();
    }

    Connections {
        target: AppLauncher
        function onShownChanged() {
            if (AppLauncher.shown) {
                searchField.text = "";
                // FORCE A CLEAN REBUILD: Fixes the delegate overlapping bug
                content.refreshApps(true);
            } else {
                // FLUSH MEMORY ON HIDE: Prevents frozen transitions
                appsModel.clear();
            }
        }
    }

    function keyFor(e) {
        return (e && e.id !== undefined && e.id !== "") ? e.id : (e ? e.name : "");
    }

    ListModel {
        id: appsModel
    }

    function refreshApps(instant = false) {
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

        // INSTANT REBUILD PATH (Fixes Overlap Bug)
        if (instant) {
            appsModel.clear();
            for (var i = 0; i < result.length; i++) {
                appsModel.append({
                    key: keyFor(result[i]),
                    appRef: result[i]
                });
            }
            content.selectedIndex = appsModel.count > 0 ? 0 : -1;
            listView.positionViewAtIndex(0, ListView.Beginning);
            return;
        }

        // DIFFING PATH (Smooth filtering while typing)
        var resultKeys = result.map(keyFor);

        for (var idx = appsModel.count - 1; idx >= 0; idx--) {
            if (resultKeys.indexOf(appsModel.get(idx).key) === -1)
                appsModel.remove(idx);
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

        // Corner structural pixels
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
            color: Qt.rgba(Bar.Colors.background.r, Bar.Colors.background.g, Bar.Colors.background.b, 0.85)
            antialiasing: false
            clip: true

            // HARDWARE SCANLINES
            Column {
                anchors.fill: parent
                spacing: 2
                z: 10
                Repeater {
                    model: Math.ceil(panelBox.height / 3)
                    delegate: Rectangle {
                        width: panelBox.width
                        height: 1
                        color: Bar.Colors.textOnBackground
                        opacity: 0.04
                    }
                }
            }

            // Outline Box
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
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Console Input Prefix
                        Text {
                            text: ">"
                            color: Bar.Colors.accent
                            font.family: "Cozette"
                            font.pixelSize: 10
                            font.bold: true
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
                                text: "SYSTEM.QUERY_APPS(" + content.totalAppsCount + ")"
                                font: searchField.font
                                color: Bar.Colors.mutedOnBackground
                                opacity: 0.5
                                visible: searchField.text.length === 0
                            }

                            onTextChanged: {
                                content.refreshApps(false);
                            }

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

                            cursorVisible: true
                            cursorDelegate: Component {
                                Rectangle {
                                    width: 6
                                    height: 10
                                    color: Bar.Colors.accent
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: 0.0
                                            duration: 400
                                        }
                                        NumberAnimation {
                                            to: 1.0
                                            duration: 400
                                        }
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
                text: "ERR: NO TARGET FOUND"
                font.family: "Cozette"
                font.pixelSize: 10
                font.letterSpacing: 1
                color: Bar.Colors.error
                z: 4
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
                            duration: Math.min(ViewTransition.index * 15, 150)
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 100
                            }
                            NumberAnimation {
                                property: "x"
                                from: -10
                                to: 0
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 50
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                delegate: Item {
                    id: row
                    width: listView.width
                    height: content.rowHeight
                    property var app: model.appRef
                    property bool isSelected: index === content.selectedIndex
                    property bool active: rowArea.containsMouse || row.isSelected

                    // Inverted Row Highlight
                    Rectangle {
                        anchors.fill: parent
                        color: Bar.Colors.surfaceContainerHigh
                        opacity: row.active ? 0.4 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 12
                        spacing: 12

                        // JRPG Menu Cursor
                        Text {
                            text: "[▶]"
                            font.family: "Cozette"
                            font.pixelSize: 10
                            color: Bar.Colors.accent
                            Layout.preferredWidth: 20
                            opacity: row.isSelected ? 1 : 0

                            SequentialAnimation on x {
                                loops: Animation.Infinite
                                running: row.isSelected
                                NumberAnimation {
                                    to: 2
                                    duration: 300
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    to: 0
                                    duration: 300
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }

                        Item {
                            Layout.preferredWidth: content.iconSize + 10
                            Layout.preferredHeight: content.iconSize + 10

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: 1
                                border.color: row.active ? Bar.Colors.accent : Bar.Colors.outlineVariant
                                antialiasing: false
                            }

                            PixelAppIcon {
                                anchors.centerIn: parent
                                width: content.iconSize
                                height: content.iconSize
                                iconSource: row.app ? Quickshell.iconPath(row.app.icon, "application-x-executable") : ""
                                opacity: row.active ? 1.0 : 0.7
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: row.app ? row.app.name.toUpperCase() : ""
                                color: row.active ? Bar.Colors.accent : Bar.Colors.textOnBackground
                                font.family: "Cozette"
                                font.pixelSize: 10
                                font.letterSpacing: 1
                                font.bold: row.active
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
