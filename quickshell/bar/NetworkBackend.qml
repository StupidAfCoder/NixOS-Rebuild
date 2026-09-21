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
    property bool ethernetConnected: false        // L2 link state only -- device says connected
    property string ethernetIface: ""
    property string ethernetConnectionName: ""
    property string ethernetIp: ""

    // ---- Connectivity (real internet reachability, not just link state) ----
    // One of "full" / "limited" / "portal" / "none" / "unknown", from NM's
    // own periodic probe (networking.networkmanager.connectivity in
    // configuration.nix). "full" is the only state that means "actually
    // online" -- "limited"/"portal" mean a link with no real internet.
    property string connectivityState: "unknown"
    property bool ethernetOnline: ethernetConnected && connectivityState === "full"

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
    property string pendingPassword: ""

    // nmcli -t escapes literal ':' inside a field as '\:' -- split on
    // real field separators only, not escaped ones
    function parseTerseLine(line) {
        let fields = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) {
                cur += line[i + 1]
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

    function refreshStatus() {
        deviceStatusProc.running = true
        connectivityProc.running = true
    }

    function scan(rescan) {
        if (wifiListProc.running) return;
        scanning = true
        wifiListProc.command = rescan
            ? ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list", "--rescan", "yes"]
            : ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list"]
        wifiListProc.running = true
    }

    function connectToNetwork(ssid, password) {
        if (busy) return;
        if (password.indexOf("\n") >= 0 || password.indexOf("\r") >= 0) {
            lastError = "Password must be on a single line";
            return;
        }
        busy = true;
        lastError = "";
        pendingPassword = password;
        // Keep credentials off the process command line and out of shell history.
        connectProc.stdinEnabled = true;
        connectProc.command = password.length > 0
            ? ["nmcli", "--ask", "--wait", "30", "device", "wifi", "connect", ssid]
            : ["nmcli", "--wait", "30", "device", "wifi", "connect", ssid];
        connectProc.running = true;
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
        radioProc.command = ["nmcli", "--wait", "0", "radio", "wifi", enabled ? "on" : "off"]
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

    // Real internet reachability, from NM's own probe -- see
    // networking.networkmanager.connectivity in configuration.nix.
    // Bare value: full / limited / portal / none / unknown.
    Process {
        id: connectivityProc
        command: ["nmcli", "-t", "-g", "CONNECTIVITY", "general", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = this.text.trim()
                root.connectivityState = state.length > 0 ? state : "unknown"
            }
        }
    }

    Process {
        id: wifiListProc
        onExited: (code, status) => { root.scanning = false; if (code !== 0) root.lastError = "Wi-Fi scan failed"; }
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
        stdinEnabled: true
        onStarted: { if (root.pendingPassword) write(root.pendingPassword + "\n"); root.pendingPassword = ""; stdinEnabled = false; }
        onExited: (code, status) => { root.pendingPassword = ""; root.busy = false; if (code !== 0 && !root.lastError) root.lastError = "Connection failed"; root.refreshStatus(); }
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.lastError = text.trim(); } }
    }
    Process {
        id: forgetProc
        onExited: (code, status) => { root.busy = false; if (code !== 0) root.lastError = "Could not forget this connection"; root.refreshStatus(); root.scan(false); }
    }
    Process {
        id: disconnectProc
        onExited: (code, status) => { root.busy = false; if (code !== 0) root.lastError = "Could not disconnect"; root.refreshStatus(); }
    }
    Process {
        id: radioProc
        onExited: (code, status) => { root.busy = false; if (code !== 0) root.lastError = "Could not change Wi-Fi radio"; root.refreshStatus(); }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }
}
