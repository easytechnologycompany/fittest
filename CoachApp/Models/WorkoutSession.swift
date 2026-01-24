//
//  WorkoutSession.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 17/12/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    // Relationships
    @Relationship(inverse: \Subscriber.workoutSessions) var subscriber: Subscriber?
    
    // Session Data
    var machineName: String = "" // One of the 7 fixed types
    var date: Date = Date() // Normalized to start of day
    
    // Performance Data
    var weight: Double? // in kg/lbs
    var enduranceTime: TimeInterval? // in seconds
    var targetDuration: TimeInterval? // Goal duration if set
    var notes: String?
    var plusTenCount: Int? // Number of times +10 seconds was added (after 40 seconds)
    
    init(
        machineName: String,
        date: Date,
        weight: Double? = nil,
        enduranceTime: TimeInterval? = nil,
        targetDuration: TimeInterval? = nil,
        notes: String? = nil,
        plusTenCount: Int? = nil
    ) {
        self.machineName = machineName
        self.date = date
        self.weight = weight
        self.enduranceTime = enduranceTime
        self.targetDuration = targetDuration
        self.notes = notes
        self.plusTenCount = plusTenCount ?? 0
    }
    
    /// Computed property to get plusTenCount with default value
    var plusTenCountValue: Int {
        return plusTenCount ?? 0
    }
}
