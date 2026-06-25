import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: presetsCardRoot
    color: "#16161E"
    border.color: "#3b4261"
    radius: 8

    property var workspace: null

    ListModel {
        id: presetsModel
    }

    property int pendingIndex: -1
    property string pendingName: ""

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55
        radius: presetsCardRoot.radius
        visible: saveDialog.visible || renameDialog.visible || deleteDialog.visible || loadWarnDialog.visible
        z: 10
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mouse => mouse.accepted = true
        }
    }

    Rectangle {
        id: saveDialog
        visible: false
        z: 20
        anchors.centerIn: parent
        width: parent.width - 28
        implicitHeight: saveDialogLayout.implicitHeight + 28
        color: "#1e2030"
        border.color: "#9ece6a"
        border.width: 1
        radius: 8

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: saveDialogLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 10

            Text {
                text: "Save Preset"
                color: "#9ece6a"
                font.pixelSize: 13
                font.bold: true
                font.family: "monospace"
            }

            TextField {
                id: saveNameField
                Layout.fillWidth: true
                placeholderText: "Preset name…"
                color: "white"
                font.family: "monospace"
                font.pixelSize: 12
                background: Rectangle {
                    color: "#16161E"
                    border.color: "#3b4261"
                    radius: 4
                }
                Keys.onReturnPressed: confirmSave()
                Keys.onEscapePressed: saveDialog.visible = false
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Cancel"
                    onClicked: saveDialog.visible = false
                    background: Rectangle {
                        color: parent.hovered ? "#2a2d3e" : "#1e2030"
                        border.color: "#3b4261"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#c0caf5"
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }

                Button {
                    text: "Save"
                    onClicked: confirmSave()
                    background: Rectangle {
                        color: parent.hovered ? "#7ddb96" : "#9ece6a"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#16161E"
                        font.bold: true
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }
            }
        }

        function open() {
            saveNameField.text = "";
            saveDialog.visible = true;
            saveNameField.forceActiveFocus();
        }
    }

    Rectangle {
        id: renameDialog
        visible: false
        z: 20
        anchors.centerIn: parent
        width: parent.width - 28
        implicitHeight: renameDialogLayout.implicitHeight + 28
        color: "#1e2030"
        border.color: "#7aa2f7"
        border.width: 1
        radius: 8

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: renameDialogLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 10

            Text {
                text: "Rename Preset"
                color: "#7aa2f7"
                font.pixelSize: 13
                font.bold: true
                font.family: "monospace"
            }

            TextField {
                id: renameField
                Layout.fillWidth: true
                color: "white"
                font.family: "monospace"
                font.pixelSize: 12
                background: Rectangle {
                    color: "#16161E"
                    border.color: "#3b4261"
                    radius: 4
                }
                Keys.onReturnPressed: confirmRename()
                Keys.onEscapePressed: renameDialog.visible = false
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Cancel"
                    onClicked: renameDialog.visible = false
                    background: Rectangle {
                        color: parent.hovered ? "#2a2d3e" : "#1e2030"
                        border.color: "#3b4261"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#c0caf5"
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }

                Button {
                    text: "Rename"
                    onClicked: confirmRename()
                    background: Rectangle {
                        color: parent.hovered ? "#9ab8ff" : "#7aa2f7"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#16161E"
                        font.bold: true
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }
            }
        }

        function open(index) {
            presetsCardRoot.pendingIndex = index;
            renameField.text = presetsModel.get(index).name;
            renameField.selectAll();
            renameDialog.visible = true;
            renameField.forceActiveFocus();
        }
    }

    Rectangle {
        id: deleteDialog
        visible: false
        z: 20
        anchors.centerIn: parent
        width: parent.width - 28
        implicitHeight: deleteDialogLayout.implicitHeight + 28
        color: "#1e2030"
        border.color: "#f7768e"
        border.width: 1
        radius: 8

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: deleteDialogLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 10

            Text {
                text: "Delete Preset"
                color: "#f7768e"
                font.pixelSize: 13
                font.bold: true
                font.family: "monospace"
            }

            Text {
                id: deleteBodyText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#c0caf5"
                font.pixelSize: 12
                font.family: "monospace"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Cancel"
                    onClicked: deleteDialog.visible = false
                    background: Rectangle {
                        color: parent.hovered ? "#2a2d3e" : "#1e2030"
                        border.color: "#3b4261"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#c0caf5"
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }

                Button {
                    text: "Delete"
                    onClicked: confirmDelete()
                    background: Rectangle {
                        color: parent.hovered ? "#ff9aaa" : "#f7768e"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#16161E"
                        font.bold: true
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }
            }
        }

        function open(index) {
            presetsCardRoot.pendingIndex = index;
            deleteBodyText.text = "Are you sure you want to delete " + presetsModel.get(index).name + "?";
            deleteDialog.visible = true;
        }
    }

    Rectangle {
        id: loadWarnDialog
        visible: false
        z: 20
        anchors.centerIn: parent
        width: parent.width - 28
        implicitHeight: loadWarnLayout.implicitHeight + 28
        color: "#1e2030"
        border.color: "#e0af68"
        border.width: 1
        radius: 8

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: loadWarnLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 10

            RowLayout {
                spacing: 6
                Text {
                    text: "⚠"
                    color: "#e0af68"
                    font.pixelSize: 14
                }
                Text {
                    text: "Replace Workspace?"
                    color: "#e0af68"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "monospace"
                }
            }

            Text {
                id: loadWarnBody
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#c0caf5"
                font.pixelSize: 12
                font.family: "monospace"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Cancel"
                    onClicked: loadWarnDialog.visible = false
                    background: Rectangle {
                        color: parent.hovered ? "#2a2d3e" : "#1e2030"
                        border.color: "#3b4261"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#c0caf5"
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }

                Button {
                    text: "Replace"
                    onClicked: confirmLoad()
                    background: Rectangle {
                        color: parent.hovered ? "#f5c97a" : "#e0af68"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#16161E"
                        font.bold: true
                        font.family: "monospace"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.clicked()
                    }
                }
            }
        }

        function open(index) {
            presetsCardRoot.pendingIndex = index;
            loadWarnBody.text = "Loading " + presetsModel.get(index).name + " will replace your current workspace. Unsaved changes will be lost.";
            loadWarnDialog.visible = true;
        }
    }

    Component.onCompleted: {
        if (typeof interfaceBridge !== "undefined") {
            let filesData = interfaceBridge.loadAllPresetFiles();
            presetsModel.clear();
            for (let i = 0; i < filesData.length; i += 2) {
                presetsModel.append({
                    "name": filesData[i],
                    "data": filesData[i + 1]
                });
            }
        }
    }

    function confirmSave() {
        let name = saveNameField.text.trim();
        if (name === "")
            return;
        if (workspace && typeof interfaceBridge !== "undefined") {
            let data = workspace.serializeGraph();
            let stringifiedData = JSON.stringify(data);

            interfaceBridge.savePresetToFile(name, stringifiedData);

            presetsModel.append({
                "name": name,
                "data": stringifiedData
            });
            saveDialog.visible = false;
            showToast("Preset " + name + " saved");
        }
    }

    function confirmRename() {
        let newName = renameField.text.trim();
        if (newName === "" || pendingIndex < 0)
            return;
        if (typeof interfaceBridge !== "undefined") {
            let oldName = presetsModel.get(pendingIndex).name;
            let rawData = presetsModel.get(pendingIndex).data;

            interfaceBridge.savePresetToFile(newName, rawData);
            interfaceBridge.deletePresetFile(oldName);

            presetsModel.setProperty(pendingIndex, "name", newName);
            renameDialog.visible = false;
            pendingIndex = -1;
            showToast("Renamed to " + newName);
        }
    }

    function confirmDelete() {
        if (pendingIndex < 0)
            return;
        if (typeof interfaceBridge !== "undefined") {
            let name = presetsModel.get(pendingIndex).name;

            interfaceBridge.deletePresetFile(name);

            presetsModel.remove(pendingIndex);
            deleteDialog.visible = false;
            pendingIndex = -1;
            showToast("Deleted " + name);
        }
    }

    function confirmLoad() {
        if (pendingIndex < 0 || !workspace)
            return;
        let entry = presetsModel.get(pendingIndex);
        let name = entry.name;
        let parsed = JSON.parse(entry.data);
        workspace.loadPreset(parsed);
        loadWarnDialog.visible = false;
        pendingIndex = -1;
        showToast("Loaded " + name);
    }

    function showToast(msg) {
        if (workspace && workspace.statusToast)
            workspace.statusToast.show(msg);
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Text {
            text: "Presets"
            color: "white"
            font.pixelSize: 18
            font.bold: true
            font.family: "monospace"
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "No presets yet.\nSave your current workspace below."
            visible: presetsModel.count === 0
            color: "#414868"
            font.pixelSize: 11
            font.family: "monospace"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.topMargin: 8
        }

        ScrollView {
            id: presetsScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: presetListLayout
                width: presetsScrollView.availableWidth !== undefined ? presetsScrollView.availableWidth : parent.width
                spacing: 6

                Repeater {
                    id: presetRepeater
                    model: presetsModel

                    delegate: Rectangle {
                        id: presetRow
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: rowHover.containsMouse ? "#1e2030" : "transparent"
                        border.color: rowHover.containsMouse ? "#7aa2f7" : "#3b4261"
                        radius: 5

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onClicked: mouse => mouse.accepted = false
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 4

                            Text {
                                text: name
                                color: "#c0caf5"
                                font.pixelSize: 12
                                font.family: "monospace"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                id: loadBtn
                                width: 22
                                height: 22
                                radius: 4
                                color: loadBtnHover.containsMouse ? "#3b4261" : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "▶"
                                    color: loadBtnHover.containsMouse ? "#7aa2f7" : "#565f89"
                                    font.pixelSize: 11
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 80
                                        }
                                    }
                                }

                                ToolTip.visible: loadBtnHover.containsMouse
                                ToolTip.delay: 600
                                ToolTip.text: "Load preset (replaces workspace)"

                                MouseArea {
                                    id: loadBtnHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: loadWarnDialog.open(index)
                                }
                            }

                            Rectangle {
                                id: renameBtn
                                width: 22
                                height: 22
                                radius: 4
                                color: renameBtnHover.containsMouse ? "#3b4261" : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✎"
                                    color: renameBtnHover.containsMouse ? "#9ece6a" : "#565f89"
                                    font.pixelSize: 13
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 80
                                        }
                                    }
                                }

                                ToolTip.visible: renameBtnHover.containsMouse
                                ToolTip.delay: 600
                                ToolTip.text: "Rename preset"

                                MouseArea {
                                    id: renameBtnHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: renameDialog.open(index)
                                }
                            }

                            Rectangle {
                                id: deleteBtn
                                width: 22
                                height: 22
                                radius: 4
                                color: deleteBtnHover.containsMouse ? "#3b4261" : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: deleteBtnHover.containsMouse ? "#f7768e" : "#565f89"
                                    font.pixelSize: 12
                                    font.bold: true
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 80
                                        }
                                    }
                                }

                                ToolTip.visible: deleteBtnHover.containsMouse
                                ToolTip.delay: 600
                                ToolTip.text: "Delete preset"

                                MouseArea {
                                    id: deleteBtnHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: deleteDialog.open(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        Button {
            id: savePresetButton
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            background: Rectangle {
                color: savePresetButton.hovered ? "#7ddb96" : "#9ece6a"
                radius: 6
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            contentItem: RowLayout {
                spacing: 6
                anchors.centerIn: parent

                Text {
                    text: "🖫"
                    color: "#16161E"
                    font.pixelSize: 13
                }
                Text {
                    text: "Save Current as Preset"
                    color: "#16161E"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "monospace"
                }
            }

            onClicked: saveDialog.open()
        }
    }
}