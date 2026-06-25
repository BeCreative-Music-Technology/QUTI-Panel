import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QUTI_interface
import "../qml"

Module_base {
    id: root
    title: "GAIN"

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Text {
            text: "GAIN LEVEL: " + slider.value.toFixed(0) + "%"
            color: "#a9b1d6"
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Slider {
            id: slider
            from: 0
            to: 100
            value: root.effectValue
            Layout.fillWidth: true
            onMoved: root.valueChanged(root.effectIndex, value)
        }
    }
}
