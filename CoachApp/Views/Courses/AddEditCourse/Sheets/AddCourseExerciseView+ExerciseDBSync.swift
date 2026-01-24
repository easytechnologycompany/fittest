import SwiftUI

extension AddCourseExerciseView {
    func syncFromExerciseDB() {
        guard ExerciseDBService.shared.isConfigured else {
            return
        }
        
        isLoadingFromExerciseDB = true
        
        Task {
            // Fetch exercises from ExerciseDB using search
            // Search for different terms to get a comprehensive set
            var allExercises: [ExerciseDBExercise] = []
            var seenIds: Set<String> = []
            
            let searchTerms = ["strength", "cardio", "weight", "machine", "bodyweight", "resistance", "exercise"]
            
            for term in searchTerms {
                do {
                    let exercises = try await ExerciseDBService.shared.searchExercises(term)
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
            
            // Get existing machines to avoid duplicates
            let existingMachineNames = Set(allMachines.map { $0.name.lowercased() })
            
            // Save new machines to Firestore
            for exercise in allExercises {
                // Skip if machine with this name already exists
                if existingMachineNames.contains(exercise.name.lowercased()) {
                    continue
                }
                
                // Create MachineFS from ExerciseDB exercise
                let category = ExerciseDBService.shared.getCategoryForExercise(exercise)
                let iconName = ExerciseDBService.shared.getIconNameForExercise(exercise)
                
                // Use effectiveImageUrl which includes fallback construction
                let imageUrl = exercise.effectiveImageUrl
                
                let machine = MachineFS(
                    name: exercise.name,
                    iconName: iconName,
                    category: category,
                    machineDescription: exercise.overview ?? exercise.instructions.first ?? "",
                    isCustom: false,
                    exerciseDBImageUrl: imageUrl,
                    exerciseDBId: exercise.exerciseId
                )
                
                do {
                    _ = try await FirestoreService.shared.saveMachine(machine)
                } catch {
                    print("Failed to save machine \(machine.name): \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                isLoadingFromExerciseDB = false
            }
        }
    }
}

