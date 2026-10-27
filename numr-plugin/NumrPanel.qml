// qmllint disable unused-imports missing-property signal-handler-parameters required
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Panel {
    id: root
    moduleName: "nic.numr"
    manageIpc: false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    // --- state ---
    property alias text: notesManager.text // bound two-way to the editor via notesManager
    property alias isFullscreen: popup.isFullscreen
    onTextChanged: {
        if (popup && popup.text !== root.text) {
            popup.text = root.text;
        }
    }
    property bool busy: false
    property bool numrAvailable: true
    property string statusText: ""
    property int activeGeneration: 0
    property int totalEvalCount: 0
    property int completedEvalCount: 0
    property bool isCliCheckComplete: false
    property int currentEditorLine: 0

    // Rows are keyed by `line` (index in the split scratchpad) so results can
    // be patched back in by position even if the queue is rebuilt.
    ListModel {
        id: resultModel
    }

    NumrNotesManager {
        id: notesManager
        onNotesLoaded: {
            if (root.opened) {
                root.evaluateNow();
            }
        }
    }

    Timer {
        id: evalDebounce
        interval: 300
        onTriggered: root.evaluateAll()
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: notesManager.saveCurrentNote()
    }

    // Availability check — numr-cli has no --version flag.
    Process {
        id: checkProc
        command: ["bash", "-c", "command -v numr-cli"]
        onExited: function (code) {
            root.isCliCheckComplete = true;
            root.numrAvailable = code === 0;
            if (root.numrAvailable)
                root.startServer();
            else
                root.statusText = "numr-cli not found";
        }
    }

    // Persistent JSON-RPC session. Keep it alive for the widget's lifetime.
    Process {
        id: serverProc
        command: ["numr-cli", "--server"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: function (data) {
                root.handleServerResponse(data);
            }
        }
        onExited: function (code) {
            // If the server died unexpectedly and we still expect it, restart it.
            if (root.numrAvailable)
                restartTimer.restart();
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: root.startServer()
    }

    Component.onCompleted: {
        checkProc.running = true;
    }

    // Closing the popup stops the debounce and persists the current note; the
    // background queue keeps draining so results are preserved on reopen.
    onOpenedChanged: {
        if (opened) {
            root.evaluateNow();
            return;
        }
        evalDebounce.stop();
        saveTimer.stop();
        notesManager.saveCurrentNote();
    }

    function startServer() {
        if (serverProc.running)
            return;
        serverProc.running = true;
    }

    function evaluateNow() {
        evalDebounce.stop();
        root.evaluateAll();
    }

    function findModelIndexForLine(lineNum) {
        if (resultModel.count === 0)
            return -1;
        return Math.max(0, Math.min(lineNum, resultModel.count - 1));
    }

    // Synchronize UI highlight with editor cursor row
    function syncHighlight() {
        if (!popup || !resultModel)
            return;
        var idx = root.findModelIndexForLine(root.currentEditorLine);
        popup.scrollToResultIndex(idx);
    }

    function evaluateAll() {
        if (!root.numrAvailable || !root.isCliCheckComplete) {
            if (!root.isCliCheckComplete)
                Qt.callLater(function () {
                    if (root.isCliCheckComplete)
                        root.evaluateAll();
                });
            return;
        }
        if (!serverProc.running) {
            root.startServer();
            evalDebounce.start();  // retry once the server is up
            return;
        }
        var gen = ++root.activeGeneration;
        var lines = root.text.split("\n");
        var exprs = [];
        var newRows = [];
        for (var i = 0; i < lines.length; i++) {
            var expr = lines[i].trim();
            if (expr === "") {
                newRows.push({
                    line: i,
                    expr: "",
                    result: "",
                    error: false,
                    pending: false,
                    isComment: false,
                    isBlank: true
                });
                continue;
            }
            var isComment = expr.charAt(0) === "#" || expr.indexOf("//") === 0;
            if (isComment) {
                newRows.push({
                    line: i,
                    expr: expr,
                    result: "",
                    error: false,
                    pending: false,
                    isComment: true,
                    isBlank: false
                });
                continue;
            }
            exprs.push(expr);
            newRows.push({
                line: i,
                expr: expr,
                result: "",
                error: false,
                pending: true,
                isComment: false,
                isBlank: false
            });
        }

        // Update in-place to avoid collapsing ListView count and scroll offset
        var commonCount = Math.min(resultModel.count, newRows.length);
        for (var j = 0; j < commonCount; j++) {
            resultModel.set(j, newRows[j]);
        }
        if (resultModel.count > newRows.length) {
            resultModel.remove(newRows.length, resultModel.count - newRows.length);
        } else if (newRows.length > resultModel.count) {
            for (var k = commonCount; k < newRows.length; k++) {
                resultModel.append(newRows[k]);
            }
        }
        if (exprs.length === 0) {
            root.busy = false;
            root.statusText = "";
            root.syncHighlight();
            return;
        }
        root.totalEvalCount = exprs.length;
        root.completedEvalCount = 0;
        root.busy = true;
        root.statusText = "evaluating…";
        var req = JSON.stringify({
            jsonrpc: "2.0",
            method: "eval_lines",
            params: {
                lines: exprs
            },
            id: gen
        });
        serverProc.write(req + "\n");
        root.syncHighlight();
    }

    function handleServerResponse(data) {
        var line = String(data || "").trim();
        if (line === "")
            return;
        var parsed;
        try {
            parsed = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (parsed.id === undefined || parsed.id === null)
            // notification
            return;
        if (parsed.id !== root.activeGeneration)
            // stale response from a previous edit
            return;
        if (parsed.error) {                                             // JSON-RPC protocol error
            root.busy = false;
            root.statusText = "numr error";
            return;
        }
        var vals = parsed.result;
        if (!Array.isArray(vals))
            return;
        var valIdx = 0;
        for (var i = 0; i < resultModel.count; i++) {
            var row = resultModel.get(i);
            if (!row)
                continue;
            if (row.isComment || row.isBlank)
                continue;
            if (valIdx >= vals.length)
                break;
            var v = vals[valIdx] || {};
            var isErr = v.type === "error";
            var display = v.display !== undefined ? String(v.display) : "";
            resultModel.set(i, {
                line: row.line,
                expr: row.expr,
                result: isErr ? (v.message !== undefined ? String(v.message) : "error") : display,
                error: isErr,
                pending: false,
                isComment: false,
                isBlank: false
            });
            valIdx++;
        }
        root.completedEvalCount = valIdx;
        if (root.completedEvalCount >= root.totalEvalCount) {
            root.busy = false;
            root.statusText = "";
        }
    }

    function copyResult(modelIndex) {
        var row = resultModel.get(modelIndex);
        if (!row || row.isComment || row.isBlank || row.error || row.pending || row.result === "")
            return;
        Quickshell.clipboardText = row.result;
        root.statusText = "copied " + row.result;
    }

    function copyAll() {
        var parts = [];
        var resultCount = 0;
        for (var i = 0; i < resultModel.count; i++) {
            var row = resultModel.get(i);
            if (!row)
                continue;
            if (row.isBlank) {
                parts.push("");
            } else if (row.isComment) {
                parts.push(row.expr);
            } else {
                if (row.error || row.pending)
                    continue;
                parts.push(row.expr + " = " + row.result);
                resultCount++;
            }
        }
        if (parts.length === 0)
            return;
        Quickshell.clipboardText = parts.join("\n");
        root.statusText = "copied " + resultCount + " result" + (resultCount !== 1 ? "s" : "");
    }

    function resetSession() {
        if (serverProc.running) {
            serverProc.write(JSON.stringify({
                jsonrpc: "2.0",
                method: "clear",
                id: 0
            }) + "\n");
        }
        ++root.activeGeneration;
        resultModel.clear();
        root.busy = false;
        root.statusText = "";
    }

    function clearAll() {
        root.resetSession();
        root.text = "";
    }

    function newNote() {
        notesManager.newNote();
        root.resetSession();
        Qt.callLater(function () {
            popup.forceEditorFocus();
        });
    }

    function deleteNote() {
        notesManager.deleteNote();
        root.resetSession();
        root.evaluateNow();
    }

    function switchNote(index, focusEditor = true) {
        if (index < 0 || index >= notesManager.notes.length)
            return;
        if (index === notesManager.selectedNoteIndex) {
            if (focusEditor) {
                Qt.callLater(function () {
                    popup.forceEditorFocus();
                });
            }
            return;
        }

        notesManager.switchNote(index);
        root.resetSession();
        root.evaluateNow();

        if (focusEditor) {
            Qt.callLater(function () {
                popup.forceEditorFocus();
            });
        }
    }

    function toggleFullscreen(): void {
        popup.toggleFullscreen();
    }

    ShellIpc {
        target: "nic.numr"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function show(): void {
            root.open();
        }
        function hide(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function toggleFullscreen(): void {
            root.toggleFullscreen();
        }
        function isFullscreen(): bool {
            return root.isFullscreen;
        }
    }

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "\uf1ec"
        tooltipText: "Numr calculator"

        onPressed: function (b) {
            if (root.opened)
                root.close();
            else
                root.open();
        }
    }

    NumrPopup {
        id: popup
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened

        notesModel: notesManager.notesModel
        resultModel: resultModel
        selectedNoteIndex: notesManager.selectedNoteIndex
        numrAvailable: root.numrAvailable
        statusText: root.statusText

        onTextChanged: {
            if (root.text !== text) {
                root.text = text;
                saveTimer.restart();
                evalDebounce.restart();
            }
        }

        onNewNoteClicked: root.newNote()
        onNewNoteRequested: root.newNote()
        onSwitchNoteRequested: function (index, focusEditor) {
            root.switchNote(index, focusEditor);
        }
        onResultClicked: function (index) {
            root.copyResult(index);
        }
        onCopyAllClicked: root.copyAll()
        onClearAllClicked: root.clearAll()
        onDeleteNoteClicked: root.deleteNote()
        onEvaluateNowRequested: root.evaluateNow()
        onEditorLineChanged: function (lineNum) {
            root.currentEditorLine = lineNum;
            root.syncHighlight();
        }
    }
}
