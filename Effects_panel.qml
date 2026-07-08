import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./qml"

Item {
    id: panelRoot
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    property var workspace: null

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 14

        Text {
            text: "LIBRARY"
            color: "white"
            font.pixelSize: 20
            font.bold: true
            font.family: "monospace"
            Layout.leftMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 230
            color: "#16161E"
            border.color: "#3b4261"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "Effects"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "monospace"
                }

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Repeater {
                        model: typeof ModuleRegistry !== "undefined" ? ModuleRegistry.modules : []

                        delegate: EffectTile {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            effectType: modelData.effectType
                            displayName: modelData.displayName
                            qmlSource: modelData.qmlSource
                            defaultValue: modelData.defaultValue
                            accentColor: modelData.borderColor
                        }
                    }
                }
            }
        }
    }
}
