//
//  GoalDetailView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let subscriber: SubscriberFS
    @State var goal: GoalFS
    @State private var showingEdit = false
    @State private var progressInputText: String = ""
    @State private var showingProgressHistory = false
    @State private var errorMessage: String?
    
    init(goal: GoalFS, subscriber: SubscriberFS) {
        self.subscriber = subscriber
        _goal = State(initialValue: goal)
    }

    var body: some View {
        Text("Goal Detail View - To be implemented")
            .platformSheet(isPresented: $showingEdit) {
                AddGoalView(subscriber: subscriber, goal: goal)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
    }
    
    private func commitProgressValue() {
        let normalizedText = progressInputText.replacingOccurrences(of: ",", with: ".")
        guard let newValue = Double(normalizedText), newValue >= 0 else {
            progressInputText = String(format: "%.1f", goal.currentValue)
            return
        }
        
        updateProgressValue(newValue)
    }
    
    private func updateProgressValue(_ newValue: Double) {
        let oldValue = goal.currentValue
        // Optimistic update
        var updatedGoal = goal
        updatedGoal.currentValue = newValue
        
        if abs(newValue - oldValue) > 0.01 {
            let entry = GoalProgressEntryFS(value: newValue, date: Date())
            if updatedGoal.progressHistory == nil {
                updatedGoal.progressHistory = []
            }
            updatedGoal.progressHistory?.append(entry)
        }
        
        goal = updatedGoal
        updateGoalInFirestore(updatedGoal, revertValue: oldValue)
    }
    
    private func updateGoalInFirestore(_ updatedGoal: GoalFS, revertValue: Double? = nil) {
        Task {
            do {
                try await FirestoreService.shared.updateGoal(updatedGoal)
                await MainActor.run {
                     progressInputText = String(format: "%.1f", updatedGoal.currentValue)
                }
            } catch {
                await MainActor.run {
                    let appError = AppError.saveError("Failed to update goal: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "GoalDetailView.updateGoal")
                    errorMessage = appError.localizedDescription
                    // Revert if provided
                    if let oldValue = revertValue {
                        var reverted = goal
                        reverted.currentValue = oldValue
                        goal = reverted
                        progressInputText = String(format: "%.1f", oldValue)
                    }
                }
            }
        }
    }
}


