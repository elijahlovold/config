pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.modules.theme

Text {
    id: root

    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice connectedDevice: Bluetooth.devices.values.find(d => d.connected) ?? null
    readonly property string icon: String.fromCharCode(0xf293) // fa-bluetooth

    text: !root.enabled ? ""
          : root.connectedDevice ? root.icon + "  " + (root.connectedDevice.name || root.connectedDevice.deviceName)
          : root.icon
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["alacritty", "-e", "bluetoothctl"])
    }
}
