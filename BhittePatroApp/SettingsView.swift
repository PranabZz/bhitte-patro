//
//  SettingsView.swift
//  BhittePatroApp
//
//  Created by Gemini on 20/03/2026.
//

import SwiftUI
import Foundation

extension Notification.Name {
    static let didChangeDefaultViewMode = Notification.Name("didChangeDefaultViewMode")
}

struct SettingsView: View {
    @AppStorage("DefaultCalendarViewMode") private var defaultMode: String = "calendar"
    @State private var launchManager = LaunchAtLoginManager.shared
    @ObservedObject var calendarManager = CalendarManager.shared

    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {


            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Launch at Login section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Launch at Login")
                            .font(.system(size: 13, weight: .semibold))

                        Toggle("Open app when you log in to your Mac", isOn: Bindable(launchManager).isEnabled)
                            .toggleStyle(.switch)
                            .font(.system(size: 12))
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

                    // Default view section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default View")
                            .font(.system(size: 13, weight: .semibold))

                        Picker("Default View", selection: $defaultMode) {
                            Text("Today").tag("today")
                            Text("Calendar").tag("calendar")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: defaultMode) { _, new in
                            // Notify the app to switch immediately
                            NotificationCenter.default.post(
                                name: .didChangeDefaultViewMode,
                                object: nil,
                                userInfo: ["mode": new]
                            )
                        }
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

                    // Calendar Update section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Calendar Data")
                            .font(.system(size: 13, weight: .semibold))

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last updated")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                
                                if let last = calendarManager.lastUpdated {
                                    Text(last, style: .date)
                                        .font(.system(size: 11, weight: .medium))
                                    Text(last, style: .time)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Never")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await calendarManager.fetchLatestCalendar()
                                }
                            } label: {
                                if calendarManager.isUpdating {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("Update Now")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(calendarManager.isUpdating)
                        }

                        if let error = calendarManager.updateError {
                            Text(error)
                                .font(.system(size: 10))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

                    Spacer(minLength: 20)

                    // Quit button
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit Bhitte Patro")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
        .padding(12)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Invisible placeholder to keep title centered
            Color.clear.frame(width: 32, height: 1)
        }
    }
}
