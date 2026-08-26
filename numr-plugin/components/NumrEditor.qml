// qmllint disable property-override missing-property unqualified
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Ui
import qs.Commons

ScrollView {
    id: root

    // --- Interface Properties ---
    property var bar                    // Exposes parent's Bar object (for style, fontFamily, foreground)
    property alias text: editor.text    // Binds scratch-pad text
    property alias editor: editor       // Exposes inner editor for external targeting/focus (e.g. focusTarget)

    // --- Interface Signals ---
    signal lineChanged(int lineNum)     // Emitted when the active line number changes based on cursor position

    // --- Interface Functions ---
    function forceFocus() {
        editor.forceActiveFocus();      // Focuses the underlying TextArea
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Style.space(120)
    clip: true

    background: BorderSurface {
        color: Style.controlFill(editor.activeFocus, editorHover.hovered, root.bar ? root.bar.foreground : "white", Color.accent)
        borderSpec: Border.controlSpec(editor.activeFocus ? "focus" : (editorHover.hovered ? "hover-cursor" : "normal"), root.bar ? root.bar.foreground : "white", Color.accent)
        radius: Style.cornerRadius
    }

    ScrollBar.vertical: NumrScrollBar {
        foregroundColor: root.bar ? root.bar.foreground : "white"
    }

    TextArea {
        id: editor
        width: parent.width   // fills the ScrollView viewport
        wrapMode: TextEdit.Wrap
        selectByMouse: true
        font.family: root.bar ? root.bar.fontFamily : "sans-serif"
        font.pixelSize: Style.font.body
        color: root.bar ? root.bar.foreground : "white"
        placeholderTextColor: root.bar ? Qt.darker(root.bar.foreground, 1.6) : "grey"
        palette.text: root.bar ? root.bar.foreground : "white"
        palette.placeholderText: root.bar ? Qt.darker(root.bar.foreground, 1.6) : "grey"
        palette.highlight: Style.selectionFillFor(root.bar ? root.bar.foreground : "white", Color.accent)
        palette.highlightedText: root.bar ? root.bar.foreground : "white"
        leftPadding: Style.spacing.controlPaddingX
        rightPadding: Style.spacing.controlPaddingX + 14   // leaves room for the scrollbar
        topPadding: Style.spacing.inputPaddingY
        bottomPadding: Style.spacing.inputPaddingY
        placeholderText: "20 inches in cm\nx = 5000\n5 * (1 + 2)"
        background: null  // themed background is handled by ScrollView background

        onCursorPositionChanged: {
            var txt = text || "";
            var textUpToCursor = txt.substring(0, cursorPosition);
            var line = textUpToCursor.split("\n").length - 1;
            root.lineChanged(line);
        }

        HoverHandler {
            id: editorHover
        }
    }
}
