//
//  NepaliPatroApp.swift
//  NepaliPatro
//
//  Created by Pranab Kc on 12/03/2026.
//

import SwiftUI

// MARK: - Models
struct BSDate: Equatable {
    var year: Int
    var month: Int
    var day: Int
}

// MARK: - Calendar Engine
class NepaliCalendar {
    static let shared = NepaliCalendar()
    
    let nepaliNumbers = ["०", "१", "२", "३", "४", "५", "६", "७", "८", "९"]
    let weekDays = ["आइत", "सोम", "मंगल", "बुध", "बिही", "शुक्र", "शनि"]
    let months = ["बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज", "कात्तिक", "मंसिर", "पुष", "माघ", "फागुन", "चैत"]
    
    // Anchor: 2060/01/01 BS = 2003/04/14 AD (Monday = 1)
    private let anchorYear = 2060
    private let anchorMonth = 1
    private let anchorDay = 1
    private let anchorWeekday = 1
    
    private let monthDaysData: [Int: [Int]] = [
        2060: [31,31,32,32,31,30,30,29,30,29,30,30],
        2061: [31,32,31,32,31,30,30,30,29,29,30,31],
        2062: [31,31,31,32,31,31,29,30,29,30,29,31],
        2063: [31,31,32,31,31,31,30,29,30,29,30,30],
        2064: [31,31,32,32,31,30,30,29,30,29,30,30],
        2065: [31,32,31,32,31,30,30,30,29,29,30,31],
        2066: [31,31,31,32,31,31,29,30,30,29,29,31],
        2067: [31,31,32,31,31,31,30,29,30,29,30,30],
        2068: [31,31,32,32,31,30,30,29,30,29,30,30],
        2069: [31,32,31,32,31,30,30,30,29,29,30,31],
        2070: [31,31,31,32,31,31,29,30,30,29,30,30],
        2071: [31,31,32,31,31,31,30,29,30,29,30,30],
        2072: [31,32,31,32,31,30,30,29,30,29,30,30],
        2073: [31,32,31,32,31,30,30,30,29,29,30,31],
        2074: [31,31,31,32,31,31,30,29,30,29,30,30],
        2075: [31,31,32,31,31,31,30,29,30,29,30,30],
        2076: [31,32,31,32,31,30,30,30,29,29,30,30],
        2077: [31,32,31,32,31,30,30,30,29,30,29,31],
        2078: [31,31,31,32,31,31,30,29,30,29,30,30],
        2079: [31,31,32,31,31,31,30,29,30,29,30,30],
        2080: [31,32,31,32,31,30,30,30,29,29,30,30],
        2081: [31,32,31,32,31,30,30,30,29,30,29,31],
        2082: [31,31,32,31,31,30,30,30,29,30,30,30],
        2083: [31,31,32,31,31,30,30,30,29,30,30,30],
        2084: [31,31,32,31,31,30,30,30,29,30,30,30],
        2085: [31,32,31,32,30,31,30,30,29,30,30,30],
    ]
    
    // MARK: Holidays
    enum HolidayID: String, CaseIterable {
        case newYear = "नयाँ वर्ष"
        case bisketJatra = "बिस्का जात्रा"
        case meshaSankranti = "मेष संक्रान्ति"
        case labourDay = "अन्तर्राष्ट्रिय श्रमिक दिवस"
        case ratoMatsyendranath = "रातो मत्स्येन्द्रनाथ रथयात्रा"
        case regionalLanguageDay = "प्रादेशिक भाषा दिवस"
        case kiratReformDay = "किरात समाज सुधार दिवस"
        case buddhaJayanti = "बुद्ध जयन्ती"
        case ubhauli = "उभौली पर्व"
        case chandiPurnima = "चण्डी पूर्णिमा"
        case republicDay = "गणतन्त्र दिवस"
        case bhotoJatra = "भोटो जात्रा (काठमाडौँ उपत्यका मात्र)"
        case sithiNakha = "सिठी नखः"
        case bakraEid = "बकर इद"
        case janaiPurnima = "जनै पूर्णिमा"
        case rakshaBandhan = "रक्षाबन्धन"
        case rishiTarpani = "ऋषितर्पणी"
        case gaijatra = "गाइजात्रा (बागमती प्रदेश मात्र)"
        case krishnaJanmashtami = "श्री कृष्ण जन्माष्टमी"
        case gauraStart = "गौरा पर्व सुरु"
        case haritalikaTeej = "हरितालिका तीज"
        case gaura = "गौरा पर्व"
        case nijamatiDiwas = "निजामती सेवा दिवस"
        case indraJatra = "इन्द्रजात्रा"
        case anantaChaturdashi = "अनन्त चतुर्दशी"
        case jitiya = "जितिया पर्व"
        case vishwakarmaPuja = "विश्वकर्मा पूजा"
        case nationalScienceDay = "राष्ट्रिय विज्ञान दिवस"
        case constitutionDay = "संविधान दिवस"
        case ghatasthapana = "घटस्थापना"
        case navaratriStart = "नवरात्र आरम्भ"
        case phulpati = "फूलपाती"
        case mahaAshtami = "महाअष्टमी"
        case mahanavami = "महानवमी"
        case vijayaDashami = "विजया दशमी"
        case papankushaEkadashi = "पापांकुशा एकादशी"
        case dashainHoliday = "दशैँ बिदा"
        case kojagratPurnima = "कोजाग्रत पूर्णिमा"
        case laxmiPuja = "लक्ष्मी पूजा"
        case kukurTihar = "कुकुर तिहार"
        case narakChaturdashi = "नरक चतुर्दशी"
        case tiharHoliday = "तिहार बिदा"
        case gaiPuja = "गाईपूजा"
        case govardhanPuja = "गोवर्द्धन पूजा"
        case mhaPuja = "म्ह पूजा"
        case nepalSambatStart = "नेपाल संवत् ११४६ आरम्भ"
        case bhaiTika = "भाई टिका"
        case kijaPuja = "किजा पूजा"
        case chhath = "छठ पर्व"
        case guruNanakJayanti = "गुरु नानक जयन्ती"
        case falgunandaJayanti = "फाल्गुनन्द जयन्ती"
        case intlDisabilityDay = "अन्तर्राष्ट्रिय अपाङ्गता दिवस"
        case udhauli = "उधौली पर्व"
        case yomariPunhi = "योमरी पुन्ही"
        case dhanyaPurnima = "धान्य पूर्णिमा"
        case christmas = "क्रिसमस डे"
        case tamuLhosar = "तमु ल्होसार"
        case prithviJayanti = "पृथ्वी जयन्ती"
        case nationalUnityDay = "राष्ट्रिय एकता दिवस"
        case magheSankranti = "माघे संक्रान्ति"
        case maghiParva = "माघी पर्व"
        case sonamLhosar = "सोनाम ल्होसार"
        case basantPanchami = "वसन्त पञ्चमी"
        case saraswatiPuja = "सरस्वती पूजा"
        case martyrDay = "शहीद दिवस"
        case mahashivaratri = "महाशिवरात्रि"
        case nepalArmyDay = "नेपाली सेना दिवस"
        case ghodeJatra = "घोडेजात्रा (काठमाडौँ उपत्यका मात्र)"
        case ramNavami = "राम नवमी"
    }
    
    // If you prefer, you can keep a separate names map. Using rawValue keeps it simple.
    private func names(for ids: [HolidayID]) -> String {
        ids.map { $0.rawValue }.joined(separator: " / ")
    }
    
    // year -> month -> day -> [HolidayID]
    private let holidays: [Int: [Int: [Int: [HolidayID]]]] = [
        2082: [
            1: [
                1: [.newYear, .bisketJatra, .meshaSankranti],
                18: [.labourDay, .ratoMatsyendranath],
                24: [.regionalLanguageDay, .kiratReformDay],
                29: [.buddhaJayanti, .ubhauli, .chandiPurnima]
            ],
            2: [
                15: [.republicDay],
                18: [.bhotoJatra, .sithiNakha],
                24: [.bakraEid]
            ],
            4: [
                24: [.janaiPurnima, .rakshaBandhan, .rishiTarpani],
                25: [.gaijatra],
                31: [.krishnaJanmashtami, .gauraStart]
            ],
            5: [
                10: [.haritalikaTeej],
                15: [.gaura, .nijamatiDiwas],
                21: [.indraJatra, .anantaChaturdashi],
                30: [.jitiya]
            ],
            6: [
                1: [.vishwakarmaPuja, .nationalScienceDay],
                3: [.constitutionDay],
                6: [.ghatasthapana, .navaratriStart],
                13: [.phulpati],
                14: [.mahaAshtami],
                15: [.mahanavami],
                16: [.vijayaDashami],
                17: [.papankushaEkadashi, .dashainHoliday],
                18: [.dashainHoliday, .kojagratPurnima]
            ],
            7: [
                3: [.laxmiPuja, .kukurTihar, .narakChaturdashi],
                4: [.tiharHoliday, .gaiPuja],
                5: [.govardhanPuja, .mhaPuja, .nepalSambatStart],
                6: [.bhaiTika, .kijaPuja],
                7: [.tiharHoliday],
                10: [.chhath],
                19: [.guruNanakJayanti],
                25: [.falgunandaJayanti]
            ],
            8: [
                17: [.intlDisabilityDay],
                18: [.udhauli, .yomariPunhi, .dhanyaPurnima]
            ],
            9: [
                10: [.christmas],
                15: [.tamuLhosar],
                27: [.prithviJayanti, .nationalUnityDay]
            ],
            10: [
                1: [.magheSankranti, .maghiParva],
                5: [.sonamLhosar],
                9: [.basantPanchami, .saraswatiPuja],
                16: [.martyrDay]
            ],
            11: [
                15: [.mahashivaratri, .nepalArmyDay]
            ],
            12: [
                4: [.ghodeJatra],
                13: [.ramNavami]
            ]
        ]
    ]
    
    func holidayText(year: Int, month: Int, day: Int) -> String? {
        guard let ids = holidays[year]?[month]?[day], !ids.isEmpty else { return nil }
        return names(for: ids)
    }
    
    func convertToBSDate(from date: Date) -> BSDate? {
        let calendar = Calendar(identifier: .gregorian)
        var anchorComps = DateComponents()
        anchorComps.year = 2003; anchorComps.month = 4; anchorComps.day = 14
        guard let anchorDate = calendar.date(from: anchorComps) else { return nil }
        
        let d1 = calendar.startOfDay(for: anchorDate)
        let d2 = calendar.startOfDay(for: date)
        guard let daysDiff = calendar.dateComponents([.day], from: d1, to: d2).day, daysDiff >= 0 else { return nil }
        
        var year = anchorYear, month = anchorMonth, day = anchorDay, remaining = daysDiff
        while remaining > 0 {
            let dim = daysInMonth(year: year, month: month)
            let left = dim - day
            if remaining <= left { day += remaining; remaining = 0 }
            else { remaining -= (left + 1); day = 1; month += 1; if month > 12 { month = 1; year += 1 } }
            if monthDaysData[year] == nil { return nil }
        }
        return BSDate(year: year, month: month, day: day)
    }
    
    func daysInMonth(year: Int, month: Int) -> Int {
        return monthDaysData[year]?[month - 1] ?? 30
    }
    
    func firstWeekday(year: Int, month: Int) -> Int {
        var total = 0
        for y in anchorYear..<year { total += monthDaysData[y]?.reduce(0, +) ?? 365 }
        for m in 1..<month { total += daysInMonth(year: year, month: m) }
        return (anchorWeekday + total) % 7
    }
    
    func toNepaliDigits(_ number: Int) -> String {
        return String(number).compactMap { char in
            if let d = char.wholeNumberValue { return nepaliNumbers[d] }
            return String(char)
        }.joined()
    }
}

// MARK: - App
@main
struct NepaliPatroApp: App {
    var body: some Scene {
        MenuBarExtra {
            VCenterView()
        } label: {
            HStack {
                Image(systemName: "calendar")
                if let today = NepaliCalendar.shared.convertToBSDate(from: Date()) {
                    Text(NepaliCalendar.shared.toNepaliDigits(today.day))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - View
struct VCenterView: View {
    @State private var displayYear: Int
    @State private var displayMonth: Int
    @State private var selectedDate: BSDate?
    @State private var showDateConversion = false
    private let today: BSDate?
    @State private var adDate = Date()
    @State private var bsDate = NepaliCalendar.shared.convertToBSDate(from: Date()) ?? BSDate(year: 2081, month: 1, day: 1)
    
    
    init() {
        let bsNow = NepaliCalendar.shared.convertToBSDate(from: Date()) ?? BSDate(year: 2081, month: 1, day: 1)
        _displayYear = State(initialValue: bsNow.year)
        _displayMonth = State(initialValue: bsNow.month)
        self.today = bsNow
        self._selectedDate = State(initialValue: bsNow) // default to today
    }

    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            if showDateConversion {
                HStack(spacing: 30){
                    // Ad Date we take default
                    VStack(alignment: .leading, spacing: 8){
                        Text("AD Date").font(.caption).foregroundColor(.secondary)
                        DatePicker(
                                "",
                                selection: $adDate,
                                displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: adDate){ _, newValue in
                                    if let converted = NepaliCalendar.shared.convertToBSDate(from: newValue){
                                        bsDate = converted
                                    }
                                }
                        }
                    // BS date :
                    VStack(alignment: .leading, spacing: 8){
                        Text("BS Date").font(.caption).foregroundColor(.secondary)
                        Text("\(NepaliCalendar.shared.months[bsDate.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(bsDate.year)) - \(NepaliCalendar.shared.toNepaliDigits(bsDate.day))").font(.caption).foregroundColor(.secondary).padding(10)
                    }
                }
            } else {
                HStack {
                    Text("\(NepaliCalendar.shared.months[displayMonth - 1]) \(NepaliCalendar.shared.toNepaliDigits(displayYear))")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    // show button take user to current month
                    Button("आज") {
                        if let today = today {
                            _displayYear.wrappedValue = today.year
                            _displayMonth.wrappedValue = today.month
                            selectedDate = today
                        }
                    }.foregroundStyle(Color(.red))
                    
                    HStack(spacing: 12) {
                        Button(action: { navigate(-1) }) { Image(systemName: "chevron.left") }
                        Button(action: { navigate(1) })  { Image(systemName: "chevron.right") }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 5)
                
                
                
                // Days of week
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(NepaliCalendar.shared.weekDays, id: \.self) { day in
                        Text(day).font(.caption2).fontWeight(.black).foregroundColor(.secondary)
                    }
                }
                
                // Grid Logic
                let firstWeekday = NepaliCalendar.shared.firstWeekday(year: displayYear, month: displayMonth)
                let daysInMonth = NepaliCalendar.shared.daysInMonth(year: displayYear, month: displayMonth)
                
                // Previous month info for leading placeholders
                let prevMonth = displayMonth == 1 ? 12 : displayMonth - 1
                let prevYear  = displayMonth == 1 ? displayYear - 1 : displayYear
                let daysInPrevMonth = NepaliCalendar.shared.daysInMonth(year: prevYear, month: prevMonth)
                
                // Always use exactly 35 cells; expand to 42 only when content overflows
                let totalNeeded    = firstWeekday + daysInMonth
                let totalGridCells = totalNeeded > 35 ? 42 : 35
                let trailingCount  = totalGridCells - totalNeeded   // always >= 0
                
                // Build a flat array of (label, isCurrentMonth, isToday, numericDay?, isHoliday)
                let cells: [(String, Bool, Bool, Int?, Bool)] = {
                    var result: [(String, Bool, Bool, Int?, Bool)] = []
                    
                    // Leading days from previous month
                    for i in 0..<firstWeekday {
                        let day = daysInPrevMonth - (firstWeekday - 1) + i
                        result.append((NepaliCalendar.shared.toNepaliDigits(day), false, false, nil, false))
                    }
                    
                    // Current month days
                    for day in 1...daysInMonth {
                        let isToday = today?.day == day &&
                        today?.month == displayMonth &&
                        today?.year == displayYear
                        let isHoliday = NepaliCalendar.shared.holidayText(year: displayYear, month: displayMonth, day: day) != nil
                        result.append((NepaliCalendar.shared.toNepaliDigits(day), true, isToday, day, isHoliday))
                    }
                    
                    // Trailing days from next month
                    for day in 1...max(1, trailingCount) where day <= trailingCount {
                        result.append((NepaliCalendar.shared.toNepaliDigits(day), false, false, nil, false))
                    }
                    
                    return result
                }()
                
                let columns = Array(repeating: GridItem(.fixed(32), spacing: 8), count: 7)
                
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                        let (label, isCurrent, isToday, numericDay, isHoliday) = cell
                        let isSelected: Bool = {
                            guard isCurrent, let d = numericDay, let sel = selectedDate else { return false }
                            return sel.year == displayYear && sel.month == displayMonth && sel.day == d
                        }()
                        
                        // Crimson-like color
                        let crimson = Color(.red)
                        
                        Text(label)
                            .font(isCurrent ? .system(size: 14, design: .rounded) : .caption2)
                            .frame(width: 32, height: 32)
                            .background(isSelected ? crimson : (isToday ? Color.red : Color.clear))
                            .foregroundColor(
                                isSelected || isToday ? .white :
                                    (index % 7 == 6 || isHoliday) ? .red : // Saturday or holiday
                                    (isCurrent ? .primary : .secondary.opacity(0.4))
                            )
                            .clipShape(Circle())
                            .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                            .contentShape(Rectangle()) // make the whole frame tappable
                            .onTapGesture {
                                guard isCurrent, let d = numericDay else { return }
                                selectedDate = BSDate(year: displayYear, month: displayMonth, day: d)
                            }
                    }
                }
                
                // Inline holiday/tithi text
                if let sel = selectedDate {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(NepaliCalendar.shared.months[sel.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(sel.day)), \(NepaliCalendar.shared.toNepaliDigits(sel.year))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let hText = NepaliCalendar.shared.holidayText(year: sel.year, month: sel.month, day: sel.day) {
                            Text(hText)
                                .font(.system(size: 14))
                                .foregroundColor(Color.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
            Divider()
            
            HStack {
                Button("Quit App") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.link).foregroundColor(.red)
                Spacer()
                
                Button(showDateConversion ? "BS Calendar" : "Date conversion") {
                    showDateConversion.toggle()
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .background(Color(.systemBlue))
                .cornerRadius(4)
            }
        }
        .padding()
        .frame(width: 280)
    }

    private func navigate(_ delta: Int) {
        var m = displayMonth + delta
        var y = displayYear
        if m < 1 { m = 12; y -= 1 }
        else if m > 12 { m = 1; y += 1 }
        if NepaliCalendar.shared.daysInMonth(year: y, month: m) > 0 {
            displayMonth = m; displayYear = y
            // keep selection within new month if possible
            if let sel = selectedDate, sel.year == y, sel.month == m {
                selectedDate = sel
            } else if let today = today, today.year == y, today.month == m {
                selectedDate = today
            } else {
                selectedDate = BSDate(year: y, month: m, day: 1)
            }
        }
    }
    
}

#Preview("Menu Content") {
    VCenterView()
        .frame(width: 280)
        .padding()
}
