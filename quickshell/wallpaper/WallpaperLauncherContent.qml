import QtQuick
import QtQuick.Layouts
import Quickshell
import "../bar" as Bar

Item {
    id: content
    property int topOffset: 4
    property int cols: 4
    property int rows: 3
    property int cellSize: 108
    property int cellSpacing: 14

    readonly property int perPage: cols * rows
    readonly property int pageWidth: cols * (cellSize + cellSpacing) - cellSpacing
    readonly property int pageHeight: rows * (cellSize + cellSpacing) - cellSpacing
    readonly property int pageCount: Math.max(1, Math.ceil(WallpaperBackend.wallpapers.length / perPage))
    readonly property int currentPage: pageWidth > 0 ? Math.round(pager.contentX / pageWidth) : 0

    // keyboard selection + pending delete-confirm state
    property int selectedIndex: 0
    property var pendingDelete: null   // {name, path} of a wallpaper awaiting delete confirmation

    implicitWidth: WallpaperLauncher.shown ? bezel.width : 0
    implicitHeight: WallpaperLauncher.shown ? bezel.height : 0
    anchors.centerIn: parent
    opacity: WallpaperLauncher.shown ? 1 : 0
    scale: WallpaperLauncher.shown ? 1 : 0.97
    visible: opacity > 0.01
    z: 6
    focus: true

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: snapAnim
        target: pager
        property: "contentX"
        duration: 260
        easing.type: Easing.OutCubic
    }

    function clampX(x) {
        return Math.max(0, Math.min(pager.contentWidth - pager.width, x));
    }
    function pageBy(delta) {
        snapAnim.stop();
        snapAnim.to = content.clampX(pager.contentX + delta * content.pageWidth);
        snapAnim.restart();
    }
    function snapToNearest() {
        const target = Math.round(pager.contentX / content.pageWidth) * content.pageWidth;
        snapAnim.stop();
        snapAnim.to = content.clampX(target);
        snapAnim.restart();
    }
    function ensureSelectionVisible() {
        const page = Math.floor(content.selectedIndex / content.perPage);
        if (page !== content.currentPage) {
            snapAnim.stop();
            snapAnim.to = content.clampX(page * content.pageWidth);
            snapAnim.restart();
        }
    }
    // moves the keyboard selection by (dx, dy) grid cells, wrapping across pages
    function moveSelection(dx, dy) {
        const total = WallpaperBackend.wallpapers.length;
        if (total === 0)
            return;

        let col = content.selectedIndex % content.cols;
        let row = Math.floor(content.selectedIndex / content.cols) % content.rows;
        let page = Math.floor(content.selectedIndex / content.perPage);

        col += dx;
        row += dy;

        if (col < 0) {
            col = content.cols - 1;
            page -= 1;
        } else if (col >= content.cols) {
            col = 0;
            page += 1;
        }
        if (row < 0) {
            row = content.rows - 1;
            page -= 1;
        } else if (row >= content.rows) {
            row = 0;
            page += 1;
        }

        page = Math.max(0, Math.min(content.pageCount - 1, page));
        let next = page * content.perPage + row * content.cols + col;
        next = Math.max(0, Math.min(total - 1, next));

        content.selectedIndex = next;
        content.ensureSelectionVisible();
    }
    function applySelection() {
        const wp = WallpaperBackend.wallpapers[content.selectedIndex];
        if (!wp)
            return;
        if (WallpaperBackend.isFailed(wp.path)) {
            content.pendingDelete = wp;
        } else {
            WallpaperBackend.apply(wp.path);
            WallpaperLauncher.hide();
        }
    }
    function confirmDelete() {
        if (content.pendingDelete) {
            WallpaperBackend.deleteWallpaper(content.pendingDelete.path);
            content.pendingDelete = null;
        }
    }
    function cancelDelete() {
        content.pendingDelete = null;
    }

    onVisibleChanged: {
        if (visible) {
            content.selectedIndex = 0;
            content.pendingDelete = null;
            content.forceActiveFocus();
        }
    }

    Keys.onPressed: event => {
        // while a delete confirmation is up, y/n/enter/esc are scoped to that dialog
        if (content.pendingDelete !== null) {
            switch (event.key) {
            case Qt.Key_Y:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                content.confirmDelete();
                event.accepted = true;
                return;
            case Qt.Key_N:
            case Qt.Key_Escape:
                content.cancelDelete();
                event.accepted = true;
                return;
            }
            return;
        }

        switch (event.key) {
        case Qt.Key_Escape:
            WallpaperLauncher.hide();
            event.accepted = true;
            break;
        case Qt.Key_H:
        case Qt.Key_Left:
            content.moveSelection(-1, 0);
            event.accepted = true;
            break;
        case Qt.Key_L:
        case Qt.Key_Right:
            content.moveSelection(1, 0);
            event.accepted = true;
            break;
        case Qt.Key_K:
        case Qt.Key_Up:
            content.moveSelection(0, -1);
            event.accepted = true;
            break;
        case Qt.Key_J:
        case Qt.Key_Down:
            content.moveSelection(0, 1);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            content.applySelection();
            event.accepted = true;
            break;
        }
    }

    // soft backdrop stand-in for a drop shadow -- avoids depending on
    // an unverified shadow component, cheap and reliable
    Rectangle {
        anchors.centerIn: parent
        width: panelBox.width + 12
        height: panelBox.height + 12
        radius: 20
        color: Bar.Colors.shadow
        opacity: 0.4
        antialiasing: true
    }

    Item {
        id: bezel
        anchors.centerIn: parent
        width: panelBox.width + 2
        height: panelBox.height + 2

        Item {
            id: panelBox
            anchors.centerIn: parent
            width: content.pageWidth + 64
            height: content.pageHeight + 48
            clip: true

            PixelPanel {
                anchors.fill: parent
                fillColor: Bar.Colors.surfaceContainerLow
                borderColor: Bar.Colors.outlineVariant
                pixelSize: 4
                cornerSteps: 3
            }

            Text {
                anchors.centerIn: parent
                visible: WallpaperBackend.scanning
                text: "Loading wallpapers..."
                font.family: "Cozette"
                font.pixelSize: 11
                color: Bar.Colors.mutedOnBackground
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: pager.verticalCenter
                anchors.leftMargin: 14
                text: "‹"
                font.pixelSize: 22
                font.weight: Font.Light
                color: leftArrowArea.containsMouse ? Bar.Colors.accent : Bar.Colors.mutedOnBackground
                opacity: content.currentPage > 0 ? 1 : 0.2
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
                MouseArea {
                    id: leftArrowArea
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: content.currentPage > 0
                    onClicked: content.pageBy(-1)
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: pager.verticalCenter
                anchors.rightMargin: 14
                text: "›"
                font.pixelSize: 22
                font.weight: Font.Light
                color: rightArrowArea.containsMouse ? Bar.Colors.accent : Bar.Colors.mutedOnBackground
                opacity: content.currentPage < content.pageCount - 1 ? 1 : 0.2
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
                MouseArea {
                    id: rightArrowArea
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: content.currentPage < content.pageCount - 1
                    onClicked: content.pageBy(1)
                }
            }

            Flickable {
                id: pager
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: content.pageWidth
                height: content.pageHeight
                contentWidth: content.pageWidth * content.pageCount
                contentHeight: content.pageHeight
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 4000
                maximumFlickVelocity: 2500
                clip: true

                onMovementEnded: content.snapToNearest()
                onFlickEnded: content.snapToNearest()

                Row {
                    Repeater {
                        model: content.pageCount
                        delegate: Item {
                            id: pageItem
                            width: content.pageWidth
                            height: content.pageHeight
                            property int pageIndex: index

                            Grid {
                                anchors.fill: parent
                                columns: content.cols
                                rowSpacing: content.cellSpacing
                                columnSpacing: content.cellSpacing

                                Repeater {
                                    model: content.perPage
                                    delegate: Item {
                                        id: tile
                                        width: content.cellSize
                                        height: content.cellSize

                                        property int wpIndex: pageItem.pageIndex * content.perPage + index
                                        property var wp: wpIndex < WallpaperBackend.wallpapers.length ? WallpaperBackend.wallpapers[wpIndex] : null
                                        property bool colorsFailed: wp !== null && WallpaperBackend.isFailed(wp.path)
                                        property bool keyboardSelected: tile.wpIndex === content.selectedIndex
                                        visible: wp !== null
                                        scale: tileArea.containsMouse ? 1.03 : 1.0
                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            id: tileFrame
                                            anchors.fill: parent
                                            radius: 10
                                            color: Bar.Colors.surfaceContainer
                                            antialiasing: true
                                            border.width: (tileArea.containsMouse || tile.keyboardSelected) ? 2 : 0
                                            border.color: tile.colorsFailed ? Bar.Colors.error : Bar.Colors.accent
                                            Behavior on border.width {
                                                NumberAnimation {
                                                    duration: 140
                                                }
                                            }

                                            // fixed inset keeps the image's square corners tucked
                                            // safely behind the frame's rounded curve -- no per-image
                                            // clip mask needed
                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 3
                                                source: tile.wp ? "file://" + tile.wp.path : ""
                                                fillMode: Image.PreserveAspectCrop
                                                smooth: true
                                                asynchronous: true
                                                sourceSize.width: content.cellSize
                                                sourceSize.height: content.cellSize
                                                opacity: tile.colorsFailed ? 0.45 : 1.0
                                            }
                                        }

                                        // warning badge for wallpapers wallust couldn't palette
                                        Rectangle {
                                            visible: tile.colorsFailed
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: Bar.Colors.textOnError
                                            antialiasing: true
                                            Text {
                                                anchors.centerIn: parent
                                                text: "!"
                                                font.family: "Cozette"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: Bar.Colors.onError
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            height: 22
                                            radius: 6
                                            color: Bar.Colors.shadow
                                            opacity: tileArea.containsMouse ? 0.85 : 0
                                            visible: opacity > 0.01
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 140
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: tile.wp ? (tile.colorsFailed ? tile.wp.name + " (no colors)" : tile.wp.name) : ""
                                                color: Bar.Colors.textOnBackground
                                                font.family: "Cozette"
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                                width: parent.width - 10
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        MouseArea {
                                            id: tileArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                content.selectedIndex = tile.wpIndex;
                                                if (tile.colorsFailed) {
                                                    content.pendingDelete = tile.wp;
                                                } else {
                                                    WallpaperBackend.apply(tile.wp.path);
                                                    WallpaperLauncher.hide();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: pager
                z: 5
                acceptedButtons: Qt.NoButton
                hoverEnabled: false
                onWheel: event => {
                    if (!wheelCooldown.running) {
                        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                        content.pageBy(delta < 0 ? 1 : -1);
                        wheelCooldown.restart();
                    }
                    event.accepted = true;
                }
            }
            Timer {
                id: wheelCooldown
                interval: 350
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 14
                spacing: 6
                Repeater {
                    model: content.pageCount
                    delegate: Rectangle {
                        width: index === content.currentPage ? 16 : 5
                        height: 5
                        radius: 0
                        antialiasing: false
                        color: index === content.currentPage ? Bar.Colors.accent : Bar.Colors.outlineVariant
                        Behavior on width {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            // delete-confirmation overlay for wallpapers with no generated palette
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: content.pendingDelete !== null ? 0.6 : 0
                visible: opacity > 0.01
                z: 10
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: content.cancelDelete()
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 280
                height: 120
                radius: 12
                color: Bar.Colors.surfaceContainerLow
                border.width: 1
                border.color: Bar.Colors.outlineVariant
                visible: content.pendingDelete !== null
                z: 11
                antialiasing: true

                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    width: parent.width - 32

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: content.pendingDelete ? "Couldn't generate colors for \"" + content.pendingDelete.name + "\". Delete it?" : ""
                        font.family: "Cozette"
                        font.pixelSize: 11
                        color: Bar.Colors.textOnBackground
                    }

                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: 80
                            height: 28
                            radius: 6
                            color: Bar.Colors.error
                            Text {
                                anchors.centerIn: parent
                                text: "Delete (Y)"
                                font.family: "Cozette"
                                font.pixelSize: 10
                                color: Bar.Colors.textOnError
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: content.confirmDelete()
                            }
                        }
                        Rectangle {
                            width: 80
                            height: 28
                            radius: 6
                            color: Bar.Colors.surfaceContainer
                            border.width: 1
                            border.color: Bar.Colors.outlineVariant
                            Text {
                                anchors.centerIn: parent
                                text: "Cancel (N)"
                                font.family: "Cozette"
                                font.pixelSize: 10
                                color: Bar.Colors.textOnBackground
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: content.cancelDelete()
                            }
                        }
                    }
                }
            }
        }
    }
}
