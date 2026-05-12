import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "."

PluginComponent {
    id: root

    readonly property string networkStatus: NetworkService.networkStatus
    readonly property bool ethernetActive: NetworkService.ethernetConnected
    readonly property bool wifiActive: NetworkService.wifiConnected
    readonly property bool otherActive: OtherNetworkService.connections.some(c => c.active)

    ccWidgetIcon: {
        if (ethernetActive)
            return "settings_ethernet";
        if (wifiActive)
            return "wifi";
        if (otherActive)
            return "lan";
        return "settings_ethernet";
    }

    ccWidgetPrimaryText: I18n.tr("Network")

    ccWidgetSecondaryText: {
        if (ethernetActive)
            return I18n.tr("Ethernet") + " \u2022 " + (NetworkService.ethernetIP || I18n.tr("Connected"));
        if (wifiActive)
            return I18n.tr("WiFi") + " \u2022 " + (NetworkService.currentWifiSSID || I18n.tr("Connected"));
        if (otherActive) {
            const active = OtherNetworkService.connections.filter(c => c.active);
            const names = active.map(c => c.name);
            return names.join(", ");
        }
        return I18n.tr("Disconnected");
    }

    ccWidgetIsActive: ethernetActive || wifiActive || otherActive

    ccDetailHeight: 400

    onCcWidgetToggled: {
        if (ethernetActive) {
            NetworkService.toggleNetworkConnection("ethernet");
        } else if (wifiActive) {
            NetworkService.disconnectWifi();
        } else if (otherActive) {
            const active = OtherNetworkService.connections.filter(c => c.active);
            if (active.length > 0)
                OtherNetworkService.disconnectConnection(active[0].name);
        } else if (NetworkService.ethernetDevices?.length > 0) {
            NetworkService.toggleNetworkConnection("ethernet");
        }
    }

    onCcWidgetExpanded: {
        OtherNetworkService.refresh();
    }

    ccDetailContent: Component {
        ExtendedNetworkDetail {}
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.ccWidgetIcon
                size: Theme.barIconSize(root.barThickness, -4)
                color: root.ccWidgetIsActive ? Theme.primary : Theme.widgetIconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: {
                    if (root.ethernetActive)
                        return root.networkStatus === "ethernet" ? (NetworkService.ethernetIP || "Eth") : "Eth";
                    if (root.wifiActive)
                        return NetworkService.currentWifiSSID || "WiFi";
                    if (root.otherActive) {
                        const active = OtherNetworkService.connections.filter(c => c.active);
                        return active.length > 0 ? active[0].name : "";
                    }
                    return "";
                }
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale)
                color: root.ccWidgetIsActive ? Theme.primary : Theme.widgetTextColor
                anchors.verticalCenter: parent.verticalCenter
                visible: text.length > 0
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                name: root.ccWidgetIcon
                size: Theme.barIconSize(root.barThickness)
                color: root.ccWidgetIsActive ? Theme.primary : Theme.widgetIconColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
