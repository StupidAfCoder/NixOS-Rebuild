pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

QtObject {
    id: root
    property int selectedIndex: -1   // -1 = auto (prefer playing, else first)

    readonly property var players: Mpris.players ? Mpris.players : null

    readonly property var player: {
        if (!players || players.count === 0) return null
        if (root.selectedIndex >= 0 && root.selectedIndex < players.count) {
            return players.values[root.selectedIndex]
        }
        for (let i = 0; i < players.count; i++) {
            if (players.values[i].playbackState === MprisPlaybackState.Playing) {
                return players.values[i]
            }
        }
        return players.values[0]
    }

    readonly property bool hasPlayer: player !== null && player !== undefined

    function selectPlayer(index) {
        root.selectedIndex = index
    }
}