//
//  SettingsView.swift
//  BhittePatroApp
//
//  Created by Gemini on 20/03/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("DefaultCalendarViewMode") private var defaultMode: String = "calendar"
    @State private var launchManager = LaunchAtLoginManager.shared

    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .frame(height: 48)

            // Divider
            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Launch at Login section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Launch at Login")
                            .font(.system(size: 12, weight: .semibold))

                        Toggle("Open app when you log in to your Mac", isOn: Bindable(launchManager).isEnabled)
                            .toggleStyle(.switch)
                            .font(.system(size: 11))
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))

                    // Default view section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Default View")
                            .font(.system(size: 12, weight: .semibold))

                        Picker("Default View", selection: $defaultMode) {
                            Text("Today").tag("today")
                            Text("Calendar").tag("calendar")
                        }
                        .pickerStyle(.segmented)
                        .font(.system(size: 11))
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))

                    // App info section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Version")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("1.0.0")
                                .font(.system(size: 11, weight: .medium))
                        }

                        HStack {
                            Text("Last updated")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Today")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))

                    // Help section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Help & Support")
                            .font(.system(size: 12, weight: .semibold))

                        Text("No link for now")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))

                    // Quit button
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit Bhitte Patro")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
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
