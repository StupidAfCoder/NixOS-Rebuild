import QtQuick
import Quickshell.Io
import "../common"

Item {
    id: root
    property string path: ""
    property url fallbackSource: ""
    implicitWidth: 24
    implicitHeight: 24
    function reload() { image.source = ""; image.source = Settings.fileUrl(path); }
    Image {
        anchors.fill: parent
        source: root.fallbackSource
        visible: image.status !== Image.Ready
        fillMode: Image.PreserveAspectFit
        smooth: false
    }
    Image {
        id: image
        anchors.fill: parent
        source: Settings.fileUrl(root.path)
        fillMode: Image.PreserveAspectFit
        smooth: false; cache: false
        visible: status === Image.Ready
    }
    FileView {
        path: root.path; watchChanges: true
        onFileChanged: root.reload()
    }
}
