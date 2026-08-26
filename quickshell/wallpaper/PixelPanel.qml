// PixelPanel.qml
import QtQuick

Item {
    id: root
    property color fillColor: "black"
    property color borderColor: "white"
    property int borderThickness: 3   // in "pixels"
    property int pixelSize: 4         // size of one logical pixel
    property int cornerSteps: 3       // stair-steps per corner
    onFillColorChanged: canvas.requestPaint()
    onBorderColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.imageSmoothingEnabled = false;

            const w = width, h = height, px = root.pixelSize, steps = root.cornerSteps;
            const bt = root.borderThickness * px;

            function stepPath(inset) {
                ctx.beginPath();
                const x0 = inset, y0 = inset, x1 = w - inset, y1 = h - inset;
                const cut = steps * px;

                ctx.moveTo(x0 + cut, y0);
                ctx.lineTo(x1 - cut, y0);

                // top-right (unchanged — this one was already correct)
                for (let i = 0; i < steps; i++) {
                    ctx.lineTo(x1 - cut + i * px, y0 + i * px);
                    ctx.lineTo(x1 - cut + (i + 1) * px, y0 + i * px);
                }
                ctx.lineTo(x1, y0 + cut);
                ctx.lineTo(x1, y1 - cut);

                // bottom-right — was diagonal-jumping, now alternates down/left
                for (let i = 0; i < steps; i++) {
                    ctx.lineTo(x1 - i * px, y1 - cut + (i + 1) * px);
                    ctx.lineTo(x1 - (i + 1) * px, y1 - cut + (i + 1) * px);
                }
                ctx.lineTo(x0 + cut, y1);

                // bottom-left (unchanged — this one was already correct)
                for (let i = 0; i < steps; i++) {
                    ctx.lineTo(x0 + cut - i * px, y1 - i * px);
                    ctx.lineTo(x0 + cut - (i + 1) * px, y1 - i * px);
                }
                ctx.lineTo(x0, y1 - cut);
                ctx.lineTo(x0, y0 + cut);

                // top-left — was diagonal-jumping, now alternates up/right
                for (let i = 0; i < steps; i++) {
                    ctx.lineTo(x0 + i * px, y0 + cut - (i + 1) * px);
                    ctx.lineTo(x0 + (i + 1) * px, y0 + cut - (i + 1) * px);
                }
                ctx.closePath();
            }

            stepPath(0);
            ctx.fillStyle = root.borderColor;
            ctx.fill();

            stepPath(bt);
            ctx.fillStyle = root.fillColor;
            ctx.fill();
        }
    }
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
}
