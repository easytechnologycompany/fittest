//
//  ExerciseHelper.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

/// Helper for managing exercises/machines used in workout sessions
struct ExerciseHelper {
    // Default exercises list (always available)
    static let defaultExercises = [
        "Elliptical cross training",
        "Chest press",
        "Lat pull down",
        "Rowing",
        "Abdominal",
        "Abduction",
        "Adduction",
        "Leg press",
        "Dumbbells"
    ]
    
    // MARK: - Exercise Exclusion Management
    private static let excludedExercisesKey = "excludedExercises"
    
    /// Exclude an exercise (effectively deleting it from the list)
    static func excludeExercise(_ name: String) {
        var excluded = UserDefaults.standard.stringArray(forKey: excludedExercisesKey) ?? []
        if !excluded.contains(name) {
            excluded.append(name)
            UserDefaults.standard.set(excluded, forKey: excludedExercisesKey)
            // Also remove from order if present
            var currentOrder = UserDefaults.standard.array(forKey: exerciseOrderKey) as? [String] ?? []
            if let index = currentOrder.firstIndex(of: name) {
                currentOrder.remove(at: index)
                saveExerciseOrder(currentOrder)
            }
        }
    }
    
    /// Get all available exercises from sessions, respecting exclusions
    /// - Parameter allSessions: All WorkoutSession records
    /// - Returns: Combined list of default exercises and exercises from sessions, minus excluded ones
    static func getAllExercises(from allSessions: [WorkoutSession]) -> [String] {
        // Get unique exercise names from ALL sessions
        let sessionExercises = Set(allSessions.map { $0.machineName })
        
        // Combine defaults with session exercises
        let all = Set(defaultExercises).union(sessionExercises)
        
        // Filter out excluded exercises
        let excluded = Set(UserDefaults.standard.stringArray(forKey: excludedExercisesKey) ?? [])
        let available = all.subtracting(excluded)
        
        // Sort: defaults first (in order), then others alphabetically
        let defaults = defaultExercises.filter { available.contains($0) }
        let others = Array(available.subtracting(Set(defaultExercises))).sorted()
        
        return defaults + others
    }
    
    /// Check if an exercise name already exists
    /// - Parameters:
    ///   - name: Exercise name to check
    ///   - allSessions: All WorkoutSession records
    /// - Returns: True if exercise exists
    static func exerciseExists(_ name: String, in allSessions: [WorkoutSession]) -> Bool {
        let allExercises = getAllExercises(from: allSessions)
        return allExercises.contains(name)
    }
    
    // MARK: - Exercise Order Management
    
    private static let exerciseOrderKey = "exerciseOrder"
    
    /// Get ordered exercises respecting user's custom order
    /// - Parameter allSessions: All WorkoutSession records
    /// - Returns: Exercises in custom order (if set) or default order
    static func getOrderedExercises(from allSessions: [WorkoutSession]) -> [String] {
        let allExercises = getAllExercises(from: allSessions)
        
        // Load custom order from UserDefaults
        if let orderData = UserDefaults.standard.array(forKey: exerciseOrderKey) as? [String] {
            // Filter to only include exercises that still exist
            let ordered = orderData.filter { allExercises.contains($0) }
            // Add any new exercises that aren't in the order
            let newExercises = allExercises.filter { !ordered.contains($0) }
            return ordered + newExercises.sorted()
        }
        
        // Return default order (defaults first in order, then others alphabetically)
        let defaults = defaultExercises.filter { allExercises.contains($0) }
        let others = allExercises.filter { !defaultExercises.contains($0) }.sorted()
        return defaults + others
    }
    
    /// Save exercise order
    /// - Parameter exercises: Ordered list of exercise names
    static func saveExerciseOrder(_ exercises: [String]) {
        UserDefaults.standard.set(exercises, forKey: exerciseOrderKey)
        // Post notification to trigger view updates
        NotificationCenter.default.post(name: NSNotification.Name("ExerciseOrderChanged"), object: nil)
    }
    
    /// Reset exercise order to default
    static func resetExerciseOrder() {
        UserDefaults.standard.removeObject(forKey: exerciseOrderKey)
        UserDefaults.standard.removeObject(forKey: excludedExercisesKey)
    }
    
    /// Apply user's custom order to a list of exercise names
    /// - Parameter names: List of exercise names to sort
    /// - Returns: Sorted list of names
    static func applyOrdering(to names: [String]) -> [String] {
        guard let orderData = UserDefaults.standard.array(forKey: exerciseOrderKey) as? [String] else {
            return names.sorted()
        }
        
        return names.sorted { (n1, n2) -> Bool in
            let idx1 = orderData.firstIndex(of: n1) ?? Int.max
            let idx2 = orderData.firstIndex(of: n2) ?? Int.max
            
            if idx1 != idx2 {
                return idx1 < idx2
            } else {
                return n1 < n2
            }
        }
    }
}

