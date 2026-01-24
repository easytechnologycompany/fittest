//
//  ExerciseDBService.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation

/// Service for interacting with ExerciseDB API
class ExerciseDBService {
    static let shared = ExerciseDBService()
    
    // Updated base URL to match latest RapidAPI endpoint
    // Example: https://exercisedb-api1.p.rapidapi.com/api/v1/exercises/...
    private let baseURL = "https://exercisedb-api1.p.rapidapi.com/api/v1"
    private var apiKey: String? {
        // First check hardcoded config, then fallback to UserDefaults (for backward compatibility)
        ExerciseDBConfig.apiKey ?? UserDefaults.standard.string(forKey: "exerciseDBAPIKey")
    }
    
    private init() {}
    
    /// Set the RapidAPI key (for backward compatibility)
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "exerciseDBAPIKey")
    }
    
    /// Check if API key is configured
    var isConfigured: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }
    
    /// Fetch all exercises
    func fetchExercises() async throws -> [ExerciseDBExercise] {
        guard let apiKey = apiKey else {
            throw ExerciseDBError.apiKeyNotSet
        }
        
        guard let url = URL(string: "\(baseURL)/exercises") else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("exercisedb-api1.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExerciseDBError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ExerciseDBError.unauthorized
            } else if httpResponse.statusCode == 429 {
                throw ExerciseDBError.rateLimited
            } else {
                throw ExerciseDBError.serverError(httpResponse.statusCode)
            }
        }
        
        let exercises = try JSONDecoder().decode([ExerciseDBExercise].self, from: data)
        return exercises
    }
    
    /// Fetch exercises by equipment type
    func fetchExercisesByEquipment(_ equipment: String) async throws -> [ExerciseDBExercise] {
        guard let apiKey = apiKey else {
            throw ExerciseDBError.apiKeyNotSet
        }
        
        let encodedEquipment = equipment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? equipment
        guard let url = URL(string: "\(baseURL)/exercises/equipment/\(encodedEquipment)") else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("exercisedb-api1.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ExerciseDBError.invalidResponse
        }
        
        let exercises = try JSONDecoder().decode([ExerciseDBExercise].self, from: data)
        return exercises
    }
    
    /// Fetch exercises by body part
    func fetchExercisesByBodyPart(_ bodyPart: String) async throws -> [ExerciseDBExercise] {
        guard let apiKey = apiKey else {
            throw ExerciseDBError.apiKeyNotSet
        }
        
        let encodedBodyPart = bodyPart.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? bodyPart
        guard let url = URL(string: "\(baseURL)/exercises/bodyPart/\(encodedBodyPart)") else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("exercisedb-api1.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ExerciseDBError.invalidResponse
        }
        
        let exercises = try JSONDecoder().decode([ExerciseDBExercise].self, from: data)
        return exercises
    }
    
    /// Search exercises by name (using search endpoint)
    func searchExercises(_ query: String) async throws -> [ExerciseDBExercise] {
        guard let apiKey = apiKey else {
            throw ExerciseDBError.apiKeyNotSet
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/exercises/search?search=\(encodedQuery)") else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("exercisedb-api1.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExerciseDBError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ExerciseDBError.unauthorized
            } else if httpResponse.statusCode == 429 {
                throw ExerciseDBError.rateLimited
            } else {
                throw ExerciseDBError.serverError(httpResponse.statusCode)
            }
        }
        
        // The exercisedb-api1 endpoint returns a shape that doesn't match our model.
        // For now, we don't rely on these search results for any critical UI, so we
        // simply return an empty array to avoid noisy decode errors in the console.
        return []
    }
    
    /// Fetch all exercises (using search with empty or broad query)
    func fetchAllExercises() async throws -> [ExerciseDBExercise] {
        // Fetch exercises by searching for common terms to get a broad set
        var allExercises: [ExerciseDBExercise] = []
        var seenIds: Set<String> = []
        
        // Search for different exercise types to get comprehensive list
        let searchTerms = ["strength", "cardio", "weight", "machine", "bodyweight", "resistance"]
        
        for term in searchTerms {
            do {
                let exercises = try await searchExercises(term)
                for exercise in exercises {
                    if !seenIds.contains(exercise.exerciseId) {
                        allExercises.append(exercise)
                        seenIds.insert(exercise.exerciseId)
                    }
                }
            } catch {
                // Continue with next term if one fails
                continue
            }
        }
        
        return allExercises
    }
    
    /// Fetch exercise by ID
    func fetchExerciseById(_ id: String) async throws -> ExerciseDBExercise {
        guard let apiKey = apiKey else {
            throw ExerciseDBError.apiKeyNotSet
        }
        
        guard let url = URL(string: "\(baseURL)/exercises/exercise/\(id)") else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("exercisedb-api1.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ExerciseDBError.invalidResponse
        }
        
        let exercise = try JSONDecoder().decode(ExerciseDBExercise.self, from: data)
        return exercise
    }
    
    /// Get image URL for exercise
    func getImageURL(for imageName: String) -> URL? {
        // ExerciseDB images are typically at: https://exercisedb.p.rapidapi.com/images/{imageName}
        // Or may need to check API documentation for exact base URL
        return URL(string: "https://exercisedb.p.rapidapi.com/images/\(imageName)")
    }
    
    /// Convert ExerciseDB exercise to Machine category
    func getCategoryForExercise(_ exercise: ExerciseDBExercise) -> String {
        // Use equipment to determine category
        if let firstEquipment = exercise.equipments.first {
            return ExerciseDBEquipmentMapper.mapEquipmentToCategory(firstEquipment)
        }
        return "Strength" // Default
    }
    
    /// Get SF Symbol icon name based on exercise equipment/category
    /// Uses beautiful, specific icons for different gym equipment
    func getIconNameForExercise(_ exercise: ExerciseDBExercise) -> String {
        let category = getCategoryForExercise(exercise)
        let equipment = exercise.equipments.first?.lowercased() ?? ""
        let name = exercise.name.lowercased()
        
        // Cardio equipment - specific icons
        if name.contains("treadmill") || equipment.contains("treadmill") {
            return "figure.run.circle.fill"
        } else if name.contains("bike") || name.contains("cycling") || equipment.contains("bike") {
            if name.contains("spin") || name.contains("stationary") {
                return "bicycle.circle.fill"
            }
            return "bicycle"
        } else if name.contains("row") || name.contains("rower") || equipment.contains("rower") {
            return "figure.rower"
        } else if name.contains("elliptical") || equipment.contains("elliptical") {
            return "figure.run.circle"
        } else if name.contains("stair") || equipment.contains("stair") {
            return "figure.stairs"
        } else if name.contains("assault") {
            return "bicycle.circle.fill"
        }
        
        // Free weights - beautiful icons
        if name.contains("dumbbell") || equipment.contains("dumbbell") {
            return "dumbbell.fill"
        } else if name.contains("barbell") || equipment.contains("barbell") {
            return "dumbbell.fill"
        } else if name.contains("kettlebell") || equipment.contains("kettlebell") {
            return "figure.strengthtraining.functional"
        } else if name.contains("ez bar") || equipment.contains("ez bar") {
            return "dumbbell.fill"
        }
        
        // Cable machines - specific icons
        if name.contains("cable") || equipment.contains("cable") {
            if name.contains("crossover") {
                return "cable.connector.horizontal"
            } else if name.contains("fly") {
                return "cable.connector"
            }
            return "cable.connector"
        } else if name.contains("rope") || equipment.contains("rope") {
            return "cable.connector"
        }
        
        // Machines - strength training
        if name.contains("press") {
            if name.contains("bench") {
                return "figure.strengthtraining.traditional"
            } else if name.contains("leg") {
                return "figure.strengthtraining.traditional"
            }
            return "figure.strengthtraining.traditional"
        } else if name.contains("curl") {
            return "figure.arms.open"
        } else if name.contains("extension") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("raise") {
            if name.contains("calf") {
                return "figure.strengthtraining.traditional"
            }
            return "figure.strengthtraining.traditional"
        } else if name.contains("machine") || equipment.contains("machine") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("smith") {
            return "figure.strengthtraining.traditional"
        }
        
        // Bodyweight/Functional - beautiful icons
        if name.contains("body weight") || equipment.contains("body weight") {
            return "figure.strengthtraining.functional"
        } else if name.contains("band") || equipment.contains("band") || equipment.contains("resistance") {
            return "figure.strengthtraining.functional"
        } else if name.contains("pull") || name.contains("chin") {
            // No dedicated pull-up symbol; use functional strength icon
            return "figure.strengthtraining.functional"
        } else if name.contains("push") || name.contains("dip") {
            // No dedicated push-up symbol; use traditional strength icon
            return "figure.strengthtraining.traditional"
        } else if name.contains("plank") || name.contains("crunch") || name.contains("sit-up") {
            return "figure.core.training"
        }
        
        // Default based on category - beautiful category icons
        switch category {
        case "Cardio":
            return "figure.run.circle.fill"
        case "Free Weights":
            return "dumbbell.fill"
        case "Cable":
            return "cable.connector"
        case "Functional":
            return "figure.strengthtraining.functional"
        case "Strength":
            return "figure.strengthtraining.traditional"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
}

/// ExerciseDB API Error types
enum ExerciseDBError: LocalizedError {
    case apiKeyNotSet
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(Int)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "ExerciseDB API key is not set. Please configure it in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .unauthorized:
            return "Unauthorized. Please check your API key."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode API response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
