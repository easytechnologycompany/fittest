//
//  Machine.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class Machine {
    var name: String = ""
    var iconName: String = "dumbbell" // SF Symbol name
    var customIconData: Data? // Optional custom image data
    var category: String = "Strength" // e.g., "Cardio", "Strength", "Free Weights", "Cable"
    var machineDescription: String = ""
    var isCustom: Bool = false // Whether it's a user-created machine
    var createdDate: Date = Date()
    var exerciseDBId: String? // Link to ExerciseDB exercise
    var exerciseDBImageUrl: String? // Image URL from ExerciseDB API
    
    @Relationship(deleteRule: .cascade, inverse: \CourseExercise.machine) var courseExercises: [CourseExercise]? = []
    
    init(
        name: String = "",
        iconName: String = "dumbbell",
        customIconData: Data? = nil,
        category: String = "Strength",
        machineDescription: String = "",
        isCustom: Bool = false,
        exerciseDBId: String? = nil,
        exerciseDBImageUrl: String? = nil
    ) {
        self.name = name
        self.iconName = iconName
        self.customIconData = customIconData
        self.category = category
        self.machineDescription = machineDescription
        self.isCustom = isCustom
        self.createdDate = Date()
        self.exerciseDBId = exerciseDBId
        self.exerciseDBImageUrl = exerciseDBImageUrl
        self.courseExercises = []
    }
}
