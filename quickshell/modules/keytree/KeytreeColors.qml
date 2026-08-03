pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Executable nodes
    readonly property color leafBg: "#CC15161B"
    readonly property color leafBorder: "#FF494D65"

    // Group/subtree nodes
    readonly property color groupBg: "#CC19171D"
    readonly property color groupBorder: "#FF5D526C"

    // Text
    readonly property color keyText: "#FFB5907C"
    readonly property color labelText: "#FFFFDDC0"

    // Connectors
    readonly property color connector: "#FFB4886F"
    readonly property color centerDot: "#FF5D526C"

    // Search panel
    readonly property color searchBg: "#CC060300"
    readonly property color searchBorder: "#FF544B60"
    readonly property color searchSelection: "#CC544B60"
    readonly property color searchText: "#FFFFDDC0"
}
