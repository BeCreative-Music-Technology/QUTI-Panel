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
    ListModel { id: connectionsModel }

    Item {
        id: workspace
        anchors.fill: parent

        property var activeSourceNode: null
        property var activeSourcePin: null
        property string activePortType: ""
        property bool isDrawingLine: false
        property point currentMousePos: Qt.point(0, 0)

        function requestRepaint() {
            connectionCanvas.requestPaint();
        }

        function startConnection(node, pin, portType) {
            activeSourceNode = node;
            activeSourcePin = pin;
            activePortType = portType;
            isDrawingLine = true;
        }

        function completeConnection(targetNode, targetPin, portType) {
            if (isDrawingLine && activePortType === portType) {

                if (portType === "effect_out") {
                    let busId = targetNode.busId;

                    for (let i = connectionsModel.count - 1; i >= 0; --i) {
                        if (connectionsModel.get(i).sourceId === activeSourceNode.effectId &&
                            connectionsModel.get(i).targetType === "audio_bus") {
                            connectionsModel.remove(i);
                        }
                    }

                    connectionsModel.append({
                        "sourceId": activeSourceNode.effectId,
                        "targetId": busId,
                        "sourceType": "effect_out",
                        "targetType": "audio_bus"
                    });
                } else {
                    for (let i = 0; i < connectionsModel.count; ++i) {
                        if (connectionsModel.get(i).targetId === targetNode.effectId) return;
                    }

                    connectionsModel.append({
                        "sourceId": activeSourceNode.controlId || activeSourceNode.effectId,
                        "targetId": targetNode.effectId,
                        "sourceType": activePortType,
                        "targetType": portType
                    });
                }
            }
            resetRoutingState();
        }

        function findPinAt(point) {
            if (workspace.activePortType === "effect_out" && busPanel) {
                let busTarget = busPanel.getBusPinAt(point, workspace);
                if (busTarget) {
                    return { node: busTarget, pin: busTarget.pin, type: "effect_out" };
                }
            }

            if (standaloneControlInput && standaloneControlInput.outputPin && standaloneControlInput.outputPin.visible) {
                let pin = standaloneControlInput.outputPin;
                let pos = pin.mapToItem(workspace, 0, 0);
                if (point.x >= pos.x && point.x <= pos.x + pin.width &&
                    point.y >= pos.y && point.y <= pos.y + pin.height) {
                    return { node: standaloneControlInput, pin: pin, type: "control" };
                }
            }

            for (let i = 0; i < canvasEffectsModel.count; ++i) {
                let node = findNodeItem("effect_" + i);
                if (!node) continue;

                if (node.inputPin && node.inputPin.visible) {
                    let pin = node.inputPin;
                    let pos = pin.mapToItem(workspace, 0, 0);
                    if (point.x >= pos.x && point.x <= pos.x + pin.width &&
                        point.y >= pos.y && point.y <= pos.y + pin.height) {
                        return { node: node, pin: pin, type: "control" };
                    }
                }
            }
            return null;
        }

        function disconnectTarget(targetId) {
            let removedAny = false;
            for (let i = connectionsModel.count - 1; i >= 0; --i) {
                if (connectionsModel.get(i).targetId === targetId || connectionsModel.get(i).sourceId === targetId) {
                    connectionsModel.remove(i);
                    removedAny = true;
                }
            }
            if (removedAny) connectionCanvas.requestPaint();
        }

        function resetRoutingState() {
            isDrawingLine = false;
            activeSourceNode = null;
            activeSourcePin = null;
            activePortType = "";
            connectionCanvas.requestPaint();
        }

        function serializeGraph() {
            let jsonPayload = {
                "audio_buses": []
            };

            for (let b = 0; b <= 3; ++b) {
                let busId = "bus_" + b;
                let busEnabled = busPanel.isBusEnabled(busId);
                let busObj = { "id": busId, "enabled": busEnabled, "effects": [] };

                for (let c = 0; c < connectionsModel.count; ++c) {
                    let conn = connectionsModel.get(c);
                    if (conn.targetId === busId && conn.targetType === "audio_bus") {
                        let effectId = conn.sourceId;
                        let idx = parseInt(effectId.replace("effect_", ""));

                        if (idx >= 0 && idx < canvasEffectsModel.count) {
                            let effect = canvasEffectsModel.get(idx);
                            let connectedControlId = "";

                            for (let k = 0; k < connectionsModel.count; ++k) {
                                let ctrlConn = connectionsModel.get(k);
                                if (ctrlConn.targetId === effectId && ctrlConn.targetType === "control") {
                                    connectedControlId = ctrlConn.sourceId;
                                }
                            }

                            // Map the correct parameter keys
                            let paramKey = "gain";
                            if (effect.type === "low_pass_filter") paramKey = "cutoff";
                            else if (effect.type === "reverb") paramKey = "room_size";
                            else if (effect.type === "delay") paramKey = "time";

                            busObj.effects.push({
                                "effect_type": effect.type,
                                "mix": 100,
                                "parameters": [
                                    {
                                        "key": effect.parameterKey || paramKey,
                                        "value": parseInt(effect.value, 10),
                                        "input_control_id": connectedControlId
                                    }
                                ]
                            });
                        }
                    }
                }
                jsonPayload.audio_buses.push(busObj);
            }

            console.log("Generated DSP Topology:", JSON.stringify(jsonPayload, null, 2));
            return jsonPayload;
        }

        function transmitGraphData(payload) {
            interfaceBridge.sendGraphData(JSON.stringify(payload));

        }

        function findNodeItem(id) {
            if (standaloneControlInput.controlId === id || standaloneControlInput.id === id) {
                return standaloneControlInput;
            }
            for (let i = 0; i < workspace.children.length; ++i) {
                let child = workspace.children[i];
                if (child.item && child.item.effectId === id) {
                    return child.item;
                }
            }
            return null;
        }

        MouseArea {
            id: trackingArea
            anchors.fill: parent
            enabled: workspace.isDrawingLine
            visible: workspace.isDrawingLine
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            z: 100

            onPositionChanged: (mouse) => {
                workspace.currentMousePos = Qt.point(mouse.x, mouse.y);
                connectionCanvas.requestPaint();
            }

            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    workspace.resetRoutingState();
                    return;
                }

                let target = workspace.findPinAt(Qt.point(mouse.x, mouse.y));
                if (target && target.type === workspace.activePortType) {
                    workspace.completeConnection(target.node, target.pin, target.type);
                } else {
                    workspace.resetRoutingState();
                }
            }
        }

        Canvas {
            id: connectionCanvas
            anchors.fill: parent
            z: 1

            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.lineWidth = 3;

                for (let i = 0; i < connectionsModel.count; ++i) {
                    let connection = connectionsModel.get(i);

                    if (connection.targetType === "audio_bus") {
                        ctx.strokeStyle = "#bb9af7";
                        let sourceModule = workspace.findNodeItem(connection.sourceId);
                        if (sourceModule) {
                            let srcPin = sourceModule.outputPin ? sourceModule.outputPin : sourceModule;
                            let p1 = srcPin.mapToItem(workspace, srcPin.width / 2, srcPin.height / 2);
                            let p2 = busPanel.getBusPinById(connection.targetId, workspace);

                            if (p2) {
                                ctx.beginPath();
                                ctx.moveTo(p1.x, p1.y);
                                ctx.bezierCurveTo(p1.x + 80, p1.y, p2.x - 80, p2.y, p2.x, p2.y);
                                ctx.stroke();
                            }
                        }
                    } else {
                        ctx.strokeStyle = "#7aa2f7";
                        let sourceModule = workspace.findNodeItem(connection.sourceId);
                        let targetModule = workspace.findNodeItem(connection.targetId);
                        if (sourceModule && targetModule) {
                            let srcPin = sourceModule.outputPin ? sourceModule.outputPin : sourceModule;
                            let tgtPin = targetModule.inputPin ? targetModule.inputPin : targetModule;

                            let p1 = srcPin.mapToItem(workspace, srcPin.width / 2, srcPin.height / 2);
                            let p2 = tgtPin.mapToItem(workspace, tgtPin.width / 2, tgtPin.height / 2);

                            ctx.beginPath();
                            ctx.moveTo(p1.x, p1.y);
                            ctx.bezierCurveTo(p1.x + 50, p1.y, p2.x - 50, p2.y, p2.x, p2.y);
                            ctx.stroke();
                        }
                    }
                }

                if (workspace.isDrawingLine && workspace.activeSourcePin) {
                    let startPos = workspace.activeSourcePin.mapToItem(workspace, workspace.activeSourcePin.width / 2, workspace.activeSourcePin.height / 2);
                    ctx.strokeStyle = workspace.activePortType === "effect_out" ? "#bb9af7" : "#ff007c";
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
                if (drop.y > fxPanel.y && drop.x < (fxPanel.x + fxPanel.width)) {
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
            }
        }

        Repeater {
            model: canvasEffectsModel
            delegate: Loader {
                id: moduleLoader
                x: model.posX
                y: model.posY

                onXChanged: connectionCanvas.requestPaint()
                onYChanged: connectionCanvas.requestPaint()

                source: typeof ModuleRegistry !== "undefined" ? "./modules/" + model.qmlSource : ""
                Drag.active: dragSpaceArea.drag.active

                MouseArea {
                    id: dragSpaceArea
                    anchors.fill: parent
                    drag.target: parent

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
                    if (item.hasOwnProperty("router")) item.router = workspace;
                    if (item.removeRequested) {
                        item.removeRequested.connect(() => {
                            workspace.disconnectTarget("effect_" + index);
                            canvasEffectsModel.remove(index);
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
        router: workspace
    }

    Effects_panel {
        id: fxPanel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        workspace: workspace
    }

    Bus_panel {
        id: busPanel
        anchors.right: parent.right
        anchors.top: parent.top
        workspace: workspace
    }

    Item {
            id: statusContainer
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 20
            width: statusLayout.implicitWidth
            height: statusLayout.implicitHeight
            z: 110

            RowLayout {
                id: statusLayout
                anchors.fill: parent
                spacing: 8

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: interfaceBridge.isConnected ? "#9ece6a" : "#f7768e"
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    text: interfaceBridge.isConnected ? "Connected to Rust DSP" : "Disconnected (Click to retry)"
                    color: "#c0caf5"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!interfaceBridge.isConnected) {
                        interfaceBridge.connectToServer();
                    }
                }
            }
        }

        // 2. Send Button (Shifted up slightly to sit on top of the status indicator)
        Button {
            id: sendButton
            anchors.right: parent.right
            anchors.bottom: statusContainer.top // Anchored to the top of the status text
            anchors.rightMargin: 20
            anchors.bottomMargin: 12            // 12px vertical gap between button and text
            width: 160
            height: 45
            z: 110

            background: Rectangle {
                color: sendButton.hovered ? "#e5006e" : "#ff007c"
                radius: parent.height / 2
            }

            contentItem: Text {
                text: "Send to Guitar"
                color: sendButton.hovered ? "white" : "#1a1b26"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: (mouse) => {
                let activeGraph = workspace.serializeGraph();
                workspace.transmitGraphData(activeGraph);
            }
        }
}