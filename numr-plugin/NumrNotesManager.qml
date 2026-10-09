// qmllint disable unused-imports missing-property signal-handler-parameters required
import QtQuick
import Quickshell
import Quickshell.Io
import "NumrNotes.js" as NumrNotes

Item {
    id: manager

    // --- State & Interface Properties ---
    property string text: ""                     // Current active note text (two-way binding)
    property var notes: []                       // In-memory list of all note objects
    property string activeNoteId: ""             // GUID of the active note
    property int selectedNoteIndex: 0            // Selected index in notes list

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy"
    property string notesPath: manager.stateDir + "/numr-notes.json"

    // Expose the model for external UI list binding
    readonly property ListModel notesModel: internalNotesModel

    // --- Signals ---
    signal notesLoaded                         // Triggers evaluation once notes are loaded

    ListModel {
        id: internalNotesModel
    }

    // Ensure the state directory exists and pre-create the notes file as 0600.
    // FileView with atomicWrites uses QSaveFile, which copies the existing file's
    // permissions on each atomic write; a 0600 pre-created file therefore keeps
    // every save owner-only. The directory itself is left at its default mode.
    Process {
        id: mkdirProc
        command: ["bash", "-c", 'd="$1"; f="$2"; mkdir -p "$d"; ' + 'if [ -e "$f" ]; then chmod 600 "$f"; ' + 'else install -m 600 /dev/null "$f"; fi', "_", manager.stateDir, manager.notesPath]
    }

    FileView {
        id: notesFile
        path: manager.notesPath
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onLoaded: manager.loadNotes(notesFile.text())
        onLoadFailed: manager.loadNotes("")
        onFileChanged: reload()
        onSaved: secureNoteFile.running = true
    }

    // Re-assert 0600 after each atomic save as defense-in-depth, in case the
    // file's mode is ever altered by another tool or future QSaveFile behavior.
    Process {
        id: secureNoteFile
        command: ["bash", "-c", 'f="$1"; [ -e "$f" ] && chmod 600 "$f" || true', "_", manager.notesPath]
    }

    Component.onCompleted: {
        mkdirProc.running = true;
    }

    // --- Note Management Functions ---

    function loadNotes(raw) {
        var parsed = NumrNotes.parseNotes(raw);

        // Safeguard active typing buffer from being overwritten during asynchronous disk loads
        var isSameActive = (parsed.activeNoteId === manager.activeNoteId);
        var activeIdx = NumrNotes.findIndex(parsed.notes, parsed.activeNoteId);
        var isSameText = activeIdx >= 0 && (parsed.notes[activeIdx].text === manager.text);

        manager.notes = parsed.notes;
        manager.activeNoteId = parsed.activeNoteId;
        if (manager.notes.length === 0) {
            manager.notes = [NumrNotes.tutorialNote()];
            manager.activeNoteId = manager.notes[0].id;
        }
        manager.selectedNoteIndex = Math.max(0, NumrNotes.findIndex(manager.notes, manager.activeNoteId));
        manager.rebuildNotes();

        // Only update the active editor text if the note changed, or if there are genuine differences on disk
        if (!isSameActive || !isSameText) {
            manager.text = manager.notes[manager.selectedNoteIndex].text;
        }

        manager.notesLoaded();
    }

    function saveNotes() {
        notesFile.setText(JSON.stringify({
            schemaVersion: 1,
            activeNoteId: manager.activeNoteId,
            notes: manager.notes
        }, null, 2) + "\n");
    }

    function currentNote() {
        if (manager.notes.length === 0)
            return null;
        return manager.notes[Math.max(0, Math.min(manager.selectedNoteIndex, manager.notes.length - 1))];
    }

    function updateCurrentNoteMemory() {
        var n = manager.currentNote();
        if (!n)
            return;
        n.text = manager.text;
        n.updatedAt = new Date().toISOString();
        manager.rebuildNotes();
    }

    function saveCurrentNote() {
        manager.updateCurrentNoteMemory();
        manager.saveNotes();
    }

    function rebuildNotes() {
        var rows = NumrNotes.displayRows(manager.notes);
        if (internalNotesModel.count === rows.length) {
            // In-place update to prevent losing list selection/focus
            for (var i = 0; i < rows.length; i++) {
                internalNotesModel.set(i, {
                    id: rows[i].id,
                    title: rows[i].title,
                    lineCount: rows[i].lineCount
                });
            }
        } else {
            // Only clear and rebuild if size changes
            internalNotesModel.clear();
            for (var j = 0; j < rows.length; j++) {
                internalNotesModel.append({
                    id: rows[j].id,
                    title: rows[j].title,
                    lineCount: rows[j].lineCount
                });
            }
        }
    }

    function newNote() {
        manager.updateCurrentNoteMemory();
        manager.notes = NumrNotes.addNote(manager.notes, NumrNotes.newNote());
        manager.activeNoteId = manager.notes[manager.notes.length - 1].id;
        manager.selectedNoteIndex = manager.notes.length - 1;
        manager.text = "";
        manager.rebuildNotes();
        manager.saveNotes();
    }

    function deleteNote() {
        if (manager.notes.length === 0)
            return;
        var idx = manager.selectedNoteIndex;
        manager.notes = NumrNotes.removeNoteAt(manager.notes, idx);
        if (manager.notes.length === 0) {
            manager.notes = [NumrNotes.newNote()];
        }
        manager.selectedNoteIndex = Math.min(idx, manager.notes.length - 1);
        manager.activeNoteId = manager.notes[manager.selectedNoteIndex].id;
        manager.text = manager.notes[manager.selectedNoteIndex].text;
        manager.rebuildNotes();
        manager.saveNotes();
    }

    function switchNote(index) {
        if (index < 0 || index >= manager.notes.length)
            return;
        if (index === manager.selectedNoteIndex) {
            return;
        }

        manager.updateCurrentNoteMemory();
        manager.selectedNoteIndex = index;
        manager.activeNoteId = manager.notes[index].id;
        manager.text = manager.notes[index].text;
        manager.rebuildNotes();
        manager.saveNotes();
    }
}
