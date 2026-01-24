//
//  GoalProgressCalculator.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftUI

/// Utility for calculating goal progress
struct GoalProgressCalculator {
    /// Calculate progress for a goal value
    static func calculateProgress(
        currentValue: Double,
        targetValue: Double,
        startingValue: Double?,
        history: [GoalProgressEntryFS]?
    ) -> Double {
        guard targetValue != 0 else { return 0 }
        
        // Determine starting value
        let startValue: Double
        if let starting = startingValue {
            startValue = starting
        } else if let firstEntry = history?.sorted(by: { $0.date < $1.date }).first {
            startValue = firstEntry.value
        } else {
            startValue = currentValue
        }
        
        // Determine if it's a decrease or increase goal
        let isDecreaseGoal = startValue > targetValue
        
        if isDecreaseGoal {
            let totalChange = startValue - targetValue
            guard totalChange > 0 else {
                return currentValue <= targetValue ? 1.0 : 0.0
            }
            let progressMade = startValue - currentValue
            return min(max(progressMade / totalChange, 0), 1)
        } else {
            let totalChange = targetValue - startValue
            guard totalChange > 0 else {
                return currentValue >= targetValue ? 1.0 : 0.0
            }
            let progressMade = currentValue - startValue
            return min(max(progressMade / totalChange, 0), 1)
        }
    }
    
    /// Calculate progress at a specific entry
    static func calculateProgressAtEntry(
        _ entry: GoalProgressEntryFS,
        goal: GoalFS,
        history: [GoalProgressEntryFS]?
    ) -> Double {
        guard goal.targetValue != 0 else { return 0 }
        
        let startValue: Double
        if let starting = goal.startingValue {
            startValue = starting
        } else if let firstEntry = history?.sorted(by: { $0.date < $1.date }).first {
            startValue = firstEntry.value
        } else {
            startValue = entry.value
        }
        
        let isDecrease = startValue > goal.targetValue
        
        if isDecrease {
            let totalChange = startValue - goal.targetValue
            if totalChange > 0 {
                let progressMade = startValue - entry.value
                return min(max(progressMade / totalChange, 0), 1)
            } else {
                return entry.value <= goal.targetValue ? 1.0 : 0.0
            }
        } else {
            let totalChange = goal.targetValue - startValue
            if totalChange > 0 {
                let progressMade = entry.value - startValue
                return min(max(progressMade / totalChange, 0), 1)
            } else {
                return entry.value >= goal.targetValue ? 1.0 : 0.0
            }
        }
    }
    
    /// Get progress color based on progress value
    static func progressColor(for progress: Double) -> Color {
        let red = 1.0 - progress
        let green = progress
        return Color(red: red, green: green, blue: 0.0)
    }
}

