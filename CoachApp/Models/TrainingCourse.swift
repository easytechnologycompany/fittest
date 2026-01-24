//
//  TrainingCourse.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class CourseExercise {
    var sets: Int = 0
    var reps: Int = 0
    var weight: Double? // in kg
    var restTime: Int? // in seconds
    var notes: String = ""
    var order: Int = 0 // Order in the course
    
    // Relationships
    var machine: Machine? // Machine used for this exercise
    @Relationship(inverse: \TrainingCourse.exercises) var course: TrainingCourse? // Direct relationship to course
    @Relationship(inverse: \CourseDay.exercises) var courseDay: CourseDay? // Keep for backward compatibility
    
    init(
        sets: Int = 0,
        reps: Int = 0,
        weight: Double? = nil,
        restTime: Int? = nil,
        notes: String = "",
        order: Int = 0,
        machine: Machine? = nil
    ) {
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.restTime = restTime
        self.notes = notes
        self.order = order
        self.machine = machine
    }
    
    /// Exercise name from machine
    var name: String {
        machine?.name ?? "Unknown Exercise"
    }
}

@Model
final class CourseDay {
    var dayNumber: Int = 1
    var dayName: String? // User-defined name for the day
    var workoutTitle: String = ""
    var order: Int = 0 // Order in the course
    
    // Relationships
    @Relationship(inverse: \TrainingCourse.days) var course: TrainingCourse?
    @Relationship(deleteRule: .cascade) var exercises: [CourseExercise]?
    
    init(
        dayNumber: Int = 1,
        dayName: String? = nil,
        workoutTitle: String = "",
        order: Int = 0
    ) {
        self.dayNumber = dayNumber
        self.dayName = dayName
        self.workoutTitle = workoutTitle
        self.order = order
        self.exercises = []
    }
    
    /// Get all unique machines used in this day
    var machines: [Machine] {
        guard let exercises = exercises else { return [] }
        var uniqueMachines: [Machine] = []
        var seenMachineIDs: Set<PersistentIdentifier> = []
        
        for exercise in exercises {
            if let machine = exercise.machine {
                let machineID = machine.persistentModelID
                if !seenMachineIDs.contains(machineID) {
                    uniqueMachines.append(machine)
                    seenMachineIDs.insert(machineID)
                }
            }
        }
        return uniqueMachines
    }
}

@Model
final class TrainingCourse {
    var title: String = ""
    var courseDescription: String = ""
    var durationMonths: Int = 1 // in months (1, 2, 3, etc.)
    var difficulty: String = "Beginner" // "Beginner", "Intermediate", "Advanced"
    var createdDate: Date = Date()
    var notes: String = ""
    
    // Relationships
    @Relationship(deleteRule: .cascade) var exercises: [CourseExercise]? // Direct exercises
    @Relationship(deleteRule: .cascade) var days: [CourseDay]? // Keep for backward compatibility
    var assignedSubscribers: [Subscriber]?
    
    init(
        title: String = "",
        courseDescription: String = "",
        durationMonths: Int = 1,
        difficulty: String = "Beginner",
        createdDate: Date = Date(),
        notes: String = ""
    ) {
        self.title = title
        self.courseDescription = courseDescription
        self.durationMonths = durationMonths
        self.difficulty = difficulty
        self.createdDate = createdDate
        self.notes = notes
        self.exercises = []
        self.days = []
        self.assignedSubscribers = []
    }
    
    var totalDays: Int {
        durationMonths * 30 // Approximate days per month
    }
    
    /// Get all unique machines needed for this course
    var requiredMachines: [Machine] {
        var uniqueMachines: [Machine] = []
        var seenMachineIDs: Set<PersistentIdentifier> = []
        
        // Get machines from direct exercises
        if let exercises = exercises {
            for exercise in exercises {
                if let machine = exercise.machine {
                    let machineID = machine.persistentModelID
                    if !seenMachineIDs.contains(machineID) {
                        uniqueMachines.append(machine)
                        seenMachineIDs.insert(machineID)
                    }
                }
            }
        }
        
        // Also check days for backward compatibility
        if let days = days {
            for day in days {
                for machine in day.machines {
                    let machineID = machine.persistentModelID
                    if !seenMachineIDs.contains(machineID) {
                        uniqueMachines.append(machine)
                        seenMachineIDs.insert(machineID)
                    }
                }
            }
        }
        
        return uniqueMachines.sorted { $0.name < $1.name }
    }
}

