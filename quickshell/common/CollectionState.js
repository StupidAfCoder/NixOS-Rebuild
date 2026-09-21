.pragma library

// Keep a selection stable when an asynchronous directory scan replaces the model.
function indexFor(items, preferredPath, fallbackPath) {
    if (!items.length) return -1;
    var index = items.findIndex(function(item) { return item.path === preferredPath; });
    if (index < 0 && fallbackPath)
        index = items.findIndex(function(item) { return item.path === fallbackPath; });
    return index < 0 ? 0 : index;
}
function boundedIndex(count, index) {
    return count ? Math.max(0, Math.min(count - 1, index)) : -1;
}
function parentPath(path, fallback) {
    if (!path || path[0] !== '/') return fallback;
    var end = path.lastIndexOf('/');
    return end === 0 ? '/' : path.substring(0, end);
}
