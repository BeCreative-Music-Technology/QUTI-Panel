import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QUTI_interface

Item {
    id: configRoot
    width: 360
    height: 700

    property var workspace: null

    readonly property var currentEffect: (workspace && (workspace.matrixRevision >= 0 || workspace.valueRevision >= 0)) ? workspace.selectedEffect : null
    readonly property var currentModule: currentEffect ? ModuleRegistry.find(currentEffect.type) : null

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            text: "CONFIGURATION"
            color: "white"
            font.pixelSize: 20
            font.bold: true
            font.family: "monospace"
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            color: "#16161E"
            border.color: currentEffect ? "#7aa2f7" : "#3b4261"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: currentEffect ? "EFFECT: " + currentEffect.displayName.toUpperCase() : "NO EFFECT SELECTED"
                    color: currentEffect ? "#7aa2f7" : "#565f89"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "monospace"
                }

                Text {
                    text: "Select a card block item inside your mix routing tracks to access parameters and routing configuration fields."
                    color: "#414868"
                    font.pixelSize: 11
                    font.family: "monospace"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    visible: !currentEffect
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !!currentEffect
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Base State (Enabled)"
                            color: "white"
                            font.family: "monospace"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        Switch {
                            id: enabledToggle
                            checked: currentEffect ? (currentEffect.enabled !== false) : true
                            onToggled: {
                                if (currentEffect) {
                                    workspace.updateSelectedEffectProperty("enabled", checked);
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: currentModule ? currentModule.parameter.label : "Parameter Value"
                                color: "white"
                                font.family: "monospace"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                            Text {
                                text: currentEffect && currentModule ? (currentModule.parameter.max - currentModule.parameter.min < 100 ? currentEffect.value.toFixed(1) : Math.round(currentEffect.value)) + " " + currentModule.parameter.unit : "0"
                                color: "#7aa2f7"
                                font.family: "monospace"
                                font.bold: true
                                font.pixelSize: 12
                            }
                        }

                        Slider {
                            id: parameterValueSlider
                            Layout.fillWidth: true

                            from: currentModule ? currentModule.parameter.min : 0
                            to: currentModule ? currentModule.parameter.max : 100

                            value: currentEffect ? currentEffect.value : 0
                            onMoved: {
                                if (currentEffect) {
                                    workspace.updateSelectedEffectProperty("value", value);
                                }
                            }
                            background: Rectangle {
                                x: parameterValueSlider.leftPadding
                                y: parameterValueSlider.topPadding + parameterValueSlider.availableHeight / 2 - height / 2
                                width: parameterValueSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#3b4261"
                                Rectangle {
                                    width: parameterValueSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#7aa2f7"
                                    radius: 2
                                }
                            }
                            handle: Rectangle {
                                x: parameterValueSlider.leftPadding + parameterValueSlider.visualPosition * (parameterValueSlider.availableWidth - width)
                                y: parameterValueSlider.topPadding + parameterValueSlider.availableHeight / 2 - height / 2
                                width: 12
                                height: 12
                                radius: 6
                                color: "#7aa2f7"
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Mix Level"
                                    color: "white"
                                    font.family: "monospace"
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: currentEffect ? Math.round(currentEffect.mix !== undefined ? currentEffect.mix : 100) + "%" : "100%"
                                    color: "#7aa2f7"
                                    font.family: "monospace"
                                    font.bold: true
                                    font.pixelSize: 12
                                }
                            }

                            Slider {
                                id: mixValueSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: currentEffect ? (currentEffect.mix !== undefined ? currentEffect.mix : 100) : 100
                                onMoved: {
                                    if (currentEffect) {
                                        workspace.updateSelectedEffectProperty("mix", value);
                                    }
                                }
                                background: Rectangle {
                                    x: mixValueSlider.leftPadding
                                    y: mixValueSlider.topPadding + mixValueSlider.availableHeight / 2 - height / 2
                                    width: mixValueSlider.availableWidth
                                    height: 4
                                    radius: 2
                                    color: "#3b4261"
                                    Rectangle {
                                        width: mixValueSlider.visualPosition * parent.width
                                        height: parent.height
                                        color: "#7aa2f7"
                                        radius: 2
                                    }
                                }
                                handle: Rectangle {
                                    x: mixValueSlider.leftPadding + mixValueSlider.visualPosition * (mixValueSlider.availableWidth - width)
                                    y: mixValueSlider.topPadding + mixValueSlider.availableHeight / 2 - height / 2
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: "#7aa2f7"
                                }
                            }
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#16161E"
            border.color: "#3b4261"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "HARDWARE MAPPINGS"
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "monospace"
                }

                Text {
                    text: currentEffect ? "Controls driving " + currentEffect.displayName.toUpperCase() + ". Lasers set the value from your hand's distance along the beam (5-30 cm) while you touch it." : "Select an effect to map controls. Current assignments:"
                    color: "#565f89"
                    font.pixelSize: 10
                    font.family: "monospace"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: ModuleRegistry.hardwareControls

                        delegate: Rectangle {
                            id: hardwareRowWrapper
                            Layout.fillWidth: true
                            Layout.preferredHeight: currentEffect ? 48 : Math.max(48, assignmentsText.implicitHeight + 20)
                            color: "#1e1e28"
                            radius: 6
                            border.color: "#24283b"

                            readonly property string hardwareIdentifier: modelData.name
                            readonly property var assignments: (workspace && workspace.matrixRevision >= 0) ? workspace.hardwareAssignments(hardwareIdentifier) : []

                            readonly property bool isMappingActive: {
                                if (!currentEffect || !currentEffect.hardwareMaps)
                                    return false;
                                let assignment = currentEffect.hardwareMaps[hardwareIdentifier];
                                return (assignment !== undefined && assignment !== "" && assignment !== "None");
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: hardwareRowWrapper.hardwareIdentifier
                                    color: hardwareRowWrapper.isMappingActive || (!currentEffect && hardwareRowWrapper.assignments.length > 0) ? "#9ece6a" : "#565f89"
                                    font.family: "monospace"
                                    font.bold: true
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 72
                                }

                                Text {
                                    id: assignmentsText
                                    visible: !currentEffect
                                    text: hardwareRowWrapper.assignments.length > 0 ? hardwareRowWrapper.assignments.join("
") : "Unassigned"
                                    color: hardwareRowWrapper.assignments.length > 0 ? "#c0caf5" : "#414868"
                                    font.family: "monospace"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    id: assignmentSwitch
                                    checked: hardwareRowWrapper.isMappingActive
                                    visible: !!currentEffect
                                    scale: 0.8
                                    onToggled: {
                                        if (!currentEffect)
                                            return;
                                        if (!checked) {
                                            workspace.updateSelectedEffectHardwareMap(hardwareRowWrapper.hardwareIdentifier, "None");
                                        } else {
                                            workspace.updateSelectedEffectHardwareMap(hardwareRowWrapper.hardwareIdentifier, currentModule.controls[0].label);
                                        }
                                    }
                                }

                                ComboBox {
                                    id: mappingTargetDropdown
                                    Layout.fillWidth: true
                                    visible: hardwareRowWrapper.isMappingActive && !!currentEffect

                                    model: currentModule ? currentModule.controls.map(control => control.label) : []

                                    currentIndex: {
                                        if (!currentEffect || !currentEffect.hardwareMaps)
                                            return 0;
                                        let activeSelection = currentEffect.hardwareMaps[hardwareRowWrapper.hardwareIdentifier];
                                        let matchIndex = model.indexOf(activeSelection);
                                        return matchIndex >= 0 ? matchIndex : 0;
                                    }

                                    onActivated: index => {
                                        workspace.updateSelectedEffectHardwareMap(hardwareRowWrapper.hardwareIdentifier, model[index]);
                                    }

                                    delegate: ItemDelegate {
                                        width: mappingTargetDropdown.width
                                        contentItem: Text {
                                            text: modelData
                                            color: "white"
                                            font.family: "monospace"
                                            font.pixelSize: 11
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            color: highlighted ? "#ff007c" : "#16161E"
                                        }
                                    }

                                    contentItem: Text {
                                        text: mappingTargetDropdown.displayText
                                        color: "white"
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 6
                                    }

                                    background: Rectangle {
                                        color: "#16161E"
                                        border.color: "#3b4261"
                                        radius: 4
                                    }

                                    popup: Popup {
                                        y: mappingTargetDropdown.height + 2
                                        width: mappingTargetDropdown.width
                                        implicitHeight: contentItem.implicitHeight + 4
                                        padding: 1

                                        contentItem: ListView {
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: mappingTargetDropdown.popup.visible ? mappingTargetDropdown.delegateModel : null
                                            currentIndex: mappingTargetDropdown.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator {}
                                        }

                                        background: Rectangle {
                                            color: "#16161E"
                                            border.color: "#3b4261"
                                            radius: 4
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    visible: !mappingTargetDropdown.visible && !!currentEffect
                                }
                            }
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}