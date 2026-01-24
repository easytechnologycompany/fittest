//
//  LocalizationHelper.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation

/// Helper class for accessing localized strings by screen/feature
struct LocalizedString {
    /// Get localized string for a specific screen and key
    static func string(for screen: Screen, key: String, comment: String = "") -> String {
        let tableName = screen.rawValue
        return NSLocalizedString(key, tableName: tableName, bundle: .main, value: key, comment: comment)
    }
}

/// Enum representing different screens/features for localization
enum Screen: String {
    case dashboard = "Dashboard"
    case subscribers = "Subscribers"
    case courses = "Courses"
    case goals = "Goals"
    case workouts = "Workouts"
    case attendance = "Attendance"
    case physicalDetails = "PhysicalDetails"
    case notes = "Notes"
    case settings = "Settings"
    case machines = "Machines"
    case common = "Common"
}

