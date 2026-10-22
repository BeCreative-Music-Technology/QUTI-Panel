import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./qml"

ApplicationWindow {
    id: rootWindow
    visible: true
    width: 1480
    height: 820
    minimumWidth: 1100
    minimumHeight: 650
    title: "Audio Router"
    color: "#0a0a0f"

    // Must match the number of audio buses the engine creates (bus_0 .. bus_2)
    readonly property int busCount: 3
    property var busEffectsMatrix: [[null], [null], [null]]
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
            "hardwareMaps": ModuleRegistry.emptyHardwareMaps()
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
        Lists every effect a hardware control is mapped to, e.g. ["Bus 1 · REVERB · Mix"].
        Used for the controller overview in the configuration panel.
    */
    function hardwareAssignments(hwName) {
        let assignments = [];
        for (let b = 0; b < busCount; b++) {
            let chain = busEffectsMatrix[b] || [];
            for (let s = 0; s < chain.length; s++) {
                let effect = chain[s];
                let target = effect && effect.hardwareMaps ? effect.hardwareMaps[hwName] : undefined;
                if (target && ModuleRegistry.controlByLabel(effect.type, target))
                    assignments.push("Bus " + b + " · " + effect.displayName + " · " + target);
            }
        }
        return assignments;
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
        Shows a short status message at the top of the window. Used by child panels,
        which cannot reach the 'statusToast' id directly.
    */
    function showStatus(message) {
        statusToast.show(message);
    }

    function percentToU16(percent) {
        return Math.min(Math.max(Math.round((percent / 100) * 65535), 0), 65535);
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

        for (let b = 0; b < busCount; b++) {
            let busData = buses[b];
            let chain = [];

            if (busData && busData.effects) {
                for (let e = 0; e < busData.effects.length; e++) {
                    let ef = busData.effects[e];
                    let registryModule = ModuleRegistry.find(ef.effect_type);
                    if (!registryModule) {
                        console.warn("Preset contains unknown effect type, skipped:", ef.effect_type);
                        continue;
                    }

                    let hwMaps = ModuleRegistry.emptyHardwareMaps();

                    let primaryValue = registryModule.defaultValue;
                    let effectMix = ef.mix !== undefined ? Math.round((ef.mix / 65535) * 100) : 100;
                    let effectEnabled = ef.enabled !== false;

                    let controls = ModuleRegistry.controls(ef.effect_type);
                    let parameters = ef.parameters || [];
                    for (let p = 0; p < parameters.length; p++) {
                        let param = parameters[p];
                        if (param.key === registryModule.parameter.key)
                            primaryValue = ModuleRegistry.fromEngineValue(ef.effect_type, param.value);

                        let hwName = ModuleRegistry.hardwareControlName(param.input_control_id || "");
                        let control = controls.find(c => c.key === param.key);
                        if (hwName && control)
                            hwMaps[hwName] = control.label;
                    }

                    chain.push({
                        "type": ef.effect_type,
                        "displayName": registryModule.displayName,
                        "qmlSource": registryModule.qmlSource,
                        "value": primaryValue,
                        "mix": effectMix,
                        "enabled": effectEnabled,
                        "hardwareMaps": hwMaps
                    });
                }
            }

            chain.push(null);
            newMatrix.push(chain);

            let busItem = busRepeaterMain.itemAt(b);
            if (busItem)
                busItem.busSwitchChecked = !busData || busData.enabled !== false;
        }

        busEffectsMatrix = newMatrix;
        matrixRevision++;
    }
    /**
        Serializes the frontend QML effect matrix into the engine's configuration message
        (see PickupProcessor/api_contract.json). Parameter keys, value ranges and the extra
        parameters each effect requires come from ModuleRegistry, so they stay in sync with the engine.
    */
    function serializeGraph() {
        let jsonPayload = {
            "main_volume": percentToU16(mainVolume),
            "audio_buses": []
        };

        for (let b = 0; b < busCount; ++b) {
            let busItem = busRepeaterMain.itemAt(b);
            let busObj = {
                "id": "bus_" + b,
                "enabled": !!(busItem && busItem.busSwitchChecked),
                "effects": []
            };

            let chain = busEffectsMatrix[b] || [];
            for (let s = 0; s < chain.length; s++) {
                let effect = chain[s];
                if (!effect)
                    continue;

                let registryModule = ModuleRegistry.find(effect.type);
                if (!registryModule) {
                    console.warn("Unknown effect type, not sent:", effect.type);
                    continue;
                }

                let mixValue = percentToU16(effect.mix !== undefined ? effect.mix : 100);

                let primaryKey = registryModule.parameter.key;
                let primaryValue = ModuleRegistry.toEngineValue(effect.type, effect.value);

                // Each hardware control driving a parameter becomes its own parameter entry, because
                // the engine binds one control input per entry. Unmapped and unknown targets are skipped.
                let bindings = [];
                let hardwareMaps = effect.hardwareMaps || {};
                for (let h = 0; h < ModuleRegistry.hardwareControls.length; h++) {
                    let hardwareControl = ModuleRegistry.hardwareControls[h];
                    let control = ModuleRegistry.controlByLabel(effect.type, hardwareMaps[hardwareControl.name]);
                    if (control)
                        bindings.push({ "key": control.key, "id": hardwareControl.id });
                }

                let primaryBindings = bindings.filter(binding => binding.key === primaryKey);
                let parametersArray = [
                    {
                        "key": primaryKey,
                        "value": primaryValue,
                        "input_control_id": primaryBindings.length > 0 ? primaryBindings[0].id : ""
                    }
                ];
                for (let p = 1; p < primaryBindings.length; p++) {
                    parametersArray.push({
                        "key": primaryKey,
                        "value": primaryValue,
                        "input_control_id": primaryBindings[p].id
                    });
                }
                // Mix is sent on the effect itself; it only needs parameter entries to carry hardware mappings
                bindings.filter(binding => binding.key === "mix").forEach(binding => parametersArray.push({
                    "key": "mix",
                    "value": mixValue,
                    "input_control_id": binding.id
                }));
                for (let f = 0; f < registryModule.fixedParameters.length; f++) {
                    let fixed = registryModule.fixedParameters[f];
                    parametersArray.push({
                        "key": fixed.key,
                        "value": fixed.value,
                        "input_control_id": ""
                    });
                }

                busObj.effects.push({
                    "effect_type": effect.type,
                    "enabled": effect.enabled !== false,
                    "mix": mixValue,
                    "parameters": parametersArray
                });
            }
            jsonPayload.audio_buses.push(busObj);
        }

        return jsonPayload;
    }
    function transmitGraphData(payload) {
        if (interfaceBridge.sendGraphData(JSON.stringify(payload)))
            statusToast.show("Sent to Guitar");
        else
            statusToast.show("Not connected to guitar");
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
                    model: rootWindow.busCount

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