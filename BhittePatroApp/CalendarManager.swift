//
//  CalendarManager.swift
//  BhittePatroApp
//
//  Created by Gemini on 26/03/2026.
//

import Foundation

class CalendarManager {
    static let shared = CalendarManager()

    private let localFileName = "calendar.json"

    private init() {}

    var localFileURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent("BhittePatro", isDirectory: true)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appSupportDir.path) {
            try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        }

        return appSupportDir.appendingPathComponent(localFileName)
    }

    func getLocalCalendarData() -> Data? {
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            return try? Data(contentsOf: localFileURL)
        }
        return nil
    }
}
