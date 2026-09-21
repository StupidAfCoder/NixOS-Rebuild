.pragma library
// Origins are window-local, never compositor-global (which may be negative).
function popupY(viewHeight, panelHeight, inset, anchorY) {
    if (anchorY < 0) return Math.round((viewHeight - panelHeight) / 2);
    return Math.round(Math.max(inset, Math.min(viewHeight - panelHeight - inset, anchorY - panelHeight / 2)));
}

function insets(edge, rail, frame) {
    return {left: edge === "left" ? rail : frame, right: edge === "right" ? rail : frame,
            top: edge === "top" ? rail : frame, bottom: edge === "bottom" ? rail : frame};
}
function barRect(width, height, edge, rail) {
    return {x: edge === "right" ? width - rail : 0, y: edge === "bottom" ? height - rail : 0,
            width: edge === "left" || edge === "right" ? rail : width,
            height: edge === "top" || edge === "bottom" ? rail : height};
}
function bounds(width, height, inset, margin) {
    return {x: inset.left + margin, y: inset.top + margin,
            width: Math.max(1, width - inset.left - inset.right - margin * 2),
            height: Math.max(1, height - inset.top - inset.bottom - margin * 2)};
}
function clamp(value, lo, hi) { return Math.max(lo, Math.min(Math.max(lo, hi), value)); }
function panelPosition(area, width, height, railEdge, centered, anchorX, anchorY) {
    var middleX = area.x + (area.width - width) / 2, middleY = area.y + (area.height - height) / 2;
    var horizontal = railEdge === "top" || railEdge === "bottom";
    return {
        x: Math.round(centered ? middleX : horizontal ? clamp(anchorX >= 0 ? anchorX - width / 2 : middleX, area.x, area.x + area.width - width)
            : railEdge === "right" ? area.x + area.width - width : area.x),
        y: Math.round(centered ? middleY : horizontal ? (railEdge === "bottom" ? area.y + area.height - height : area.y)
            : clamp(anchorY >= 0 ? anchorY - height / 2 : middleY, area.y, area.y + area.height - height))
    };
}
