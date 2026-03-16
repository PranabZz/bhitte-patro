
import Foundation
import Combine

// Mock DateUpdater for testing
class DateUpdater: ObservableObject {
    @Published var currentDate = Date()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for midnight changes
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.currentDate = Date()
            }
            .store(in: &cancellables)
    }
}

func testDateUpdater() {
    print("--- TESTING DATE UPDATER ---")
    
    let updater = DateUpdater()
    let initialDate = updater.currentDate
    print("Initial Date: \(initialDate)")
    
    var updatedDate: Date? = nil
    
    let cancellable = updater.$currentDate
        .dropFirst() // Ignore initial value
        .sink { date in
            updatedDate = date
            print("Received Updated Date: \(date)")
        }
    
    // Simulate midnight change notification
    print("Simulating .NSCalendarDayChanged notification...")
    NotificationCenter.default.post(name: .NSCalendarDayChanged, object: nil)
    
    // Give it a moment to process (since it uses RunLoop.main)
    let runLoop = RunLoop.main
    let timeout = Date(timeIntervalSinceNow: 1.0)
    while updatedDate == nil && runLoop.run(mode: .default, before: timeout) {
        // waiting...
    }
    
    if let updated = updatedDate {
        if updated >= initialDate {
            print("SUCCESS: Date updated correctly.")
        } else {
            print("FAILURE: Updated date is earlier than initial date.")
        }
    } else {
        print("FAILURE: Date did not update after notification.")
    }
    
    cancellable.cancel()
}

testDateUpdater()
