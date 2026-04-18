import Foundation
import SQLite3
import SwiftUI
import Combine

struct Note: Identifiable {
    let id: String // Format: "YYYY-MM-DD" (BS)
    var content: String
}

class PatroNoteManager: ObservableObject {
    static let shared = PatroNoteManager()
    private var db: OpaquePointer?
    
    @Published var notes: [String: String] = [:]

    init() {
        openDatabase()
        createTable()
        loadAllNotes()
    }

    private func openDatabase() {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let dbURL = appSupportURL.appendingPathComponent("bhitte_patro_notes.sqlite")
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS notes(
        id TEXT PRIMARY KEY NOT NULL,
        content TEXT
        );
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                // Table created or exists
            } else {
                print("Notes table could not be created.")
            }
        }
        sqlite3_finalize(createTableStatement)
    }

    func loadAllNotes() {
        let queryStatementString = "SELECT id, content FROM notes;"
        var queryStatement: OpaquePointer?
        
        var loadedNotes: [String: String] = [:]
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                if let idCol = sqlite3_column_text(queryStatement, 0),
                   let contentCol = sqlite3_column_text(queryStatement, 1) {
                    let id = String(cString: idCol)
                    let content = String(cString: contentCol)
                    loadedNotes[id] = content
                }
            }
        }
        sqlite3_finalize(queryStatement)
        
        DispatchQueue.main.async {
            self.notes = loadedNotes
        }
    }

    func saveNote(id: String, content: String) {
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deleteNote(id: id)
            return
        }
        
        let insertStatementString = "INSERT OR REPLACE INTO notes (id, content) VALUES (?, ?);"
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (content as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                DispatchQueue.main.async {
                    self.notes[id] = content
                }
            } else {
                print("Could not insert/replace row.")
            }
        }
        sqlite3_finalize(insertStatement)
    }

    func deleteNote(id: String) {
        let deleteStatementString = "DELETE FROM notes WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, (id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                DispatchQueue.main.async {
                    self.notes.removeValue(forKey: id)
                }
            }
        }
        sqlite3_finalize(deleteStatement)
    }
}
