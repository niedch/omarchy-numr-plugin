// qmllint disable missing-property
import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
    id: row

    // --- Model / ListView Context ---
    required property int index
    required property string expr
    required property string result
    required property bool error
    required property bool pending
    required property bool isComment

    // --- Configurable State and Styling ---
    property color foreground: "white"
    property color urgent: "red"
    property string fontFamily: "sans-serif"

    // --- Signals ---
    signal clicked

    width: ListView.view.width
    height: Style.space(28)
    radius: Style.cornerRadius
    color: (ListView.isCurrentItem && !row.isComment) ? Util.alpha(row.foreground, 0.08) : (mouse.containsMouse && !row.isComment) ? Style.hoverFillFor(row.foreground, Color.accent) : "transparent"

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !row.isComment
        hoverEnabled: !row.isComment
        cursorShape: row.isComment ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.spacing.controlPaddingX
        anchors.rightMargin: Style.spacing.controlPaddingX
        spacing: Style.space(8)

        Text {
            id: exprText
            Layout.fillWidth: true
            text: row.expr
            color: row.isComment ? Qt.darker(row.foreground, 1.8) : Qt.darker(row.foreground, 1.4)
            font.family: row.fontFamily
            font.pixelSize: Style.font.body
            font.italic: row.isComment
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: resultText
            visible: !row.isComment
            Layout.maximumWidth: parent.width * 0.55
            text: row.error ? "error" : row.pending ? "…" : row.result
            color: row.error ? row.urgent : row.pending ? Qt.darker(row.foreground, 1.4) : row.foreground
            font.family: row.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
