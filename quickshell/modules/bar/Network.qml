pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.modules.common

Text {
    id: root

    readonly property NetworkDevice wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property Network activeNetwork: root.wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property WifiNetwork activeWifiNetwork: root.activeNetwork
    readonly property string iconConnected: String.fromCharCode(0xf1eb) // fa-wifi

    text: root.activeNetwork
          ? root.iconConnected + "  " + Math.round(root.activeWifiNetwork?.signalStrength ?? 0) + "%"
          : "󰖪 "
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["rofi-wifi-menu"])
    }
}
