import QtQuick
import "../bar"

Item {
    id: root
    property url iconSource: ""
    property int pixelResolution: 28
    ColoredIcon { anchors.fill: parent; iconName: "app-windows.svg"; tint: Colors.accent; visible: image.status !== Image.Ready }
    Image {
        id: image
        anchors.fill: parent
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: false; mipmap: false; cache: true; asynchronous: true
        sourceSize.width: root.pixelResolution; sourceSize.height: root.pixelResolution
    }
}
