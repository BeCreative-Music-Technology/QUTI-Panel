import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: baseRoot

    property int effectIndex: -1
    property real effectValue: 0.0
    property string title: ""
    property string effectId: ""

    signal removeRequested()
    signal valueChanged(int index, real newValue)

    anchors.fill: parent

    RowLayout {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        Text {
            text: baseRoot.title
            color: "#7aa2f7"
            font.bold: true
            font.pixelSize: 11
            font.family: "monospace"
            elide: Text.ElideRight

            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
        }

        Button {
            id: removeButton
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter

            padding: 0
            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0

            background: Rectangle {
                color: removeButton.hovered ? "#ff007c" : "transparent"
                radius: 4
                anchors.fill: parent
            }

            contentItem: Text {
                text: "✕"
                color: removeButton.hovered ? "#ffffff" : "#565f89"
                font.bold: true
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: baseRoot.removeRequested()
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
        anchors.topMargin: 6
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }
}
