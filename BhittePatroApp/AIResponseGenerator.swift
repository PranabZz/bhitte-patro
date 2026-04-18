//
//  AIResponseGenerator.swift
//  BhittePatroApp
//
//  Created by Pranab Kc on 18/04/2026.
//

import Foundation

class AIResponseGenerator {
    static let shared = AIResponseGenerator()
    private var conversationState: ConversationState = .idle
    private var userOffDays: [Int]? // 0 = Sunday, 6 = Saturday
    private var leaveDaysToTake: Int?

    private enum ConversationState {
        case idle
        case awaitingOffDays
        case awaitingLeaveDayCount
    }
    
    private let holidaySynonyms: [String: [String]] = [
        "dashain": ["dashain", "दशैं", "विजया दशमी"],
        "tihar": ["tihar", "तिहार", "दीपावली"],
        "holi": ["holi", "होली", "फागु पूर्णिमा"],
        "new year": ["navabarsha", "नयाँ वर्ष"],
        "maha shivaratri": ["maha shivaratri", "महाशिवरात्री"],
        "gai jatra": ["gai jatra", "गाईजात्रा"],
        "buddha jayanti": ["buddha jayanti", "बुद्ध जयन्ती"]
    ]

    func generateResponse(for input: String) -> String {
        let lowercasedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        switch conversationState {
        case .awaitingOffDays:
            return handleOffDaysResponse(for: lowercasedInput)
        case .awaitingLeaveDayCount:
            return handleLeaveCountResponse(for: lowercasedInput)
        case .idle:
            return handleIdleState(for: lowercasedInput)
        }
    }
    
    private func handleIdleState(for input: String) -> String {
        if matches(input: input, keywords: ["hello", "hi", "namaste", "hey"]) {
            return "नमस्ते! How can I help you with your schedule?"
        }
        
        if matches(input: input, keywords: ["what is today", "today's date"]) {
            return getTodaysDateInfo()
        }
        
        if let holidayName = findHolidayName(in: input) {
            return findNextHoliday(named: holidayName)
        }
        
        if matches(input: input, keywords: ["when is next holiday", "next public holiday"]) {
            return findNextHoliday(named: nil)
        }
        
        if input.contains("what is on") {
            return getInfoForDate(input: input)
        }
        
        if input.contains("how long till") || input.contains("how many days until") {
            return calculateDaysUntil(input: input)
        }

        if matches(input: input, keywords: ["best day to take leave", "plan a vacation", "when can i take a leave"]) {
            conversationState = .awaitingOffDays
            return "I can help you plan a vacation. First, what are your weekly off-days? (e.g., Saturday, Sunday)"
        }

        return "Sorry, I'm not sure how to answer that. You can ask me about dates, holidays, or help planning a vacation."
    }
    
    private func getTodaysDateInfo() -> String {
        guard let today = NepaliCalendar.shared.convertToBSDate(from: Date()) else {
            return "I'm having trouble getting today's date."
        }
        let nepaliDate = "\(NepaliCalendar.shared.months[today.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(today.day)), \(NepaliCalendar.shared.toNepaliDigits(today.year))"
        var response = "Today is \(nepaliDate)."
        
        if let tithi = NepaliCalendar.shared.tithiText(year: today.year, month: today.month, day: today.day) {
            response += "\nTithi: \(tithi)."
        }
        if let holiday = NepaliCalendar.shared.holidayText(year: today.year, month: today.month, day: today.day) {
            response += "\nIt is also **\(holiday)**."
        }
        return response
    }
    
    private func getInfoForDate(input: String) -> String {
        guard let date = parseDate(from: input) else {
            return "I couldn't understand which date you're asking about. Please use a format like '18th Baishakh'."
        }
        
        let nepaliDate = "\(NepaliCalendar.shared.months[date.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(date.day))"
        var response = "On \(nepaliDate):"
        
        var detailsFound = false
        if let tithi = NepaliCalendar.shared.tithiText(year: date.year, month: date.month, day: date.day) {
            response += "\n- Tithi is \(tithi)."
            detailsFound = true
        }
        if let holiday = NepaliCalendar.shared.holidayText(year: date.year, month: date.month, day: date.day) {
            response += "\n- It's **\(holiday)**."
            detailsFound = true
        }
        
        return detailsFound ? response : "I don't have any specific events for \(nepaliDate)."
    }

    private func handleOffDaysResponse(for input: String) -> String {
        var offDays: [Int] = []
        if input.contains("sunday") { offDays.append(0) }
        if input.contains("monday") { offDays.append(1) }
        if input.contains("tuesday") { offDays.append(2) }
        if input.contains("wednesday") { offDays.append(3) }
        if input.contains("thursday") { offDays.append(4) }
        if input.contains("friday") { offDays.append(5) }
        offDays.append(6) // Assume Saturday is always off
        
        self.userOffDays = Array(Set(offDays))
        conversationState = .awaitingLeaveDayCount
        
        return "Great. And how many working days can you take off? CHAT_OPTIONS:[1 Day,2 Days,3 Days,4 Days]"
    }
    
    private func handleLeaveCountResponse(for input: String) -> String {
        let numericInput = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let leaveDays = Int(numericInput), (1...4).contains(leaveDays) else {
            resetConversation()
            return "Please select one of the provided options. Let's start over when you're ready."
        }
        
        self.leaveDaysToTake = leaveDays
        resetConversation()

        guard let result = calculateBestLeaveDay(leaveDays: leaveDays) else {
            return "I looked ahead 3 months but couldn't find a good opportunity to use \(leaveDays) leave day(s). Maybe try with fewer days?"
        }
        
        let (leaveDates, totalDays) = result
        let startDate = leaveDates.first!
        let nepaliStartDate = "\(NepaliCalendar.shared.months[startDate.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(startDate.day))"
        
        if leaveDates.count == 1 {
            return "Your best option is to take **\(nepaliStartDate)** off. This will give you a **\(totalDays)-day vacation**."
        } else {
            let endDate = leaveDates.last!
            let nepaliEndDate = "\(NepaliCalendar.shared.months[endDate.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(endDate.day))"
            return "Your best option is to take leave from **\(nepaliStartDate)** to **\(nepaliEndDate)**. This will give you a **\(totalDays)-day vacation**."
        }
    }

    private func calculateBestLeaveDay(leaveDays: Int) -> (dates: [BSDate], total: Int)? {
        guard let offDays = userOffDays, let today = NepaliCalendar.shared.convertToBSDate(from: Date()) else { return nil }

        var bestOption: (dates: [BSDate], total: Int) = ([], 0)

        for i in 1...90 {
            guard let startDate = NepaliCalendar.shared.addDays(to: today, days: i) else { continue }
            
            var potentialLeaveDays: [BSDate] = []
            var cursorDate = startDate
            while potentialLeaveDays.count < leaveDays {
                if isWorkDay(date: cursorDate, offDays: offDays) {
                    potentialLeaveDays.append(cursorDate)
                }
                guard let nextDay = NepaliCalendar.shared.addDays(to: cursorDate, days: 1) else { break }
                cursorDate = nextDay
            }
            
            if potentialLeaveDays.count != leaveDays { continue }
            
            var vacationBlock: Set<String> = Set(potentialLeaveDays.map { $0.id })
            
            var backDate = potentialLeaveDays.first!
            while true {
                guard let prevDay = NepaliCalendar.shared.addDays(to: backDate, days: -1) else { break }
                if !isWorkDay(date: prevDay, offDays: offDays) {
                    vacationBlock.insert(prevDay.id)
                    backDate = prevDay
                } else { break }
            }
            
            var fwdDate = potentialLeaveDays.last!
            while true {
                guard let nextDay = NepaliCalendar.shared.addDays(to: fwdDate, days: 1) else { break }
                if !isWorkDay(date: nextDay, offDays: offDays) {
                    vacationBlock.insert(nextDay.id)
                    fwdDate = nextDay
                } else { break }
            }
            
            if vacationBlock.count > bestOption.total {
                bestOption = (potentialLeaveDays, vacationBlock.count)
            }
        }

        return bestOption.total > 0 ? bestOption : nil
    }
    
    private func isWorkDay(date: BSDate, offDays: [Int]) -> Bool {
        if NepaliCalendar.shared.holidayText(year: date.year, month: date.month, day: date.day) != nil {
            return false
        }
        guard let adDate = NepaliCalendar.shared.convertToADDate(from: date) else { return true }
        let weekday = Calendar.current.component(.weekday, from: adDate) - 1
        return !offDays.contains(weekday)
    }

    private func findHolidayName(in input: String) -> String? {
        let inputWords = Set(input.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map { String($0) })
        for (englishName, synonyms) in holidaySynonyms {
            for synonym in synonyms {
                if inputWords.contains(where: { $0.caseInsensitiveCompare(synonym) == .orderedSame }) {
                    return englishName
                }
            }
        }
        return nil
    }

    private func findNextHoliday(named holidayName: String?) -> String {
        let today = NepaliCalendar.shared.convertToBSDate(from: Date())!
        
        let synonyms: [String]
        if let name = holidayName {
            synonyms = holidaySynonyms[name] ?? []
        } else {
            synonyms = [] // Empty array means search for any holiday
        }

        if let result = NepaliCalendar.shared.findNextHoliday(matching: synonyms) {
            let nepaliDate = "\(NepaliCalendar.shared.months[result.date.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(result.date.day))"
            let daysRemaining = NepaliCalendar.shared.daysBetween(from: today, to: result.date) ?? 0
            
            if holidayName != nil {
                return "The next \(result.name) is on **\(nepaliDate)**, in **\(daysRemaining) days**."
            } else {
                return "The next public holiday is **\(result.name)** on **\(nepaliDate)**, in **\(daysRemaining) days**."
            }
        } else {
            let holidayDisplayName = holidayName != nil ? "'\(holidayName!)'" : "any upcoming holidays"
            return "I couldn't find \(holidayDisplayName) in the next year."
        }
    }
    
    private func parseDate(from input: String) -> BSDate? {
        let components = input.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        
        guard let dayStr = components.first(where: { Int($0.trimmingCharacters(in: .decimalDigits.inverted)) != nil }),
              let day = Int(dayStr.trimmingCharacters(in: .decimalDigits.inverted)),
              let monthName = components.first(where: { NepaliCalendar.shared.months.map { $0.lowercased() }.contains(String($0)) })
        else {
            return nil
        }

        if let monthIndex = NepaliCalendar.shared.months.firstIndex(where: { $0.lowercased() == monthName.lowercased() }) {
            let month = monthIndex + 1
            let year = NepaliCalendar.shared.convertToBSDate(from: Date())?.year ?? 2081
            return BSDate(year: year, month: month, day: day)
        }
        return nil
    }

    private func calculateDaysUntil(input: String) -> String {
        guard let targetDate = parseDate(from: input) else {
            return "I couldn't understand the date. Please use a format like '12th Jestha'."
        }
        
        if let today = NepaliCalendar.shared.convertToBSDate(from: Date()) {
            var finalTargetDate = targetDate
            if (targetDate.month < today.month || (targetDate.month == today.month && targetDate.day < today.day)) {
                finalTargetDate.year += 1
            }
            if let days = NepaliCalendar.shared.daysBetween(from: today, to: finalTargetDate) {
                let nepaliDateText = "\(NepaliCalendar.shared.months[targetDate.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(targetDate.day))"
                return "There are **\(days) days** until \(nepaliDateText)."
            }
        }
        return "Sorry, I was unable to calculate the duration."
    }

    private func matches(input: String, keywords: [String]) -> Bool {
        keywords.contains { input.contains($0) }
    }
    
    private func resetConversation() {
        conversationState = .idle
        userOffDays = nil
        leaveDaysToTake = nil
    }
}
