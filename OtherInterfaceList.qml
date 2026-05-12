import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import "."

Rectangle {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property int listHeight: 200

    implicitHeight: availableHeight
    radius: Theme.cornerRadius
    color: "transparent"

    readonly property int availableHeight: {
        if (!OtherNetworkService.available && OtherNetworkService.connections.length === 0)
            return emptyStateColumn.implicitHeight + Theme.spacingM * 2;
        return listHeight;
    }

    Component.onCompleted: {
        OtherNetworkService.refresh();
    }

    Connections {
        target: OtherNetworkService
        function onRefreshed() {
            listView.positionViewAtBeginning();
        }
    }

    Item {
        id: emptyState
        anchors.fill: parent
        visible: !OtherNetworkService.refreshing && OtherNetworkService.connections.length === 0

        Column {
            id: emptyStateColumn
            anchors.centerIn: parent
            spacing: Theme.spacingM

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "settings_ethernet"
                size: 40
                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.4)
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.tr("No other interfaces")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.tr("No bridges, VLANs, or bonds found")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }

    Item {
        id: loadingState
        anchors.fill: parent
        visible: OtherNetworkService.refreshing && OtherNetworkService.connections.length === 0

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingM

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "sync"
                size: 32
                color: Theme.primary

                RotationAnimation on rotation {
                    running: loadingState.visible
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.tr("Scanning...")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
            }
        }
    }

    DankListView {
        id: listView
        anchors.fill: parent
        visible: !emptyState.visible && !loadingState.visible
        spacing: Theme.spacingS
        clip: true

        model: ScriptModel {
            values: OtherNetworkService.connections
            objectProp: "name"
        }

        delegate: Rectangle {
            id: delegateRoot
            required property var modelData
            required property int index

            readonly property bool isActive: modelData.active
            readonly property string connName: modelData.name || ""
            readonly property string connType: modelData.type || ""
            readonly property string connDevice: modelData.device || ""

            width: listView.width
            height: contentRow.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: mouseArea.containsMouse ? Theme.primaryHoverLight : Theme.surfaceLight
            border.color: isActive ? Theme.primary : Theme.outlineLight
            border.width: isActive ? 2 : 1

            Row {
                id: contentRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Theme.spacingM
                spacing: Theme.spacingS

                DankIcon {
                    name: OtherNetworkService.getTypeIcon(connType)
                    size: Theme.iconSize - 4
                    color: isActive ? Theme.primary : Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180

                    StyledText {
                        text: connName
                        font.pixelSize: Theme.fontSizeMedium
                        color: isActive ? Theme.primary : Theme.surfaceText
                        font.weight: isActive ? Font.Medium : Font.Normal
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Row {
                        spacing: Theme.spacingXS
                        visible: connType.length > 0

                        StyledText {
                            text: OtherNetworkService.getTypeLabel(connType)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: connDevice ? "\u2022 " + connDevice : ""
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            visible: text.length > 0
                        }
                    }
                }
            }

            DankActionButton {
                id: actionButton
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                iconName: isActive ? "link_off" : "link"
                buttonSize: 28
                tooltipText: isActive ? I18n.tr("Disconnect") : I18n.tr("Connect")
                onClicked: {
                    if (isActive)
                        OtherNetworkService.disconnectConnection(connName);
                    else
                        OtherNetworkService.connectConnection(connName);
                }
            }

            DankRipple {
                id: ripple
                cornerRadius: parent.radius
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                anchors.rightMargin: actionButton.width + Theme.spacingS
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => ripple.trigger(mouse.x, mouse.y)
                onClicked: {
                    if (!isActive)
                        OtherNetworkService.connectConnection(connName);
                }
            }
        }
    }
}
