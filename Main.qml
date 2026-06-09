import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./qml"
import "./modules"

ApplicationWindow {
    id: rootWindow
    visible: true
    width: 1000
    height: 600
    title: "Audio DSP Router"
    color: "#0f1015"

    ListModel { id: canvasEffectsModel }

    // Internal Data Layer Tracking Active Connection Cables
    ListModel {
        id: connectionsModel
        onCountChanged: workspace.serializeGraph()
    }

    Item {
        id: workspace
        anchors.fill: parent

        // Drag Routing State Tracking Properties
        property var activeSourceNode: null
        property var activeSourcePin: null
        property string activePortType: ""
        property bool isDrawingLine: false
        property point currentMousePos: Qt.point(0, 0)

        function startConnection(node, pin, portType) {
            activeSourceNode = node;
            activeSourcePin = pin;
            activePortType = portType;
            isDrawingLine = true;
        }

        function completeConnection(targetNode, targetPin, portType) {
            if (isDrawingLine && activePortType !== portType) {
                // Eliminate duplicated connection routing layouts
                for (let i = 0; i < connectionsModel.count; ++i) {
                    if (connectionsModel.get(i).targetId === targetNode.effectId) return;
                }

                let p1 = activeSourcePin.mapToItem(workspace, activeSourcePin.width/2, activeSourcePin.height/2);
                let p2 = targetPin.mapToItem(workspace, targetPin.width/2, targetPin.height/2);

                connectionsModel.append({
                    "sourceId": activeSourceNode.controlId || activeSourceNode.effectId,
                    "targetId": targetNode.effectId,
                    "sourceType": activePortType,
                    "targetType": portType
                });
            }
            resetRoutingState();
        }

        function resetRoutingState() {
            isDrawingLine = false;
            activeSourceNode = null;
            activeSourcePin = null;
            activePortType = "";
            connectionCanvas.requestPaint();
        }

        // --- JSON Data Sync Pipeline ---
        function serializeGraph() {
            let jsonPayload = {
                "control_inputs": [
                    { "id": "rotary_1", "control_type": "rotary" }
                ],
                "audio_buses": []
            };

            // Hardcoded representation mimicking application layout scope logic
            for (let b = 1; b <= 4; ++b) {
                let busObj = { "id": "bus_" + b, "enabled": true, "effects": [] };

                // Parse dynamic canvas configurations
                for (let i = 0; i < canvasEffectsModel.count; ++i) {
                    let effect = canvasEffectsModel.get(i);
                    let connectedControlId = "";

                    // Cross-reference backend data map with connection lines
                    for (let c = 0; c < connectionsModel.count; ++c) {
                        let conn = connectionsModel.get(c);
                        if (conn.targetId === "effect_" + i) {
                            connectedControlId = conn.sourceId;
                        }
                    }

                    busObj.effects.push({
                        "id": "effect_" + i,
                        "effect_type": effect.type,
                        "parameters": [
                            {
                                "key": "param",
                                "value": String(effect.value),
                                "input_control_id": connectedControlId
                            }
                        ]
                    });
                }
                jsonPayload.audio_buses.push(busObj);
            }

            // Output data packet ready to dispatch to network endpoint
            console.log(JSON.stringify(jsonPayload, null, 2));
            return jsonPayload;
        }

        function findNodeItem(id) {
            // Check standalone inputs first
            if (standaloneControlInput.controlId === id || standaloneControlInput.id === id) {
                return standaloneControlInput; // Assuming it has an output pin property
            }

            // Check dynamic effects loop
            for (let i = 0; i < workspace.children.length; ++i) {
                let child = workspace.children[i];
                // Ensure child is a Loader and has the generated effectId
                if (child.item && child.item.effectId === id) {
                    return child.item;
                }
            }
            return null;
        }

        // Interactive Tracking Mouse Layer
        MouseArea {
            anchors.fill: parent
            enabled: workspace.isDrawingLine
            preventStealing: true
            propagateComposedEvents: true
            onPositionChanged: (mouse) => {
                workspace.currentMousePos = Qt.point(mouse.x, mouse.y);
                connectionCanvas.requestPaint();
            }
            onReleased: workspace.resetRoutingState();
        }

        // Routing Wire Canvas Renderer Overlay
        Canvas {
            id: connectionCanvas
            anchors.fill: parent
            z: 1

            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.lineWidth = 3;

                // 1. Render Registered Node Routes
                for (let i = 0; i < connectionsModel.count; ++i) {
                    let connection = connectionsModel.get(i);
                    let ctx = getContext("2d");
                    ctx.strokeStyle = "#7aa2f7";

                    let sourceModule = workspace.findNodeItem(connection.sourceId);
                    let targetModule = workspace.findNodeItem(connection.targetId);

                    if (sourceModule && targetModule) {
                        // MAGIC FIX: Look for the specific exposed pin properties.
                        // If they don't exist, fallback to the whole module.
                        let srcPin = sourceModule.outputPin ? sourceModule.outputPin : sourceModule;
                        let tgtPin = targetModule.inputPin ? targetModule.inputPin : targetModule;

                        // Map relative to the specific pins, not the whole block
                        let p1 = srcPin.mapToItem(workspace, srcPin.width/2, srcPin.height/2);
                        let p2 = tgtPin.mapToItem(workspace, tgtPin.width/2, tgtPin.height/2);

                        ctx.beginPath();
                        ctx.moveTo(p1.x, p1.y);
                        ctx.bezierCurveTo(p1.x + 50, p1.y, p2.x - 50, p2.y, p2.x, p2.y);
                        ctx.stroke();
                    }
                }

                // 2. Render Temporary Active Drag Vector Wire
                if (workspace.isDrawingLine && workspace.activeSourcePin) {
                    let startPos = workspace.activeSourcePin.mapToItem(workspace, workspace.activeSourcePin.width/2, workspace.activeSourcePin.height/2);
                    ctx.strokeStyle = "#ff007c";
                    ctx.beginPath();
                    ctx.moveTo(startPos.x, startPos.y);
                    ctx.bezierCurveTo(startPos.x + 50, startPos.y, workspace.currentMousePos.x - 50, workspace.currentMousePos.y, workspace.currentMousePos.x, workspace.currentMousePos.y);
                    ctx.stroke();
                }
            }
        }

        DropArea {
            id: workspaceDropArea
            anchors.fill: parent
            keys: typeof ModuleRegistry !== "undefined" ? ModuleRegistry.modules.map(m => m.effectType) : []

            onDropped: (drop) => {
                let src = drop.source;
                let targetX = drop.x - (src.width / 2);
                let targetY = drop.y - (src.height / 2);

                if (drop.y > effectsPanel.y && drop.x < (effectsPanel.x + effectsPanel.width)) {
                    drop.action = Qt.IgnoreAction;
                    return;
                }

                canvasEffectsModel.append({
                    "type": src.effectType,
                    "value": src.defaultValue,
                    "qmlSource": src.qmlSource,
                    "posX": targetX,
                    "posY": targetY
                });
                drop.accept();
                workspace.serializeGraph();
            }
        }

        Repeater {
            model: canvasEffectsModel
            delegate: Loader {
                id: moduleLoader
                x: model.posX
                y: model.posY
                source: typeof ModuleRegistry !== "undefined" ? "./modules/" + model.qmlSource : ""
                Drag.active: dragSpaceArea.drag.active

                MouseArea {
                    id: dragSpaceArea
                    anchors.fill: parent
                    drag.target: parent
                    onPositionChanged: connectionCanvas.requestPaint()
                    onReleased: {
                        if (dragSpaceArea.drag.active) {
                            model.posX = parent.x;
                            model.posY = parent.y;
                            connectionCanvas.requestPaint();
                        }
                    }
                }

                onLoaded: {
                    if (item.hasOwnProperty("isSourceTile")) item.isSourceTile = false;
                    if (item.hasOwnProperty("effectId")) item.effectId = "effect_" + index;

                    if (item.removeRequested) {
                        item.removeRequested.connect(function() {
                            canvasEffectsModel.remove(index);
                            workspace.serializeGraph();
                        });
                    }
                }
            }
        }
    }

    Control_input {
        id: standaloneControlInput
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
    }

    Rectangle {
        id: effectsPanel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        width: 460
        height: 180
        color: "#16161E"
        border.color: "#3b4261"
        radius: 8

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Text {
                text: "AVAILABLE EFFECTS"
                color: "white"
                font.pixelSize: 14
                font.bold: true
                font.family: "monospace"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 15

                Repeater {
                    model: typeof ModuleRegistry !== "undefined" ? ModuleRegistry.modules : []

                    delegate: Item {
                        id: dragSourceItem
                        width: 140
                        height: 120

                        property string effectType: modelData.effectType
                        property string qmlSource: modelData.qmlSource
                        property real defaultValue: modelData.defaultValue

                        Item {
                            id: tile
                            anchors.fill: parent

                            Loader {
                                anchors.fill: parent
                                source: typeof ModuleRegistry !== "undefined" ? "./modules/" + modelData.qmlSource : ""

                                onLoaded: {
                                    if (item.hasOwnProperty("isSourceTile")) {
                                        item.isSourceTile = true;
                                    }
                                }
                            }

                            Drag.active: dragArea.drag.active
                            Drag.keys: [modelData.effectType]
                            Drag.source: dragSourceItem
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2

                            states: State {
                                when: dragArea.drag.active

                                ParentChange {
                                    target: tile
                                    parent: rootWindow.contentItem
                                }

                                PropertyChanges {
                                    target: tile
                                    anchors.fill: undefined
                                    width: dragSourceItem.width
                                    height: dragSourceItem.height
                                    opacity: 0.8
                                }
                            }
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            drag.target: tile
                            onReleased: tile.Drag.drop()
                        }
                    }
                }
            }
        }
    }

    Column {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        Repeater {
            model: 4
            delegate: Rectangle {
                width: 80
                height: 120
                color: "#16161E"
                border.color: "#3b4261"
                radius: 8

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 5

                    Text {
                        text: "BUS " + (index + 1)
                        color: "white"
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "monospace"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }

                    Switch {
                        checked: true
                        scale: 0.6
                        Layout.alignment: Qt.AlignHCenter
                        palette.button: "white"
                    }
                }
            }
        }
    }
}