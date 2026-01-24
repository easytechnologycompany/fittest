//
//  DashboardView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = DashboardViewModel()
    @Binding var selectedTab: Int
    @State private var scrollOffset: CGFloat = 0
    @State private var initialOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                         ProgressView("Loading stats...")
                             .padding()
                    }
                    
                    // Statistics Cards
                    LazyVGrid(columns: adaptiveGridColumns, spacing: PlatformAdaptations.defaultSpacing) {
                        StatCard(
                            title: "Total Subscribers",
                            value: "\(viewModel.subscribers.count)",
                            icon: "person.2.fill",
                            color: .blue,
                            action: {
                                #if !os(macOS)
                                selectedTab = 1
                                #endif
                            }
                        )
                        
                        StatCard(
                            title: "Training Courses",
                            value: "\(viewModel.courses.count)",
                            icon: "book.fill",
                            color: .green,
                            action: {
                                #if !os(macOS)
                                selectedTab = 2
                                #endif
                            }
                        )
                        
                        StatCard(
                            title: "Total Workouts",
                            // Using sessions count as workouts proxy for now, as originally it was WorkoutLog query
                            value: "\(viewModel.sessions.count)", 
                            icon: "dumbbell.fill",
                            color: .orange,
                            action: {
                                #if !os(macOS)
                                selectedTab = 1
                                #endif
                            }
                        )
                        
                        StatCard(
                            title: "Active Goals",
                            value: "\(activeGoalsCount)",
                            icon: "target",
                            color: .purple,
                            action: {
                                #if !os(macOS)
                                selectedTab = 1
                                #endif
                            }
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if recentSessions.isEmpty && recentAttendance.isEmpty { // Changed from recentWorkouts to recentSessions
                            ContentUnavailableView(
                                "No Recent Activity",
                                systemImage: "clock",
                                description: Text("Activity will appear here as you add workouts and attendance records.")
                            )
                            .frame(height: 200)
                        } else {
                            VStack(spacing: 12) {
                                if !recentSessions.isEmpty {
                                    Section {
                                        ForEach(recentSessions.prefix(3)) { session in
                                            // Assuming we can find subscriber name from session context or ID?
                                            // SessionFS doesn't store subscriber name directly usually, just link?
                                            // Wait, SessionFS is embedded or linked? 
                                            // The view might need to join data. 
                                            // For now, let's display "Workout" or look up from subscribers list if possible.
                                            // Or simplified: Just show date/machine
                                            ActivityRow(
                                                title: findSubscriberName(for: session),
                                                subtitle: "Session",
                                                date: session.date,
                                                icon: "dumbbell",
                                                color: .orange
                                            )
                                        }
                                    } header: {
                                        Text("Recent Sessions")
                                            .font(.headline)
                                            .padding(.horizontal)
                                    }
                                }
                                
                                if !recentAttendance.isEmpty {
                                    Section {
                                        ForEach(recentAttendance.prefix(3)) { attendance in
                                            ActivityRow(
                                                title: findSubscriberName(for: attendance),
                                                subtitle: "Gym Visit",
                                                date: attendance.date,
                                                icon: "calendar",
                                                color: .blue
                                            )
                                        }
                                    } header: {
                                        Text("Recent Attendance")
                                            .font(.headline)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Stats")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            StatRow(label: "Total Attendance Records", value: "\(viewModel.attendanceRecords.count)")
                            StatRow(label: "Completed Goals", value: "\(completedGoalsCount)")
                            StatRow(label: "Pending Goals", value: "\(pendingGoalsCount)")
                            StatRow(label: "Expired Subscriptions", value: "\(expiredSubscribersCount)")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .background(AppTheme.backgroundColor(for: colorScheme))
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                if initialOffset == 0 {
                    initialOffset = value
                }
                // As we scroll down, value decreases (becomes more negative)
                // Calculate how much we've scrolled from the initial position
                let scrolledAmount = max(0, initialOffset - value)
                withAnimation(.easeInOut(duration: 0.2)) {
                    scrollOffset = scrolledAmount
                }
            }
            .navigationTitle("Dashboard")
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
    }
    
    private var activeSubscribersCount: Int {
        viewModel.subscribers.filter { ($0.paymentStatus ?? "").lowercased() == "active" }.count
    }
    
    private var activeGoalsCount: Int {
        viewModel.goals.filter { !$0.isCompleted }.count
    }
    
    private var completedGoalsCount: Int {
        viewModel.goals.filter { $0.isCompleted }.count
    }
    
    private var pendingGoalsCount: Int {
        // GoalFS uses targetDate.
        viewModel.goals.filter { !$0.isCompleted && $0.targetDate >= Date() }.count
    }
    
    private var expiredSubscribersCount: Int {
        viewModel.subscribers.filter { ($0.paymentStatus ?? "").lowercased() == "expired" }.count
    }
    
    private var recentSessions: [SessionFS] {
        viewModel.sessions.sorted { $0.date > $1.date }
    }
    
    private var recentAttendance: [AttendanceFS] {
        viewModel.attendanceRecords.sorted { $0.date > $1.date }
    }
    
    // Helper to find name since SessionFS assumes localized or we need to join
    private func findSubscriberName(for session: SessionFS) -> String {
        if let subId = session.subscriberId {
             return viewModel.subscribers.first(where: { $0.id == subId })?.name ?? "Unknown"
        }
        return "Unknown"
    }
    
    private func findSubscriberName(for attendance: AttendanceFS) -> String {
        if let subId = attendance.subscriberId {
             return viewModel.subscribers.first(where: { $0.id == subId })?.name ?? "Unknown"
        }
        return "Unknown"
    }
    
    private var adaptiveGridColumns: [GridItem] {
        #if os(macOS)
        return [GridItem(.adaptive(minimum: 200), spacing: 20), GridItem(.adaptive(minimum: 200), spacing: 20)]
        #else
        // Default to iPad (2 columns for stats), fallback to iPhone
        if PlatformAdaptations.isIPhone {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else {
            // iPad default: 2 columns for stats cards
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        }
        #endif
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryGradient(for: colorScheme))
            .modernCard(isOrange: true)
        }
        .buttonStyle(.plain)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let date: Date
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                .frame(width: 30)
                .padding(8)
                .background(AppTheme.primaryGradient(for: colorScheme))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }
            Spacer()
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
        .padding()
        .modernCard(isOrange: true)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.orange)
        }
        .padding()
        .modernCard(isOrange: true)
    }
}

// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    DashboardView(selectedTab: .constant(0))
        .modelContainer(for: [Subscriber.self, WorkoutLog.self, Goal.self, Attendance.self, TrainingCourse.self], inMemory: true)
}

