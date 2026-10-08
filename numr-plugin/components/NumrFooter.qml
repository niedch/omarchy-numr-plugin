// qmllint disable property-override missing-property unqualified
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Ui
import qs.Commons

RowLayout {
    id: root

    // --- Interface Properties ---
    property var bar                        // Styling constraints (fontFamily, foreground)
    property var notesModel                 // Bound notes model
    property var resultModel                // Bound evaluation results model

    // --- Interface Signals ---
    signal copyAllClicked
    signal clearAllClicked
    signal deleteNoteClicked

    Layout.fillWidth: true

    Button {
        text: "Copy all"
        enabled: root.resultModel ? root.resultModel.count > 0 : false
        foreground: root.bar ? root.bar.foreground : "white"
        fontFamily: root.bar ? root.bar.fontFamily : "sans-serif"
        fontSize: Style.font.bodySmall
        bordered: true
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.copyAllClicked()
    }

    Item {
        Layout.fillWidth: true
    }

    Button {
        text: "Clear"
        foreground: root.bar ? root.bar.foreground : "white"
        fontFamily: root.bar ? root.bar.fontFamily : "sans-serif"
        fontSize: Style.font.bodySmall
        bordered: true
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.clearAllClicked()
    }

    Button {
        text: "Delete"
        tooltipText: "Delete this note"
        enabled: root.notesModel ? root.notesModel.count > 0 : false
        foreground: root.bar ? root.bar.foreground : "white"
        fontFamily: root.bar ? root.bar.fontFamily : "sans-serif"
        fontSize: Style.font.bodySmall
        bordered: true
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.deleteNoteClicked()
    }
}
