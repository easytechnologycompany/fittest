//
//  MachineDatabase.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation

/// Predefined machines database for the app
struct MachineDatabase {
    /// Get all predefined machines
    static func getAllMachines() -> [(name: String, iconName: String, category: String, machineDescription: String)] {
        return [
            // Strength Machines
            ("Leg Press", "figure.strengthtraining.traditional", "Strength", "Leg press machine for lower body strength training"),
            ("Bench Press", "dumbbell.fill", "Strength", "Bench press machine for chest and upper body"),
            ("Lat Pulldown", "figure.strengthtraining.traditional", "Cable", "Lat pulldown machine for back muscles"),
            ("Cable Crossover", "cable.connector", "Cable", "Cable crossover machine for versatile upper body exercises"),
            ("Chest Press", "figure.arms.open", "Strength", "Chest press machine for pectoral muscles"),
            ("Shoulder Press", "figure.strengthtraining.functional", "Strength", "Shoulder press machine for deltoids"),
            ("Leg Extension", "figure.strengthtraining.traditional", "Strength", "Leg extension machine for quadriceps"),
            ("Leg Curl", "figure.strengthtraining.traditional", "Strength", "Leg curl machine for hamstrings"),
            ("Seated Row", "figure.rower", "Cable", "Seated row machine for back muscles"),
            ("Cable Fly", "cable.connector", "Cable", "Cable fly machine for chest muscles"),
            ("Tricep Pushdown", "cable.connector", "Cable", "Tricep pushdown cable machine"),
            ("Bicep Curl", "cable.connector", "Cable", "Bicep curl cable machine"),
            ("Calf Raise", "figure.strengthtraining.traditional", "Strength", "Calf raise machine for lower legs"),
            ("Hack Squat", "figure.strengthtraining.traditional", "Strength", "Hack squat machine for legs"),
            ("Smith Machine", "dumbbell.fill", "Free Weights", "Smith machine with guided barbell"),
            
            // Free Weights
            ("Barbell", "dumbbell.fill", "Free Weights", "Standard barbell for free weight exercises"),
            ("Dumbbells", "dumbbell.fill", "Free Weights", "Dumbbells for free weight exercises"),
            ("Kettlebell", "figure.strengthtraining.functional", "Free Weights", "Kettlebell for functional training"),
            ("EZ Bar", "dumbbell.fill", "Free Weights", "EZ curl bar for arm exercises"),
            ("Cable Machine", "cable.connector", "Cable", "Multi-purpose cable machine"),
            
            // Cardio Machines
            ("Treadmill", "figure.run", "Cardio", "Treadmill for running and walking"),
            ("Elliptical", "figure.run", "Cardio", "Elliptical trainer for low-impact cardio"),
            ("Rowing Machine", "figure.rower", "Cardio", "Rowing machine for full-body cardio"),
            ("Stationary Bike", "bicycle", "Cardio", "Stationary bike for cycling cardio"),
            ("Stair Climber", "figure.stairs", "Cardio", "Stair climber machine for cardio"),
            ("Assault Bike", "bicycle", "Cardio", "Assault bike for high-intensity cardio"),
            ("Spin Bike", "bicycle", "Cardio", "Spin bike for cycling workouts"),
            
            // Functional
            ("Pull-up Bar", "figure.arms.open", "Functional", "Pull-up bar for bodyweight exercises"),
            ("Dip Station", "figure.arms.open", "Functional", "Dip station for tricep and chest exercises"),
            ("Battle Ropes", "figure.strengthtraining.functional", "Functional", "Battle ropes for functional training"),
            ("Suspension Trainer", "figure.strengthtraining.functional", "Functional", "TRX or suspension trainer"),
            ("Medicine Ball", "figure.strengthtraining.functional", "Functional", "Medicine ball for functional training"),
            ("Resistance Bands", "figure.strengthtraining.functional", "Functional", "Resistance bands for various exercises"),
            ("Plyometric Box", "square.stack", "Functional", "Plyometric box for jumping exercises"),
            ("Foam Roller", "cylinder", "Functional", "Foam roller for recovery"),
        ]
    }
    
    /// Get machines filtered by category
    static func getMachines(by category: String) -> [(name: String, iconName: String, category: String, machineDescription: String)] {
        return getAllMachines().filter { $0.category == category }
    }
    
    /// Get all unique categories
    static func getAllCategories() -> [String] {
        return Array(Set(getAllMachines().map { $0.category })).sorted()
    }
    
    /// Search machines by name
    static func searchMachines(_ searchText: String) -> [(name: String, iconName: String, category: String, machineDescription: String)] {
        let lowercased = searchText.lowercased()
        return getAllMachines().filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.machineDescription.lowercased().contains(lowercased) ||
            $0.category.lowercased().contains(lowercased)
        }
    }
}
