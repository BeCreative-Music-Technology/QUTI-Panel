pragma Singleton
import QtQuick

QtObject {
    readonly property var modules: [
        {
            "effectType": "gain",
            "displayName": "GAIN",
            "borderColor": "#ff007c",
            "qmlSource": "../modules/GainModule.qml",
            "defaultValue": 50.0
        },
        {
            "effectType": "tuner",
            "displayName": "TUNER",
            "borderColor": "#00fff0",
            "qmlSource": "../modules/TunerModule.qml",
            "defaultValue": 440.0
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