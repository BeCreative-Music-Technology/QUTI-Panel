pragma Singleton
import QtQuick

QtObject {
    readonly property var modules: [
        {
            "effectType": "gain",
            "displayName": "GAIN",
            "borderColor": "#ff007c",
            "qmlSource": "GainModule.qml",
            "defaultValue": 50.0
        },
        {
            "effectType": "low_pass_filter",
            "displayName": "LPF",
            "borderColor": "#ff9e64",
            "qmlSource": "LowPassFilterModule.qml",
            "defaultValue": 2000.0
        },
        {
            "effectType": "reverb",
            "displayName": "REVERB",
            "borderColor": "#7aa2f7",
            "qmlSource": "ReverbModule.qml",
            "defaultValue": 30.0
        },
        {
            "effectType": "delay",
            "displayName": "DELAY",
            "borderColor": "#bb9af7",
            "qmlSource": "DelayModule.qml",
            "defaultValue": 400.0
        }
    ]

    // Parameter transformation per effect type.
    function paramTransformer(type, value) {
        switch (type) {
        case "gain":
            return { "gain": Math.round((value / 100) * 32767).toString() };
        case "tuner":
            return { "frequency": Math.round(value).toString() };
        default:
            console.warn("No transformer for", type);
            return {};
        }
    }
}