import QtQuick
import Quickshell.Io
import "../bar"
Rectangle {
    id: root
    implicitWidth: 64; implicitHeight: 64
    color: Colors.surfaceContainerHigh
    border.color: Colors.outlineVariant
    PixelText { anchors.centerIn: parent; text: Settings.displayName.substring(0,1).toUpperCase(); font.pixelSize: Math.round(root.height / 2) }
    Image {
        id: image
        anchors.fill: parent; anchors.margins: 2
        source: Settings.fileUrl(Settings.avatarPath)
        cache: false; asynchronous: true; fillMode: Image.PreserveAspectCrop
    }
    FileView {
        path: Settings.avatarPath; watchChanges: true
        onFileChanged: { image.source = ""; image.source = Settings.fileUrl(Settings.avatarPath); }
    }
}
