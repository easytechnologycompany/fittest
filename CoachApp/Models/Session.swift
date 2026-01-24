//
//  Session.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID = UUID()
    var date: Date = Date()
    var status: String = "Active" // "Active", "Completed", "Cancelled"
    var title: String = "New Session"
    
    // Relationships
    @Relationship(deleteRule: .cascade) var exercises: [SessionExercise]?
    @Relationship var subscribers: [Subscriber]?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        status: String = "Active",
        title: String = "New Session"
    ) {
        self.id = id
        self.date = date
        self.status = status
        self.title = title
        self.exercises = []
        self.subscribers = []
    }
}

@Model
final class SessionExercise {
    var id: UUID = UUID()
    var name: String = ""
    var machineName: String?
    var machineCategory: String? // To help with icons
    
    // Parameters
    var rhythm: Int = 0 // seconds
    var weight: Double = 0.0 // kg or lbs based on user pref, but let's assume raw value for now
    var intensity: String = "Medium" // "Low", "Medium", "High"
    var targetDuration: Int? // seconds, optional target time 
    
    var isCompleted: Bool = false
    var orderIndex: Int = 0
    
    // Relationship
    @Relationship(inverse: \Session.exercises) var session: Session?
    
    init(
        id: UUID = UUID(),
        name: String,
        machineName: String? = nil,
        machineCategory: String? = nil,
        rhythm: Int = 0,
        weight: Double = 0.0,
        intensity: String = "Medium",
        targetDuration: Int? = nil,
        isCompleted: Bool = false,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.machineName = machineName
        self.machineCategory = machineCategory
        self.rhythm = rhythm
        self.weight = weight
        self.intensity = intensity
        self.targetDuration = targetDuration
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
    }
}
