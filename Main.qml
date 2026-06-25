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

    property var busEffectsMatrix: [[null], [null], [null], [null]]
    property int matrixRevision: 0
    property real mainVolume: 80

    property int valueRevision: 0
    property int selectedBus: -1
    property int selectedSlot: -1
    readonly property var selectedEffect: (selectedBus >= 0 && selectedSlot >= 0 && busEffectsMatrix[selectedBus] && valueRevision >= 0) ? busEffectsMatrix[selectedBus][selectedSlot] : null

    /**

    Instantiates or overwrites an audio effect module within a specific slot of a bus.
    Deep-copies the targeted bus chain to safely update the QML matrix property,
    appends a trailing 'null' slot if a new element is added to allow for future drops,
    and increments 'matrixRevision' to notify binding expressions.

    */
    function setBusEffect(busIndex, slotIndex, moduleInfo) {
        let matrixCopy = busEffectsMatrix.slice();
        let busChain = matrixCopy[busIndex].slice();

        busChain[slotIndex] = {
            "type": moduleInfo.type,
            "displayName": moduleInfo.displayName,
            "qmlSource": moduleInfo.qmlSource,
            "value": moduleInfo.value,
            "mix": 100,
            "enabled": true,
            "hardwareMaps": {
                "Rotary": "None",
                "Button": "None",
                "Laser-1": "None",
                "Laser-2": "None",
                "Laser-3": "None"
            }
        };

        if (slotIndex === busChain.length - 1) {
            busChain.push(null);
        }

        matrixCopy[busIndex] = busChain;
        busEffectsMatrix = matrixCopy;
        matrixRevision++;
    }

    /**
        Removes an effect module from a specific bus slot and shifts subsequent effects down.
        Maintains a trailing 'null' slot placeholder for the user interface layout,
        safely updates dynamic selection indices to avoid referencing non-existent slots,
        and increments 'matrixRevision' to force UI view updates.
    */
    function clearBusEffect(busIndex, slotIndex) {
        let matrixCopy = busEffectsMatrix.slice();
        let busChain = matrixCopy[busIndex].slice();

        busChain.splice(slotIndex, 1);
        if (busChain.length === 0 || busChain[busChain.length - 1] !== null) {
            busChain.push(null);
        }

        matrixCopy[busIndex] = busChain;
        busEffectsMatrix = matrixCopy;

        if (selectedBus === busIndex && selectedSlot === slotIndex) {
            selectedBus = -1;
            selectedSlot = -1;
        } else if (selectedBus === busIndex && selectedSlot > slotIndex) {
            selectedSlot--;
        }

        matrixRevision++;
    }
    /**
        Updates the primary parameter value for a specific effect module in real time.
        Shallow-copies the targeted effect configuration object inside the matrix to apply
        the change safely, then increments 'valueRevision' to break read caches and
        force dependent QML visual components to re-evaluate their bindings.
        */
    function updateBusEffectValue(busIndex, slotIndex, newValue) {
        if (!busEffectsMatrix[busIndex] || !busEffectsMatrix[busIndex][slotIndex])
            return;
        let updatedEffect = Object.assign({}, busEffectsMatrix[busIndex][slotIndex]);
        updatedEffect.value = newValue;
        busEffectsMatrix[busIndex][slotIndex] = updatedEffect;
        valueRevision++;
    }

    /**
        Modifies a specific arbitrary property on the currently focused or selected effect module.
        Used by the sidebar controls to alter general metadata fields like 'mix' or 'enabled' states.
        Immutably reconstructs the target matrix chain and increments both 'matrixRevision'
        and 'valueRevision' to ensure global interface synchronization.
    */
    function updateSelectedEffectProperty(propName, value) {
        if (selectedBus < 0 || selectedSlot < 0)
            return;
        let matrixCopy = busEffectsMatrix.slice();
        let busChain = matrixCopy[selectedBus].slice();
        if (!busChain[selectedSlot])
            return;

        let updatedEffect = Object.assign({}, busChain[selectedSlot]);
        updatedEffect[propName] = value;

        busChain[selectedSlot] = updatedEffect;
        matrixCopy[selectedBus] = busChain;
        busEffectsMatrix = matrixCopy;
        matrixRevision++;
        valueRevision++;
    }

    /**
        Maps a physical hardware control interface component to an internal parameters macro.
        Injects a targeted control string into the selected effect's hardware mapping dictionary,
        linking elements like rotary dials or laser sensors directly to properties like cutoff,
        room size, or gain, before updating the matrix revision.
    */
    function updateSelectedEffectHardwareMap(hwName, targetParam) {
        if (selectedBus < 0 || selectedSlot < 0)
            return;
        let matrixCopy = busEffectsMatrix.slice();
        let busChain = matrixCopy[selectedBus].slice();
        if (!busChain[selectedSlot])
            return;

        let updatedEffect = Object.assign({}, busChain[selectedSlot]);
        updatedEffect.hardwareMaps = Object.assign({}, updatedEffect.hardwareMaps || {});
        updatedEffect.hardwareMaps[hwName] = targetParam;

        busChain[selectedSlot] = updatedEffect;
        matrixCopy[selectedBus] = busChain;
        busEffectsMatrix = matrixCopy;
        matrixRevision++;
    }

    /**
        Serializes the entire active mixer layout graph state into a JSON string payload.
        Logs the output dataset directly to the standard debugging terminal and triggers
        a timed, on-screen status toast confirmation notifying the user that the preset is safe.
    */

    function saveCurrentAsPreset() {
        console.log("Preset save requested:", JSON.stringify(serializeGraph()));
        statusToast.show("Preset saved");
    }

    /**
        Parses a raw hardware engine data payload and dynamically builds out the interface state.
        Resets existing selection focal points, normalizes raw 16-bit unsigned integer data from the
        DSP engine back into native UI percentages or frequencies, maps elements back to their
        original registry source structures, and signals a global matrix revision change.
        */
    function loadPreset(payload) {
        if (!payload)
            return;

        if (payload.main_volume !== undefined)
            mainVolume = Math.round((payload.main_volume / 65535) * 100);

        selectedBus = -1;
        selectedSlot = -1;
        let newMatrix = [];
        let buses = payload.audio_buses || [];

        for (let b = 0; b < 4; b++) {
            let busData = buses[b];
            let chain = [];

            if (busData && busData.effects) {
                for (let e = 0; e < busData.effects.length; e++) {
                    let ef = busData.effects[e];

                    let hwMaps = {
                        "Rotary": "None",
                        "Button": "None",
                        "Laser-1": "None",
                        "Laser-2": "None",
                        "Laser-3": "None"
                    };

                    let primaryValue = 50;
                    let effectMix = ef.mix !== undefined ? Math.round((ef.mix / 65535) * 100) : 100;
                    let effectEnabled = ef.enabled !== false;
                    let reverseHwId = {
                        "rotary_0": "Rotary",
                        "button": "Button",
                        "laser_1": "Laser-1",
                        "laser_2": "Laser-2",
                        "laser_3": "Laser-3"
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
                            } else if (param.key === "mix") {
                                effectMix = Math.round((param.value / 65535) * 100);
                            } else {
                                let v = param.value;
                                if (ef.effect_type === "low_pass_filter") {
                                    let hzPct = v / 65535;
                                    primaryValue = 20 + hzPct * (20000 - 20);
                                } else if (ef.effect_type === "gain" || ef.effect_type === "reverb" || ef.effect_type === "delay") {
                                    primaryValue = (v / 65535) * 100;
                                } else {
                                    primaryValue = v;
                                }

                                if (param.input_control_id && param.input_control_id !== "") {
                                    let hwName = reverseHwId[param.input_control_id] || param.input_control_id;
                                    let targetLabel = "Gain";
                                    if (ef.effect_type === "low_pass_filter")
                                        targetLabel = "Cutoff";
                                    else if (ef.effect_type === "reverb")
                                        targetLabel = "Room Size";
                                    else if (ef.effect_type === "delay")
                                        targetLabel = "Time";
                                    hwMaps[hwName] = targetLabel;
                                }
                            }
                        }
                    }

                    let registryModule = null;
                    if (typeof ModuleRegistry !== "undefined" && ModuleRegistry.modules) {
                        for (let m = 0; m < ModuleRegistry.modules.length; m++) {
                            if (ModuleRegistry.modules[m].effectType === ef.effect_type) {
                                registryModule = ModuleRegistry.modules[m];
                                break;
                            }
                        }
                    }

                    let fullQmlSource = registryModule ? registryModule.qmlSource : "";
                    chain.push({
                        "type": ef.effect_type,
                        "displayName": registryModule ? registryModule.displayName : ef.effect_type.toUpperCase(),
                        "qmlSource": fullQmlSource,
                        "value": primaryValue,
                        "mix": effectMix,
                        "enabled": effectEnabled,
                        "hardwareMaps": hwMaps
                    });
                }
            }

            chain.push(null);
            newMatrix.push(chain);
        }

        busEffectsMatrix = newMatrix;
        matrixRevision++;
    }
    /**
        Serializes and flattens the frontend QML effect matrix into a strict backend DSP topology.
        Translates standard operational percentages and cutoff scales into uniform 16-bit unsigned integers,
        maps specific device control identifiers to their low-level definitions, formats the active parameters array,
        and returns a structured topology schema payload prepared for transmission to the hardware audio engine.
    */
    function serializeGraph() {
        let mainVolumeU16 = Math.round((mainVolume / 100) * 65535);
        let jsonPayload = {
            "main_volume": mainVolumeU16,
            "audio_buses": []
        };

        for (let b = 0; b < busRepeaterMain.count; ++b) {
            let busItem = busRepeaterMain.itemAt(b);
            let busEnabled = !!(busItem && busItem.busSwitchChecked); // Sends true or false

            let busObj = {
                "id": "bus_" + b,
                "enabled": busEnabled,
                "effects": []
            };
            let chain = busEffectsMatrix[b];
            for (let s = 0; s < chain.length; s++) {
                let effect = chain[s];
                if (effect) {

                    let paramKey = "gain";
                    if (effect.type === "low_pass_filter")
                        paramKey = "frequency";
                    else
                    if (effect.type === "reverb")
                        paramKey = "room_size";
                    else if (effect.type === "delay")
                        paramKey = "frequency";
                    else if (effect.type === "gain")
                        paramKey = "gain";

                    let primaryInputControlId = "";
                    let enabledInputControlId = "";
                    let hardwareMaps = effect.hardwareMaps || {};
                    for (let hwName in hardwareMaps) {
                        let target = hardwareMaps[hwName];
                        let lowerName = hwName.toLowerCase();
                        let normalizedId = lowerName;

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

                    let finalValue = 0;
                    if (effect.type === "low_pass_filter") {
                        let hzPct = (effect.value - 20) / (20000 - 20);
                        finalValue = Math.round(hzPct * 65535);
                    } else if (effect.type === "gain" || effect.type === "reverb" || effect.type === "delay") {
                        finalValue = Math.round((effect.value / 100) * 65535);
                    } else {
                        finalValue = Math.round(effect.value);
                    }

                    finalValue = Math.min(Math.max(finalValue, 0), 65535);

                    let currentMix = effect.mix !== undefined ? effect.mix : 100;
                    let finalMixValue = Math.min(Math.max(Math.round((currentMix / 100) * 65535), 0), 65535);

                    let parametersArray = [
                        {
                            "key": paramKey,
                            "value": finalValue,
                            "input_control_id": primaryInputControlId
                        },
                        {
                            "key": "mix",
                            "value": finalMixValue,
                            "input_control_id": ""
                        }
                    ];

                    let effectEnabled = (effect.enabled !== false); // Sends true or false

                    busObj.effects.push({
                        "effect_type": effect.type,
                        "enabled": effectEnabled,
                        "mix": finalMixValue,
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

            Item {
                Layout.fillWidth: true
            }

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
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
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

                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                }

                Repeater {
                    id: busRepeaterMain
                    model: 3

                    delegate: BusSlot {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        busIndex: index
                        workspace: rootWindow
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                }
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

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

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