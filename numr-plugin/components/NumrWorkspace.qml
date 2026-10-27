// qmllint disable property-override missing-property unused-imports Quick.layout-positioning
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Ui
import qs.Commons

FocusScope {
    id: root

    // --- Interface Properties ---
    required property var notesModel           // Binds list of note headers
    required property var resultModel          // Binds active calculation results
    property int selectedNoteIndex: 0          // Tracks active note highlighting
    property alias text: editor.text           // Bidirectional binding to active note text
    property bool numrAvailable: true          // Tracks CLI process status
    property string statusText: ""             // Feedback/error text shown in list header
    property var bar                           // Theming/styling constraints
    property bool isFullscreen: false          // Tracks popup fullscreen state

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

    // --- Interface Functions ---
    function forceEditorFocus() {
        editor.forceFocus();
    }

    function scrollToResultIndex(index) {
        resultsList.scrollToIndex(index);
    }

    focus: true

    Keys.onPressed: event => {
        // Ctrl+N: Create new note
        if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
            root.newNoteRequested();
            event.accepted = true;
            return;
        }
        // Ctrl+Return: Force evaluate now
        if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
            root.evaluateNowRequested();
            event.accepted = true;
            return;
        }
        // Ctrl+Tab: Switch focus between editor and sidebar notes list
        if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
            if (editor.activeFocus) {
                sidebar.focusList();
            } else {
                editor.forceFocus();
            }
            event.accepted = true;
            return;
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: Style.spacing.panelGap

        // Left Column: Note list & creation
        NumrSidebar {
            id: sidebar
            bar: root.bar
            notesModel: root.notesModel
            selectedNoteIndex: root.selectedNoteIndex
            isFullscreen: root.isFullscreen
            onNewNoteClicked: root.newNoteClicked()
            onSwitchNoteRequested: (index, focusEditor) => {
                root.switchNoteRequested(index, focusEditor);
            }
        }

        // Vertical Separator
        Rectangle {
            Layout.fillHeight: true
            width: Style.normalBorderWidth
            color: Util.alpha(root.bar ? root.bar.foreground : "white", 0.12)
        }

        // Right Area: Editor + Result List + Action Buttons (Normal: vertical stack; Fullscreen: side-by-side)
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.isFullscreen ? 3 : 1
            rows: root.isFullscreen ? 2 : 3
            columnSpacing: Style.spacing.panelGap
            rowSpacing: Style.spacing.md

            NumrEditor {
                id: editor
                Layout.row: 0
                Layout.column: 0
                Layout.fillWidth: true
                Layout.fillHeight: root.isFullscreen
                Layout.preferredWidth: root.isFullscreen ? 1 : -1
                bar: root.bar
                isFullscreen: root.isFullscreen
                onLineChanged: lineNum => {
                    root.editorLineChanged(lineNum);
                }
            }

            // Vertical Separator between Editor and Results in fullscreen mode
            Rectangle {
                Layout.row: 0
                Layout.column: 1
                Layout.fillHeight: true
                Layout.preferredWidth: Style.normalBorderWidth
                width: Style.normalBorderWidth
                visible: root.isFullscreen
                color: Util.alpha(root.bar ? root.bar.foreground : "white", 0.12)
            }

            NumrResultList {
                id: resultsList
                Layout.row: root.isFullscreen ? 0 : 1
                Layout.column: root.isFullscreen ? 2 : 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.isFullscreen ? 1 : -1
                bar: root.bar
                numrAvailable: root.numrAvailable
                statusText: root.statusText
                resultModel: root.resultModel
                onResultClicked: index => {
                    root.resultClicked(index);
                }
            }

            NumrFooter {
                id: footer
                Layout.row: root.isFullscreen ? 1 : 2
                Layout.column: 0
                Layout.columnSpan: root.isFullscreen ? 3 : 1
                Layout.fillWidth: true
                bar: root.bar
                notesModel: root.notesModel
                resultModel: root.resultModel
                isFullscreen: root.isFullscreen
                onCopyAllClicked: root.copyAllClicked()
                onClearAllClicked: root.clearAllClicked()
                onDeleteNoteClicked: root.deleteNoteClicked()
            }
        }
    }
}
