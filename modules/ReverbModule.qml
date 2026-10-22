import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QUTI_interface

Module_base {
    id: root
    title: "REVERB"
    effectType: "reverb"

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Text {
            text: root.parameter.label.toUpperCase() + ": " + slider.value.toFixed(0) + " " + root.parameter.unit
            color: "#a9b1d6"
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Slider {
            id: slider
            from: root.parameter.min
            to: root.parameter.max
            value: root.effectValue
            Layout.fillWidth: true
            onMoved: root.valueChanged(root.effectIndex, value)
        }
    }
}
