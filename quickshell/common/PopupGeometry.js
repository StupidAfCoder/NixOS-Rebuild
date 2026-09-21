.pragma library
// Origins are window-local, never compositor-global (which may be negative).
function popupY(viewHeight, panelHeight, inset, anchorY) {
    if (anchorY < 0) return Math.round((viewHeight - panelHeight) / 2);
    return Math.round(Math.max(inset, Math.min(viewHeight - panelHeight - inset, anchorY - panelHeight / 2)));
}
