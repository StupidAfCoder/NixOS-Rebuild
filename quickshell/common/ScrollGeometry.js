.pragma library
function clamp(value, low, high) { return Math.max(low, Math.min(high, value)); }
function thumbSize(track, viewport, content) {
    return Math.min(track, Math.max(28, track * viewport / Math.max(1, viewport, content)));
}
function contentPosition(pointer, grabOffset, track, thumb, origin, range) {
    return origin + (track > thumb ? clamp((pointer - grabOffset) / (track - thumb), 0, 1) : 0) * Math.max(0, range);
}
