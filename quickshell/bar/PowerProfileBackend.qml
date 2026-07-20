pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property string activeProfile: ""
    property var availableProfiles: []
    property bool daemonAvailable: false

    function setProfile(profile) {
        if (!root.daemonAvailable) return
        setProc.command = ["powerprofilesctl", "set", profile]
        setProc.running = true
    }

    function refresh() {
        if (!root.daemonAvailable) return
        getProc.running = true
        listProc.running = true
    }

    // one-shot existence check -- runs before anything else touches powerprofilesctl
    Process {
        id: checkProc
        command: ["sh", "-c", "command -v powerprofilesctl"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.daemonAvailable = this.text.trim().length > 0
                if (root.daemonAvailable) {
                    root.refresh()
                    pollTimer.start()
                }
            }
        }
    }

    Component.onCompleted: checkProc.running = true

    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.activeProfile = this.text.trim()
        }
    }

    Process {
        id: listProc
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = []
                for (const name of ["power-saver", "balanced", "performance"]) {
                    if (this.text.indexOf(name) !== -1) found.push(name)
                }
                root.availableProfiles = found
            }
        }
    }

    Process {
        id: setProc
        stdout: StdioCollector { onStreamFinished: root.refresh() }
    }

    Timer {
        id: pollTimer
        interval: 5000
        running: false
        repeat: true
        onTriggered: root.refresh()
    }
}