//
//  CalendarView.swift
//  NepaliPatro
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

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .center), count: 7)
    private let rowSpacing: CGFloat = 4
    private let cellCornerRadius: CGFloat = 6

    var body: some View {
        HStack {
            Text("\(NepaliCalendar.shared.months[displayMonth - 1]) \(NepaliCalendar.shared.toNepaliDigits(displayYear))")
                .font(.system(size: 18, weight: .bold))
            Spacer()
            Button("आज") {
                if let today = today {
                    displayYear = today.year
                    displayMonth = today.month
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
        
        LazyVGrid(columns: columns, alignment: .center, spacing: rowSpacing) {
            ForEach(NepaliCalendar.shared.weekDays, id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.black))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 18, alignment: .center)
                    .padding(.vertical, 2)
            }
        }
        
        let firstWeekday = NepaliCalendar.shared.firstWeekday(year: displayYear, month: displayMonth)
        let daysInMonth = NepaliCalendar.shared.daysInMonth(year: displayYear, month: displayMonth)
        
        let cells = buildCells(displayYear: displayYear,
                               displayMonth: displayMonth,
                               firstWeekday: firstWeekday,
                               daysInMonth: daysInMonth,
                               today: today)
        
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let cellSize = floor(totalWidth / 7.0)
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0, alignment: .center), count: 7),
                      alignment: .center,
                      spacing: rowSpacing) {
                ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                    let isSelected: Bool = {
                        guard cell.isCurrent, let sel = selectedDate else { return false }
                        return sel.year == cell.bsYear && sel.month == cell.bsMonth && sel.day == cell.bsDay
                    }()
                    
                    let selectionColor = Color(.red)
                    let todayColor = Color.red.opacity(0.12)
                    
                    let nepaliLabel = NepaliCalendar.shared.toNepaliDigits(cell.bsDay)
                    let englishDay: String = {
                        if let ad = NepaliCalendar.shared.convertToADDate(from: BSDate(year: cell.bsYear, month: cell.bsMonth, day: cell.bsDay)) {
                            let day = Calendar(identifier: .gregorian).component(.day, from: ad)
                            return String(day)
                        } else {
                            return ""
                        }
                    }()
                    
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: cellCornerRadius)
                                .fill(selectionColor)
                        } else if cell.isToday {
                            RoundedRectangle(cornerRadius: cellCornerRadius)
                                .fill(todayColor)
                        } else {
                            Color.clear
                        }
                        
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            
                            Text(nepaliLabel)
                                .font(cell.isCurrent ? .system(size: 14, weight: .medium, design: .rounded) : .caption2)
                                .foregroundColor(
                                    isSelected ? .white :
                                    (index % 7 == 6 || cell.isHoliday) ? .red :
                                    (cell.isCurrent ? .primary : .secondary.opacity(0.6))
                                )
                            
                            Spacer(minLength: 0)
                            
                            HStack {
                                Spacer(minLength: 0)
                                Text(englishDay)
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundColor(isSelected ? .white.opacity(0.9) :
                                                     cell.isCurrent ? .secondary : .secondary.opacity(0.5))
                            }
                            .padding(.trailing, 3)
                            .padding(.bottom, 3)
                        }
                        .padding(4)
                    }
                    .frame(width: cellSize, height: cellSize, alignment: .center)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard cell.isCurrent else { return }
                        selectedDate = BSDate(year: cell.bsYear, month: cell.bsMonth, day: cell.bsDay)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }
            }
        }
        .frame(height: gridHeight(displayYear: displayYear, displayMonth: displayMonth, firstWeekday: firstWeekday, daysInMonth: daysInMonth))
        
        if let sel = selectedDate {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(NepaliCalendar.shared.months[sel.month - 1]) \(NepaliCalendar.shared.toNepaliDigits(sel.day)), \(NepaliCalendar.shared.toNepaliDigits(sel.year))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let hText = NepaliCalendar.shared.holidayText(year: sel.year, month: sel.month, day: sel.day) {
                        Text(hText)
                            .font(.system(size: 14))
                            .foregroundColor(Color.primary)
                    }
                    
                    if let tithi = NepaliCalendar.shared.tithiText(year: sel.year, month: sel.month, day: sel.day) {
                        Text(tithi)
                            .foregroundColor(.purple)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
    }
    
    private func gridHeight(displayYear: Int, displayMonth: Int, firstWeekday: Int, daysInMonth: Int) -> CGFloat {
        let totalNeeded = firstWeekday + daysInMonth
        let rows = totalNeeded > 35 ? 6 : 5
        let approxCell: CGFloat = 52
        let rowSpacing: CGFloat = self.rowSpacing
        return CGFloat(rows) * approxCell + CGFloat(rows - 1) * rowSpacing
    }
    
    private func navigate(_ delta: Int) {
        var m = displayMonth + delta
        var y = displayYear
        if m < 1 { m = 12; y -= 1 }
        else if m > 12 { m = 1; y += 1 }
        if NepaliCalendar.shared.daysInMonth(year: y, month: m) > 0 {
            displayMonth = m; displayYear = y
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

private struct CellModel {
    let bsYear: Int
    let bsMonth: Int
    let bsDay: Int
    let isCurrent: Bool
    let isToday: Bool
    let isHoliday: Bool
}

private extension CalendarView {
    func buildCells(displayYear: Int,
                    displayMonth: Int,
                    firstWeekday: Int,
                    daysInMonth: Int,
                    today: BSDate?) -> [CellModel] {
        let prevMonth = displayMonth == 1 ? 12 : displayMonth - 1
        let prevYear  = displayMonth == 1 ? displayYear - 1 : displayYear
        let daysInPrevMonth = NepaliCalendar.shared.daysInMonth(year: prevYear, month: prevMonth)
        
        let totalNeeded    = firstWeekday + daysInMonth
        let totalGridCells = totalNeeded > 35 ? 42 : 35
        let trailingCount  = totalGridCells - totalNeeded
        
        var result: [CellModel] = []
        
        for i in 0..<firstWeekday {
            let day = daysInPrevMonth - (firstWeekday - 1) + i
            result.append(CellModel(
                bsYear: prevYear, bsMonth: prevMonth, bsDay: day,
                isCurrent: false,
                isToday: false,
                isHoliday: false
            ))
        }
        
        for day in 1...daysInMonth {
            let isToday = today?.day == day &&
            today?.month == displayMonth &&
            today?.year == displayYear
            let isHoliday = NepaliCalendar.shared.holidayText(year: displayYear, month: displayMonth, day: day) != nil
            result.append(CellModel(
                bsYear: displayYear, bsMonth: displayMonth, bsDay: day,
                isCurrent: true,
                isToday: isToday,
                isHoliday: isHoliday
            ))
        }
        
        let nextMonth = displayMonth == 12 ? 1 : displayMonth + 1
        let nextYear = displayMonth == 12 ? displayYear + 1 : displayYear
        if trailingCount > 0 {
            for day in 1...trailingCount {
                result.append(CellModel(
                    bsYear: nextYear, bsMonth: nextMonth, bsDay: day,
                    isCurrent: false,
                    isToday: false,
                    isHoliday: false
                ))
            }
        }
        
        return result
    }
}
