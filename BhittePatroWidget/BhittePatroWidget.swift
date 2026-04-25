//
//  BhittePatroWidget.swift
//  BhittePatroWidget
//

import WidgetKit
import SwiftUI
import Foundation
import SQLite3

// MARK: - Models
struct BSDate: Equatable, Codable {
    var year: Int
    var month: Int
    var day: Int
    
    var dateString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}

struct CalendarData: Codable {
    let monthDaysData: [String: [Int]]
    let holidays: [String: [String: [String: [String]]]]
    let tithi: [String: [String: [Int]]]
}

// MARK: - Note Manager for Widget
class BhitteNoteManager {
    static let shared = BhitteNoteManager()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
    }
    
    private func openDatabase() {
        let appGroupIdentifier = "group.com.pranab.BhittePatro"
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else { return }
        let dbURL = containerURL.appendingPathComponent("bhitte_patro_notes.sqlite")
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK { print("Widget: Error opening DB") }
    }
    
    func getNote(for date: BSDate) -> String? {
        let query = "SELECT content FROM notes WHERE id = ?;"
        var statement: OpaquePointer?
        var content: String? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (date.dateString as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                if let col = sqlite3_column_text(statement, 0) {
                    content = String(cString: col)
                }
            }
        }
        sqlite3_finalize(statement)
        return content
    }
}

// MARK: - Calendar Engine
class BhitteCalendar {
    static let shared = BhitteCalendar()

    let nepaliNumbers = ["०", "१", "२", "३", "४", "५", "६", "७", "८", "९"]
    let weekDays = ["आइत", "सोम", "मंगल", "बुध", "बिही", "शुक्र", "शनि"]
    let months = ["बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज", "कात्तिक", "मंसिर", "पुष", "माघ", "फागुन", "चैत"]
    let tithiNames = ["", "प्रतिपदा", "द्वितीया", "तृतीया", "चतुर्थी", "पञ्चमी", "षष्ठी", "सप्तमी", "अष्टमी", "नवमी", "दशमी", "एकादशी", "द्वादशी", "त्रयोदशी", "चतुर्दशी", "पूर्णिमा/औँसी"]

    private let anchorYear = 2060
    private let anchorMonth = 1
    private let anchorDay = 1
    private let anchorWeekday = 1

    private var monthDaysData: [Int: [Int]] = [:]
    private var holidays: [Int: [Int: [Int: [String]]]] = [:]
    private var tithi: [Int: [Int: [Int]]] = [:]
    private var isLoaded = false

    private init() {}

    private func ensureLoaded() {
        if isLoaded { return }
        loadCalendarData()
        isLoaded = true
    }

    func loadCalendarData() {
        let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.pranab.BhittePatro")
        let sharedFileURL = sharedContainerURL?.appendingPathComponent("calendar.json")
        var data: Data?
        if let url = sharedFileURL, FileManager.default.fileExists(atPath: url.path) { data = try? Data(contentsOf: url) }
        if data == nil {
            guard let url = Bundle.main.url(forResource: "calendar", withExtension: "json") else { return }
            data = try? Data(contentsOf: url)
        }
        guard let data = data else { return }
        do {
            let decodedData = try JSONDecoder().decode(CalendarData.self, from: data)
            for (yearStr, days) in decodedData.monthDaysData { if let year = Int(yearStr) { self.monthDaysData[year] = days } }
            for (yearStr, months) in decodedData.holidays {
                if let year = Int(yearStr) {
                    var yearHolidays: [Int: [Int: [String]]] = [:]
                    for (monthStr, days) in months {
                        if let month = Int(monthStr) {
                            var monthHolidays: [Int: [String]] = [:]
                            for (dayStr, names) in days { if let day = Int(dayStr) { monthHolidays[day] = names } }
                            yearHolidays[month] = monthHolidays
                        }
                    }
                    self.holidays[year] = yearHolidays
                }
            }
            for (yearStr, months) in decodedData.tithi {
                if let year = Int(yearStr) {
                    var yearTithi: [Int: [Int]] = [:]
                    for (monthStr, days) in months { if let month = Int(monthStr) { yearTithi[month] = days } }
                    self.tithi[year] = yearTithi
                }
            }
        } catch { print("Error loading calendar data: \(error)") }
    }

    func holidayText(year: Int, month: Int, day: Int) -> String? {
        ensureLoaded()
        guard let names = holidays[year]?[month]?[day], !names.isEmpty else { return nil }
        return names.joined(separator: " / ")
    }

    func tithiText(year: Int, month: Int, day: Int) -> String? {
        ensureLoaded()
        guard let monthTithis = tithi[year]?[month], day > 0 && day <= monthTithis.count else { return nil }
        let val = monthTithis[day - 1]
        return (val >= 1 && val <= 15) ? tithiNames[val] : nil
    }

    func convertToBSDate(from date: Date) -> BSDate? {
        ensureLoaded()
        let calendar = Calendar(identifier: .gregorian)
        var anchorComps = DateComponents(); anchorComps.year = 2003; anchorComps.month = 4; anchorComps.day = 14
        guard let anchorDate = calendar.date(from: anchorComps) else { return nil }
        let d1 = calendar.startOfDay(for: anchorDate), d2 = calendar.startOfDay(for: date)
        guard let daysDiff = calendar.dateComponents([.day], from: d1, to: d2).day, daysDiff >= 0 else { return nil }
        var year = anchorYear, month = anchorMonth, day = anchorDay, remaining = daysDiff
        while remaining > 0 {
            let dim = daysInMonth(year: year, month: month), left = dim - day
            if remaining <= left { day += remaining; remaining = 0 }
            else { remaining -= (left + 1); day = 1; month += 1; if month > 12 { month = 1; year += 1 } }
            if monthDaysData[year] == nil { return nil }
        }
        return BSDate(year: year, month: month, day: day)
    }

    func addDays(to date: BSDate, days: Int) -> BSDate? {
        ensureLoaded()
        var y = date.year; var m = date.month; var d = date.day + days
        guard monthDaysData[y] != nil else { return nil }
        while true {
            guard let dim = monthDaysData[y]?[m - 1] else { return nil }
            if d <= dim { break } else { d -= dim; m += 1; if m > 12 { m = 1; y += 1; if monthDaysData[y] == nil { return nil } } }
        }
        return BSDate(year: y, month: m, day: d)
    }

    func daysInMonth(year: Int, month: Int) -> Int {
        ensureLoaded()
        return monthDaysData[year]?[month - 1] ?? 30
    }

    func firstWeekday(year: Int, month: Int) -> Int {
        ensureLoaded()
        var total = 0
        for y in anchorYear..<year { total += monthDaysData[y]?.reduce(0, +) ?? 365 }
        for m in 1..<month { total += daysInMonth(year: year, month: m) }
        return (anchorWeekday + total) % 7
    }

    func toNepaliDigits(_ number: Int) -> String {
        String(number).compactMap { char in
            if let d = char.wholeNumberValue { return nepaliNumbers[d] }
            return String(char)
        }.joined()
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todayBS: BSDate(year: 2083, month: 1, day: 6))
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let today = BhitteCalendar.shared.convertToBSDate(from: Date()) ?? BSDate(year: 2083, month: 1, day: 6)
        completion(SimpleEntry(date: Date(), todayBS: today))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let date = Date()
        let today = BhitteCalendar.shared.convertToBSDate(from: date) ?? BSDate(year: 2083, month: 1, day: 6)
        completion(Timeline(entries: [SimpleEntry(date: date, todayBS: today)], policy: .atEnd))
    }
}

struct SimpleEntry: TimelineEntry, Codable {
    let date: Date
    let todayBS: BSDate
}

// MARK: - Views
struct CalendarCell: Identifiable {
    let id: String
    let day: Int?
    let isCurrentMonth: Bool
    let isToday: Bool
}

func buildCalendarCells(displayYear: Int, displayMonth: Int, firstWeekday: Int, daysInMonth: Int, today: BSDate) -> [CalendarCell] {
    var cells: [CalendarCell] = []
    for i in 0..<firstWeekday { cells.append(CalendarCell(id: "prev-\(i)", day: nil, isCurrentMonth: false, isToday: false)) }
    for day in 1...daysInMonth {
        let isToday = today.year == displayYear && today.month == displayMonth && today.day == day
        cells.append(CalendarCell(id: "curr-\(displayYear)-\(displayMonth)-\(day)", day: day, isCurrentMonth: true, isToday: isToday))
    }
    let remaining = 42 - cells.count
    if remaining > 0 { for i in 1...remaining { cells.append(CalendarCell(id: "next-\(i)", day: nil, isCurrentMonth: false, isToday: false)) } }
    return cells
}

struct CalendarCellView: View {
    let cell: CalendarCell
    let isToday: Bool
    var fontSize: CGFloat = 14
    var padding: CGFloat = 4
    var body: some View {
        ZStack {
            if let day = cell.day {
                if isToday { Circle().fill(Color.red).aspectRatio(1, contentMode: .fit).padding(padding) }
                Text(BhitteCalendar.shared.toNepaliDigits(day))
                    .font(.system(size: cell.isCurrentMonth ? fontSize : fontSize * 0.8, weight: cell.isCurrentMonth ? .semibold : .regular))
                    .foregroundColor(isToday ? .white : (cell.isCurrentMonth ? .primary : .secondary))
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    var body: some View {
        VStack(spacing: 4) {
            Text("आज").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            Text(BhitteCalendar.shared.toNepaliDigits(entry.todayBS.day)).font(.system(size: 42, weight: .bold, design: .rounded))
            Text("\(BhitteCalendar.shared.months[entry.todayBS.month - 1]) \(BhitteCalendar.shared.toNepaliDigits(entry.todayBS.year))").font(.caption).foregroundStyle(.secondary)
            if let holiday = BhitteCalendar.shared.holidayText(year: entry.todayBS.year, month: entry.todayBS.month, day: entry.todayBS.day) {
                Text(holiday).font(.caption2).foregroundColor(.red).lineLimit(2).multilineTextAlignment(.center)
            }
        }
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    var body: some View {
        HStack(spacing: 0) {
            // Left: Today (60%)
            VStack(alignment: .leading, spacing: 6) {
                Text("आज").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(BhitteCalendar.shared.toNepaliDigits(entry.todayBS.day))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    let weekdayIndex = (BhitteCalendar.shared.firstWeekday(year: entry.todayBS.year, month: entry.todayBS.month) + entry.todayBS.day - 1) % 7
                    Text(BhitteCalendar.shared.weekDays[weekdayIndex]).font(.system(size: 16, weight: .medium)).foregroundColor(.secondary)
                }
                
                Text("\(BhitteCalendar.shared.months[entry.todayBS.month - 1]) \(BhitteCalendar.shared.toNepaliDigits(entry.todayBS.year))")
                    .font(.system(size: 14, weight: .semibold))
                
                if let tithi = BhitteCalendar.shared.tithiText(year: entry.todayBS.year, month: entry.todayBS.month, day: entry.todayBS.day) {
                    Text(tithi).font(.system(size: 12)).foregroundColor(.secondary)
                }
                
                if let holiday = BhitteCalendar.shared.holidayText(year: entry.todayBS.year, month: entry.todayBS.month, day: entry.todayBS.day) {
                    Label(holiday, systemImage: "star.fill").font(.system(size: 11, weight: .bold)).foregroundColor(.red).lineLimit(1)
                }
                
                if let note = BhitteNoteManager.shared.getNote(for: entry.todayBS) {
                    Label(note, systemImage: "doc.text.fill").font(.system(size: 11)).foregroundColor(.secondary).lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().padding(.vertical, 16)
            
            // Right: Upcoming (40%)
            VStack(alignment: .leading, spacing: 10) {
                upcomingSection(daysAhead: 1, base: entry.todayBS)
                upcomingSection(daysAhead: 2, base: entry.todayBS)
                upcomingSection(daysAhead: 3, base: entry.todayBS)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .frame(width: 130, alignment: .leading)
        }
    }
    
    private func upcomingSection(daysAhead: Int, base: BSDate) -> some View {
        Group {
            if let date = BhitteCalendar.shared.addDays(to: base, days: daysAhead) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(daysAhead == 1 ? "भोलि" : (daysAhead == 2 ? "पर्सि" : "निको पर्सि"))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text("\(BhitteCalendar.shared.months[date.month - 1]) \(BhitteCalendar.shared.toNepaliDigits(date.day))")
                        .font(.system(size: 11, weight: .bold))
                    
                    if let holiday = BhitteCalendar.shared.holidayText(year: date.year, month: date.month, day: date.day) {
                        Text(holiday).font(.system(size: 9, weight: .bold)).foregroundColor(.red).lineLimit(1)
                    }
                    
                    if let note = BhitteNoteManager.shared.getNote(for: date) {
                        Text(note).font(.system(size: 9)).foregroundColor(.secondary).lineLimit(1)
                    }
                }
            }
        }
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    var body: some View {
        VStack(spacing: 0) {
            let displayYear = entry.todayBS.year
            let displayMonth = entry.todayBS.month
            let firstWeekday = BhitteCalendar.shared.firstWeekday(year: displayYear, month: displayMonth)
            let daysInMonth = BhitteCalendar.shared.daysInMonth(year: displayYear, month: displayMonth)
            let cells = buildCalendarCells(displayYear: displayYear, displayMonth: displayMonth, firstWeekday: firstWeekday, daysInMonth: daysInMonth, today: entry.todayBS)
            
            HStack {
                HStack(spacing: 8) {
                    Text(BhitteCalendar.shared.months[displayMonth - 1]).font(.system(size: 20, weight: .bold)).foregroundStyle(.primary)
                    Text(BhitteCalendar.shared.toNepaliDigits(displayYear)).font(.system(size: 16, weight: .medium)).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("आज: \(BhitteCalendar.shared.toNepaliDigits(entry.todayBS.day))").font(.system(size: 14, weight: .bold)).foregroundColor(.red)
                    if let tithi = BhitteCalendar.shared.tithiText(year: entry.todayBS.year, month: entry.todayBS.month, day: entry.todayBS.day) {
                        Text(tithi).font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1).padding(.horizontal, 16)
            
            HStack(spacing: 1) {
                ForEach(BhitteCalendar.shared.weekDays, id: \.self) { day in
                    Text(day).font(.system(size: 11, weight: .bold)).foregroundColor(day == "शनि" ? .red : .secondary).frame(maxWidth: .infinity)
                }
            }.padding(.horizontal, 12).padding(.vertical, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(cells, id: \.id) { cell in CalendarCellView(cell: cell, isToday: cell.isToday, fontSize: 13, padding: 3).aspectRatio(1, contentMode: .fit) }
            }.padding(.horizontal, 12)
            
            Spacer(minLength: 12)
            
            VStack(spacing: 0) {
                if let holiday = BhitteCalendar.shared.holidayText(year: entry.todayBS.year, month: entry.todayBS.month, day: entry.todayBS.day) {
                    footerView(text: holiday, icon: "star.fill", color: .red)
                }
                if let note = BhitteNoteManager.shared.getNote(for: entry.todayBS) {
                    footerView(text: note, icon: "doc.text.fill", color: .secondary)
                }
            }
        }
    }
    
    private func footerView(text: String, icon: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1)
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 10))
                Text(text).font(.system(size: 12, weight: .medium)).lineLimit(1)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(color.opacity(0.03))
        }
    }
}

// MARK: - Main Widget
struct BhittePatroWidget: Widget {
    let kind: String = "BhittePatroWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetContentView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Bhitte Patro")
        .description("Nepali Calendar Widget")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetContentView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .systemSmall: SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default: LargeWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) { BhittePatroWidget() } timeline: { SimpleEntry(date: .now, todayBS: BSDate(year: 2083, month: 1, day: 6)) }
#Preview(as: .systemMedium) { BhittePatroWidget() } timeline: { SimpleEntry(date: .now, todayBS: BSDate(year: 2083, month: 1, day: 6)) }
#Preview(as: .systemLarge) { BhittePatroWidget() } timeline: { SimpleEntry(date: .now, todayBS: BSDate(year: 2083, month: 1, day: 6)) }
