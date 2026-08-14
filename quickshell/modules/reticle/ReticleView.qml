pragma ComponentBehavior: Bound
import QtQuick

// Renders the active reticle style, centered on its own bounding box.
// Shared between ReticleWindow.qml (live overlay) and ReticleEditOverlay.qml
// (drag/resize proxy) - same "one Loader + inline Component per skin" shape
// as Workspaces.qml's per-theme skins, except keyed on ReticleStore.style
// rather than ThemeManager.activeTheme since reticle style is this widget's
// own concern, not the app-wide structural-theme axis.
//
// Styles are hybrids named after their real-game namesakes (Apex/CoD's
// "Cross+Dot", Halo's ring reticle, CoD's "Angle" chevron, Apex/Titanfall's
// ADS corner brackets) rather than invented shapes - see ReticleBar/Dot/Ring
// for the shared outlined-pill-shape rendering all of them build on.
//
// contentScale (not Item.scale) drives sizing, same reasoning as
// ClockWeatherCard.contentScale: every skin's line thickness/radius is
// recomputed at the target size instead of GPU-transformed, so thin lines
// stay crisp and implicitWidth/Height correctly reports the real footprint
// (a plain transform scale would leave the window's own sizing wrong and
// risk clipping the visual at the surface edge).
Item {
    id: root

    property string style: ReticleStore.style
    property color reticleColor: ReticleStore.color
    property real contentScale: 1.0
    property bool outlined: ReticleStore.outlined

    readonly property real baseSize: 48 * contentScale
    readonly property color outlineColor: Qt.rgba(0, 0, 0, 0.85)
    readonly property real outlineWidth: root.outlined ? Math.max(1, Math.round(1 * root.contentScale)) : 0
    // Shared line thickness/gap tokens so every style reads as one family
    // at a glance, rather than each skin picking its own numbers.
    readonly property real barThickness: Math.max(2, Math.round(2.5 * root.contentScale))
    readonly property real gap: 6 * root.contentScale
    readonly property real dotDiameter: Math.max(2, 3 * root.contentScale)

    implicitWidth: baseSize
    implicitHeight: baseSize

    Loader {
        anchors.centerIn: parent
        sourceComponent: {
            switch (root.style) {
            case "Dot":
                return dotSkin;
            case "Circle":
                return circleSkin;
            case "Chevron":
                return chevronSkin;
            case "Brackets":
                return bracketsSkin;
            default:
                return crossSkin;
            }
        }
    }

    // Apex/CoD "Cross + Dot": a thin gapped plus (not a solid abrasive
    // block) with a small center dot for a precise aim reference.
    Component {
        id: crossSkin
        Item {
            id: crossRoot
            width: root.baseSize
            height: root.baseSize

            readonly property real armLength: 13 * root.contentScale

            Repeater {
                model: [0, 90, 180, 270]

                delegate: ReticleBar {
                    required property real modelData

                    length: crossRoot.armLength
                    thickness: root.barThickness
                    color: root.reticleColor
                    outlineColor: root.outlineColor
                    outlineWidth: root.outlineWidth
                    rotation: modelData
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: (root.gap / 2 + crossRoot.armLength / 2) * Math.cos(modelData * Math.PI / 180)
                    anchors.verticalCenterOffset: (root.gap / 2 + crossRoot.armLength / 2) * Math.sin(modelData * Math.PI / 180)
                }
            }

            ReticleDot {
                anchors.centerIn: parent
                diameter: root.dotDiameter
                color: root.reticleColor
                outlineColor: root.outlineColor
                outlineWidth: root.outlineWidth
            }
        }
    }

    // Minimalist single point - CS:GO/Valorant "dot only" style.
    Component {
        id: dotSkin
        ReticleDot {
            diameter: Math.max(3, 6 * root.contentScale)
            color: root.reticleColor
            outlineColor: root.outlineColor
            outlineWidth: root.outlineWidth
        }
    }

    // Halo-style ring: a stroked circle with short cardinal tick marks
    // outside it plus a center dot, evoking Halo's classic reticle without
    // needing the contextual red/green recoloring that requires actual
    // game/hitscan integration.
    Component {
        id: circleSkin
        Item {
            id: circleRoot
            width: root.baseSize
            height: root.baseSize

            readonly property real ringDiameter: 22 * root.contentScale
            readonly property real tickLength: 4 * root.contentScale

            ReticleRing {
                anchors.centerIn: parent
                diameter: circleRoot.ringDiameter
                ringWidth: Math.max(1, Math.round(1.5 * root.contentScale))
                color: root.reticleColor
                outlineColor: root.outlineColor
                outlineWidth: root.outlineWidth
            }

            Repeater {
                model: [0, 90, 180, 270]

                delegate: ReticleBar {
                    required property real modelData

                    length: circleRoot.tickLength
                    thickness: Math.max(1, Math.round(1.5 * root.contentScale))
                    color: root.reticleColor
                    outlineColor: root.outlineColor
                    outlineWidth: root.outlineWidth
                    rotation: modelData
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: (circleRoot.ringDiameter / 2 + circleRoot.tickLength / 2 + 1) * Math.cos(modelData * Math.PI / 180)
                    anchors.verticalCenterOffset: (circleRoot.ringDiameter / 2 + circleRoot.tickLength / 2 + 1) * Math.sin(modelData * Math.PI / 180)
                }
            }

            ReticleDot {
                anchors.centerIn: parent
                diameter: root.dotDiameter
                color: root.reticleColor
                outlineColor: root.outlineColor
                outlineWidth: root.outlineWidth
            }
        }
    }

    // CoD "Angle": an open chevron below a center dot, its two legs meeting
    // near the dot and fanning out diagonally - like an iron-sight post.
    Component {
        id: chevronSkin
        Item {
            id: chevronRoot
            width: root.baseSize
            height: root.baseSize

            readonly property real armLength: 13 * root.contentScale
            readonly property real legOffset: armLength * 0.55

            ReticleDot {
                anchors.centerIn: parent
                diameter: root.dotDiameter
                color: root.reticleColor
                outlineColor: root.outlineColor
                outlineWidth: root.outlineWidth
            }

            ReticleBar {
                length: chevronRoot.armLength
                thickness: root.barThickness
                color: root.reticleColor
                outlineColor: root.outlineColor
                outlineWidth: root.outlineWidth
                rotation: -45
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -chevronRoot.legOffset
                anchors.verticalCenterOffset: chevronRoot.legOffset
            }
            ReticleBar {
                length: chevronRoot.armLength
                thickness: root.barThickness
                color: root.reticleColor
                outlineColor: root.outlineColor
                outlineWidth: root.outlineWidth
                rotation: 45
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: chevronRoot.legOffset
                anchors.verticalCenterOffset: chevronRoot.legOffset
            }
        }
    }

    // Apex/Titanfall ADS-style corner brackets: four L-shaped corners
    // framing an implied square, open in the middle of each edge - about
    // as far from "abrasive solid bars" as a reticle gets while still
    // giving a clear aim reference via the negative space at center.
    Component {
        id: bracketsSkin
        Item {
            id: bracketsRoot
            width: root.baseSize
            height: root.baseSize

            readonly property real half: 11 * root.contentScale
            readonly property real armLength: 6 * root.contentScale

            Repeater {
                model: [
                    {
                        cx: -1,
                        cy: -1
                    }, // NW
                    {
                        cx: 1,
                        cy: -1
                    }, // NE
                    {
                        cx: -1,
                        cy: 1
                    }, // SW
                    {
                        cx: 1,
                        cy: 1
                    } // SE
                ]

                delegate: Item {
                    id: corner
                    required property var modelData

                    readonly property real cornerX: bracketsRoot.half * modelData.cx
                    readonly property real cornerY: bracketsRoot.half * modelData.cy

                    anchors.fill: parent

                    // Horizontal leg of the L, hugging the corner's own edge.
                    ReticleBar {
                        length: bracketsRoot.armLength
                        thickness: root.barThickness
                        color: root.reticleColor
                        outlineColor: root.outlineColor
                        outlineWidth: root.outlineWidth
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: corner.cornerX - modelData.cx * bracketsRoot.armLength / 2
                        anchors.verticalCenterOffset: corner.cornerY
                    }
                    // Vertical leg of the L.
                    ReticleBar {
                        length: bracketsRoot.armLength
                        thickness: root.barThickness
                        color: root.reticleColor
                        outlineColor: root.outlineColor
                        outlineWidth: root.outlineWidth
                        rotation: 90
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: corner.cornerX
                        anchors.verticalCenterOffset: corner.cornerY - modelData.cy * bracketsRoot.armLength / 2
                    }
                }
            }

            ReticleDot {
                anchors.centerIn: parent
                diameter: root.dotDiameter
                color: root.reticleColor
                outlineColor: root.outlineColor
                outlineWidth: root.outlineWidth
            }
        }
    }
}
