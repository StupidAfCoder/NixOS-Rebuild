pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// All nmcli interaction lives here -- nothing else in the shell talks
// to nmcli directly. Root is Item (not QtObject) so Process/Timer
// children can nest directly, same convention as SystemTray.qml's
// netCheck block.
Item {
    id: root

    // ---- Ethernet ----
    property bool ethernetConnected: false
    property string ethernetIface: ""
    property string ethernetConnectionName: ""
    property string ethernetIp: ""

    // ---- Wifi ----
    property bool wifiRadioEnabled: false
    property bool wifiConnected: false
    property string wifiIface: ""
    property string connectedSsid: ""
    property string wifiIp: ""

    property var networks: []   // [{ ssid, signal, secured, inUse }]
    property bool scanning: false
    property bool busy: false
    property string lastError: ""

    // nmcli -t escapes literal ':' inside a field as '\:' -- split on
    // real field separators only, not escaped ones
    function parseTerseLine(line) {
        let fields = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && line[i + 1] === ":") {
                cur += ":"
                i++
            } else if (line[i] === ":") {
                fields.push(cur)
                cur = ""
            } else {
                cur += line[i]
            }
        }
        fields.push(cur)
        return fields
    }

    function refreshStatus() { deviceStatusProc.running = true }

    function scan(rescan) {
        scanning = true
        wifiListProc.command = rescan
            ? ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list", "--rescan", "yes"]
            : ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list"]
        wifiListProc.running = true
    }

    function connectToNetwork(ssid, password) {
        busy = true
        lastError = ""
        connectProc.command = password.length > 0
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    function forgetNetwork(ssid) {
        busy = true
        forgetProc.command = ["nmcli", "connection", "delete", ssid]
        forgetProc.running = true
    }

    function disconnectWifi() {
        if (wifiIface === "") return
        busy = true
        disconnectProc.command = ["nmcli", "device", "disconnect", wifiIface]
        disconnectProc.running = true
    }

    function setRadio(enabled) {
        busy = true
        radioProc.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"]
        radioProc.running = true
    }

    // ---------------- processes ----------------

    Process {
        id: deviceStatusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let eth = null, wifi = null
                for (const line of this.text.split("\n")) {
                    if (!line) continue
                    const f = root.parseTerseLine(line)
                    const dev = f[0], type = f[1], state = f[2], conn = f[3]
                    if (type === "ethernet" && state === "connected" && !eth) eth = { dev: dev, conn: conn }
                    if (type === "wifi" && !wifi) wifi = { dev: dev, state: state, conn: conn }
                }

                root.ethernetConnected = !!eth
                root.ethernetIface = eth ? eth.dev : ""
                root.ethernetConnectionName = eth ? eth.conn : ""
                if (eth) {
                    ethIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", eth.dev]
                    ethIpProc.running = true
                } else {
                    root.ethernetIp = ""
                }

                root.wifiIface = wifi ? wifi.dev : ""
                root.wifiConnected = wifi ? wifi.state === "connected" : false
                root.connectedSsid = root.wifiConnected ? wifi.conn : ""

                if (root.wifiConnected) {
                    wifiIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", wifi.dev]
                    wifiIpProc.running = true
                } else {
                    root.wifiIp = ""
                }

                radioStatusProc.running = true
            }
        }
    }

    Process {
        id: ethIpProc
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n").find(l => l.indexOf("IP4.ADDRESS") === 0)
                root.ethernetIp = line ? (root.parseTerseLine(line)[1] || "") : ""
            }
        }
    }

    Process {
        id: wifiIpProc
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n").find(l => l.indexOf("IP4.ADDRESS") === 0)
                root.wifiIp = line ? (root.parseTerseLine(line)[1] || "") : ""
            }
        }
    }

    Process {
        id: radioStatusProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiRadioEnabled = this.text.trim() === "enabled"
        }
    }

    Process {
        id: wifiListProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const list = []
                for (const line of this.text.split("\n")) {
                    if (!line) continue
                    const f = root.parseTerseLine(line)
                    const ssid = f[0]
                    if (!ssid) continue
                    const signal = parseInt(f[1] || "0", 10)
                    const secTrim = (f[2] || "").trim()
                    const secured = secTrim !== "" && secTrim !== "--"
                    const inUse = (f[3] || "").trim() === "*"

                    if (seen[ssid] === undefined) {
                        seen[ssid] = list.length
                        list.push({ ssid: ssid, signal: signal, secured: secured, inUse: inUse })
                    } else if (list[seen[ssid]].signal < signal) {
                        list[seen[ssid]] = { ssid: ssid, signal: signal, secured: secured, inUse: inUse }
                    }
                }
                list.sort((a, b) => b.signal - a.signal)
                root.networks = list
                root.scanning = false
            }
        }
    }

    Process {
        id: connectProc
        stdout: StdioCollector { onStreamFinished: { root.busy = false; root.refreshStatus() } }
        stderr: StdioCollector {
            onStreamFinished: { if (this.text.trim().length > 0) root.lastError = this.text.trim() }
        }
    }

    Process {
        id: forgetProc
        stdout: StdioCollector { onStreamFinished: { root.busy = false; root.refreshStatus(); root.scan(false) } }
    }

    Process {
        id: disconnectProc
        stdout: StdioCollector { onStreamFinished: { root.busy = false; root.refreshStatus() } }
    }

    Process {
        id: radioProc
        stdout: StdioCollector { onStreamFinished: { root.busy = false; root.refreshStatus() } }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }
}