import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: controlInputRoot
    property string controlId: "rotary_1" // Matches JSON id

    // ADD THIS: Bring in the router pattern
    property var router: null

    // Expose the pin to the global Canvas for coordinate mapping
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

        Item { Layout.fillWidth: true }

        Switch {
            checked: true
            scale: 0.5
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Output Routing Pin
    Image {
        id: outputIcon
        source: "../assets/output.svg"
        sourceSize.height: 16
        anchors.right: parent.right
        anchors.rightMargin: -32
        anchors.verticalCenter: parent.verticalCenter
        z: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            onClicked: {
                if (!router)
                    return;
                // Start routing from the control output
                router.startConnection(controlInputRoot, outputIcon, "control");
                let pinCenter = outputIcon.mapToItem(router, outputIcon.width/2, outputIcon.height/2);
                router.currentMousePos = pinCenter;
                router.isDrawingLine = true;
                router.requestRepaint();
            }
        }
    }
}