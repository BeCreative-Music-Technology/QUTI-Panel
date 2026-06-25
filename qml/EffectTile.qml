import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: dragSourceItem
    width: 100
    height: 100

    property string effectType: ""
    property string displayName: ""
    property string qmlSource: ""
    property real defaultValue: 0
    property color accentColor: "#7aa2f7"

    Rectangle {
        id: tile
        anchors.fill: parent
        color: "#16161E"
        border.color: dragArea.containsMouse ? dragSourceItem.accentColor : "#3b4261"
        border.width: 1
        radius: 6

        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }

        Text {
            anchors.centerIn: parent
            text: dragSourceItem.displayName
            color: dragSourceItem.accentColor
            font.pixelSize: 11
            font.bold: true
            font.family: "monospace"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width - 12
        }

        Drag.active: dragArea.drag.active
        Drag.keys: [dragSourceItem.effectType]
        Drag.source: dragSourceItem
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        states: State {
            when: dragArea.drag.active
            ParentChange {
                target: tile
                parent: dragSourceItem.Window.contentItem
            }
            PropertyChanges {
                target: tile
                anchors.fill: undefined
                width: dragSourceItem.width
                height: dragSourceItem.height
                opacity: 0.85
                z: 1000
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            drag.target: tile
            cursorShape: Qt.OpenHandCursor
            onReleased: tile.Drag.drop()
        }
    }
}
