.pragma library

// Two-step pixel staircase corners instead of a single diagonal chamfer.
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

// Chamfered (45°-cut-corner) rect — used for the workspace chip/rivet caps.
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

// Plain flush rectangle.
function flushRectPath(w, h) {
    return "M0,0 L" + w + ",0 L" + w + "," + h + " L0," + h + " Z";
}

// Pixel-stair corner bracket — an L-shaped frame piece. Drawn in
// top-left orientation by default; rotate the Shape itself in QML for
// the other 3 corners.
function cornerBracketPath(size, thickness, steps) {
    steps = steps || 2;
    var s = thickness / steps;
    var d = [];

    // top arm
    d.push("M0,0 L" + size + ",0 L" + size + "," + thickness + " L" + (thickness) + "," + thickness);
    // stair down into the inner corner
    for (var i = 0; i < steps; i++) {
        d.push("L" + (thickness - s * i) + "," + (thickness + s * (i + 1)));
        d.push("L" + (thickness - s * (i + 1)) + "," + (thickness + s * (i + 1)));
    }
    // left arm (down to bottom of bracket)
    d.push("L" + thickness + "," + size);
    d.push("L0," + size);
    d.push("Z");

    return d.join(" ");
}
