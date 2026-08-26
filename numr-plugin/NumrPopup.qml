// qmllint disable property-override missing-property unused-imports Quick.layout-positioning
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Ui
import qs.Commons
import "components"

KeyboardPanel {
    id: popup

    // --- Interface Properties ---
    required property var notesModel
    required property var resultModel
    property int selectedNoteIndex: 0
    property alias text: workspace.text
    property bool numrAvailable: true
    property string statusText: ""

    // --- Interface Signals ---
    signal newNoteClicked
    signal newNoteRequested
    signal switchNoteRequested(int index, bool focusEditor)
    signal resultClicked(int index)
    signal copyAllClicked
    signal clearAllClicked
    signal deleteNoteClicked
    signal evaluateNowRequested
    signal editorLineChanged(int lineNum)

    readonly property bool opened: popup.open

    // --- Interface Functions ---
    function forceEditorFocus() {
        workspace.forceEditorFocus();
    }

    function scrollToResultIndex(index) {
        workspace.scrollToResultIndex(index);
    }

    focusTarget: workspace
    contentWidth: popup.fittedContentWidth(Style.space(660))
    contentHeight: popup.fittedContentHeight(Style.space(420))

    Item {
        anchors.fill: parent

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                popup.close();
                event.accepted = true;
                return;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Style.spacing.md

            // Hero Header aligned with Battery's hero metrics
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

                Text {
                    id: heroIcon
                    text: "\uf1ec" // JetBrainsMono Nerd Font Calculator Icon ()
                    color: popup.bar.foreground
                    font.family: popup.bar.fontFamily
                    font.pixelSize: Style.font.display // Matches 24px battery icon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    id: heroLabels
                    anchors.left: heroIcon.right
                    anchors.leftMargin: Style.space(14)
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space(10)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(2)

                    Text {
                        text: "Numr Calculator"
                        color: popup.bar.foreground
                        font.family: popup.bar.fontFamily
                        font.pixelSize: Style.font.title
                        font.bold: true
                    }

                    NumrHeaderStatus {
                        id: headerStatus
                        bar: popup.bar
                        active: popup.opened
                    }
                }
            }

            PanelSeparator {
                Layout.fillWidth: true
                foreground: popup.bar.foreground
            }

            // Body: Workspace encapsulates notes column, divider, editor, results, and footer
            NumrWorkspace {
                id: workspace
                Layout.fillWidth: true
                Layout.fillHeight: true
                bar: popup.bar
                notesModel: popup.notesModel
                resultModel: popup.resultModel
                selectedNoteIndex: popup.selectedNoteIndex
                numrAvailable: popup.numrAvailable
                statusText: popup.statusText

                onNewNoteClicked: popup.newNoteClicked()
                onNewNoteRequested: popup.newNoteRequested()
                onSwitchNoteRequested: (index, focusEditor) => {
                    popup.switchNoteRequested(index, focusEditor);
                }
                onResultClicked: index => {
                    popup.resultClicked(index);
                }
                onCopyAllClicked: popup.copyAllClicked()
                onClearAllClicked: popup.clearAllClicked()
                onDeleteNoteClicked: popup.deleteNoteClicked()
                onEvaluateNowRequested: popup.evaluateNowRequested()
                onEditorLineChanged: lineNum => {
                    popup.editorLineChanged(lineNum);
                }
            }
        }
    }
}
