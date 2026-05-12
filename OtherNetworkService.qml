pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    property var connections: []
    property bool refreshing: false
    property bool available: false

    signal refreshed

    readonly property var lowPriorityCmd: ["nice", "-n", "19", "ionice", "-c3"]

    Component.onCompleted: {
        Qt.callLater(refresh);
    }

    function refresh() {
        if (refreshing)
            return;
        refreshing = true;
        listProcess.command = lowPriorityCmd.concat(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show"]);
        listProcess.running = true;
    }

    Process {
        id: listProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const allConnections = [];

                const excludedTypes = [
                    "802-11-wireless",
                    "802-3-ethernet",
                    "tun",
                    "tap",
                    "loopback",
                    "vpn",
                    "wireguard"
                ];

                for (const line of lines) {
                    const parts = line.split(":");
                    if (parts.length < 3)
                        continue;

                    const name = parts[0];
                    const type = parts[1];
                    const device = parts[2] || "";

                    if (excludedTypes.includes(type))
                        continue;

                    allConnections.push({
                        name: name,
                        type: type,
                        device: device,
                        active: device.length > 0
                    });
                }

                allConnections.sort((a, b) => {
                    if (a.active && !b.active)
                        return -1;
                    if (!a.active && b.active)
                        return 1;
                    return a.name.localeCompare(b.name);
                });

                root.connections = allConnections;
                root.available = allConnections.length > 0;
                root.refreshing = false;
                root.refreshed();
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.connections = [];
                root.available = false;
            }
            root.refreshing = false;
        }
    }

    Process {
        id: actionProcess
        running: false

        onExited: exitCode => {
            if (exitCode === 0)
                Qt.callLater(() => root.refresh());
        }
    }

    function connectConnection(name) {
        actionProcess.command = lowPriorityCmd.concat(["nmcli", "connection", "up", name]);
        actionProcess.running = true;
    }

    function disconnectConnection(name) {
        actionProcess.command = lowPriorityCmd.concat(["nmcli", "connection", "down", name]);
        actionProcess.running = true;
    }

    function getTypeIcon(type) {
        switch (type) {
        case "bridge":
            return "lan";
        case "vlan":
            return "lan";
        case "bond":
            return "lan";
        case "team":
            return "lan";
        case "dummy":
            return "lan";
        case "macvlan":
            return "lan";
        case "ip-tunnel":
            return "lan";
        default:
            return "settings_ethernet";
        }
    }

    function getTypeLabel(type) {
        switch (type) {
        case "bridge":
            return "Bridge";
        case "vlan":
            return "VLAN";
        case "bond":
            return "Bond";
        case "team":
            return "Team";
        case "dummy":
            return "Dummy";
        case "macvlan":
            return "MAC VLAN";
        case "ip-tunnel":
            return "Tunnel";
        case "wireguard":
            return "WireGuard";
        default:
            return type;
        }
    }
}
