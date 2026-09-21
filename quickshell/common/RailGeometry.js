.pragma library

// Center in the monitor, not in the unequal space left by the end groups.
// Shift only to avoid collision; when nothing fits, extend the scrollable axis.
function arrange(viewport, start, middle, end, padding, gap) {
    const firstGap = start && middle ? gap : 0;
    const lastGap = middle && end ? gap : 0;
    const emptyMiddleGap = !middle && start && end ? gap : 0;
    const extent = Math.max(viewport, padding * 2 + start + middle + end + firstGap + lastGap + emptyMiddleGap);
    const endPosition = extent - padding - end;
    const low = padding + start + firstGap;
    const high = endPosition - lastGap - middle;
    return {extent: extent, positions: [padding, Math.max(low, Math.min(high, (extent - middle) / 2)), endPosition]};
}
