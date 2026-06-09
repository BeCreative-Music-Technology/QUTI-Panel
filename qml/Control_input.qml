import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: controlInputRoot
    property string controlId: "rotary_1" // Matches JSON id

    // FIX 1: Expose the pin to the global Canvas for coordinate mapping
    property alias outputPin: outputIcon

    width: 170
    height: 60
    color: "#16161E"
    border.color: "#3b4261"
    radius: 8

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            text: "ROTARY 1"
            color: "white"
            font.pixelSize: 11
            font.bold: true
            font.family: "monospace"
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true } // Spacer

        Switch {
            checked: true
            scale: 0.5
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Output Routing Pin (Moved outside RowLayout for proper edge anchoring)
    Image {
        id: outputIcon // FIX 2: Renamed to avoid property collision
        source: "../assets/output.svg"
        sourceSize.height: 16
        anchors.right: parent.right
        anchors.rightMargin: -16
        anchors.verticalCenter: parent.verticalCenter
        z: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            // FIX 3: Full drag-and-drop continuous tracking
            onPressed: (mouse) => {
                workspace.startConnection(controlInputRoot, outputIcon, "control_out");
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
}