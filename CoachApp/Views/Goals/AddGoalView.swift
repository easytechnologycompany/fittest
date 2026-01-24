//
//  AddGoalView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData

//
//  AddGoalView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    
    let subscriber: SubscriberFS
    var goal: GoalFS?
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var targetDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var targetValue: String = ""
    @State private var currentValue: String = "0"
    @State private var unit: String = "kg"
    @State private var isCompleted: Bool = false
    @State private var selectedGoalType: String = "Body Weight"
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    let units = ["kg", "lbs", "cm", "inches", "%", "reps", "sets"]
    let goalTypes = [
        "Body Weight",
        "Chest Measurement",
        "Arm Measurement",
        "Leg Measurement",
        "Calf Measurement",
        "Waist Measurement",
        "Body Fat %",
        "Exercise Weight",
        "Exercise Reps",
        "Exercise Sets"
    ]
    
    init(subscriber: SubscriberFS, goal: GoalFS? = nil) {
        self.subscriber = subscriber
        self.goal = goal
        if let goal = goal {
            _title = State(initialValue: goal.title)
            _description = State(initialValue: goal.goalDescription)
            _targetDate = State(initialValue: goal.targetDate)
            _targetValue = State(initialValue: String(format: "%.1f", goal.targetValue))
            _currentValue = State(initialValue: String(format: "%.1f", goal.currentValue))
            _unit = State(initialValue: goal.unit)
            _isCompleted = State(initialValue: goal.isCompleted)
            _selectedGoalType = State(initialValue: goal.title)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizedString.string(for: .goals, key: "Goal Type")) {
                    Picker(LocalizedString.string(for: .goals, key: "Select Goal Type"), selection: $selectedGoalType) {
                        ForEach(goalTypes, id: \.self) { type in
                            Text(LocalizedString.string(for: .goals, key: type)).tag(type)
                        }
                    }
                    .onChange(of: selectedGoalType) { _, newValue in
                        title = newValue
                        updateUnitForGoalType(newValue)
                    }
                }
                
                Section(LocalizedString.string(for: .goals, key: "Goal Information")) {
                    TextField(LocalizedString.string(for: .goals, key: "Custom Title (Optional)"), text: $title)
                    TextField(LocalizedString.string(for: .common, key: "Description"), text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker(LocalizedString.string(for: .goals, key: "Target Date"), selection: $targetDate, displayedComponents: .date)
                }
                
                Section(LocalizedString.string(for: .goals, key: "Target & Progress")) {
                    HStack {
                        TextField(LocalizedString.string(for: .goals, key: "Target Value"), text: $targetValue)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                        Picker(LocalizedString.string(for: .goals, key: "Unit"), selection: $unit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    TextField(LocalizedString.string(for: .goals, key: "Current Value"), text: $currentValue)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                }
                
                if goal != nil {
                    Section(LocalizedString.string(for: .common, key: "Status")) {
                        Toggle(LocalizedString.string(for: .goals, key: "Complete"), isOn: $isCompleted)
                    }
                }
            }
            .navigationTitle(goal == nil ? LocalizedString.string(for: .goals, key: "Add Goal") : LocalizedString.string(for: .goals, key: "Edit Goal"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString.string(for: .common, key: "Cancel")) {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isLoading ? "Saving..." : LocalizedString.string(for: .common, key: "Save")) {
                        saveGoal()
                    }
                    .disabled(!isValid || isLoading)
                }
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
    
    private var isValid: Bool {
        !title.isEmpty && !targetValue.isEmpty && Double(targetValue) != nil
    }
    
    private func updateUnitForGoalType(_ type: String) {
        switch type {
        case "Body Weight", "Exercise Weight":
            unit = "kg"
        case "Chest Measurement", "Arm Measurement", "Leg Measurement", "Calf Measurement", "Waist Measurement":
            unit = "cm"
        case "Body Fat %":
            unit = "%"
        case "Exercise Reps":
            unit = "reps"
        case "Exercise Sets":
            unit = "sets"
        default:
            unit = "kg"
        }
    }
    
    private func saveGoal() {
        guard let targetVal = Double(targetValue) else {
            errorMessage = AppError.validationError("Invalid target value").localizedDescription
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if var goal = goal {
                    // Update existing
                    let oldValue = goal.currentValue
                    goal.title = title
                    goal.goalDescription = description
                    goal.targetDate = targetDate
                    goal.targetValue = targetVal
                    goal.currentValue = Double(currentValue) ?? 0
                    goal.unit = unit
                    goal.isCompleted = isCompleted
                    
                    if goal.startingDate == nil {
                        goal.startingDate = Date()
                    }
                    
                    // Add history entry if value changed significantly
                    if abs(goal.currentValue - oldValue) > 0.01 {
                        let entry = GoalProgressEntryFS(value: goal.currentValue, date: Date())
                        if goal.progressHistory == nil {
                            goal.progressHistory = []
                        }
                        goal.progressHistory?.append(entry)
                    }
                    
                    if isCompleted && goal.completedDate == nil {
                        goal.completedDate = Date()
                    } else if !isCompleted {
                        goal.completedDate = nil
                    }
                    
                    try await FirestoreService.shared.updateGoal(goal)
                    
                } else {
                    // Create new
                    let currentVal = Double(currentValue) ?? 0
                    let startVal = currentVal
                    
                    let newGoal = GoalFS(
                        title: title,
                        goalDescription: description,
                        targetDate: targetDate,
                        targetValue: targetVal,
                        currentValue: currentVal,
                        startingValue: startVal,
                        startingDate: Date(),
                        unit: unit,
                        isCompleted: isCompleted,
                        completedDate: isCompleted ? Date() : nil,
                        subscriberId: subscriber.id,
                        progressHistory: [GoalProgressEntryFS(value: currentVal, date: Date())]
                    )
                     
                    try await FirestoreService.shared.addGoal(newGoal)
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to save goal: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AddGoalView.saveGoal")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}


