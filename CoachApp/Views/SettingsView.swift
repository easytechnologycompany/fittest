//
//  SettingsView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData
import CloudKit
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var subscribers: [Subscriber]
    @State private var showingDeleteConfirmation = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @State private var cloudKitStatus: CKAccountStatus = .couldNotDetermine
    @State private var isCheckingCloudKit = false
    @State private var showingResetConfirmation = false
    @State private var migrationResetComplete = false
    
    enum AppearanceMode: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section {
                        HStack {
                            Spacer()
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: PlatformAdaptations.isIPhone ? 60 : 100)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    Section("Appearance") {
                        Picker("Appearance", selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                HStack {
                                    Image(systemName: iconName(for: mode))
                                    Text(mode.displayName)
                                }
                                .tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("App Information") {
                        HStack {
                            Text("Total Subscribers")
                            Spacer()
                            Text("\(subscribers.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        NavigationLink {
                            MachinesView()
                        } label: {
                            HStack {
                                Image(systemName: "dumbbell")
                                Text("Exercises")
                            }
                        }
                    }
                    
                    Section(LocalizedString.string(for: .settings, key: "iCloud Sync")) {
                        HStack {
                            Image(systemName: cloudKitStatusIcon)
                                .foregroundColor(cloudKitStatusColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cloudKitStatusText)
                                    .font(.body)
                                Text(LocalizedString.string(for: .settings, key: "Your data will automatically sync across all your devices when signed in to iCloud."))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isCheckingCloudKit {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                
                    Section("Data Management") {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete All Data")
                            }
                        }
                        
                        Button {
                            showingResetConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise.icloud")
                                Text("Reset Firestore Migration")
                            }
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Section("About") {
                        HStack {
                            Text("Coach Analytics")
                            Spacer()
                            Text("Gym Management")
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Track and manage your gym subscribers' progress, workouts, goals, and attendance all in one place.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.backgroundColor(for: colorScheme))
                
                Text("Developed By Easy Technology Company 2025. all rights reserved")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.backgroundColor(for: colorScheme))
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle("Settings")
        .preferredColorScheme(appearanceMode.colorScheme)
        .task {
            await checkCloudKitStatus()
        }
            .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all subscribers, workouts, goals, attendance records, and notes. This action cannot be undone.")
            }
            .alert("Migration Reset", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    MigrationService.shared.resetMigrationStatus()
                    migrationResetComplete = true
                }
            } message: {
                Text("This will mark the Firestore migration as incomplete. The app will attempt to migrate all data (including machines and subscribers) again upon the next restart. Use this if your data didn't sync correctly to the cloud.")
            }
            .alert("Success", isPresented: $migrationResetComplete) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Firestore migration status has been reset. Please restart the app to begin the migration again.")
            }
        }
    }
    
    private func iconName(for mode: AppearanceMode) -> String {
        switch mode {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    private func deleteAllData() {
        withAnimation {
            for subscriber in subscribers {
                modelContext.delete(subscriber)
            }
        }
    }
    
    // MARK: - CloudKit Status
    
    private var cloudKitStatusIcon: String {
        switch cloudKitStatus {
        case .available:
            return "icloud.fill"
        case .noAccount:
            return "icloud.slash"
        case .restricted:
            return "exclamationmark.triangle.fill"
        case .couldNotDetermine:
            return "questionmark.circle"
        case .temporarilyUnavailable:
            return "icloud.slash"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    private var cloudKitStatusColor: Color {
        switch cloudKitStatus {
        case .available:
            return .green
        case .noAccount:
            return .orange
        case .restricted:
            return .orange
        case .couldNotDetermine:
            return .gray
        case .temporarilyUnavailable:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var cloudKitStatusText: String {
        switch cloudKitStatus {
        case .available:
            return LocalizedString.string(for: .settings, key: "Syncing")
        case .noAccount:
            return LocalizedString.string(for: .settings, key: "Not Signed In")
        case .restricted:
            return LocalizedString.string(for: .settings, key: "Restricted")
        case .couldNotDetermine:
            return LocalizedString.string(for: .settings, key: "Could Not Determine")
        case .temporarilyUnavailable:
            return LocalizedString.string(for: .settings, key: "Not Signed In")
        @unknown default:
            return LocalizedString.string(for: .settings, key: "Could Not Determine")
        }
    }
    
    private func checkCloudKitStatus() async {
        isCheckingCloudKit = true
        defer { isCheckingCloudKit = false }
        
        do {
            cloudKitStatus = try await CloudKitService.shared.getAccountStatus()
        } catch {
            cloudKitStatus = .couldNotDetermine
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Subscriber.self, inMemory: true)
}
