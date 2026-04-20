//
//  AIResponseGenerator.swift
//  BhittePatroApp
//
//  Created by Pranab Kc on 18/04/2026.
//

import Foundation

class AIResponseGenerator {
    static let shared = AIResponseGenerator()
    
    // MARK: - Knowledge Base Models
    struct KnowledgeBase: Codable {
        let calendarInfo: CalendarInfo
        let tithiInfo: TithiInfo
        let holidays: [HolidayInfo]
        
        enum CodingKeys: String, CodingKey {
            case calendarInfo = "calendar_info"
            case tithiInfo = "tithi_info"
            case holidays
        }
    }
    
    struct CalendarInfo: Codable {
        let name: String
        let description: String
        let history: String
        let whyItExists: String
        let newYear: String
        
        enum CodingKeys: String, CodingKey {
            case name, description, history
            case whyItExists = "why_it_exists"
            case newYear = "new_year"
        }
    }
    
    struct TithiInfo: Codable {
        let definition: String
        let phases: [String: String]
        let significance: String
        let names: [String]
    }
    
    struct HolidayInfo: Codable {
        let name: String
        let significance: String
        let traditions: String
    }
    
    private var knowledgeBase: KnowledgeBase?
    
    private var conversationState: ConversationState = .idle
    private var userOffDays: [Int]? // 0 = Sunday, 6 = Saturday
    private var lastHolidayQueried: String?
    private var lastAction: AIAction?
    private var leaveDaysToTake: Int?
    private var conversionType: ConversionType?
    
    // For days between calculation
    private var daysBetweenStart: (month: Int, day: Int)?
    private var daysBetweenEnd: (month: Int, day: Int)?
    private var daysBetweenYear: Int?

    private enum ConversationState {
        case idle
        case awaitingOffDays
        case awaitingLeaveDayCount
        case awaitingDesiredBreakLength
        case awaitingConversionType
        case awaitingConversionDate
        case awaitingDaysBetweenRange
        case awaitingDaysBetweenYear
    }
    
    private enum ConversionType {
        case bsToAD
        case adToBS
    }
    
    private enum AIAction {
        case checkingHoliday
        case checkingDate
        case calculatingDuration
        case planningVacation
    }
    
    private let holidaySynonyms: [String: [String]] = [
        "dashain": ["dashain", "दशैं", "विजया दशमी", "dashain", "dasain"],
        "tihar": ["tihar", "तिहार", "दीपावली", "tihar", "deepawali", "yamapanchak"],
        "holi": ["holi", "होली", "फागु पूर्णिमा", "holi", "fagu"],
        "new year": ["navabarsha", "नयाँ वर्ष", "new year", "nava barsha"],
        "maha shivaratri": ["maha shivaratri", "महाशिवरात्री", "shivaratri", "shiva ratri"],
        "gai jatra": ["gai jatra", "गाईजात्रा", "gaijatra", "gai jatra"],
        "buddha jayanti": ["buddha jayanti", "बुद्ध जयन्ती", "buddha jayanti", "buddha purnima"],
        "chhat": ["chhath", "छठ", "chhath puja", "chhat"],
        "lhosar": ["lhosar", "ल्होसार", "sonam lhosar", "gyalpo lhosar", "tamu lhosar"],
        "janai purnima": ["janai purnima", "जनै पूर्णिमा", "rakshya bandhan"]
    ]
    
    private init() {
        loadKnowledgeBase()
    }
    
    private func loadKnowledgeBase() {
        guard let url = Bundle.main.url(forResource: "KnowledgeBase", withExtension: "json") ??
                        Bundle.main.url(forResource: "KnowledgeBase", withExtension: "json", subdirectory: "data") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.knowledgeBase = try JSONDecoder().decode(KnowledgeBase.self, from: data)
        } catch {
            print("Error loading KnowledgeBase: \(error)")
        }
    }
    
    private let monthSynonyms: [Int: [String]] = [
        1: ["baishakh", "baisakh", "बैशाख"],
        2: ["jestha", "jeth", "जेठ"],
        3: ["ashad", "ashar", "असार"],
        4: ["shrawan", "saun", "साउन"],
        5: ["bhadra", "bhadau", "भदौ"],
        6: ["ashwin", "asoj", "असोज"],
        7: ["kartik", "कात्तिक"],
        8: ["mangsir", "mansir", "marg", "मंसिर"],
        9: ["poush", "paush", "push", "पुष"],
        10: ["magh", "माघ"],
        11: ["falgun", "phagun", "फागुन"],
        12: ["chaitra", "chait", "चैत"]
    ]

    func generateResponse(for input: String, history: [ChatMessage] = []) -> String {
        let lowercasedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Context awareness: handle very short queries if they follow a previous query
        let words = lowercasedInput.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map(String.init)
        
        // Month conversion check
        if words.count <= 3 {
            for (index, synonyms) in monthSynonyms {
                if synonyms.contains(where: { lowercasedInput.contains($0) }) {
                    let nepaliName = BhitteCalendar.shared.months[index - 1]
                    // If it's just the month name or "what is baishakh", return conversion
                    if words.count == 1 || lowercasedInput.contains("what") || lowercasedInput.contains("convert") || lowercasedInput.contains("meaning") {
                        let suffix = index == 1 ? "st" : index == 2 ? "nd" : index == 3 ? "rd" : "th"
                        return "**\(nepaliName)** is the \(index)\(suffix) month of the Nepali calendar. [DATE:2081:\(index):1]"
                    }
                }
            }
        }

        if words.count <= 2 {
            if let holidayName = findHolidayName(in: lowercasedInput) {
                lastHolidayQueried = holidayName
                lastAction = .checkingHoliday
                return findNextHoliday(named: holidayName)
            }
        }
        
        // Handle "what about..." or "and..." context
        if lowercasedInput.contains("what about") || lowercasedInput.contains("and") || lowercasedInput.hasPrefix("how about") {
            if let holidayName = findHolidayName(in: lowercasedInput) {
                lastHolidayQueried = holidayName
                return findNextHoliday(named: holidayName)
            }
            
            // If they just say "and tomorrow?" or "and next week?"
            if lowercasedInput.contains("today") { return getTodaysDateInfo() }
            if lowercasedInput.contains("tomorrow") {
                if let tomorrow = BhitteCalendar.shared.addDays(to: BhitteCalendar.shared.convertToBSDate(from: Date())!, days: 1) {
                    return getInfoForBSDate(date: tomorrow)
                }
            }
        }

        switch conversationState {
        case .awaitingOffDays:
            return handleOffDaysResponse(for: lowercasedInput)
        case .awaitingLeaveDayCount:
            return handleLeaveCountResponse(for: lowercasedInput)
        case .awaitingDesiredBreakLength:
            return handleDesiredBreakLengthResponse(for: lowercasedInput)
        case .awaitingConversionType:
            return handleConversionTypeResponse(for: lowercasedInput)
        case .awaitingConversionDate:
            return handleConversionDateResponse(for: lowercasedInput)
        case .awaitingDaysBetweenRange:
            return handleDaysBetweenRangeResponse(for: lowercasedInput)
        case .awaitingDaysBetweenYear:
            return handleDaysBetweenYearResponse(for: lowercasedInput)
        case .idle:
            return handleIdleState(for: lowercasedInput)
        }
    }
    
    private func handleDaysBetweenRangeResponse(for input: String) -> String {
        let (start, end) = parseTwoDates(from: input)
        
        if let s = start, let e = end {
            self.daysBetweenStart = s
            self.daysBetweenEnd = e
            
            // Check if year was also provided in this message
            var year: Int?
            let yearMatches = input.lowercased().split(whereSeparator: { !$0.isNumber })
            for match in yearMatches {
                if match.count == 4, let y = Int(String(match)), y >= 2000 && y <= 2100 {
                    year = y
                    break
                }
            }
            
            if let y = year {
                self.daysBetweenYear = y
                let response = performDaysBetweenCalculation()
                resetConversation()
                return response
            }
            
            conversationState = .awaitingDaysBetweenYear
            return "Which year are we looking at? (e.g., 2083)"
        } else {
            return "Sure! Please provide the date range like 'Baishak 12 to Kartik 16' and I'll help you calculate the days."
        }
    }
    
    private func handleDaysBetweenYearResponse(for input: String) -> String {
        let numericInput = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let year = Int(numericInput), year >= 2000 && year <= 2100 {
            self.daysBetweenYear = year
            let response = performDaysBetweenCalculation()
            resetConversation()
            return response
        } else {
            return "Please provide a valid year, like 2083."
        }
    }
    
    private func parseTwoDates(from input: String) -> (start: (month: Int, day: Int)?, end: (month: Int, day: Int)?) {
        let separators = [" to ", " and ", " - "]
        var parts: [String] = []
        
        for sep in separators {
            let p = input.lowercased().components(separatedBy: sep)
            if p.count == 2 {
                parts = p
                break
            }
        }
        
        guard parts.count == 2 else { return (nil, nil) }
        
        return (parseMonthDay(from: parts[0]), parseMonthDay(from: parts[1]))
    }
    
    private func parseMonthDay(from input: String) -> (month: Int, day: Int)? {
        let components = input.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        var foundDay: Int?
        var foundMonth: Int?
        
        for comp in components {
            let cleanComp = String(comp).trimmingCharacters(in: .decimalDigits.inverted)
            if let day = Int(cleanComp) {
                // Ensure we don't pick up a year as a day
                if day > 0 && day <= 32 {
                    foundDay = day
                }
            }
            
            for (index, synonyms) in monthSynonyms {
                if synonyms.contains(String(comp)) {
                    foundMonth = index
                    break
                }
            }
        }
        
        if let m = foundMonth, let d = foundDay {
            return (m, d)
        }
        return nil
    }
    
    private func performDaysBetweenCalculation() -> String {
        guard let start = daysBetweenStart, let end = daysBetweenEnd, let year = daysBetweenYear else {
            return "I'm sorry, I ran into an issue calculating those days. Could we try again?"
        }
        
        let startBS = BSDate(year: year, month: start.month, day: start.day)
        let endBS = BSDate(year: year, month: end.month, day: end.day)
        
        if let days = BhitteCalendar.shared.daysBetween(from: startBS, to: endBS) {
            let startMonthName = BhitteCalendar.shared.months[start.month - 1]
            let endMonthName = BhitteCalendar.shared.months[end.month - 1]
            let startDayDigits = BhitteCalendar.shared.toNepaliDigits(start.day)
            let endDayDigits = BhitteCalendar.shared.toNepaliDigits(end.day)
            let yearDigits = BhitteCalendar.shared.toNepaliDigits(year)
            
            let absDays = abs(days)
            return "There are **\(absDays) days** between \(startMonthName) \(startDayDigits) and \(endMonthName) \(endDayDigits), \(yearDigits) BS. [DATE:\(startBS.year):\(startBS.month):\(startBS.day)] [DATE:\(endBS.year):\(endBS.month):\(endBS.day)]"
        }
        
        return "I couldn't calculate the duration for those specific dates. Please make sure they are valid dates for the year \(year)."
    }
    
    private func handleIdleState(for input: String) -> String {
        if matches(input: input, keywords: ["hello", "hi", "namaste", "hey"]) {
            return "नमस्ते! How can I help you with your schedule today? You can ask about holidays, calculate days between dates, or plan a vacation."
        }
        
        if matches(input: input, keywords: ["what is today", "today's date", "today date", "tell me about today"]) {
            lastAction = .checkingDate
            return getTodaysDateInfo()
        }
        
        // Check for date range: "Jestha 12th to Kartik 13th" or "days between..."
        if input.contains(" to ") || input.contains(" and ") || input.contains("days between") || input.contains("how many days from") {
            let (start, end) = parseTwoDates(from: input)
            
            if let s = start, let e = end {
                // Extract a 4-digit year
                var year: Int?
                let yearMatches = input.lowercased().split(whereSeparator: { !$0.isNumber })
                for match in yearMatches {
                    if match.count == 4, let y = Int(String(match)), y >= 2000 && y <= 2100 {
                        year = y
                        break
                    }
                }
                
                if let y = year {
                    self.daysBetweenStart = s
                    self.daysBetweenEnd = e
                    self.daysBetweenYear = y
                    let response = performDaysBetweenCalculation()
                    resetConversation()
                    return response
                } else {
                    self.daysBetweenStart = s
                    self.daysBetweenEnd = e
                    conversationState = .awaitingDaysBetweenYear
                    return "Which year are we looking at? (e.g., 2083)"
                }
            } else if input.contains("days between") || input.contains("how many days from") {
                conversationState = .awaitingDaysBetweenRange
                return "Sure! Please let me know the dates you're interested in, like 'Baishak 12 to Kartik 16'."
            }
        }

        if let holidayName = findHolidayName(in: input) {
            lastHolidayQueried = holidayName
            lastAction = .checkingHoliday
            return findNextHoliday(named: holidayName)
        }
        
        // Check for notes if no holiday was specifically named
        if let noteResult = findNextNoteMatch(matching: input) {
            lastAction = .checkingDate
            let daysRemaining = BhitteCalendar.shared.daysBetween(from: BhitteCalendar.shared.convertToBSDate(from: Date())!, to: noteResult.date) ?? 0
            let dateTag = "[DATE:\(noteResult.date.year):\(noteResult.date.month):\(noteResult.date.day)]"
            
            if daysRemaining == 0 {
                return "Today you have a note: **\(noteResult.name)**. \(dateTag)"
            } else if daysRemaining == 1 {
                return "Tomorrow is **\(noteResult.name)**. \(dateTag)"
            } else {
                return "**\(noteResult.name)** is in **\(daysRemaining) days**. \(dateTag)"
            }
        }
        
        if matches(input: input, keywords: ["when is next holiday", "next public holiday", "upcoming holiday"]) {
            lastAction = .checkingHoliday
            return findNextHoliday(named: nil)
        }
        
        if input.contains("what is on") || input.contains("what's on") || input.contains("events on") || input.contains("tell me about") {
            lastAction = .checkingDate
            return getInfoForDate(input: input)
        }

        let durationKeywords = ["how long", "how many days", "days left", "days remaining", "until", "till"]
        if durationKeywords.contains(where: { input.contains($0) }) {
            lastAction = .calculatingDuration
            return calculateDaysUntil(input: input)
        }
        
        if input.contains("date conversion") || input.contains("convert date") {
            conversationState = .awaitingConversionType
            return "Sure! Would you like to convert **BS to AD** or **AD to BS**? CHAT_OPTIONS:[BS to AD,AD to BS]"
        }

        let vacationTriggers = [
            "plan a vacation",
            "plan vacation",
            "take leave",
            "take a break",
            "need a break",
            "vacation planning",
            "best time to leave",
            "when to take off",
            "exhausted",
            "tired of work"
        ]
        
        if vacationTriggers.contains(where: { input.contains($0) }) {
            conversationState = .awaitingOffDays
            lastAction = .planningVacation
            return "I can help you plan a vacation. Saturday is always off. Which other day do you have off? CHAT_OPTIONS:[Friday,Sunday]"
        }
        
        // Knowledge Base Triggers
        if input.contains("bikram sambat") || input.contains("nepali calendar history") || input.contains("why nepali calendar") {
            if let info = knowledgeBase?.calendarInfo {
                return "**\(info.name)**\n\n\(info.description)\n\n**History:** \(info.history)\n\n**Why it exists:** \(info.whyItExists)"
            }
        }
        
        if input.contains("what is tithi") || input.contains("tithi definition") || input.contains("explain tithi") {
            if let info = knowledgeBase?.tithiInfo {
                return "**What is Tithi?**\n\n\(info.definition)\n\n**Phases:**\n- *Shukla Paksha:* \(info.phases["shukla_paksha"] ?? "")\n- *Krishna Paksha:* \(info.phases["krishna_paksha"] ?? "")\n\n**Significance:** \(info.significance)"
            }
        }
        
        if input.contains("culture") || input.contains("traditions") || input.contains("tell me about nepal") {
            return "Nepali culture is rich with festivals and traditions! You can ask me about major holidays like Dashain or Tihar, or about the Bikram Sambat calendar and Tithis."
        }
        
        // Fallback: if input looks like just a date (e.g. "17th baishakh")
        if parseDate(from: input) != nil {
            return getInfoForDate(input: input)
        }

        return "I'm not sure I understood. You can ask me:\n- \"When is Dashain?\"\n- \"How many days until 15th Jestha?\"\n- \"What is today's date?\"\n- \"Help me plan a vacation\""
    }
    
    private func getTodaysDateInfo() -> String {
        guard let today = BhitteCalendar.shared.convertToBSDate(from: Date()) else {
            return "I'm having trouble getting today's date."
        }
        let monthName = BhitteCalendar.shared.months[today.month - 1]
        let nepaliDay = BhitteCalendar.shared.toNepaliDigits(today.day)
        let nepaliYear = BhitteCalendar.shared.toNepaliDigits(today.year)
        
        var response = "Today is **\(monthName) \(nepaliDay), \(nepaliYear)** [DATE:\(today.year):\(today.month):\(today.day)]."
        
        if let tithi = BhitteCalendar.shared.tithiText(year: today.year, month: today.month, day: today.day) {
            response += "\nTithi: **\(tithi)**."
        }
        if let holiday = BhitteCalendar.shared.holidayText(year: today.year, month: today.month, day: today.day) {
            response += "\n\nIt is **\(holiday)**!"
            
            // Explain the holiday if we have info
            if let holidayInfo = findHolidayInfo(named: holiday) {
                response += "\n\n**Significance:** \(holidayInfo.significance)\n\n**Traditions:** \(holidayInfo.traditions)"
            }
        }
        return response
    }
    
    private func getInfoForBSDate(date: BSDate) -> String {
        let monthName = BhitteCalendar.shared.months[date.month - 1]
        let nepaliDay = BhitteCalendar.shared.toNepaliDigits(date.day)
        var response = "**\(monthName) \(nepaliDay)** [DATE:\(date.year):\(date.month):\(date.day)]:"
        
        var detailsFound = false
        if let tithi = BhitteCalendar.shared.tithiText(year: date.year, month: date.month, day: date.day) {
            response += "\n- Tithi: **\(tithi)**"
            detailsFound = true
        }
        if let holiday = BhitteCalendar.shared.holidayText(year: date.year, month: date.month, day: date.day) {
            response += "\n- Holiday: **\(holiday)**"
            detailsFound = true
        }
        
        // Check for user notes
        let dateKey = "\(date.year)-\(String(format: "%02d", date.month))-\(String(format: "%02d", date.day))"
        if let note = PatroNoteManager.shared.notes[dateKey], !note.isEmpty {
            response += "\n- Note: **\(note)**"
            detailsFound = true
        }
        
        return detailsFound ? response : "No specific events for \(monthName) \(nepaliDay)."
    }
    
    private func getInfoForDate(input: String) -> String {
        guard let date = parseDate(from: input) else {
            return "I couldn't understand which date you're asking about. Please use a format like '18th Baishakh'."
        }
        
        let monthName = BhitteCalendar.shared.months[date.month - 1]
        let nepaliDay = BhitteCalendar.shared.toNepaliDigits(date.day)
        var response = "On **\(monthName) \(nepaliDay)** [DATE:\(date.year):\(date.month):\(date.day)]:"
        
        var detailsFound = false
        if let tithi = BhitteCalendar.shared.tithiText(year: date.year, month: date.month, day: date.day) {
            response += "\n- Tithi is **\(tithi)**."
            detailsFound = true
        }
        if let holiday = BhitteCalendar.shared.holidayText(year: date.year, month: date.month, day: date.day) {
            response += "\n- It's **\(holiday)**."
            detailsFound = true
        }
        
        return detailsFound ? response : "I don't have any specific events for \(monthName) \(nepaliDay)."
    }

    private func handleOffDaysResponse(for input: String) -> String {
        var offDays: [Int] = [6] // Saturday is always off
        
        if input.contains("friday") {
            offDays.append(5)
        } else if input.contains("sunday") {
            offDays.append(0)
        } else {
            return "Please choose between Friday or Sunday. CHAT_OPTIONS:[Friday,Sunday]"
        }
        
        self.userOffDays = offDays
        conversationState = .awaitingLeaveDayCount
        
        return "Got it. And how many working days can you take off? CHAT_OPTIONS:[1 Day,2 Days,3 Days,4 Days]"
    }
    
    private func handleLeaveCountResponse(for input: String) -> String {
        let numericInput = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let leaveDays = Int(numericInput), (0...10).contains(leaveDays) else {
            return "Please provide a valid number of days (0-10)."
        }
        
        self.leaveDaysToTake = leaveDays
        conversationState = .awaitingDesiredBreakLength
        
        return "Got it. How long of a break are you looking for? CHAT_OPTIONS:[3 days,4 days,5+ days,10+ days]"
    }
    
    private func handleDesiredBreakLengthResponse(for input: String) -> String {
        let numericInput = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let desiredLength = Int(numericInput) else {
            return "Please select a break length. CHAT_OPTIONS:[3 days,4 days,5+ days,10+ days]"
        }
        
        let leaveDays = self.leaveDaysToTake ?? 0
        let result = calculateBestVacation(leaveDays: leaveDays, minTotalLength: desiredLength, searchDays: 40)
        
        let next40Message = "I searched for potential breaks within the next **40 days**."

        guard let bestOption = result else {
            // Stay in the current state to let them try a different break length
            return "\(next40Message)\n\nSorry, I couldn't find a **\(desiredLength)-day** break using only **\(leaveDays) leave days**. Would you like to look for a different length of break? CHAT_OPTIONS:[3 days,4 days,5+ days,10+ days]"
        }
        
        let (leaveDates, fullBlock) = bestOption
        let totalDays = fullBlock.count
        
        var response = "\(next40Message)\n\n"
        
        if leaveDates.isEmpty {
            response += "Great news! You can get a **\(totalDays)-day** break without taking any leave days!\n\nYour break will be:\n"
        } else {
            let leaveDateStrings = leaveDates.map { date in
                let month = BhitteCalendar.shared.months[date.month - 1]
                let day = BhitteCalendar.shared.toNepaliDigits(date.day)
                return "**\(month) \(day)**"
            }.joined(separator: ", ")
            
            response += "To get a **\(totalDays)-day** break, you should take leave on \(leaveDateStrings).\n\nYour full break will be:\n"
        }
        
        // Reset only on success
        resetConversation()
        
        // Sort full block by date
        let sortedBlock = fullBlock.sorted { d1, d2 in
            if d1.year != d2.year { return d1.year < d2.year }
            if d1.month != d2.month { return d1.month < d2.month }
            return d1.day < d2.day
        }
        
        for date in sortedBlock {
            response += "[DATE:\(date.year):\(date.month):\(date.day)] "
        }
        
        return response
    }

    private func calculateBestVacation(leaveDays: Int, minTotalLength: Int, searchDays: Int) -> (leaveDates: [BSDate], fullBlock: [BSDate])? {
        guard let offDays = userOffDays, let today = BhitteCalendar.shared.convertToBSDate(from: Date()) else { return nil }

        var bestOption: (leaveDates: [BSDate], fullBlock: [BSDate])?

        // Search for a vacation block that meets minTotalLength within searchDays
        for i in 1...searchDays {
            guard let startDate = BhitteCalendar.shared.addDays(to: today, days: i) else { continue }
            
            // For each starting day, try to build a block using up to 'leaveDays'
            var cursorDate = startDate
            var currentLeaveUsed = 0
            var currentBlock: [BSDate] = []
            var leaveDatesUsed: [BSDate] = []
            
            // Expand forward until we hit a workday we can't take leave for
            while true {
                let isWork = isWorkDay(date: cursorDate, offDays: offDays)
                if isWork {
                    if currentLeaveUsed < leaveDays {
                        currentLeaveUsed += 1
                        leaveDatesUsed.append(cursorDate)
                        currentBlock.append(cursorDate)
                    } else {
                        // Out of leave days
                        break
                    }
                } else {
                    // Holiday or Weekend
                    currentBlock.append(cursorDate)
                }
                
                guard let nextDay = BhitteCalendar.shared.addDays(to: cursorDate, days: 1) else { break }
                cursorDate = nextDay
                
                // Safety: don't look too far ahead for a single block
                if currentBlock.count > 45 { break }
            }
            
            // Also expand backward from startDate to catch any adjacent non-work days
            var backDate = startDate
            while true {
                guard let prevDay = BhitteCalendar.shared.addDays(to: backDate, days: -1) else { break }
                if !isWorkDay(date: prevDay, offDays: offDays) {
                    currentBlock.insert(prevDay, at: 0)
                    backDate = prevDay
                } else {
                    break
                }
            }
            
            if currentBlock.count >= minTotalLength {
                // If we found multiple, prefer the one with the MOST total days
                if bestOption == nil || currentBlock.count > bestOption!.fullBlock.count {
                    bestOption = (leaveDatesUsed, currentBlock)
                }
            }
        }

        return bestOption
    }
    
    private func isWorkDay(date: BSDate, offDays: [Int]) -> Bool {
        if BhitteCalendar.shared.holidayText(year: date.year, month: date.month, day: date.day) != nil {
            return false
        }
        guard let adDate = BhitteCalendar.shared.convertToADDate(from: date) else { return true }
        let weekday = Calendar.current.component(.weekday, from: adDate) - 1 // 0=Sun, 6=Sat
        
        if weekday == 6 { return false } // Saturday is ALWAYS a holiday
        
        return !offDays.contains(weekday)
    }

    private func findHolidayInfo(named name: String) -> HolidayInfo? {
        return knowledgeBase?.holidays.first { info in
            info.name.lowercased() == name.lowercased() || name.lowercased().contains(info.name.lowercased())
        }
    }

    private func findHolidayName(in input: String) -> String? {
        let words = input.lowercased().split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map(String.init)
        
        // Check for specific holiday names
        for (englishName, synonyms) in holidaySynonyms {
            for synonym in synonyms {
                // Use strict word matching for short names like "holi" 
                // to prevent matching "holiday"
                if synonym == "holi" || synonym == "fagu" {
                    if words.contains(synonym) {
                        return englishName
                    }
                } else if words.contains(synonym) || input.contains(synonym) {
                    return englishName
                }
            }
        }
        return nil
    }

    private func findNextHoliday(named holidayName: String?) -> String {
        let today = BhitteCalendar.shared.convertToBSDate(from: Date())!
        
        let synonyms: [String]
        if let name = holidayName {
            synonyms = holidaySynonyms[name] ?? [name]
        } else {
            synonyms = []
        }

        if let result = BhitteCalendar.shared.findNextHoliday(matching: synonyms.isEmpty ? nil : synonyms) {
            let daysRemaining = BhitteCalendar.shared.daysBetween(from: today, to: result.date) ?? 0
            
            let dateTag = "[DATE:\(result.date.year):\(result.date.month):\(result.date.day)]"
            
            var response = ""
            if daysRemaining == 0 {
                response = "Today is **\(result.name)**! \(dateTag)"
            } else if daysRemaining == 1 {
                response = "**\(result.name)** is tomorrow! \(dateTag)"
            } else {
                response = "**\(result.name)** is in **\(daysRemaining) days**. \(dateTag)"
            }
            
            if let holidayInfo = findHolidayInfo(named: result.name) {
                response += "\n\n**Significance:** \(holidayInfo.significance)\n\n**Traditions:** \(holidayInfo.traditions)"
            }
            
            return response
        } else {
            let display = holidayName ?? "any holiday"
            return "I couldn't find \(display) in the upcoming months."
        }
    }
    
    private func parseDate(from input: String) -> BSDate? {
        let components = input.lowercased().split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        
        var foundDay: Int?
        var foundMonth: Int?
        
        for comp in components {
            let cleanComp = String(comp).trimmingCharacters(in: .decimalDigits.inverted)
            if let day = Int(cleanComp) {
                foundDay = day
            }
            
            // Check month synonyms
            for (index, synonyms) in monthSynonyms {
                if synonyms.contains(String(comp)) {
                    foundMonth = index
                    break
                }
            }
        }
        
        if let m = foundMonth {
            let year = BhitteCalendar.shared.convertToBSDate(from: Date())?.year ?? 2081
            return BSDate(year: year, month: m, day: foundDay ?? 1)
        }
        return nil
    }

    private func calculateDaysUntil(input: String) -> String {
        if let targetDate = parseDate(from: input) {
            if let today = BhitteCalendar.shared.convertToBSDate(from: Date()) {
                var finalTargetDate = targetDate
                if (targetDate.month < today.month || (targetDate.month == today.month && targetDate.day < today.day)) {
                    finalTargetDate.year += 1
                }
                if let days = BhitteCalendar.shared.daysBetween(from: today, to: finalTargetDate) {
                    let monthName = BhitteCalendar.shared.months[targetDate.month - 1]
                    let dateTag = "[DATE:\(finalTargetDate.year):\(finalTargetDate.month):\(finalTargetDate.day)]"
                    return "There are **\(days) days** until \(monthName) \(targetDate.day). \(dateTag)"
                }
            }
        }
        
        // Fallback: check notes
        if let noteResult = findNextNoteMatch(matching: input) {
            let daysRemaining = BhitteCalendar.shared.daysBetween(from: BhitteCalendar.shared.convertToBSDate(from: Date())!, to: noteResult.date) ?? 0
            let dateTag = "[DATE:\(noteResult.date.year):\(noteResult.date.month):\(noteResult.date.day)]"
            return "Your note **\(noteResult.name)** is in **\(daysRemaining) days**. \(dateTag)"
        }
        
        return "I couldn't understand that date or find a matching note."
    }

    private func matches(input: String, keywords: [String]) -> Bool {
        keywords.contains { input.contains($0) }
    }
    
    private func handleConversionTypeResponse(for input: String) -> String {
        if input.contains("bs to ad") {
            conversionType = .bsToAD
            conversationState = .awaitingConversionDate
            return "Please provide the BS date in **yyyy-mm-dd** format (e.g., 2081-01-01)."
        } else if input.contains("ad to bs") {
            conversionType = .adToBS
            conversationState = .awaitingConversionDate
            return "Please provide the AD date in **yyyy-mm-dd** format (e.g., 2024-04-13)."
        } else {
            return "Please select a conversion type. CHAT_OPTIONS:[BS to AD,AD to BS]"
        }
    }
    
    private func handleConversionDateResponse(for input: String) -> String {
        let components = input.components(separatedBy: CharacterSet(charactersIn: "-/."))
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return "Invalid format. Please use **yyyy-mm-dd**."
        }
        
        let type = conversionType
        resetConversation()
        
        if type == .bsToAD {
            let bsDate = BSDate(year: year, month: month, day: day)
            if let adDate = BhitteCalendar.shared.convertToADDate(from: bsDate) {
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                return "The AD equivalent of **\(year)-\(month)-\(day) BS** is **\(formatter.string(from: adDate))**."
            }
        } else {
            // AD to BS
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = day
            if let adDate = Calendar.current.date(from: dateComponents),
               let bsDate = BhitteCalendar.shared.convertToBSDate(from: adDate) {
                let monthName = BhitteCalendar.shared.months[bsDate.month - 1]
                let nepaliDay = BhitteCalendar.shared.toNepaliDigits(bsDate.day)
                let nepaliYear = BhitteCalendar.shared.toNepaliDigits(bsDate.year)
                return "The BS equivalent of **\(year)-\(month)-\(day) AD** is **\(monthName) \(nepaliDay), \(nepaliYear)** [DATE:\(bsDate.year):\(bsDate.month):\(bsDate.day)]."
            }
        }
        
        return "I couldn't convert that date. Please make sure it's a valid date."
    }

    private func resetConversation() {
        conversationState = .idle
        userOffDays = nil
        leaveDaysToTake = nil
        conversionType = nil
        daysBetweenStart = nil
        daysBetweenEnd = nil
        daysBetweenYear = nil
    }

    private func findNextNoteMatch(matching input: String) -> (name: String, date: BSDate)? {
        let today = BhitteCalendar.shared.convertToBSDate(from: Date())!
        let notes = PatroNoteManager.shared.notes
        
        // Search for the next 365 days
        for i in 0...365 {
            if let date = BhitteCalendar.shared.addDays(to: today, days: i) {
                let dateKey = "\(date.year)-\(String(format: "%02d", date.month))-\(String(format: "%02d", date.day))"
                if let noteContent = notes[dateKey], !noteContent.isEmpty {
                    let noteContentLower = noteContent.lowercased()
                    let inputLower = input.lowercased()
                    
                    // Simple contains check for phrases like "my birthday" or "workout"
                    if inputLower.contains(noteContentLower) || noteContentLower.contains(inputLower) {
                        return (noteContent, date)
                    }
                    
                    // Word by word check
                    let noteWords = noteContentLower.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
                    let inputWords = inputLower.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
                    
                    for word in inputWords {
                        if noteWords.contains(where: { $0 == word }) {
                            return (noteContent, date)
                        }
                    }
                }
            }
        }
        return nil
    }
}
