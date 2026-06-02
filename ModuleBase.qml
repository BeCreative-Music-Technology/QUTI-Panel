import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: "MODULE"
    default property alias content: moduleContent.data

    width: 160
    height: 300
    color: "#1a1b26" // Dark background from image
    radius: 12
    border.color: "#2a2b36"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        Text {
            text: root.title
            color: "#e0e0e0"
            font.pixelSize: 24
            font.bold: true
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignHCenter
        }

        // This is where your custom module content will live
        Column {
            id: moduleContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
        }
    }
}