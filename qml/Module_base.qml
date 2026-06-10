import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: baseRoot

    property int effectIndex: -1
    property real effectValue: 0.0
    property string title: ""
    property string effectId: ""

    property bool isSourceTile: false
    property var router: null

    signal removeRequested()
    signal valueChanged(int index, real newValue)

    property alias inputPin: inputIcon
    property alias outputPin: outputIcon

    width: 180
    height: 120
    color: "#16161e"
    border.color: "#24283b"
    border.width: 1
    radius: 6
    z:20

    Image {
        id: inputIcon
        source: "../assets/input.svg"
        sourceSize.height: 16
        anchors.left: parent.left
        anchors.leftMargin: -24
        anchors.verticalCenter: parent.verticalCenter
        z: 10
        visible: !baseRoot.isSourceTile

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !baseRoot.isSourceTile
            preventStealing: true

            onClicked: {
                if (baseRoot.router && !baseRoot.router.isDrawingLine) {
                    baseRoot.router.disconnectTarget(baseRoot.effectId);
                }
                if (!router || !router.isDrawingLine)
                    return;
                if (router.activePortType === "control") {
                    router.completeConnection(baseRoot, inputIcon, "control");
                }
            }
        }
    }


    Image {
        id: outputIcon
        source: "../assets/output.svg"
        sourceSize.height: 16
        anchors.right: parent.right
        anchors.rightMargin: -32
        anchors.verticalCenter: parent.verticalCenter
        z: 10
        visible: !baseRoot.isSourceTile

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !baseRoot.isSourceTile
            preventStealing: true

            onClicked: {
                if (!router)
                    return;
                router.startConnection(baseRoot, outputIcon, "effect_out");
                let pinCenter = outputIcon.mapToItem(router, outputIcon.width/2, outputIcon.height/2);
                router.currentMousePos = pinCenter;
                router.isDrawingLine = true;
                router.requestRepaint();
            }
        }
    }

    RowLayout {
            id: headerRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 30
            spacing: 8

            Text {
                text: baseRoot.title
                color: "#7aa2f7"
                font.bold: true
                font.pixelSize: 11

                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
            }

            Button {
                id: removeButton
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                visible: !baseRoot.isSourceTile

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
                    font.pixelSize: 14
                    font.family: "Segoe UI Symbol, Arial, sans-serif"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (baseRoot.router && !baseRoot.router.isDrawingLine) {
                        baseRoot.router.disconnectTarget(baseRoot.effectId);
                        baseRoot.removeRequested();
                    }
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