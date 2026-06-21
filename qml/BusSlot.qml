import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: busRow
    width: parent ? parent.width : 1000
    height: 110

    property int busIndex: 0
    property var workspace: null
    property bool busEnabled: true
    property alias busSwitchChecked: busSwitch.checked

    readonly property var effectChain: rootWindow.matrixRevision >= 0 ? rootWindow.busEffectsMatrix[busIndex] : []

    Item {
        anchors.fill: parent

        ListView {
            id: effectChainListView
            anchors.left: parent.left
            anchors.right: busTileAnchorPoint.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            orientation: ListView.Horizontal
            interactive: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 0
            layoutDirection: Qt.RightToLeft
            model: busRow.effectChain

            ScrollBar.horizontal: ScrollBar {
                id: hScrollBar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 8
                policy: effectChainListView.contentWidth > effectChainListView.width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff

                contentItem: Rectangle {
                    implicitHeight: 6
                    radius: 3
                    color: hScrollBar.pressed ? "#ff007c" : "#3b4261"
                    opacity: hScrollBar.hovered || hScrollBar.pressed ? 1.0 : 0.5
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }
                background: Rectangle { color: "transparent" }
            }

            delegate: Item {
                width: 210
                height: 110

                readonly property var slotData: modelData
                readonly property bool isSlotEmpty: modelData === null
                readonly property int slotIndex: index

                // Selection check state matching the active workspace index definitions
                readonly property bool isSelected: rootWindow.selectedBus === busRow.busIndex && rootWindow.selectedSlot === slotIndex

                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    layoutDirection: Qt.LeftToRight

                    Item {
                        id: leftWireContainer
                        width: 40
                        Layout.preferredWidth: 40
                        Layout.fillHeight: true

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                ctx.strokeStyle = "#565f89";
                                ctx.lineWidth = 2;
                                ctx.setLineDash([4, 4]);
                                ctx.beginPath();
                                ctx.moveTo(0, height / 2);
                                ctx.lineTo(width, height / 2);
                                ctx.stroke();

                                ctx.fillStyle = "gray";
                                ctx.setLineDash([]);
                                ctx.beginPath();
                                ctx.moveTo(0, (height / 2) - 9);
                                ctx.lineTo(14, height / 2);
                                ctx.lineTo(0, (height / 2) + 9);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                    }

                    Rectangle {
                        id: slotBox
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 95
                        Layout.alignment: Qt.AlignVCenter
                        color: "#16161E"

                        // Glow hot-pink if selected, blue if populated, grey if empty
                        border.color: isSelected ? "#ff007c" : (isSlotEmpty ? "#3b4261" : "#7aa2f7")
                        border.width: isSelected ? 2 : (isSlotEmpty ? 1 : 2)
                        radius: 8

                        // Click handle selection configuration
                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            onClicked: {
                                if (!isSlotEmpty) {
                                    rootWindow.selectedBus = busRow.busIndex;
                                    rootWindow.selectedSlot = slotIndex;
                                }
                            }
                        }

                        DropArea {
                            anchors.fill: parent
                            keys: typeof ModuleRegistry !== "undefined" ? ModuleRegistry.modules.map(m => m.effectType) : []
                            onEntered: { if (!isSelected) slotBox.border.color = "#9ece6a" }
                            onExited: { slotBox.border.color = isSelected ? "#ff007c" : (isSlotEmpty ? "#3b4261" : "#7aa2f7") }
                            onDropped: (drop) => {
                                let src = drop.source;
                                busRow.workspace.setBusEffect(busRow.busIndex, slotIndex, {
                                    "type": src.effectType,
                                    "displayName": src.displayName,
                                    "qmlSource": src.qmlSource,
                                    "value": src.defaultValue
                                });
                                drop.accept();
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            visible: isSlotEmpty

                            Text {
                                text: "EMPTY"
                                color: "#565f89"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "monospace"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Drag effect to Add"
                                color: "#414868"
                                font.pixelSize: 9
                                font.family: "monospace"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 6
                            active: !isSlotEmpty
                            visible: !isSlotEmpty
                            source: !isSlotEmpty ? "../modules/" + slotData.qmlSource : ""
                            onLoaded: {
                                if (item) {
                                    item.effectValue = slotData.value;
                                    item.effectIndex = busRow.busIndex;
                                    if (item.hasOwnProperty("title"))
                                        item.title = slotData.displayName || slotData.type;

                                    if (item.removeRequested)
                                        item.removeRequested.connect(() => busRow.workspace.clearBusEffect(busRow.busIndex, slotIndex));
                                    if (item.valueChanged)
                                        item.valueChanged.connect((idx, v) => busRow.workspace.updateBusEffectValue(busRow.busIndex, slotIndex, v));
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: leftFadeMask
            anchors.left: effectChainListView.left
            anchors.top: effectChainListView.top
            anchors.bottom: effectChainListView.bottom
            width: 50
            z: 10
            enabled: true

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#0d0d12" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Item {
            id: busTileAnchorPoint
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 180

            Canvas {
                anchors.fill: parent
                onPaint: {
                    let ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    let tipX = 0;
                    let arrowLength = 14;
                    let baseX = tipX + arrowLength;
                    let busTileLeftWall = parent.width - busTile.width - busTile.anchors.rightMargin;
                    ctx.strokeStyle = "white";
                    ctx.lineWidth = 2;
                    ctx.setLineDash([4, 4]);
                    ctx.beginPath();
                    ctx.moveTo(baseX, height / 2);
                    ctx.lineTo(busTileLeftWall, height / 2);
                    ctx.stroke();

                    ctx.fillStyle = "white";
                    ctx.setLineDash([]);
                    ctx.beginPath();
                    ctx.moveTo(tipX, height / 2 - 9);
                    ctx.lineTo(baseX, height / 2);
                    ctx.lineTo(tipX, height / 2 + 9);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            Rectangle {
                id: busTile
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 110
                height: 95
                color: "#16161E"
                border.color: "#3b4261"
                radius: 8

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 14
                    anchors.bottomMargin: 12
                    spacing: 0

                    Text {
                        text: "BUS " + busRow.busIndex
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "monospace"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }

                    Switch {
                        id: busSwitch
                        checked: true
                        scale: 0.75
                        Layout.alignment: Qt.AlignHCenter
                        indicator: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 20
                            radius: 10
                            color: busSwitch.checked ? "#ff007c" : "#3b4261"
                            Rectangle {
                                x: busSwitch.checked ? parent.width - width - 2 : 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                radius: 8
                                color: "white"
                                Behavior on x { NumberAnimation { duration: 120 } }
                            }
                        }
                    }
                }
            }
        }
    }
}