import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../qml"

Module_base {
    id: root
    title: "DELAY"

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Text {
            text: "TIME: " + slider.value.toFixed(0) + " ms"
            color: "#a9b1d6"
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Slider {
            id: slider
            from: 20
            to: 2000
            value: root.effectValue
            Layout.fillWidth: true
            onMoved: root.valueChanged(root.effectIndex, value)
        }
    }
}