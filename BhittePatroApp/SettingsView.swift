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
    static let didSelectCalendarDate = Notification.Name("didSelectCalendarDate")
}

struct SettingsView: View {
    @AppStorage("DefaultCalendarViewMode") private var defaultMode: String = "calendar"
    @AppStorage("CalendarDesign") private var calendarDesign: String = CalendarDesign.classic.rawValue
    @AppStorage("AppTheme") private var appTheme: String = AppTheme.standard.rawValue
    @State private var launchManager = LaunchAtLoginManager.shared
    @ObservedObject var calendarManager = CalendarManager.shared

    var onBack: () -> Void
    
    private var currentTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .standard
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Appearance Section
                    sectionGroup(title: "APPEARANCE", icon: "paintbrush.fill") {
                        settingsRow(title: "Design Style", subtitle: "Calendar grid layout") {
                            Picker("", selection: $calendarDesign) {
                                ForEach(CalendarDesign.allCases) { design in
                                    Text(design.title).tag(design.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }

                        Divider().padding(.horizontal, 12)

                        settingsRow(title: "Color Theme", subtitle: "App-wide color palette") {
                            Picker("", selection: $appTheme) {
                                ForEach(AppTheme.allCases) { theme in
                                    Text(theme.title).tag(theme.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 140)
                        }
                    }

                    // 2. Behavior Section
                    sectionGroup(title: "SYSTEM", icon: "cpu") {
                        settingsRow(title: "Launch at Login", subtitle: "Start with your Mac") {
                            Toggle("", isOn: Bindable(launchManager).isEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .controlSize(.small)
                        }
                    }

                    // 3. Calendar Sync Section
                    sectionGroup(title: "CALENDAR SYNC", icon: "arrow.triangle.2.circlepath") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Last synchronized")
                                        .font(.system(size: 12, weight: .medium))
                                    
                                    if let last = calendarManager.lastUpdated {
                                        Text("\(last, style: .date) at \(last, style: .time)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Never updated")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    Task { await calendarManager.fetchLatestCalendar() }
                                } label: {
                                    if calendarManager.isUpdating {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Label("Sync Now", systemImage: "arrow.clockwise")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(calendarManager.isUpdating)
                            }

                            if let error = calendarManager.updateError {
                                Text(error)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.red)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                }
                .padding(16)
            }

            Divider()

            // Footer
            footerSection
        }
        .background {
            if currentTheme == .himalaya {
                Color.blue.opacity(0.01).ignoresSafeArea()
            } else if currentTheme == .terai {
                Color.green.opacity(0.01).ignoresSafeArea()
            } else {
                Color.clear.ignoresSafeArea()
            }
        }
    }

    private var footerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bhitte Patro")
                    .font(.system(size: 11, weight: .bold))
                Text("Version 1.2.1")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .black))
                    Text("Quit App")
                        .font(.system(size: 11, weight: .black))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red, in: Capsule())
                .shadow(color: Color.red.opacity(0.3), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.secondary.opacity(0.04))
    }

    private func sectionGroup<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.secondary)
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func settingsRow<Content: View>(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color.secondary.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            Text("Settings")
                .font(.system(size: 15, weight: .semibold))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
