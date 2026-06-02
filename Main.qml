import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 600
    height: 450
    title: "Audio DSP Controller"
    color: "white"

    RowLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 20

        // TUNER / FREQUENCY MODULE
        ModuleBase {
            title: "TUNER"

            Text {
                text: toneValue.value.toFixed(0) + " Hz"
                color: "#787c99"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Big Central Display
            Text {
                text: "C#"
                color: "#ff007c"
                font.pixelSize: 48
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: parent.width * 0.8; height: 4
                color: "#00fff0"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Slider {
                id: toneValue
                from: 40; to: 1000
                // Pulls tracked state from the AudioBridge
                value: audioBridge.frequencyValue
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: Qt.Horizontal
                height: 100

                // Fires updates live as the user modifies the slider position
                onMoved: {
                    audioBridge.setEffectValue("bus_0", "frequency", value)
                }
            }
        }

        // GAIN MODULE
        ModuleBase {
            title: "GAIN"

            Text {
                text: "Gain: " + gainSlider.value.toFixed(1)
                color: "white"
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Slider {
                id: gainSlider
                from: 0; to: 100
                value: audioBridge.gainValue
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: Qt.Vertical
                height: 100

                onMoved: {
                    audioBridge.setEffectValue("bus_0", "gain", value)
                }
            }

            // Status Indicator
            Rectangle {
                width: 60; height: 30
                color: "#24283b"
                radius: 4
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    text: audioBridge.status === "Connected" ? "ON" : "OFF"
                    color: audioBridge.status === "Connected" ? "#00fff0" : "#565f89"
                    anchors.centerIn: parent
                }
            }
        }

        // METRICS / CONNECTIONS STATUS
        ModuleBase {
            title: 'ENGINE \nSTATUS'

            Text {
                text: "Network Status"
                color: "white"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: audioBridge.status
                font.pixelSize: 16
                color: audioBridge.status === "Connected" ? "#00fff0" : "#ff007c"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                text: "Sync Config"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: audioBridge.requestConfig()
            }
        }
    }
}