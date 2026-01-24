//
//  ExerciseDBModels.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation

/// Exercise model from ExerciseDB API
struct ExerciseDBExercise: Codable, Identifiable, Hashable {
    let exerciseId: String
    let name: String
    let imageUrl: String?
    let videoUrl: String?
    let equipments: [String]
    let bodyParts: [String]
    let gender: String?
    let exerciseType: String?
    let targetMuscles: [String]
    let secondaryMuscles: [String]
    let keywords: [String]?
    let overview: String?
    let instructions: [String]
    let exerciseTips: [String]?
    let variations: [String]?
    let relatedExerciseIds: [String]?
    
    var id: String { exerciseId }
    
    /// Get the image URL, constructing it from exercise ID if not provided
    var effectiveImageUrl: String? {
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            return imageUrl
        }
        // Fallback: construct image URL from exercise ID
        // Common patterns for ExerciseDB image URLs
        return "https://exercisedb.p.rapidapi.com/images/\(exerciseId).gif"
    }
    
    enum CodingKeys: String, CodingKey {
        case exerciseId
        case name
        case imageUrl
        case image
        case image_url
        case gifUrl
        case gif_url
        case videoUrl
        case equipments
        case bodyParts
        case gender
        case exerciseType
        case targetMuscles
        case secondaryMuscles
        case keywords
        case overview
        case instructions
        case exerciseTips
        case variations
        case relatedExerciseIds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseId = try container.decode(String.self, forKey: .exerciseId)
        name = try container.decode(String.self, forKey: .name)
        
        // Try multiple possible field names for image URL (break into steps for compiler)
        if let directImage = try container.decodeIfPresent(String.self, forKey: .imageUrl) {
            imageUrl = directImage
        } else if let altImage = try container.decodeIfPresent(String.self, forKey: .image) {
            imageUrl = altImage
        } else if let snakeImage = try container.decodeIfPresent(String.self, forKey: .image_url) {
            imageUrl = snakeImage
        } else if let gifImage = try container.decodeIfPresent(String.self, forKey: .gifUrl) {
            imageUrl = gifImage
        } else if let gifSnakeImage = try container.decodeIfPresent(String.self, forKey: .gif_url) {
            imageUrl = gifSnakeImage
        } else {
            imageUrl = nil
        }
        
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        equipments = try container.decodeIfPresent([String].self, forKey: .equipments) ?? []
        bodyParts = try container.decodeIfPresent([String].self, forKey: .bodyParts) ?? []
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        exerciseType = try container.decodeIfPresent(String.self, forKey: .exerciseType)
        targetMuscles = try container.decodeIfPresent([String].self, forKey: .targetMuscles) ?? []
        secondaryMuscles = try container.decodeIfPresent([String].self, forKey: .secondaryMuscles) ?? []
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        exerciseTips = try container.decodeIfPresent([String].self, forKey: .exerciseTips)
        variations = try container.decodeIfPresent([String].self, forKey: .variations)
        relatedExerciseIds = try container.decodeIfPresent([String].self, forKey: .relatedExerciseIds)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exerciseId, forKey: .exerciseId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(videoUrl, forKey: .videoUrl)
        try container.encode(equipments, forKey: .equipments)
        try container.encode(bodyParts, forKey: .bodyParts)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(exerciseType, forKey: .exerciseType)
        try container.encode(targetMuscles, forKey: .targetMuscles)
        try container.encode(secondaryMuscles, forKey: .secondaryMuscles)
        try container.encodeIfPresent(keywords, forKey: .keywords)
        try container.encodeIfPresent(overview, forKey: .overview)
        try container.encode(instructions, forKey: .instructions)
        try container.encodeIfPresent(exerciseTips, forKey: .exerciseTips)
        try container.encodeIfPresent(variations, forKey: .variations)
        try container.encodeIfPresent(relatedExerciseIds, forKey: .relatedExerciseIds)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(exerciseId)
    }
    
    static func == (lhs: ExerciseDBExercise, rhs: ExerciseDBExercise) -> Bool {
        lhs.exerciseId == rhs.exerciseId
    }
}

/// Helper to map ExerciseDB equipment to our Machine categories
struct ExerciseDBEquipmentMapper {
    static func mapEquipmentToCategory(_ equipment: String) -> String {
        let lowercased = equipment.lowercased()
        
        if lowercased.contains("dumbbell") || lowercased.contains("barbell") || lowercased.contains("kettlebell") || lowercased.contains("ez bar") {
            return "Free Weights"
        } else if lowercased.contains("cable") || lowercased.contains("rope") {
            return "Cable"
        } else if lowercased.contains("machine") || lowercased.contains("leverage") || lowercased.contains("smith") {
            return "Strength"
        } else if lowercased.contains("treadmill") || lowercased.contains("bike") || lowercased.contains("elliptical") || lowercased.contains("rower") {
            return "Cardio"
        } else if lowercased.contains("band") || lowercased.contains("body weight") || lowercased.contains("resistance") {
            return "Functional"
        } else {
            return "Strength" // Default
        }
    }
    
    static func mapCategoryToEquipment(_ category: String) -> [String] {
        switch category {
        case "Free Weights":
            return ["DUMBBELL", "BARBELL", "KETTLEBELL", "EZ BAR"]
        case "Cable":
            return ["CABLE", "ROPE"]
        case "Strength":
            return ["LEVERAGE MACHINE", "MACHINE", "SMITH MACHINE"]
        case "Cardio":
            return ["TREADMILL", "BIKE", "ELLIPTICAL", "ROWER"]
        case "Functional":
            return ["BAND", "BODY WEIGHT", "RESISTANCE BAND"]
        default:
            return []
        }
    }
}
