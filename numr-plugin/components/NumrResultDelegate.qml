// qmllint disable missing-property
import QtQuick
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

    Text {
        id: exprText
        anchors.left: parent.left
        anchors.leftMargin: Style.spacing.controlPaddingX
        anchors.right: row.isComment ? parent.right : resultText.left
        anchors.rightMargin: row.isComment ? Style.spacing.controlPaddingX : Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        text: row.expr
        color: row.isComment ? Qt.darker(row.foreground, 1.8) : Qt.darker(row.foreground, 1.4)
        font.family: row.fontFamily
        font.pixelSize: Style.font.body
        font.italic: row.isComment
        elide: Text.ElideRight
    }

    Text {
        id: resultText
        visible: !row.isComment
        anchors.right: parent.right
        anchors.rightMargin: Style.spacing.controlPaddingX
        anchors.verticalCenter: parent.verticalCenter
        text: row.error ? "error" : row.pending ? "…" : row.result
        color: row.error ? row.urgent : row.pending ? Qt.darker(row.foreground, 1.4) : row.foreground
        font.family: row.fontFamily
        font.pixelSize: Style.font.body
        horizontalAlignment: Text.AlignRight
    }
}
