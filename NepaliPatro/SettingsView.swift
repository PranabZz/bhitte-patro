//
//  SettingsView.swift
//  NepaliPatro
//
//  Created by Gemini on 20/03/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("DefaultCalendarViewMode") private var defaultMode: String = "calendar"
    @State private var launchManager = LaunchAtLoginManager.shared
    
    var onBack: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                    .font(.headline)
                
                Spacer()
                
                // Invisible placeholder to keep title centered
                Color.clear.frame(width: 32, height: 1)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Launch at Login")
                                .font(.headline)
                            Toggle("Open app when you log in to your Mac", isOn: Bindable(launchManager).isEnabled)
                                .toggleStyle(.switch)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Make default view")
                                .font(.headline)
                            
                            Picker("Default View", selection: $defaultMode) {
                                Text("Today").tag("today")
                                Text("Calendar").tag("calendar")
                            }
                            .pickerStyle(.segmented)
                            .help("Choose which view to show when the app starts")
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Last updated")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Help Support")
                            .font(.headline)
                        Text("No link for now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Power button moved here
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit Nepali Patro")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Quit App")
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
