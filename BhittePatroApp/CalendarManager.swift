//
//  CalendarManager.swift
//  BhittePatroApp
//
//  Created by Gemini on 26/03/2026.
//

import Foundation
import Combine
import WidgetKit

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    private let calendarURL = URL(string: "https://calendar.pranabkca321.workers.dev/calendar.json")!
    private let lastUpdatedKey = "CalendarLastUpdated"
    private let localFileName = "calendar.json"
    private let appGroupIdentifier = "group.com.pranab.BhittePatro"
    
    @Published var lastUpdated: Date? {
        didSet {
            UserDefaults.standard.set(lastUpdated, forKey: lastUpdatedKey)
        }
    }
    
    @Published var isUpdating = false
    @Published var updateError: String?

    private init() {
        self.lastUpdated = UserDefaults.standard.object(forKey: lastUpdatedKey) as? Date
    }
    
    var localFileURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent("BhittePatro", isDirectory: true)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appSupportDir.path) {
            try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        }

        return appSupportDir.appendingPathComponent(localFileName)
    }
    
    var sharedFileURL: URL? {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        return containerURL?.appendingPathComponent(localFileName)
    }
    
    func getLocalCalendarData() -> Data? {
        // Prefer shared file if it exists
        if let sharedURL = sharedFileURL, FileManager.default.fileExists(atPath: sharedURL.path) {
            return try? Data(contentsOf: sharedURL)
        }
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            return try? Data(contentsOf: localFileURL)
        }
        return nil
    }
    
    func fetchLatestCalendar() async {
        await MainActor.run {
            isUpdating = true
            updateError = nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: calendarURL)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // Validate JSON
            _ = try JSONDecoder().decode(CalendarData.self, from: data)
            
            // Save to shared container
            if let sharedURL = sharedFileURL {
                try data.write(to: sharedURL)
            }
            
            // Also save to local file as backup
            try data.write(to: localFileURL)
            
            await MainActor.run {
                self.lastUpdated = Date()
                self.isUpdating = false
                // Notify BhitteCalendar to reload
                BhitteCalendar.shared.loadCalendarData()
                // Reload Widget
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            await MainActor.run {
                self.updateError = error.localizedDescription
                self.isUpdating = false
            }
        }
    }
    
    func checkAndAutoUpdate() {
        let now = Date()
        if let last = lastUpdated {
            // Update if more than 24 hours ago
            if now.timeIntervalSince(last) > 24 * 60 * 60 {
                Task {
                    await fetchLatestCalendar()
                }
            }
        } else {
            // Never updated, fetch now
            Task {
                await fetchLatestCalendar()
            }
        }
    }
}
