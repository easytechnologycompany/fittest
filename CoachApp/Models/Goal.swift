//
//  Goal.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class GoalProgressEntry {
    var value: Double = 0
    var date: Date = Date()
    @Relationship(inverse: \Goal.progressHistory) var goal: Goal?
    
    init(value: Double = 0, date: Date = Date()) {
        self.value = value
        self.date = date
    }
}

@Model
final class Goal {
    var title: String = ""
    var goalDescription: String = ""
    var targetDate: Date = Date()
    var targetValue: Double = 0
    var currentValue: Double = 0
    var startingValue: Double? // Starting value when goal was created (for proper progress calculation)
    var startingDate: Date? // Date when starting value was set
    var unit: String = "" // e.g., "kg", "cm", "%"
    var isCompleted: Bool = false
    var completedDate: Date?
    var createdDate: Date? // Date when goal was created
    
    // Relationships
    @Relationship(inverse: \Subscriber.goals) var subscriber: Subscriber?
    @Relationship(deleteRule: .cascade) var progressHistory: [GoalProgressEntry]?
    
    init(
        title: String = "",
        goalDescription: String = "",
        targetDate: Date = Date(),
        targetValue: Double = 0,
        currentValue: Double = 0,
        startingValue: Double? = nil,
        unit: String = "",
        isCompleted: Bool = false
    ) {
        self.title = title
        self.goalDescription = goalDescription
        self.targetDate = targetDate
        self.targetValue = targetValue
        self.currentValue = currentValue
        let startValue = startingValue ?? currentValue
        self.startingValue = startValue
        self.startingDate = Date() // Set starting date when goal is created
        self.unit = unit
        self.isCompleted = isCompleted
        self.completedDate = nil
        self.createdDate = Date()
        self.progressHistory = []
    }
    
    var progress: Double {
        guard targetValue != 0 else { return 0 }
        
        // For existing goals without startingValue, use current value
        let startValue = startingValue ?? currentValue
        
        // Automatically determine if it's a decrease or increase goal based on values
        // If startingValue > targetValue, it's a decrease goal (e.g., 83kg -> 70kg)
        // If startingValue < targetValue, it's an increase goal (e.g., 70kg -> 83kg)
        let isDecreaseGoal = startValue > targetValue
        
        if isDecreaseGoal {
            // For decrease goals: progress = (startingValue - currentValue) / (startingValue - targetValue)
            // Example: Start 83kg, Target 70kg, Current 83kg -> 0% progress
            // Example: Start 83kg, Target 70kg, Current 76.5kg -> 50% progress
            // Example: Start 83kg, Target 70kg, Current 70kg -> 100% progress
            let totalChange = startValue - targetValue
            guard totalChange > 0 else { 
                // If target >= start, check if already achieved
                return currentValue <= targetValue ? 1.0 : 0.0
            }
            let progressMade = startValue - currentValue
            let calculatedProgress = progressMade / totalChange
            return min(max(calculatedProgress, 0), 1)
        } else {
            // For increase goals: progress = (currentValue - startingValue) / (targetValue - startingValue)
            // Example: Start 70kg, Target 83kg, Current 70kg -> 0% progress
            // Example: Start 70kg, Target 83kg, Current 76.5kg -> 50% progress
            // Example: Start 70kg, Target 83kg, Current 83kg -> 100% progress
            let totalChange = targetValue - startValue
            guard totalChange > 0 else {
                // If target <= start, check if already achieved
                return currentValue >= targetValue ? 1.0 : 0.0
            }
            let progressMade = currentValue - startValue
            let calculatedProgress = progressMade / totalChange
            return min(max(calculatedProgress, 0), 1)
        }
    }
}

