.pragma library

// Two-step pixel staircase corners instead of a single diagonal chamfer.
// w, h = shape dimensions. cut = total corner inset. steps = stair count (2 = pixel-HUD feel).
function pixelStairPath(w, h, cut, steps) {
    steps = steps || 2;
    var s = cut / steps;
    var d = [];

    d.push("M" + cut + ",0");
    d.push("L" + (w - cut) + ",0");
    for (var i = 0; i < steps; i++) {
        d.push("L" + (w - cut + s * (i + 1)) + "," + (s * i));
        d.push("L" + (w - cut + s * (i + 1)) + "," + (s * (i + 1)));
    }
    d.push("L" + w + "," + (h - cut));
    for (var i = 0; i < steps; i++) {
        d.push("L" + (w - s * i) + "," + (h - cut + s * (i + 1)));
        d.push("L" + (w - s * (i + 1)) + "," + (h - cut + s * (i + 1)));
    }
    d.push("L" + cut + "," + h);
    for (var i = 0; i < steps; i++) {
        d.push("L" + (cut - s * (i + 1)) + "," + (h - s * i));
        d.push("L" + (cut - s * (i + 1)) + "," + (h - s * (i + 1)));
    }
    d.push("L0," + cut);
    for (var i = 0; i < steps; i++) {
        d.push("L" + (s * i) + "," + (cut - s * (i + 1)));
        d.push("L" + (s * (i + 1)) + "," + (cut - s * (i + 1)));
    }
    d.push("Z");
    return d.join(" ");
}

// Chamfered (45°-cut-corner) rect — used for the rivet cap discs.
// Renders as a blocky octagon rather than a smooth circle, matching
// the hard-edge pixel style of the rest of the bar.
function chamferedRectPath(w, h, cut) {
    var c = Math.min(cut, w / 2, h / 2);
    var d = [];

    d.push("M" + c + ",0");
    d.push("L" + (w - c) + ",0");
    d.push("L" + w + "," + c);
    d.push("L" + w + "," + (h - c));
    d.push("L" + (w - c) + "," + h);
    d.push("L" + c + "," + h);
    d.push("L0," + (h - c));
    d.push("L0," + c);
    d.push("Z");

    return d.join(" ");
}