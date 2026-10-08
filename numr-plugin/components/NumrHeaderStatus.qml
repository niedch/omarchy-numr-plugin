// qmllint disable missing-property
import QtQuick
import qs.Commons

Text {
    id: root

    // --- Required Properties ---
    required property var bar
    required property bool active

    // --- Read-only Properties ---
    readonly property var activePhrases: ["Crunching numbers", "Solving equations", "Balancing ledgers", "Summing columns", "Synthesizing variables", "Parsing matrices", "Evaluating proofs", "Calculating limits"]

    // --- Read-write Properties ---
    property int phraseIndex: 0

    // --- Text Styling and Binding ---
    text: root.activePhrases[root.phraseIndex].toUpperCase()
    color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : "grey"
    font.family: root.bar ? root.bar.fontFamily : "sans-serif"
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 1.2

    // --- Timer ---
    Timer {
        id: phraseTimer
        interval: 2800
        running: root.active
        repeat: true
        triggeredOnStart: false
        onTriggered: phraseSwap.restart()
    }

    // --- Transition Animation ---
    SequentialAnimation {
        id: phraseSwap
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0.0
            duration: 180
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: {
                var n = root.activePhrases.length;
                if (n > 0) {
                    root.phraseIndex = (root.phraseIndex + 1) % n;
                }
            }
        }
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 1.0
            duration: 260
            easing.type: Easing.InQuad
        }
    }
}
