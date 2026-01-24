//
//  SubscriberSessionsView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 17/12/2025.
//

import SwiftUI

struct SubscriberSessionsView: View {
    let subscriber: SubscriberFS
    let sessions: [SessionFS]
    @Environment(\.colorScheme) var colorScheme
    
    let availableExercises: [String]
    
    // Config
    var showAddButton: Bool = true // Default to true
    
    @State private var editorConfig: SessionEditorConfig?
    @State private var showingMailComposer = false
    @StateObject private var emailComposer = EmailComposerViewModel()
    @State private var refreshTrigger = UUID()
    
    // Config for Editor Presentation moved to SessionEditorConfig in FirestoreModels.swift
    
    // Computed Properties
    private var exercises: [String] {
        // Get unique machine names from sessions
        let sessionExercises = Set(sessions.flatMap { $0.exercises ?? [] }.map { $0.name })
        
        // Combine with availableExercises (from Firestore / Settings)
        let all = Set(availableExercises).union(sessionExercises)
        
        // Sort: Defined machines first (preserve original order if possible?), then others alphabetically.
        // Since Set kills order, we rely on availableExercises being ordered.
        
        // Filter those in availableExercises to keep their order
        let known = availableExercises.filter { all.contains($0) }
        
        // Find any that are in sessions but NOT in availableExercises (e.g. deleted ones)
        let unknown = all.subtracting(Set(known)).sorted()
        
        return known + unknown
    }
    
    private var sortedSessions: [SessionFS] {
        sessions.sorted(by: { $0.date > $1.date })
    }
    
    private var displayDates: [Date] {
        let dates = Set(sortedSessions.map { normalizeDate($0.date) })
        var result = Array(dates).sorted(by: { $0 < $1 })
        if result.isEmpty {
            result = [normalizeDate(Date())]
        }
        return result
    }
    
    // MARK: - View Components
    
    private var borderColor: Color { .white.opacity(0.2) }
    
    private var machineNamesColumn: some View {
        VStack(spacing: 0) {
            // Corner Header
            Text("Machine")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 150, height: 45, alignment: .leading)
                .padding(.leading, 12)
                .background(AppTheme.backgroundColor(for: colorScheme))
            
            Rectangle().fill(borderColor).frame(height: 1)
            
            // Machine Rows
            VStack(spacing: 0) {
                ForEach(exercises, id: \.self) { machine in
                    VStack(spacing: 0) {
                        Button {
                            editorConfig = SessionEditorConfig(machine: machine, date: Date())
                        } label: {
                            Text(machine)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .frame(width: 150, height: 60, alignment: .leading)
                                .padding(.leading, 12)
                        }
                        .buttonStyle(.plain)
                        
                        Rectangle().fill(borderColor).frame(height: 1)
                    }
                }
            }
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
        .zIndex(2)
    }
    
    private var dataGrid: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // Header Row (Dates)
                HStack(spacing: 0) {
                    ForEach(Array(displayDates.enumerated()), id: \.element) { index, date in
                        dateHeaderCell(date: date, isLast: index == displayDates.count - 1)
                    }
                }
                Rectangle().fill(borderColor).frame(height: 1)
                
                // Data Rows
                VStack(spacing: 0) {
                    ForEach(exercises, id: \.self) { machine in
                        dataRow(for: machine)
                    }
                }
            }
        }
    }
    
    private func dateHeaderCell(date: Date, isLast: Bool) -> some View {
        Group {
            Text(dateFormatter.string(from: date))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 100, height: 45)
                .background(AppTheme.backgroundColor(for: colorScheme))
        }
        .overlay(
            Group {
                if !isLast {
                    Rectangle().fill(borderColor).frame(width: 1)
                }
            },
            alignment: .trailing
        )
    }
    
    private func dataRow(for machine: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(displayDates.enumerated()), id: \.element) { index, date in
                    dataCell(machine: machine, date: date, isLast: index == displayDates.count - 1)
                }
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            Rectangle().fill(borderColor).frame(height: 1)
        }
    }
    
    private func dataCell(machine: String, date: Date, isLast: Bool) -> some View {
        let (session, exercise) = getSessionAndExercise(machine: machine, date: date)
        
        return Button {
            if let existingSession = session, let existingExercise = exercise {
                editorConfig = SessionEditorConfig(session: existingSession, exercise: existingExercise)
            } else {
                editorConfig = SessionEditorConfig(machine: machine, date: date, session: session)
            }
        } label: {
            SessionCell(exercise: exercise)
                .frame(width: 100, height: 60)
        }
        .buttonStyle(.plain)
        .overlay(
            Group {
                if !isLast {
                    Rectangle().fill(borderColor).frame(width: 1)
                }
            },
            alignment: .trailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Left Column (Fixed)
                    machineNamesColumn
                    
                    Rectangle().fill(borderColor).frame(width: 1)
                    
                    // Right Column (Scrollable)
                    dataGrid
                }
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if showAddButton {
                        Button(action: {
                            if let firstExercise = exercises.first {
                                editorConfig = SessionEditorConfig(machine: firstExercise, date: Date())
                            }
                        }) {
                            Label("Add Session", systemImage: "plus")
                        }
                        .disabled(exercises.isEmpty)
                    }
                    
                    Button(action: {
                        sendAllSessionsByEmail()
                        if emailComposer.canSendMail {
                            showingMailComposer = true
                        }
                    }) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.orange)
                    }
                    .disabled(!emailComposer.canSendMail)
                }
            }
        }
        .background(AppTheme.backgroundColor(for: colorScheme)) // Screen BG
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExerciseOrderChanged"))) { _ in
            // Trigger view refresh when exercise order changes
            refreshTrigger = UUID()
        }
        .id(refreshTrigger) // Force refresh when trigger changes
        .fullScreenCover(item: $editorConfig) { config in
            // Use Refactored WorkoutSessionDetailView (need to implement/update it)
            // For now, assume we will update it to take correct params
            WorkoutSessionDetailView(
                config: config,
                subscriber: subscriber
            )
        }
        .sheet(isPresented: $showingMailComposer) {
            if emailComposer.canSendMail {
                MailComposerView(
                    subject: emailComposer.subject,
                    body: emailComposer.body,
                    toRecipients: nil,
                    completion: { result, error in
                        emailComposer.handleMailResult(result, error: error)
                        showingMailComposer = false
                    }
                )
            }
        }
        .alert(LocalizedString.string(for: .common, key: "Cannot Send Email"), isPresented: .constant(emailComposer.errorMessage != nil && !emailComposer.canSendMail)) {
            Button(LocalizedString.string(for: .common, key: "OK")) {
                emailComposer.errorMessage = nil
            }
        } message: {
            if let errorMessage = emailComposer.errorMessage {
                Text(errorMessage)
            }
        }
        .alert(LocalizedString.string(for: .common, key: "Email Status"), isPresented: .constant(emailComposer.errorMessage != nil && emailComposer.canSendMail)) {
            Button(LocalizedString.string(for: .common, key: "OK")) {
                emailComposer.errorMessage = nil
            }
        } message: {
            if let errorMessage = emailComposer.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func sendAllSessionsByEmail() {
        // ... update email logic to use sessions ...
        // Placeholder for now
    }
    
    // Helpers
    private func getSessionAndExercise(machine: String, date: Date) -> (SessionFS?, SessionExerciseFS?) {
        // Find session for date
        guard let session = sessions.first(where: { normalizeDate($0.date) == date }) else {
            return (nil, nil)
        }
        // Find exercise
        let exercise = session.exercises?.first(where: { $0.name == machine })
        return (session, exercise)
    }
    
    private func normalizeDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
}

struct SessionCell: View {
    let exercise: SessionExerciseFS?
    
    var body: some View {
        VStack(spacing: 2) {
            if let exercise = exercise {
                
                if let weight = exercise.weight, weight > 0 {
                    Text("\(Int(weight)) kg")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    // hasContent = true // Not needed for logic below necessarily
                }
                
                // Show target duration if present (Plan)
                if let duration = exercise.targetDuration, duration > 0 {
                   // Display in mm:ss:ms format
                   Text(formatDuration(duration))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                } else if let endurance = exercise.enduranceTime, endurance > 0 {
                     // Check actual time if no target
                     Text(formatDuration(endurance))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                // If neither (just created but empty), show placeholder/icon?
                // But orange box implies presence.
                
            } else {
                Text("-")
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .frame(width: 85, height: 60)
        .background(exercise != nil ? AppTheme.orange : Color.clear)
        .cornerRadius(6)
    }
    
    func formatDuration(_ value: Double) -> String {
        // value is in Seconds
        let totalSeconds = Int(value)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let ms = Int((value.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", minutes, seconds, ms)
    }
}

