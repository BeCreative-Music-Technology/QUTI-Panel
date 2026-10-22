pragma Singleton
import QtQuick

QtObject {
    // Every effect the Rust engine (PickupProcessor) supports.
    // "parameter" is the value edited in the UI; the engine receives it as a u16 (0..65535)
    // mapped linearly onto [min, max], matching the ranges in the engine's effect implementations.
    // "fixedParameters" are required by the engine but not editable yet; their values are u16 already.
    // "controls" are the parameters hardware controls can drive live. Reverb and delay only offer mix,
    // because the engine cannot change room size or delay time while playing.
    readonly property var modules: [
        {
            "effectType": "gain",
            "displayName": "GAIN",
            "borderColor": "#ff007c",
            "qmlSource": "GainModule.qml",
            "defaultValue": 0.0,
            "parameter": {
                "key": "gain",
                "label": "Gain",
                "unit": "dB",
                "min": -6,
                "max": 18
            },
            "controls": [
                { "key": "gain", "label": "Gain" },
                { "key": "mix", "label": "Mix" }
            ],
            "fixedParameters": []
        },
        {
            "effectType": "low_pass_filter",
            "displayName": "LOW PASS FILTER",
            "borderColor": "#ff9e64",
            "qmlSource": "LowPassFilterModule.qml",
            "defaultValue": 2000.0,
            "parameter": {
                "key": "frequency",
                "label": "Cutoff",
                "unit": "Hz",
                "min": 20,
                "max": 20000
            },
            "controls": [
                { "key": "frequency", "label": "Cutoff" },
                { "key": "mix", "label": "Mix" }
            ],
            "fixedParameters": [
                {
                    "key": "q_factor",
                    "value": 2750 // Q 0.707 on a 0.3..10 range
                }
            ]
        },
        {
            "effectType": "reverb",
            "displayName": "REVERB",
            "borderColor": "#7aa2f7",
            "qmlSource": "ReverbModule.qml",
            "defaultValue": 20.0,
            "parameter": {
                "key": "room_size",
                "label": "Room Size",
                "unit": "m",
                "min": 10,
                "max": 30
            },
            "controls": [
                { "key": "mix", "label": "Mix" }
            ],
            "fixedParameters": [
                {
                    "key": "decay",
                    "value": 6524 // 2 seconds on a 0.01..20 s range
                },
                {
                    "key": "dampening",
                    "value": 32767 // 50%
                }
            ]
        },
        {
            "effectType": "delay",
            "displayName": "DELAY",
            "borderColor": "#bb9af7",
            "qmlSource": "DelayModule.qml",
            "defaultValue": 400.0,
            "parameter": {
                "key": "delay",
                "label": "Time",
                "unit": "ms",
                "min": 10,
                "max": 2000
            },
            "controls": [
                { "key": "mix", "label": "Mix" }
            ],
            "fixedParameters": []
        }
    ]

    // Physical controls on the guitar and their control input id in the engine.
    // Laser strings send the hand's distance along the beam (5 cm = 0%, 30 cm = 100%) while the beam is touched,
    // and keep that value after letting go.
    readonly property var hardwareControls: [
        { "name": "Rotary", "id": "rotary_0", "description": "Rotary encoder" },
        { "name": "Laser 1", "id": "laser_0", "description": "Laser string 1, hand distance 5-30 cm" },
        { "name": "Laser 2", "id": "laser_1", "description": "Laser string 2, hand distance 5-30 cm" },
        { "name": "Laser 3", "id": "laser_2", "description": "Laser string 3, hand distance 5-30 cm" }
    ]

    // { "Rotary": "None", "Laser 1": "None", ... }, the initial hardware mapping of an effect
    function emptyHardwareMaps() {
        let maps = {};
        for (let i = 0; i < hardwareControls.length; i++)
            maps[hardwareControls[i].name] = "None";
        return maps;
    }

    function hardwareControlId(name) {
        for (let i = 0; i < hardwareControls.length; i++) {
            if (hardwareControls[i].name === name)
                return hardwareControls[i].id;
        }
        return "";
    }

    function hardwareControlName(id) {
        for (let i = 0; i < hardwareControls.length; i++) {
            if (hardwareControls[i].id === id)
                return hardwareControls[i].name;
        }
        return "";
    }

    function find(effectType) {
        for (let i = 0; i < modules.length; i++) {
            if (modules[i].effectType === effectType)
                return modules[i];
        }
        return null;
    }

    // Parameters hardware controls can drive for an effect: [{ key, label }]
    function controls(effectType) {
        let module = find(effectType);
        return module ? module.controls : [];
    }

    function controlByLabel(effectType, label) {
        let list = controls(effectType);
        for (let i = 0; i < list.length; i++) {
            if (list[i].label === label)
                return list[i];
        }
        return null;
    }

    // UI value -> engine u16
    function toEngineValue(effectType, value) {
        let module = find(effectType);
        if (!module)
            return 0;
        let p = module.parameter;
        let normalized = (value - p.min) / (p.max - p.min);
        return Math.min(Math.max(Math.round(normalized * 65535), 0), 65535);
    }

    // Engine u16 -> UI value
    function fromEngineValue(effectType, value) {
        let module = find(effectType);
        if (!module)
            return value;
        let p = module.parameter;
        return p.min + (value / 65535) * (p.max - p.min);
    }
}
