import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./qml"
import "./modules"

ApplicationWindow {
    id: rootWindow
    visible: true
    width: 1480
    height: 820
    minimumWidth: 1100
    minimumHeight: 650
    title: "Audio Router"
    color: "#0a0a0f"

    property var busEffectsMatrix: [ [null], [null], [null], [null] ]
    property int matrixRevision: 0
    property real mainVolume: 80

    // Global active selection tracking
    property int selectedBus: -1
    property int selectedSlot: -1
    readonly property var selectedEffect: (selectedBus >= 0 && selectedSlot >= 0 && busEffectsMatrix[selectedBus]) ? busEffectsMatrix[selectedBus][selectedSlot] : null

    function setBusEffect(busIndex, slotIndex, moduleInfo) {
        let matrixCopy = busEffectsMatrix.slice();
        let busChain = matrixCopy[busIndex].slice();

        // Enforce basic parameters and an empty mapping dictionary on drop
        busChain[slotIndex] = {
            "type": moduleInfo.type,
            "displayName": moduleInfo.displayName,
            "qmlSource": moduleInfo.qmlSource,
            "value": moduleInfo.value,
            "enabled": true,
            "hardwareMaps": { "Rotary": "None", "Button": "None", "Laser-1": "None", "Laser-2": "None", "Laser-3": "None" }
        };

        if (slotIndex === busChain.length - 1) {
            busChain.push(null);
        }

        matrixCopy[busIndex] = busChain;
        busEffectsMatrix = matrixCopy;
        matrixRevision++;
    }

    function clearBusEffect(busIndex, slotIndex) {
        let matrixCopy = busEffectsMatrix.slice();
        let busChain = matrixCopy[busIndex].slice();

        busChain.splice(slotIndex, 1);
        if (busChain.length === 0 || busChain[busChain.length - 1] !== null) {
            busChain.push(null);
        }

        matrixCopy[busIndex] = busChain;
        busEffectsMatrix = matrixCopy;

        // Clean up or adjust current active selection indices safely
        if (selectedBus === busIndex && selectedSlot === slotIndex) {
            selectedBus = -1;
            selectedSlot = -1;
        } else if (selectedBus === busIndex && selectedSlot > slotIndex) {
            selectedSlot--;
        }

        matrixRevision++;
    }

    function updateBusEffectValue(busIndex, slotIndex, newValue) {
        let matrixCopy = busEffectsMatrix.slice();
        let busChain = matrixCopy[busIndex].slice();

        if (!busChain[slotIndex]) return;
        busChain[slotIndex].value = newValue;
        matrixCopy[busIndex] = busChain;
        busEffectsMatrix = matrixCopy;
        matrixRevision++;
    }

        function updateSelectedEffectProperty(propName, value) {
            if (selectedBus < 0 || selectedSlot < 0) return;
            let matrixCopy = busEffectsMatrix.slice();
            let busChain = matrixCopy[selectedBus].slice();
            if (!busChain[selectedSlot]) return;

            // FIX: Force a fresh object reference assignment so QML captures the mutation instantly
            let updatedEffect = Object.assign({}, busChain[selectedSlot]);
            updatedEffect[propName] = value;

            busChain[selectedSlot] = updatedEffect;
            matrixCopy[selectedBus] = busChain;
            busEffectsMatrix = matrixCopy;
            matrixRevision++;
        }

        function updateSelectedEffectHardwareMap(hwName, targetParam) {
            if (selectedBus < 0 || selectedSlot < 0) return;
            let matrixCopy = busEffectsMatrix.slice();
            let busChain = matrixCopy[selectedBus].slice();
            if (!busChain[selectedSlot]) return;

            // FIX: Structural copy both the parent container and nested map dictionary definitions
            let updatedEffect = Object.assign({}, busChain[selectedSlot]);
            updatedEffect.hardwareMaps = Object.assign({}, updatedEffect.hardwareMaps || {});
            updatedEffect.hardwareMaps[hwName] = targetParam;

            busChain[selectedSlot] = updatedEffect;
            matrixCopy[selectedBus] = busChain;
            busEffectsMatrix = matrixCopy;
            matrixRevision++;
        }

    function saveCurrentAsPreset() {
        console.log("Preset save requested:", JSON.stringify(serializeGraph()));
        statusToast.show("Preset saved");
    }

    // Restore a previously serialised graph snapshot back into the workspace
    function loadPreset(payload) {
        if (!payload) return;

        // Restore main volume if present
        if (payload.main_volume !== undefined)
            mainVolume = payload.main_volume;

        // Clear selection first
        selectedBus  = -1;
        selectedSlot = -1;

        let newMatrix = [];
        let buses = payload.audio_buses || [];

        for (let b = 0; b < 4; b++) {
            let busData = buses[b];
            let chain   = [];

            if (busData && busData.effects) {
                for (let e = 0; e < busData.effects.length; e++) {
                    let ef = busData.effects[e];

                    // Rebuild the hardware maps from the parameters array
                    let hwMaps = {
                        "Rotary":  "None",
                        "Button":  "None",
                        "Laser-1": "None",
                        "Laser-2": "None",
                        "Laser-3": "None"
                    };

                    let primaryValue = 50;
                    let effectEnabled = ef.enabled !== false;

                    let reverseHwId = {
                        "rotary_0": "Rotary",
                        "button":   "Button",
                        "laser_1":  "Laser-1",
                        "laser_2":  "Laser-2",
                        "laser_3":  "Laser-3"
                    };

                    if (ef.parameters) {
                        for (let p = 0; p < ef.parameters.length; p++) {
                            let param = ef.parameters[p];
                            if (param.key === "enabled") {
                                effectEnabled = param.value !== 0;
                                if (param.input_control_id && param.input_control_id !== "") {
                                    let hwName = reverseHwId[param.input_control_id] || param.input_control_id;
                                    hwMaps[hwName] = "Enabled";
                                }
                            } else {
                                // Reverse the gain 32767 → 100 normalisation
                                let v = param.value;
                                if (param.key === "gain" && v === 32767) v = 100;
                                primaryValue = v;

                                if (param.input_control_id && param.input_control_id !== "") {
                                    let hwName = reverseHwId[param.input_control_id] || param.input_control_id;
                                    let targetLabel = "Gain";
                                    if (ef.effect_type === "low_pass_filter") targetLabel = "Cutoff";
                                    else if (ef.effect_type === "reverb")     targetLabel = "Room Size";
                                    else if (ef.effect_type === "delay")      targetLabel = "Time";
                                    hwMaps[hwName] = targetLabel;
                                }
                            }
                        }
                    }

                    // find the matching module descriptor from your ModuleRegistry singleton
                    let registryModule = null;
                    if (typeof ModuleRegistry !== "undefined" && ModuleRegistry.modules) {
                        for (let m = 0; m < ModuleRegistry.modules.length; m++) {
                            if (ModuleRegistry.modules[m].effectType === ef.effect_type) {
                                registryModule = ModuleRegistry.modules[m];
                                break;
                            }
                        }
                    }

                    let fullQmlSource = registryModule.qmlSource;

                    chain.push({
                        "type":        ef.effect_type,
                        "displayName": registryModule.displayName,
                        "qmlSource":   fullQmlSource,
                        "value":       primaryValue,
                        "enabled":     effectEnabled,
                        "hardwareMaps": hwMaps
                    });
                }
            }

            // Always terminate each chain with a null drop-target slot
            chain.push(null);
            newMatrix.push(chain);
        }

        busEffectsMatrix = newMatrix;
        matrixRevision++;
    }

    function serializeGraph() {
        let jsonPayload = { "main_volume": mainVolume, "audio_buses": [] };

        for (let b = 0; b < busRepeaterMain.count; ++b) {
            let busItem = busRepeaterMain.itemAt(b);
            let busObj = {
                "id": "bus_" + b,
                "enabled": busItem ? busItem.busSwitchChecked : true,
                "effects": []
            };

            let chain = busEffectsMatrix[b];
            for (let s = 0; s < chain.length; s++) {
                let effect = chain[s];
                if (effect) { // skip trailing structural nulls
                    let paramKey = "gain";
                    if (effect.type === "low_pass_filter") paramKey = "cutoff";
                    else if (effect.type === "reverb") paramKey = "room_size";
                    else if (effect.type === "delay") paramKey = "time";
                    else if (effect.type === "gain") paramKey = "gain";

                    // Scan the hardware configurations for active routing targets
                    let primaryInputControlId = "";
                    let enabledInputControlId = "";
                    let hardwareMaps = effect.hardwareMaps || {};

                    for (let hwName in hardwareMaps) {
                        let target = hardwareMaps[hwName];
                        let lowerName = hwName.toLowerCase();
                        let normalizedId = lowerName;

                        // Normalize standard component names to lower_snake_case
                        if (lowerName === "rotary") {
                            normalizedId = "rotary_0";
                        } else if (lowerName.startsWith("laser-")) {
                            normalizedId = lowerName.replace("-", "_");
                        }

                        if (target === "Enabled") {
                            enabledInputControlId = normalizedId;
                        } else if (target !== "None" && target !== "") {
                            primaryInputControlId = normalizedId;
                        }
                    }

                    // Handle peak integer constraints (e.g. mapping 100% UI to 32767 scale value)
                    let finalValue = Math.round(effect.value);
                    if (paramKey === "gain" && finalValue === 100) {
                        finalValue = 32767;
                    }

                    // Build parameters array holding both the target lane configuration and bypass lane routing
                    let parametersArray = [
                        {
                            "key": paramKey,
                            "value": finalValue,
                            "input_control_id": primaryInputControlId
                        },
                        {
                            "key": "enabled",
                            "value": (effect.enabled !== false) ? 1 : 0,
                            "input_control_id": enabledInputControlId
                        }
                    ];

                    busObj.effects.push({
                        "effect_type": effect.type === "low_pass_filter" ? "low_pass_filter" : effect.type,
                        "enabled": effect.enabled !== false,
                        "mix": 100,
                        "parameters": parametersArray
                    });
                }
            }
            jsonPayload.audio_buses.push(busObj);
        }

        console.log("Generated DSP Topology:", JSON.stringify(jsonPayload, null, 2));
        return jsonPayload;
    }

    function transmitGraphData(payload) {
        interfaceBridge.sendGraphData(JSON.stringify(payload));
        statusToast.show("Sent to Guitar");
    }

    // ---- Top header bar ----
    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 70
        color: "#0a0a0f"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 20

            Text {
                text: "AUDIO ROUTER"
                color: "white"
                font.pixelSize: 30
                font.bold: true
                font.family: "monospace"
                font.letterSpacing: 2
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 320
                Layout.preferredHeight: 44
                color: "transparent"
                border.color: "#3b4261"
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 14

                    Text {
                        text: "Main Volume"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "monospace"
                    }

                    Slider {
                        id: mainVolumeSlider
                        from: 0
                        to: 100
                        value: rootWindow.mainVolume
                        Layout.fillWidth: true

                        background: Rectangle {
                            x: mainVolumeSlider.leftPadding
                            y: mainVolumeSlider.topPadding + mainVolumeSlider.availableHeight / 2 - height / 2
                            width: mainVolumeSlider.availableWidth
                            height: 4
                            radius: 2
                            color: "#3b4261"

                            Rectangle {
                                width: mainVolumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: "white"
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: mainVolumeSlider.leftPadding + mainVolumeSlider.visualPosition * (mainVolumeSlider.availableWidth - width)
                            y: mainVolumeSlider.topPadding + mainVolumeSlider.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: "#ff007c"
                            border.color: "white"
                            border.width: 2
                        }

                        onMoved: rootWindow.mainVolume = value
                    }
                }
            }

            Button {
                id: sendButton
                Layout.preferredWidth: 170
                Layout.preferredHeight: 44

                background: Rectangle {
                    color: sendButton.hovered ? "#e5006e" : "#ff007c"
                    radius: 22
                }

                contentItem: Text {
                    text: "SEND TO GUITAR"
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "monospace"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    let activeGraph = rootWindow.serializeGraph();
                    rootWindow.transmitGraphData(activeGraph);
                }
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: interfaceBridge.isConnected ? "#9ece6a" : "#f7768e"
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    text: interfaceBridge.isConnected ? "Connected to Rust DSP" : "Disconnected (Click to retry)"
                    color: "#565f89"
                    font.pixelSize: 11
                    font.family: "monospace"
                    Layout.alignment: Qt.AlignVCenter

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
            }
        }
    }

    // ---- Main content row ----
    RowLayout {
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 20

        ColumnLayout {
            Layout.minimumWidth: 270
            Layout.maximumWidth: 270
            Layout.preferredWidth: 270

            Layout.fillHeight: true
            spacing: 20

            Effects_panel {
                id: fxPanel
                Layout.fillWidth: true
                workspace: rootWindow
            }

            PresetsPanel {
                id: presetsPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                workspace: rootWindow
            }
        }

        // ---- Center routing panel ----
        Rectangle {
            id: routingPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0d0d12"
            border.color: "#24283b"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 12

                Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }

                Repeater {
                    id: busRepeaterMain
                    model: 4

                    delegate: BusSlot {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        busIndex: index
                        workspace: rootWindow
                    }
                }

                Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }
            }
        }

        ConfigPanel {
            id: configPanel
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            workspace: rootWindow
        }
    }

    Rectangle {
        id: statusToast
        property bool visibleFlag: false
        function show(msg) {
            toastText.text = msg;
            visibleFlag = true;
            toastTimer.restart();
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30
        width: toastText.implicitWidth + 32
        height: 38
        radius: 19
        color: "#16161E"
        border.color: "#9ece6a"
        opacity: visibleFlag ? 1 : 0
        visible: opacity > 0
        z: 200

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            id: toastText
            anchors.centerIn: parent
            color: "#9ece6a"
            font.pixelSize: 12
            font.bold: true
            font.family: "monospace"
        }

        Timer {
            id: toastTimer
            interval: 1800
            onTriggered: statusToast.visibleFlag = false
        }
    }
}