//
//  SubscriberDetailView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData
import Combine
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

 struct SubscriberDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    let subscriber: SubscriberFS
    @StateObject private var viewModel = SubscriberDetailViewModel()
    @State private var selectedTab = 0
    @State private var showingEditView = false
    @State private var showingInfoView = false
    
    // Email Composer (Update to not rely on SwiftData specific logic if any)
    @State private var showingMailComposer = false
    @StateObject private var emailComposer = EmailComposerViewModel()
    @State private var showingDeleteAlert = false
    @State private var cancellables = Set<AnyCancellable>() // Add cancellables for Combine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        #if os(macOS)
        // Mac: Use sidebar navigation for better UX
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: 0) {
                    Label("Overview", systemImage: "person.circle")
                }
                NavigationLink(value: 1) {
                    Label("Physical", systemImage: "figure.arms.open")
                }
                NavigationLink(value: 2) {
                    Label("Courses", systemImage: "dumbbell")
                }
                NavigationLink(value: 3) {
                    Label("Goals", systemImage: "target")
                }
                NavigationLink(value: 4) {
                    Label("Attendance", systemImage: "calendar")
                }
                NavigationLink(value: 5) {
                    Label("Notes", systemImage: "note.text")
                }
                NavigationLink(value: 6) {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                NavigationLink(value: 7) {
                    Label("Sessions", systemImage: "list.clipboard")
                }
            }
            .navigationTitle(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            if viewModel.isLoading {
                ProgressView("Loading details...")
            } else {
                Group {
                    switch selectedTab {
                    case 0: OverviewTab(subscriber: subscriber, viewModel: viewModel)
                    case 1: PhysicalDetailsView(subscriber: subscriber, physicalDetails: viewModel.physicalDetails)
                    case 2: AssignedCoursesView(subscriber: subscriber, allCourses: viewModel.courses)
                    case 3: GoalsView(subscriber: subscriber, goals: viewModel.goals)
                    case 4: AttendanceView(subscriber: subscriber, attendanceRecords: viewModel.attendanceRecords)
                    case 5: NotesView(subscriber: subscriber, notes: viewModel.coachNotes)
                    case 6: ProgressComparisonView(subscriber: subscriber, physicalDetails: viewModel.physicalDetails, workoutLogs: viewModel.workoutLogs, goals: viewModel.goals)
                    case 7: SubscriberSessionsView(subscriber: subscriber, sessions: viewModel.sessions)
                    default: OverviewTab(subscriber: subscriber, viewModel: viewModel)
                    }
                }
            }
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 16) {
                    // Show email button only when Sessions tab is selected
                    if selectedTab == 7 {
                        Button(action: {
                            sendAllSessionsByEmail()
                        }) {
                            Label("Send Sessions", systemImage: "envelope.fill")
                        }
                    }
                    
                    Button {
                        showingInfoView = true
                    } label: {
                        Label("Info", systemImage: "info.circle")
                    }
                    
                    Button {
                        showingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .platformSheet(isPresented: $showingEditView) {
            AddEditSubscriberView(subscriber: subscriber)
        }
        .fullScreenCover(isPresented: $showingInfoView) {
            SubscriberInfoView(subscriber: subscriber)
        }
        .onAppear {
            if let id = subscriber.id {
                viewModel.loadData(for: id)
            }
        }
        #else
        // iOS/iPad: Use TabView
        TabView(selection: $selectedTab) {
            overviewTab
            physicalTab
            sessionsTab
            coursesTab
            goalsTab
            attendanceTab
            notesTab
            progressTab
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .edgesIgnoringSafeArea(.all)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if selectedTab == 7 {
                        Button(action: {
                            sendAllSessionsByEmail()
                        }) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.orange)
                        }
                    }
                    
                    Button {
                        showingInfoView = true
                    } label: {
                        Label("Info", systemImage: "info.circle")
                    }
                    
                    Button {
                        showingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .platformSheet(isPresented: $showingEditView) {
            AddEditSubscriberView(subscriber: subscriber)
        }
        .fullScreenCover(isPresented: $showingInfoView) {
            SubscriberInfoView(subscriber: subscriber)
        }
        .alert("Delete Subscriber", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSubscriber()
            }
        } message: {
            Text("Are you sure you want to delete this subscriber? This action cannot be undone.")
        }
        .onAppear {
            if let id = subscriber.id {
                viewModel.loadData(for: id)
            }
            // Store subscriber ID for SessionsView navigation
            if let id = subscriber.id {
                UserDefaults.standard.set(id, forKey: "pendingSubscriberSelection")
            }
        }
        #endif
    }
    
    @ViewBuilder
    private var overviewTab: some View {
        OverviewTab(subscriber: subscriber, viewModel: viewModel)
            .tabItem {
                Label("Overview", systemImage: "person.circle")
            }
            .tag(0)
    }
    
    @ViewBuilder
    private var physicalTab: some View {
        PhysicalDetailsView(subscriber: subscriber, physicalDetails: viewModel.physicalDetails)
            .tabItem {
                Label("Physical", systemImage: "figure.arms.open")
            }
            .tag(1)
    }
    
    @ViewBuilder
    private var coursesTab: some View {
        AssignedCoursesView(subscriber: subscriber, allCourses: viewModel.courses)
            .tabItem {
                Label(LocalizedString.string(for: .courses, key: "Courses"), systemImage: "book")
            }
            .tag(2)
    }
    
    @ViewBuilder
    private var goalsTab: some View {
        GoalsView(subscriber: subscriber, goals: viewModel.goals)
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(3)
    }
    
    @ViewBuilder
    private var attendanceTab: some View {
        AttendanceView(subscriber: subscriber, attendanceRecords: viewModel.attendanceRecords)
            .tabItem {
                Label("Attendance", systemImage: "calendar")
            }
            .tag(4)
    }
    
    @ViewBuilder
    private var notesTab: some View {
        NotesView(subscriber: subscriber, notes: viewModel.coachNotes)
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(5)
    }
    
    @ViewBuilder
    private var progressTab: some View {
        ProgressComparisonView(subscriber: subscriber, physicalDetails: viewModel.physicalDetails, workoutLogs: viewModel.workoutLogs, goals: viewModel.goals)
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(6)
    }
    
    @State private var machines: [String] = [] // Add state for machines

    @ViewBuilder
    private var sessionsTab: some View {
        SubscriberSessionsView(subscriber: subscriber, sessions: viewModel.sessions, availableExercises: machines)
            .tabItem {
                Label("Sessions", systemImage: "list.clipboard")
            }
            .tag(7)
            .onAppear {
                // Fetch machines if empty
                if machines.isEmpty {
                     loadMachines()
                }
            }
    }
    
    // Add loadMachines function
    private func loadMachines() {
        FirestoreService.shared.fetchMachines()
            .sink { _ in } receiveValue: { machines in
                let fetchedNames = machines.map { $0.name }
                let defaults = ExerciseHelper.defaultExercises
                let all = Set(defaults).union(fetchedNames)
                self.machines = Array(all).sorted()
            }
            .store(in: &cancellables) // Need cancellables storage
    }
    
    private func sendAllSessionsByEmail() {
        // ... (Update this later to use viewModel.sessions)
    }
    
    private func deleteSubscriber() {
        guard let id = subscriber.id else { return }
        Task {
            try? await FirestoreService.shared.deleteSubscriberAndData(subscriberId: id)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct OverviewTab: View {
    let subscriber: SubscriberFS
    @ObservedObject var viewModel: SubscriberDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var latestPhysicalDetail: PhysicalDetailFS? {
        viewModel.physicalDetails.first
    }
    
    var activeGoals: [GoalFS] {
         viewModel.goals.filter { !$0.isCompleted }
    }
    
    // Assigned courses for this subscriber
    var assignedCourses: [TrainingCourseFS] {
        return viewModel.courses 
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Header
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(AppTheme.laurelLeaf)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        Text(subscriber.email)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        Text(subscriber.phone)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Subscription Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Subscription")
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                    
                    InfoRow(label: "Plan", value: subscriber.planType ?? "Unknown")
                    InfoRow(label: "Start Date", value: subscriber.subscriptionStartDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                    InfoRow(label: "Status", value: subscriber.paymentStatus ?? "Unknown")
                }
                .padding()
                
                Divider()
                
                // Latest Physical Details
                if let latest = latestPhysicalDetail {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Latest Physical Details")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                            Spacer()
                            Text(latest.dateRecorded.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            if let weight = latest.weight {
                                MeasurementCard(icon: "scalemass", label: "Weight", value: "\(String(format: "%.1f", weight)) kg", colorScheme: colorScheme)
                            }
                            if let height = latest.height {
                                MeasurementCard(icon: "ruler", label: "Height", value: "\(String(format: "%.1f", height)) cm", colorScheme: colorScheme)
                            }
                            if let bodyFat = latest.bodyFatPercentage {
                                MeasurementCard(icon: "percent", label: "Body Fat", value: "\(String(format: "%.1f", bodyFat))%", colorScheme: colorScheme)
                            }
                        }
                    }
                    .padding()
                    Divider()
                }
                
                // Active Goals
                if !activeGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Goals (\(activeGoals.count))")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        
                        ForEach(activeGoals.prefix(3)) { goal in
                            GoalSummaryCard(goal: goal, colorScheme: colorScheme)
                        }
                    }
                    .padding()
                    Divider()
                }

                // Medical Info
                if let injuries = subscriber.injuries, !injuries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medical Information")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        
                        InfoRow(label: "Injuries", value: injuries)
                        
                        if let restrictions = subscriber.restrictions, !restrictions.isEmpty {
                            InfoRow(label: "Restrictions", value: restrictions)
                        }
                        if let conditions = subscriber.healthConditions, !conditions.isEmpty {
                            InfoRow(label: "Health Conditions", value: conditions)
                        }
                    }
                    .padding()
                } else if (subscriber.restrictions?.isEmpty == false) || (subscriber.healthConditions?.isEmpty == false) {
                     // Fallback if injuries is empty but others are not
                     VStack(alignment: .leading, spacing: 12) {
                        Text("Medical Information")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        
                        if let restrictions = subscriber.restrictions, !restrictions.isEmpty {
                            InfoRow(label: "Restrictions", value: restrictions)
                        }
                        if let conditions = subscriber.healthConditions, !conditions.isEmpty {
                            InfoRow(label: "Health Conditions", value: conditions)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
    }
}

// Measurement Card for Physical Details
struct MeasurementCard: View {
    let icon: String
    let label: String
    let value: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .gradientCard()
    }
}

// Goal Summary Card
struct GoalSummaryCard: View {
    let goal: GoalFS
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .font(.title2)
                .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                
                HStack(spacing: 4) {
                    Text("\(String(format: "%.1f", goal.currentValue))")
                        .fontWeight(.bold)
                    Text("→")
                        .foregroundColor(AppTheme.orange)
                    Text("\(String(format: "%.1f", goal.targetValue)) \(goal.unit)")
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.orange)
                }
                .font(.caption)
                .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(Int(calculateProgress(goal) * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(calculateProgress(goal) >= 1.0 ? .green : AppTheme.orange)
            }
        }
        .padding()
        .gradientCard()
    }
    
    func calculateProgress(_ goal: GoalFS) -> Double {
        let start = goal.startingValue ?? 0
        guard (goal.targetValue - start) != 0 else { return 0.0 }
        return (goal.currentValue - start) / (goal.targetValue - start)
    }
}

// Course Summary Card (Placeholder)
struct CourseSummaryCard: View {
    let courseName: String
    let colorScheme: ColorScheme
    
    var body: some View {
        Text(courseName)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var isOnGradient: Bool = false
    var colorScheme: ColorScheme = .light
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(isOnGradient ? AppTheme.gradientCardSecondaryTextColor(for: colorScheme) : AppTheme.secondaryTextColor(for: colorScheme))
            Spacer()
            Text(value)
                .foregroundColor(isOnGradient ? AppTheme.gradientCardTextColor(for: colorScheme) : .primary)
        }
    }
}

#Preview {
    // SubscriberDetailView(subscriber: SubscriberFS(...))
    Text("Preview")
}

