import QtQuick
import qs.modules.theme

// Generic rounded-pill container for grouping related bar widgets. Content
// is placed directly inside `Pill { ... }` (reparented into the inner Row
// via the default-property alias, same pattern as ii's ContentSection.qml
// etc). Collapses to zero width/invisible on its own if every child inside
// happens to be invisible (e.g. Music with nothing playing), since Row
// excludes invisible children from its own implicit size.
//
// Sets both implicitWidth/Height and width/height: a plain Item/Rectangle
// never auto-binds width to implicitWidth, but RowLayout (used for the
// evenly-spread bar layout) sizes non-stretching children FROM
// implicitWidth/Layout.preferredWidth - so Pill needs to satisfy both a
// plain Row (reads width) and a RowLayout (reads implicitWidth) depending
// on where it's used.
Rectangle {
    id: root

    default property alias content: innerRow.data
    property int spacing: 10
    property int horizontalPadding: 10

    radius: 8
    color: Theme.pillBg
    border.width: 1
    border.color: Theme.pillBorder
    implicitWidth: innerRow.width > 0 ? innerRow.width + root.horizontalPadding * 2 : 0
    implicitHeight: 22
    width: implicitWidth
    height: implicitHeight
    visible: root.width > 0

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
