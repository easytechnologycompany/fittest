//
//  ContentView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @State private var selectedTab = 0
    @AppStorage("requestedRootTab") private var requestedRootTab: Int = -1
    @StateObject private var migrationService = MigrationService.shared
    @State private var showMigrationView = false
    
    var selectedColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some View {
        ZStack {
            // Main Content
            mainContent
            
            // Migration Overlay
            if showMigrationView {
                MigrationView(migrationService: migrationService)
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .onAppear {
            checkMigrationStatus()
            handleRequestedRootTab()
        }
        .onChange(of: migrationService.migrationComplete) { oldValue, newValue in
            if newValue {
                // Dismiss migration view after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        showMigrationView = false
                    }
                }
            }
        }
        .onChange(of: requestedRootTab) { oldValue, newValue in
            handleRequestedRootTab()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        // Mac uses NavigationSplitView for better UX
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: 0) {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                NavigationLink(value: 1) {
                    Label("Subscribers", systemImage: "person.2.fill")
                }
                NavigationLink(value: 2) {
                    Label("Courses", systemImage: "book.fill")
                }
                NavigationLink(value: 3) {
                    Label("Sessions", systemImage: "dumbbell.fill")
                }
                NavigationLink(value: 4) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("Fit Fast")
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    DashboardView(selectedTab: $selectedTab)
                case 1:
                    SubscriberListView()
                case 2:
                    TrainingCoursesView()
                case 3:
                    SessionsView()
                case 4:
                    SettingsView()
                default:
                    DashboardView(selectedTab: $selectedTab)
                }
            }
        }
        .preferredColorScheme(selectedColorScheme)
        #else
        // iOS uses TabView
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            SubscriberListView()
                .tabItem {
                    Label("Subscribers", systemImage: "person.2.fill")
                }
                .tag(1)
            
            TrainingCoursesView()
                .tabItem {
                    Label("Courses", systemImage: "book.fill")
                }
                .tag(2)
            
            SessionsView()
                .tabItem {
                    Label("Sessions", systemImage: "dumbbell.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(AppTheme.orange)
        .preferredColorScheme(selectedColorScheme)
        .background(AppTheme.backgroundColor(for: selectedColorScheme ?? colorScheme))
        .onAppear {
            updateTabBarAppearance()
        }
        .onChange(of: colorScheme) { oldValue, newValue in
            updateTabBarAppearance()
        }
        .onChange(of: appearanceMode) { oldValue, newValue in
            updateTabBarAppearance()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // When Sessions tab (3) is selected, check for pending subscriber selection
            if newValue == 3 {
                // Post notification to trigger SessionsView to check for pending subscriber
                NotificationCenter.default.post(name: NSNotification.Name("SessionsTabSelected"), object: nil)
            }
        }
        #endif
    }
    
    private func checkMigrationStatus() {
        if !migrationService.hasMigrationCompleted() {
            showMigrationView = true
            Task {
                await migrationService.checkAndMigrate(modelContext: modelContext)
            }
        }
    }
    
    private func handleRequestedRootTab() {
        guard requestedRootTab >= 0 else { return }
        selectedTab = requestedRootTab
        requestedRootTab = -1
    }
    
    #if os(iOS)
    private func updateTabBarAppearance() {
        let currentScheme: ColorScheme = selectedColorScheme ?? colorScheme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.backgroundColor(for: currentScheme))
        appearance.shadowColor = UIColor(AppTheme.orange.opacity(currentScheme == .dark ? 0.5 : 0.3))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    #endif
}

#Preview {
    ContentView()
        .modelContainer(for: [Subscriber.self, PhysicalDetail.self, WorkoutLog.self, Exercise.self, Goal.self, Attendance.self, CoachNote.self, TrainingCourse.self, CourseDay.self, CourseExercise.self], inMemory: true)
}
