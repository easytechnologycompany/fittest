//
//  WorkoutLog.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String = ""
    var sets: Int = 0
    var reps: Int = 0
    var weight: Double? // in kg
    var notes: String = ""
    
    // Relationship
    @Relationship(inverse: \WorkoutLog.exercises) var workout: WorkoutLog?
    
    init(name: String = "", sets: Int = 0, reps: Int = 0, weight: Double? = nil, notes: String = "") {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
    }
}

@Model
final class WorkoutLog {
    var date: Date = Date()
    var duration: TimeInterval = 0 // in seconds
    var notes: String = ""
    
    // Relationships
    @Relationship(inverse: \Subscriber.workouts) var subscriber: Subscriber?
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]?
    
    init(date: Date = Date(), duration: TimeInterval = 0, notes: String = "") {
        self.date = date
        self.duration = duration
        self.notes = notes
        self.exercises = []
    }
}

