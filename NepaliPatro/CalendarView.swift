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

    var body: some View {
        HStack {
            Text("\(NepaliCalendar.shared.months[displayMonth - 1]) \(NepaliCalendar.shared.toNepaliDigits(displayYear))")
                .font(.system(size: 18, weight: .bold))
            Spacer()
            // show button take user to current month
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
