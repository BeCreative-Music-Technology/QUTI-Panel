import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: configRoot
    width: 360
    height: 700

    property var workspace: null

    // Dynamic structural binding hooks map changes tracking back to the active array matrix
    readonly property var currentEffect: (workspace && workspace.matrixRevision >= 0) ? workspace.selectedEffect : null

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

        // --- SUB-PANEL 1: ACTIVE EFFECT PARAMETERS ---
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
                                    workspace.updateSelectedEffectProperty("enabled", checked)
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
                                text: {
                                    if (!currentEffect) return "Parameter Value";
                                    if (currentEffect.type === "low_pass_filter") return "Cutoff Frequency";
                                    if (currentEffect.type === "reverb") return "Room Size";
                                    if (currentEffect.type === "delay") return "Delay Time";
                                    return "Gain Level";
                                }
                                color: "white"
                                font.family: "monospace"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                            Text {
                                text: currentEffect ? Math.round(currentEffect.value) : "0"
                                color: "#7aa2f7"
                                font.family: "monospace"
                                font.bold: true
                                font.pixelSize: 12
                            }
                        }

                        Slider {
                            id: parameterValueSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: currentEffect ? currentEffect.value : 0
                            onMoved: {
                                if (currentEffect) {
                                    workspace.updateSelectedEffectProperty("value", value)
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
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // --- SUB-PANEL 2: MERGED HARDWARE INPUT ASSIGNMENTS ---
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: ["Rotary", "Button", "Laser-1", "Laser-2", "Laser-3"]

                        delegate: Rectangle {
                            id: hardwareRowWrapper
                            Layout.fillWidth: true
                            height: 48
                            color: "#1e1e28"
                            radius: 6
                            border.color: "#24283b"

                            readonly property string hardwareIdentifier: modelData

                            readonly property bool isMappingActive: {
                                if (!currentEffect || !currentEffect.hardwareMaps) return false;
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
                                    color: hardwareRowWrapper.isMappingActive ? "#9ece6a" : "#565f89"
                                    font.family: "monospace"
                                    font.bold: true
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 72
                                }

                                Switch {
                                    id: assignmentSwitch
                                    checked: hardwareRowWrapper.isMappingActive
                                    enabled: !!currentEffect
                                    scale: 0.8
                                    onToggled: {
                                        if (!currentEffect) return;
                                        if (!checked) {
                                            workspace.updateSelectedEffectHardwareMap(hardwareRowWrapper.hardwareIdentifier, "None");
                                        } else {
                                            workspace.updateSelectedEffectHardwareMap(hardwareRowWrapper.hardwareIdentifier, "Enabled");
                                        }
                                    }
                                }

                                ComboBox {
                                    id: mappingTargetDropdown
                                    Layout.fillWidth: true
                                    visible: hardwareRowWrapper.isMappingActive && !!currentEffect

                                    model: {
                                        if (!currentEffect) return ["None"];
                                        let fields = ["Enabled"];
                                        if (currentEffect.type === "low_pass_filter") fields.push("Cutoff");
                                        else if (currentEffect.type === "reverb") fields.push("Room Size");
                                        else if (currentEffect.type === "delay") fields.push("Time");
                                        else fields.push("Gain");
                                        return fields;
                                    }

                                    currentIndex: {
                                        if (!currentEffect || !currentEffect.hardwareMaps) return 0;
                                        let activeSelection = currentEffect.hardwareMaps[hardwareRowWrapper.hardwareIdentifier];
                                        let matchIndex = model.indexOf(activeSelection);
                                        return matchIndex >= 0 ? matchIndex : 0;
                                    }

                                    onActivated: (index) => {
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

                                    // FIX: Override and fully style the internal Popup wrapper container
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
                                            ScrollIndicator.vertical: ScrollIndicator { }
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
                                    visible: !mappingTargetDropdown.visible
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}