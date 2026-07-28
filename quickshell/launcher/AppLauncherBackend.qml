pragma Singleton
import QtQuick
import Quickshell

Item {
    id: root

    // Full sorted list of visible desktop entries
    readonly property var allApps: {
        var apps = []
        var list = DesktopEntries.applications.values
        for (var i = 0; i < list.length; i++) {
            var entry = list[i]
            if (!entry.noDisplay) apps.push(entry)
        }
        apps.sort(function (a, b) { return a.name.localeCompare(b.name) })
        return apps
    }

    // Simple substring-scored fuzzy-ish filter. Name match beats
    // genericName/comment match; earlier match position scores higher.
    function filtered(query) {
        if (!query || query.length === 0) return allApps

        var q = query.toLowerCase()
        var scored = []

        for (var i = 0; i < allApps.length; i++) {
            var entry = allApps[i]
            var name = entry.name.toLowerCase()
            var nameIdx = name.indexOf(q)

            if (nameIdx !== -1) {
                scored.push({ entry: entry, score: nameIdx })
                continue
            }

            var generic = (entry.genericName || "").toLowerCase()
            var comment = (entry.comment || "").toLowerCase()
            if (generic.indexOf(q) !== -1 || comment.indexOf(q) !== -1) {
                scored.push({ entry: entry, score: 1000 })
            }
        }

        scored.sort(function (a, b) { return a.score - b.score })
        return scored.map(function (s) { return s.entry })
    }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        AppLauncher.hide()
    }
}