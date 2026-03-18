//  DateConversionView.swift
//  NepaliPatro
//
//  Created by Pranab Kc on 16/03/2026.
//

import SwiftUI

struct DateConversionView: View {
    @Binding var adDate: Date
    @Binding var bsDate: BSDate  // your NepaliCalendar BS date struct

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // AD Date — custom stepper
            VStack(alignment: .center, spacing: 10) {
                Label("AD Date", systemImage: "calendar")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                // Month
                DateStepperRow(
                    label: adDate.formatted(.dateTime.month(.wide)),
                    font: .subheadline,
                    onDecrement: { adDate = Calendar.current.date(byAdding: .month, value: -1, to: adDate) ?? adDate },
                    onIncrement: { adDate = Calendar.current.date(byAdding: .month, value:  1, to: adDate) ?? adDate }
                )

                // Year
                DateStepperRow(
                    label: adDate.formatted(.dateTime.year()),
                    font: .title3.weight(.medium),
                    onDecrement: { adDate = Calendar.current.date(byAdding: .year, value: -1, to: adDate) ?? adDate },
                    onIncrement: { adDate = Calendar.current.date(byAdding: .year, value:  1, to: adDate) ?? adDate }
                )

                // Day
                DateStepperRow(
                    label: adDate.formatted(.dateTime.day()),
                    font: .subheadline,
                    onDecrement: { adDate = Calendar.current.date(byAdding: .day, value: -1, to: adDate) ?? adDate },
                    onIncrement: { adDate = Calendar.current.date(byAdding: .day, value:  1, to: adDate) ?? adDate }
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.leading, 16)
            .onChange(of: adDate) { _, newValue in
                if let converted = NepaliCalendar.shared.convertToBSDate(from: newValue) {
                    bsDate = converted
                }
            }

            // BS Date — mirror layout, display only
            VStack(alignment: .center, spacing: 10) {
                Label("BS Date", systemImage: "sun.max.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(NepaliCalendar.shared.months[bsDate.month - 1])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 26)

                Text(NepaliCalendar.shared.toNepaliDigits(bsDate.year))
                    .font(.title2.weight(.medium))
                    .frame(height: 26)

                Text(NepaliCalendar.shared.toNepaliDigits(bsDate.day))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }
}
