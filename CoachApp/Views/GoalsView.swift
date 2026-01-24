//
//  GoalsView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct GoalsView: View {
    @Environment(\.colorScheme) var colorScheme
    let subscriber: SubscriberFS
    let goals: [GoalFS]
    
    @State private var showingAddGoal = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    @State private var deleteCompletion: ((IndexSet) -> Void)?
    
    var activeGoals: [GoalFS] {
        goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [GoalFS] {
        goals.filter { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack {
            List {
                activeGoalsSection
                completedGoalsSection
                addGoalSection
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle(LocalizedString.string(for: .goals, key: "Goals"))
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Label("Add Goal", systemImage: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
            .platformSheet(isPresented: $showingAddGoal) {
                AddGoalView(subscriber: subscriber)
            }
            .alert("Delete Goal", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    itemsToDelete = nil
                    deleteCompletion = nil
                }
                Button("Delete", role: .destructive) {
                    if let offsets = itemsToDelete, let completion = deleteCompletion {
                         completion(offsets)
                    }
                    itemsToDelete = nil
                    deleteCompletion = nil
                }
            } message: {
                Text("Are you sure you want to delete this goal? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    @ViewBuilder
    private var activeGoalsSection: some View {
        if !activeGoals.isEmpty {
            Section(LocalizedString.string(for: .goals, key: "Active Goals")) {
                ForEach(activeGoals) { goal in
                    NavigationLink {
                        GoalDetailView(goal: goal, subscriber: subscriber)
                    } label: {
                        GoalRowView(goal: goal)
                    }
                }
                .onDelete { offsets in
                    itemsToDelete = offsets
                    deleteCompletion = { idx in
                        deleteGoals(from: activeGoals, at: idx)
                    }
                    showingDeleteConfirmation = true
                }
            }
        }
    }

    @ViewBuilder
    private var completedGoalsSection: some View {
        if !completedGoals.isEmpty {
            Section(LocalizedString.string(for: .goals, key: "Completed Goals")) {
                ForEach(completedGoals) { goal in
                    NavigationLink {
                        GoalDetailView(goal: goal, subscriber: subscriber)
                    } label: {
                        GoalRowView(goal: goal)
                    }
                }
                .onDelete { offsets in
                    itemsToDelete = offsets
                    deleteCompletion = { idx in
                        deleteGoals(from: completedGoals, at: idx)
                    }
                    showingDeleteConfirmation = true
                }
            }
        }
    }

    @ViewBuilder
    private var addGoalSection: some View {
        Section {
            Button(action: { showingAddGoal = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                        .font(.title3)
                    Text(LocalizedString.string(for: .goals, key: "Add New Goal"))
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                    Spacer()
                }
            }
        }
    }
    
    private func deleteGoals(from sourceList: [GoalFS], at offsets: IndexSet) {
        Task {
            do {
                for index in offsets {
                    if let id = sourceList[index].id {
                        try await FirestoreService.shared.deleteGoal(id)
                    }
                }
            } catch {
                let appError = AppError.deleteError("Failed to delete goal: \(error.localizedDescription)")
                await MainActor.run {
                    ErrorHandler.handle(appError, context: "GoalsView.deleteGoals")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

#Preview {
    // GoalsView(subscriber: SubscriberFS(...), goals: [])
    Text("Preview")
}

