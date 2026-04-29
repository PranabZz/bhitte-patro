//
//  CalendarView.swift
//  BhittePatroApp
//
//  Created by Pranab Kc on 16/03/2026.
//

import SwiftUI

struct CalendarView: View {
  @Binding var displayYear: Int
  @Binding var displayMonth: Int
  @Binding var selectedDate: BSDate?
  @Binding var today: BSDate?
  @Binding var adDate: Date
  @Binding var bsDate: BSDate
  @Binding var viewMode: CalendarViewMode
  @Binding var isAISelection: Bool

  @AppStorage("CalendarDesign") private var calendarDesign: String = CalendarDesign.classic.rawValue
  @AppStorage("AppTheme") private var appTheme: String = AppTheme.standard.rawValue

  private var design: CalendarDesign {
      CalendarDesign(rawValue: calendarDesign) ?? .classic
  }
  
  private var currentTheme: AppTheme {
      AppTheme(rawValue: appTheme) ?? .standard
  }

  @EnvironmentObject var noteManager: PatroNoteManager
  @State private var showNoteEditor: Bool = false
  @State private var popoverDate: BSDate? = nil

  private let rowSpacing: CGFloat = 2
  private let cellCornerRadius: CGFloat = 6
  private let numberOfRows = 6  // Always show 6 rows

  @State private var monthTransitionPhase: Double = 0

  private var displayMonthName: String {
    BhitteCalendar.shared.months[displayMonth - 1]
  }

  private var displayYearText: String {
    BhitteCalendar.shared.toNepaliDigits(displayYear)
  }

  private var englishMonthLabel: String? {
    let daysInMonth = BhitteCalendar.shared.daysInMonth(year: displayYear, month: displayMonth)
    guard
      let startDate = BhitteCalendar.shared.convertToADDate(
        from: BSDate(year: displayYear, month: displayMonth, day: 1)),
      let endDate = BhitteCalendar.shared.convertToADDate(
        from: BSDate(year: displayYear, month: displayMonth, day: daysInMonth))
    else {
      return nil
    }

    let monthFormatter = DateFormatter()
    monthFormatter.locale = Locale(identifier: "en_US_POSIX")
    monthFormatter.dateFormat = "MMMM"

    let yearFormatter = DateFormatter()
    yearFormatter.locale = Locale(identifier: "en_US_POSIX")
    yearFormatter.dateFormat = "yyyy"

    let startMonth = monthFormatter.string(from: startDate)
    let endMonth = monthFormatter.string(from: endDate)
    let startYear = yearFormatter.string(from: startDate)
    let endYear = yearFormatter.string(from: endDate)

    if startMonth == endMonth && startYear == endYear {
      return "\(startMonth) \(startYear)"
    }
    if startYear == endYear {
      return "\(startMonth)-\(endMonth) \(startYear)"
    }
    return "\(startMonth) \(startYear)-\(endMonth) \(endYear)"
  }

  var body: some View {
    VStack(spacing: 0) {
      if showNoteEditor, let sel = selectedDate {
        NoteEditorView(date: sel, noteManager: _noteManager.wrappedValue) {
          withAnimation(.easeInOut(duration: 0.2)) {
            showNoteEditor = false
          }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
      } else {
        VStack(spacing: 0) {
          // Header Section
          headerSection
            .frame(height: 38)
            .padding(.bottom, 10)

          // Weekday headers
          weekdaySection
            .frame(height: 32)

          // Calendar grid with directional slide animation
          calendarGridSection
            .animation(.easeInOut(duration: 0.25), value: displayMonth)

          // Selected date info / Settings
          footerSection
        }
        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
      }
    }
    .padding(16)
    .background {
        if currentTheme == .himalaya {
            ZStack {
                Color.blue.opacity(0.01) // Very light to let particles show
                LinearGradient(colors: [.blue.opacity(0.04), .clear], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        } else if currentTheme == .terai {
            ZStack {
                Color.green.opacity(0.01)
                LinearGradient(colors: [.green.opacity(0.04), .clear], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        } else {
            Color.clear.ignoresSafeArea()
        }
    }
  }

  // MARK: - Header Section
  private var headerSection: some View {
    HStack(spacing: 0) {
      // Month/Year Navigation
      HStack(spacing: 12) {
        Button(action: { navigate(-1) }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 10, weight: .bold))
            .frame(width: 32, height: 32)
            .background(
                currentTheme == .himalaya ? Color.blue.opacity(0.12) : 
                currentTheme == .terai ? Color.green.opacity(0.12) : 
                Color.secondary.opacity(0.12), 
                in: Circle()
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Menu {
          ForEach(1...12, id: \.self) { month in
            Button(action: { displayMonth = month }) {
              Text(BhitteCalendar.shared.months[month - 1])
            }
          }
        } label: {
          Text(displayMonthName)
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()

        Menu {
          ForEach(2060...2085, id: \.self) { year in
            Button(action: { displayYear = year }) {
              Text(BhitteCalendar.shared.toNepaliDigits(year))
            }
          }
        } label: {
          Text(displayYearText)
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()

        Button(action: { navigate(1) }) {
          Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .bold))
            .frame(width: 32, height: 32)
            .background(
                currentTheme == .himalaya ? Color.blue.opacity(0.12) : 
                currentTheme == .terai ? Color.green.opacity(0.12) : 
                Color.secondary.opacity(0.12), 
                in: Circle()
            )
            .contentShape(Rectangle())
        }

        .buttonStyle(.plain)
      }
      .foregroundStyle(.primary)

      Spacer()

      HStack(spacing: 12) {
        // "Today" Button
        if let today, !(today.year == displayYear && today.month == displayMonth) {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
              displayYear = today.year
              displayMonth = today.month
              selectedDate = today
            }
          }) {
            HStack(spacing: 4) {
              Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 11, weight: .semibold))
              Text("आज")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.red)
          }
          .buttonStyle(.plain)
          .transition(.opacity.combined(with: .scale))
        }

        // AI Chat Button
        if let today, today.year == displayYear && today.month == displayMonth {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewMode = .ai
            }
          }) {
            Image(systemName: "sparkle")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 28, height: 28)
              .background(Color.purple.gradient, in: Circle())
          }
          .buttonStyle(.plain)
          .transition(.opacity.combined(with: .scale))
        }
      }
    }
  }

  // MARK: - Weekday Section
  private var weekdaySection: some View {
    HStack(spacing: 0) {
      ForEach(BhitteCalendar.shared.weekDays, id: \.self) { day in
        Text(day)
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(day == "शनि" ? .red : 
              currentTheme == .himalaya ? Color.blue.opacity(0.7) : 
              currentTheme == .terai ? Color.green.opacity(0.7) : 
              .secondary
          )
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.vertical, 6)
  }

  // MARK: - Calendar Grid Section
  private var calendarGridSection: some View {
    let firstWeekday = BhitteCalendar.shared.firstWeekday(year: displayYear, month: displayMonth)
    let daysInMonth = BhitteCalendar.shared.daysInMonth(year: displayYear, month: displayMonth)
    let cells = buildCells(firstWeekday: firstWeekday, daysInMonth: daysInMonth)
    let cellHeight = CGFloat(45)

    return GeometryReader { geo in
      let totalWidth = geo.size.width
      let cellSize = (totalWidth - (6 * rowSpacing)) / 7

      LazyVGrid(
        columns: Array(repeating: GridItem(.fixed(cellSize), spacing: rowSpacing), count: 7),
        alignment: .center,
        spacing: rowSpacing
      ) {
        ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
          CalendarCellView(
            cell: cell,
            index: index,
            cellSize: cellSize,
            cellHeight: cellHeight,
            selectedDate: selectedDate,
            displayYear: displayYear,
            displayMonth: displayMonth,
            isAISelection: isAISelection,
            design: design,
            theme: currentTheme
          )
          .contentShape(Rectangle())
          .onTapGesture { 
            if !cell.isEmpty {
              handleCellTap(cell: cell) 
            }
          }
          .popover(
            item: Binding(
              get: {
                if !cell.isEmpty && popoverDate == BSDate(year: cell.bsYear, month: cell.bsMonth, day: cell.bsDay) {
                  return cell.toBSDate()
                }
                return nil
              },
              set: { if $0 == nil { popoverDate = nil } }
            )
          ) { date in
            PopoverContentView(
              date: date,
              onEdit: {
                popoverDate = nil
                withAnimation(.easeInOut(duration: 0.2)) {
                  showNoteEditor = true
                }
              })
          }
        }
      }
      .frame(height: CGFloat(numberOfRows) * cellHeight + CGFloat(numberOfRows - 1) * rowSpacing)
    }
    .animation(.easeInOut(duration: 0.2), value: displayMonth)
  }

  // MARK: - Footer Section
  private var footerSection: some View {
    HStack(alignment: .center) {
      ZStack(alignment: .leading) {
        // Theme specific background accents
        if currentTheme == .himalaya {
            HStack {
                Spacer()
                HimalayaIconView()
                    .frame(width: 80, height: 40)
                    .opacity(0.15)
                    .offset(x: 10, y: 15)
            }
        } else if currentTheme == .terai {
            HStack {
                Spacer()
                HillIconView()
                    .frame(width: 80, height: 40)
                    .opacity(0.15)
                    .offset(x: 10, y: 15)
            }
        }

        Group {
          if let sel = selectedDate {
            let isToday =
              today?.year == sel.year && today?.month == sel.month && today?.day == sel.day
            let holiday = BhitteCalendar.shared.holidayText(
              year: sel.year, month: sel.month, day: sel.day)
            let upcoming =
              isToday
              ? BhitteCalendar.shared.nextHoliday(from: sel.year, month: sel.month, day: sel.day)
              : nil

            VStack(alignment: .leading, spacing: 6) {
              HStack(spacing: 4) {
                Text(
                  "\(BhitteCalendar.shared.months[sel.month - 1]) \(BhitteCalendar.shared.toNepaliDigits(sel.day))"
                )
                .font(.system(size: 10, weight: .bold))
                  

                Text(getEnglishDay(year: sel.year, month: sel.month, day: sel.day))
                  .font(.system(size: 9, weight: .bold))
                  .opacity(0.6)
              }
              .foregroundStyle(.secondary)

              Group {
                if let holidayText = holiday {
                  Text(holidayText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.red)
                } else if let upcomingHoliday = upcoming {
                  HStack(spacing: 4) {
                    Text("\(BhitteCalendar.shared.toNepaliDigits(upcomingHoliday.daysAway)) दिन मा")
                      .foregroundStyle(
                          currentTheme == .terai ? .green : 
                          currentTheme == .himalaya ? .blue : 
                          .primary
                      )
                    Text(upcomingHoliday.text)
                      .foregroundStyle(.red)
                  }
                  .font(.system(size: 12, weight: .bold))
                } else {
                  Text(isToday ? "No upcoming holidays" : "No holiday")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          } else {
            Text("Select a date")
              .font(.system(size: 11, weight: .bold))
              .foregroundStyle(Color.secondary.opacity(0.5))
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Settings Button
      Button {
        NotificationCenter.default.post(
          name: .didChangeDefaultViewMode,
          object: nil,
          userInfo: ["mode": "settings"]
        )
      } label: {
        Image(systemName: "gearshape.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.secondary)
          .frame(width: 32, height: 32)
          .background(
              currentTheme == .himalaya ? Color.blue.opacity(0.12) :
              currentTheme == .terai ? Color.green.opacity(0.12) :
              Color.secondary.opacity(0.12), 
              in: Circle()
          )
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background {
        if currentTheme == .himalaya {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        } else if currentTheme == .terai {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.06))
        }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  // MARK: - Helper Methods
  private func handleCellTap(cell: CellModel) {
    let tapped = BSDate(year: cell.bsYear, month: cell.bsMonth, day: cell.bsDay)

    selectedDate = tapped
    isAISelection = false

    if popoverDate == tapped {
      popoverDate = nil
    } else {
      popoverDate = tapped
    }
  }

  private func navigate(_ delta: Int) {
    var newMonth = displayMonth + delta
    var newYear = displayYear

    if newMonth < 1 {
      newMonth = 12
      newYear -= 1
    } else if newMonth > 12 {
      newMonth = 1
      newYear += 1
    }

    guard newYear >= 2060 && newYear <= 2085 else { return }

    withAnimation(.easeInOut(duration: 0.2)) {
      displayMonth = newMonth
      displayYear = newYear
    }
  }

  private func buildCells(firstWeekday: Int, daysInMonth: Int) -> [CellModel] {
    let prevMonth = displayMonth == 1 ? 12 : displayMonth - 1
    let prevYear = displayMonth == 1 ? displayYear - 1 : displayYear
    let daysInPrevMonth = BhitteCalendar.shared.daysInMonth(year: prevYear, month: prevMonth)

    let nextMonth = displayMonth == 12 ? 1 : displayMonth + 1
    let nextYear = displayMonth == 12 ? displayYear + 1 : displayYear

    var result: [CellModel] = []

    // Previous month days (empty padding)
    for i in 0..<firstWeekday {
      let day = daysInPrevMonth - (firstWeekday - 1) + i
      result.append(
        CellModel(
          bsYear: prevYear, bsMonth: prevMonth, bsDay: day,
          isCurrent: false,
          isToday: false,
          isHoliday: false,
          englishDay: "",
          nepaliDay: "",
          isEmpty: true
        ))
    }

    // Current month days
    for day in 1...daysInMonth {
      let isToday = today?.day == day && today?.month == displayMonth && today?.year == displayYear
      let isHoliday =
        BhitteCalendar.shared.holidayText(year: displayYear, month: displayMonth, day: day) != nil
      let nepaliDay = BhitteCalendar.shared.toNepaliDigits(day)
      let englishDay = getEnglishDay(year: displayYear, month: displayMonth, day: day)
      result.append(
        CellModel(
          bsYear: displayYear, bsMonth: displayMonth, bsDay: day,
          isCurrent: true,
          isToday: isToday,
          isHoliday: isHoliday,
          englishDay: englishDay,
          nepaliDay: nepaliDay,
          isEmpty: false
        ))
    }

    // Next month days (empty padding)
    let remainingCells = 42 - result.count
    for day in 1...remainingCells {
      result.append(
        CellModel(
          bsYear: nextYear, bsMonth: nextMonth, bsDay: day,
          isCurrent: false,
          isToday: false,
          isHoliday: false,
          englishDay: "",
          nepaliDay: "",
          isEmpty: true
        ))
    }

    return result
  }

  private func getEnglishDay(year: Int, month: Int, day: Int) -> String {
    guard
      let ad = BhitteCalendar.shared.convertToADDate(
        from: BSDate(year: year, month: month, day: day))
    else {
      return ""
    }
    let calendarDay = Calendar(identifier: .gregorian).component(.day, from: ad)
    return String(calendarDay)
  }
}

// MARK: - Popover Content
struct PopoverContentView: View {
  let date: BSDate
  var onEdit: () -> Void
  @EnvironmentObject var noteManager: PatroNoteManager

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Tithi
      VStack(alignment: .leading, spacing: 2) {
        Text("तिथि")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(.secondary)

        Text(
          BhitteCalendar.shared.tithiText(year: date.year, month: date.month, day: date.day) ?? "-"
        )
        .font(.system(size: 12, weight: .semibold))
      }

      Divider()

      // Notes
      VStack(alignment: .leading, spacing: 4) {
        let dateString =
          "\(date.year)-\(String(format: "%02d", date.month))-\(String(format: "%02d", date.day))"
        let hasNote =
          noteManager.notes[dateString] != nil && !noteManager.notes[dateString]!.isEmpty

        HStack {
          Text("NOTES")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.secondary)
          Spacer()
        }

        if hasNote {
          Text(noteManager.notes[dateString]!)
            .font(.system(size: 11))
            .lineLimit(4)
        }

        Button(action: onEdit) {
          Label(hasNote ? "Edit Note" : "Add Note", systemImage: hasNote ? "pencil.line" : "plus")
            .font(.system(size: 11))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)

      }
    }
    .padding(12)
    .frame(width: 180)
  }
}

// MARK: - Cell Model
private struct CellModel: Equatable {
  let bsYear: Int
  let bsMonth: Int
  let bsDay: Int
  let isCurrent: Bool
  let isToday: Bool
  let isHoliday: Bool
  let englishDay: String
  let nepaliDay: String
  var isEmpty: Bool = false

  func toBSDate() -> BSDate {
    BSDate(year: bsYear, month: bsMonth, day: bsDay)
  }

  static func == (lhs: CellModel, rhs: CellModel) -> Bool {
    return lhs.bsYear == rhs.bsYear && lhs.bsMonth == rhs.bsMonth && lhs.bsDay == rhs.bsDay
      && lhs.isCurrent == rhs.isCurrent && lhs.isToday == rhs.isToday
      && lhs.isHoliday == rhs.isHoliday && lhs.isEmpty == rhs.isEmpty
  }
}

// MARK: - Calendar Cell View
private struct CalendarCellView: View {
  let cell: CellModel
  let index: Int
  let cellSize: CGFloat
  let cellHeight: CGFloat
  let selectedDate: BSDate?
  let displayYear: Int
  let displayMonth: Int
  let isAISelection: Bool
  let design: CalendarDesign
  let theme: AppTheme

  @EnvironmentObject var noteManager: PatroNoteManager

  @State private var isCurrentMonth = false

  private var cellCornerRadius: CGFloat {
    switch design {
    case .classic: return 6
    case .modern: return 12
    case .minimalist: return 4
    }
  }

  var body: some View {
    let isSelected: Bool = {
      if let sel = selectedDate {
        return sel.year == cell.bsYear && sel.month == cell.bsMonth && sel.day == cell.bsDay
      }
      return false
    }()

    let dateString =
      "\(cell.bsYear)-\(String(format: "%02d", cell.bsMonth))-\(String(format: "%02d", cell.bsDay))"
    let hasNote = noteManager.notes[dateString] != nil && !noteManager.notes[dateString]!.isEmpty

    let animationDelay = Double(index) * 0.003

    ZStack {
      if !cell.isEmpty {
        // Background - today is red, AI selection is blue, manual selection is light gray
        if cell.isToday {
          if design == .minimalist {
            Circle()
              .fill(Color.red)
              .frame(width: 32, height: 32)
          } else {
            RoundedRectangle(cornerRadius: cellCornerRadius)
              .fill(design == .modern ? Color.red.gradient : Color.red.gradient)
          }
        } else if isSelected && isAISelection {
          RoundedRectangle(cornerRadius: cellCornerRadius)
            .fill(design == .modern ? Color.blue.gradient : Color.blue.gradient)
        } else if isSelected {
          if design == .minimalist {
            RoundedRectangle(cornerRadius: cellCornerRadius)
              .strokeBorder(theme == .himalaya ? Color.blue : theme == .terai ? Color.green : Color.primary.opacity(0.3), lineWidth: 1)
          } else {
            RoundedRectangle(cornerRadius: cellCornerRadius)
              .fill(theme == .himalaya ? Color.blue.opacity(0.15) : theme == .terai ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
          }
        } else {
          if design == .classic {
            RoundedRectangle(cornerRadius: cellCornerRadius)
              .fill(Color.secondary.opacity(0.15))
              .opacity(0) // Hide background for non-selected cells
          } else if design == .modern {
             RoundedRectangle(cornerRadius: cellCornerRadius)
              .fill(theme == .himalaya ? Color.blue.opacity(0.04) : theme == .terai ? Color.green.opacity(0.04) : Color.secondary.opacity(0.03))
          }
        }

        // Note indicator
        if hasNote {
          VStack {
            HStack {
              Spacer()
              if design == .minimalist {
                  Circle()
                    .fill(cell.isToday ? .white : theme == .himalaya ? .blue : theme == .terai ? .green : .blue)
                    .frame(width: 4, height: 4)
                    .padding(4)
              } else {
                  Image(systemName: "doc.text")
                    .font(.system(size: 7))
                    .foregroundStyle((cell.isToday || (isSelected && isAISelection)) ? .white : theme == .himalaya ? .blue : theme == .terai ? .green : .secondary)
                    .padding(4)
              }
            }
            Spacer()
          }
        }

        // Content
        VStack(spacing: 0) {
          Spacer(minLength: 0)

          // Nepali day number
          Text(cell.nepaliDay)
            .font(.system(size: design == .modern ? 20 : 18, weight: (cell.isToday || (isSelected && isAISelection)) ? .semibold : .regular, design: .rounded))
            .foregroundStyle(
              (cell.isToday || (isSelected && isAISelection))
                ? Color.white
                : (cell.isCurrent && cell.isHoliday)
                  ? Color.red
                  : (cell.isCurrent && index % 7 == 6)
                    ? Color.red
                    : (cell.isCurrent ? Color.primary : Color.gray.opacity(0.5))
            )

          Spacer(minLength: 0)

          // English day number
          HStack {
            Spacer(minLength: 0)
            if !cell.englishDay.isEmpty && design != .minimalist {
              Text(cell.englishDay)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(
                  (cell.isToday || (isSelected && isAISelection))
                    ? Color.white.opacity(0.9)
                    : (cell.isCurrent ? Color.secondary : Color.gray.opacity(0.4))
                )
                .padding(.trailing, 3)
                .padding(.bottom, 2)
            }
          }
        }
      }
    }
    .frame(width: cellSize, height: cellHeight)
    .opacity(cell.isCurrent ? (isCurrentMonth ? 1 : 0.5) : 0.6)
    .scaleEffect(cell.isCurrent ? (isCurrentMonth ? 1 : 0.85) : 1)
    .animation(.easeOut(duration: 0.25).delay(animationDelay), value: isCurrentMonth)
    .onChange(of: displayYear) { _, _ in
      if cell.isCurrent {
        withAnimation {
          isCurrentMonth = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          withAnimation {
            isCurrentMonth = (cell.bsYear == displayYear && cell.bsMonth == displayMonth)
          }
        }
      }
    }
    .onChange(of: displayMonth) { _, _ in
      if cell.isCurrent {
        withAnimation {
          isCurrentMonth = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          withAnimation {
            isCurrentMonth = (cell.bsYear == displayYear && cell.bsMonth == displayMonth)
          }
        }
      }
    }
    .onAppear {
      isCurrentMonth = (cell.bsYear == displayYear && cell.bsMonth == displayMonth)
    }
  }
}

// MARK: - Custom Theme Icons
struct HimalayaIconView: View {
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 512.0
            
            // Back Mountain
            var backMountain = Path()
            backMountain.move(to: CGPoint(x: 221.99 * scale, y: 308.864 * scale))
            backMountain.addLine(to: CGPoint(x: 503.648 * scale, y: 308.864 * scale))
            backMountain.addLine(to: CGPoint(x: 435.495 * scale, y: 190.829 * scale))
            backMountain.addLine(to: CGPoint(x: 350.158 * scale, y: 308.835 * scale))
            backMountain.closeSubpath()
            context.fill(backMountain, with: .color(Color(red: 0.29, green: 0.45, blue: 0.51)))
            
            // Front Mountain
            var frontMountain = Path()
            frontMountain.move(to: CGPoint(x: 10.066 * scale, y: 308.835 * scale))
            frontMountain.addLine(to: CGPoint(x: 350.158 * scale, y: 308.835 * scale))
            frontMountain.addLine(to: CGPoint(x: 276.607 * scale, y: 151.225 * scale))
            frontMountain.addLine(to: CGPoint(x: 10.066 * scale, y: 308.835 * scale))
            frontMountain.closeSubpath()
            context.fill(frontMountain, with: .color(Color(red: 0.29, green: 0.45, blue: 0.51)))
            
            // Snow Caps
            var cap1 = Path()
            cap1.move(to: CGPoint(x: 442.728 * scale, y: 178.358 * scale))
            cap1.addLine(to: CGPoint(x: 423.974 * scale, y: 206.089 * scale))
            cap1.addLine(to: CGPoint(x: 387 * scale, y: 206.089 * scale))
            cap1.addLine(to: CGPoint(x: 410 * scale, y: 150 * scale))
            cap1.closeSubpath()
            context.fill(cap1, with: .color(.white))
            
            var cap2 = Path()
            cap2.move(to: CGPoint(x: 276.607 * scale, y: 151.225 * scale))
            cap2.addLine(to: CGPoint(x: 254 * scale, y: 184 * scale))
            cap2.addLine(to: CGPoint(x: 216 * scale, y: 130 * scale))
            cap2.closeSubpath()
            context.fill(cap2, with: .color(.white))
        }
    }
}

struct HillIconView: View {
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 512.0
            
            // Simplified Hill Path based on the SVG
            var hill = Path()
            hill.move(to: CGPoint(x: 83.335 * scale, y: 413.542 * scale))
            hill.addQuadCurve(to: CGPoint(x: 261.604 * scale, y: 299.381 * scale), control: CGPoint(x: 180 * scale, y: 240 * scale))
            hill.addQuadCurve(to: CGPoint(x: 457.556 * scale, y: 413.542 * scale), control: CGPoint(x: 350 * scale, y: 350 * scale))
            hill.addLine(to: CGPoint(x: 83.335 * scale, y: 413.542 * scale))
            hill.closeSubpath()
            
            context.fill(hill, with: .color(.green))
            
            // Sun (Modern addition)
            var sun = Path()
            sun.addEllipse(in: CGRect(x: 350 * scale, y: 100 * scale, width: 60 * scale, height: 60 * scale))
            context.fill(sun, with: .color(.orange.opacity(0.8)))
        }
    }
}
