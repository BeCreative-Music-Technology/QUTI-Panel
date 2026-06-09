import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: baseRoot

    property int effectIndex: -1
    property real effectValue: 0.0
    property string title: ""
    property string effectId: ""

    signal removeRequested()
    signal valueChanged(int index, real newValue)

    // FIX 1: Use aliases and point them to the new specific IDs below
    property alias inputPin: inputIcon
    property alias outputPin: outputIcon

    width: 160
    height: 120
    color: "#16161e"
    border.color: "#24283b"
    border.width: 1
    radius: 6

    // --- INPUT PIN ---
    Image {
        id: inputIcon // Renamed to avoid collision
        source: "../assets/input.svg"
        sourceSize.height: 16
        anchors.left: parent.left
        anchors.leftMargin: -24
        anchors.verticalCenter: parent.verticalCenter
        z: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onPressed: (mouse) => {
                // FIX 2: Use baseRoot, not rootModule
                workspace.startConnection(baseRoot, inputIcon, "effect_in");
                workspace.currentMousePos = mapToItem(workspace, mouse.x, mouse.y);
                connectionCanvas.requestPaint();
            }

            onPositionChanged: (mouse) => {
                workspace.currentMousePos = mapToItem(workspace, mouse.x, mouse.y);
                connectionCanvas.requestPaint();
            }

            onReleased: (mouse) => {
                workspace.resetRoutingState();
            }
        }
    }

    // --- OUTPUT PIN ---
    Image {
        id: outputIcon // Renamed to avoid collision
        source: "../assets/output.svg"
        sourceSize.height: 16
        anchors.right: parent.right
        anchors.rightMargin: -24
        anchors.verticalCenter: parent.verticalCenter
        z: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            // FIX 3: Add the continuous position tracking here too!
            onPressed: (mouse) => {
                workspace.startConnection(baseRoot, outputIcon, "effect_out");
                workspace.currentMousePos = mapToItem(workspace, mouse.x, mouse.y);
                connectionCanvas.requestPaint();
            }

            onPositionChanged: (mouse) => {
                workspace.currentMousePos = mapToItem(workspace, mouse.x, mouse.y);
                connectionCanvas.requestPaint();
            }

            onReleased: (mouse) => {
                workspace.resetRoutingState();
            }
        }
    }

    RowLayout {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: 30

        Text {
            text: baseRoot.title
            color: "#7aa2f7"
            font.bold: true
            font.pixelSize: 11
            Layout.fillWidth: true
        }

        Button {
            id: removeButton
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            background: Rectangle {
                color: removeButton.hovered ? "#ff007c" : "transparent"
                radius: 3
            }

            contentItem: Text {
                text: "×"
                color: removeButton.hovered ? "white" : "#565f89"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                baseRoot.removeRequested()
            }
        }
    }

    Rectangle {
        id: separator
        anchors.top: headerRow.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#24283b"
    }

    default property alias content: childContainer.data
    Item {
        id: childContainer
        anchors.top: separator.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
    }
}