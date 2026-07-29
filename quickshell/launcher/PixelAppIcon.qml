import QtQuick

Image {
    id: root
    property alias iconSource: root.source
    // Number of "pixels" along the longest edge before blow-up.
    // 12-16 = strong pixel-art look, still identifiable.
    // 20-28 = subtler, closer to the source icon.
    property int pixelResolution: 28

    fillMode: Image.PreserveAspectFit
    smooth: false
    mipmap: false
    cache: true
    asynchronous: true

    sourceSize.width: pixelResolution
    sourceSize.height: pixelResolution
}
