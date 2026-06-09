import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QUTI_interface
import "../qml"

Module_base {
    id: root

    title: "TUNER"

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Text {
            text: "FREQUENCY: " + slider.value.toFixed(0) + " Hz"
            color: "#a9b1d6"
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Slider {
            id: slider
            from: 20
            to: 20000
            value: root.effectValue
            Layout.fillWidth: true

            onMoved: root.valueChanged(root.effectIndex, value)
        }
    }
}