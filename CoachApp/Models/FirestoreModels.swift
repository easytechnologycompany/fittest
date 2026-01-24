//
//  FirestoreModels.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 18/01/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Subscriber (Firestore)
struct SubscriberFS: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var phone: String
    var dateOfBirth: Date?
    var gender: String?
    // For small images, we can store as Base64 constrained string, but better to use Storage.
    // Let's assume we will upload photos to Firebase Storage and store the URL here.
    var photoUrl: String?
    var photoBase64: String? // Added to match CloudKit 'photo: Data?' capability if needed
    
    var subscriptionStartDate: Date?
    var planType: String?
    var paymentStatus: String?
    
    // Medical
    var injuries: String?
    var restrictions: String?
    var healthConditions: String?
    
    // Onboarding - Physical
    var onboardingHeight: Double?
    var onboardingWeight: Double?
    var onboardingAge: Int?
    var onboardingHeartRate: Int?
    var onboardingBodyFatPercentage: Double?
    var onboardingMuscleMassPercentage: Double?
    var onboardingPreviousActivityLevel: String?
    
    // Onboarding - Health
    var onboardingHealthConditions: String?
    var onboardingPastInjuries: String?
    var onboardingPreviousSurgeries: String?
    var onboardingAllergies: String?
    var onboardingCurrentMedications: String?
    var onboardingPregnancyStatus: Bool?
    
    // Onboarding - Goals
    var onboardingFitnessGoals: String?
    
    // Onboarding - Signature
    // Storing as Base64 string for Firestore instead of raw Data
    var signatureData: String?
    
    // Referral
    var howDidYouHearAboutUs: String?
    var referrerName: String?
    
    // Metadata
    var createdAt: Date? = Date()
    var updatedAt: Date? = Date()
    
    // Flag to link back to original CloudKit record if needed
    var originalCloudKitID: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SubscriberFS, rhs: SubscriberFS) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Machine (Firestore)
struct MachineFS: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var iconName: String
    var category: String
    var machineDescription: String
    var isCustom: Bool
    var exerciseDBImageUrl: String?
    var exerciseDBId: String?
}

// MARK: - Session (Firestore)
struct SessionFS: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var status: String?
    var title: String?
    
    // We store references effectively by ID
    var subscriberId: String?
    
    // Embedded exercises for simplicity
    var exercises: [SessionExerciseFS]?
}

// MARK: - Session Exercise (Firestore)
struct SessionExerciseFS: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var machineName: String?
    var machineCategory: String?
    
    var rhythm: Int?
    var weight: Double?
    var intensity: String?
    var targetDuration: Double? // Changed from Int to Double to match CloudKit 'TimeInterval'
    var enduranceTime: Double? // Matches CloudKit 'enduranceTime'
    
    var isCompleted: Bool?
    var orderIndex: Int?
    
    // Additional metrics
    var notes: String?
    var plusTenCount: Int?
}

// MARK: - CoachNote (Firestore)
struct CoachNoteFS: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var title: String
    var content: String
    var category: String
    var subscriberId: String?
}

// MARK: - Attendance (Firestore)
struct AttendanceFS: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var checkInTime: Date?
    var checkOutTime: Date?
    var notes: String
    var subscriberId: String?
}

// MARK: - Goal (Firestore)
struct GoalProgressEntryFS: Codable, Identifiable {
    var id: UUID = UUID() // Internal ID for UI lists
    var value: Double
    var date: Date
}

struct GoalFS: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var goalDescription: String
    var targetDate: Date
    var targetValue: Double
    var currentValue: Double
    var startingValue: Double?
    var startingDate: Date?
    var unit: String
    var isCompleted: Bool
    var completedDate: Date?
    var createdDate: Date?
    var subscriberId: String?
    
    // We can embed progress history as it's usually small
    var progressHistory: [GoalProgressEntryFS]?
    
    var progress: Double {
        guard targetValue != 0 else { return 0 }
        
        let startValue = startingValue ?? currentValue
        let isDecreaseGoal = startValue > targetValue
        
        if isDecreaseGoal {
            let totalChange = startValue - targetValue
            guard totalChange > 0 else {
                return currentValue <= targetValue ? 1.0 : 0.0
            }
            let progressMade = startValue - currentValue
            let calculatedProgress = progressMade / totalChange
            return min(max(calculatedProgress, 0), 1)
        } else {
            let totalChange = targetValue - startValue
            guard totalChange > 0 else {
                return currentValue >= targetValue ? 1.0 : 0.0
            }
            let progressMade = currentValue - startValue
            let calculatedProgress = progressMade / totalChange
            return min(max(calculatedProgress, 0), 1)
        }
    }
}

// MARK: - PhysicalDetail (Firestore)
struct PhysicalDetailFS: Codable, Identifiable {
    @DocumentID var id: String?
    var dateRecorded: Date
    
    var weight: Double?
    var bodyFatPercentage: Double?
    var height: Double?
    
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var leftArm: Double?
    var rightArm: Double?
    var leftLeg: Double?
    var rightLeg: Double?
    
    var photoUrl: String?
    var photoBase64: String?
    var subscriberId: String?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - WorkoutLog (Firestore)
struct WorkoutExerciseFS: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var notes: String
}

struct WorkoutLogFS: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var duration: TimeInterval
    var notes: String
    var subscriberId: String?
    
    var exercises: [WorkoutExerciseFS]?
}

// MARK: - Training Course (Firestore)
struct CourseExerciseFS: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var restTime: Int?
    var notes: String?
    var order: Int
    
    var machineId: String?
    var machineName: String?
}

struct CourseDayFS: Codable, Identifiable {
    var id: UUID = UUID()
    var dayNumber: Int
    var dayName: String?
    var workoutTitle: String?
    var order: Int
    
    var exercises: [CourseExerciseFS]?
}

struct TrainingCourseFS: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var courseDescription: String?
    var durationMonths: Int
    var difficulty: String
    var createdDate: Date = Date()
    var notes: String?
    
    var exercises: [CourseExerciseFS]? // Flat list if needed
    var days: [CourseDayFS]?
    
    // Instead of direct objects, we store subscriber IDs
    var assignedSubscriberIds: [String]?
}

// MARK: - Workout Session (Firestore)
struct WorkoutSessionFS: Codable, Identifiable {
    @DocumentID var id: String?
    var subscriberId: String
    var machineName: String
    var date: Date
    var weight: Double?
    var enduranceTime: TimeInterval?
    var targetDuration: TimeInterval?
    var notes: String?
    var plusTenCount: Int?
}

// MARK: - Session Editor Config
struct SessionEditorConfig: Identifiable {
    let id = UUID()
    let session: SessionFS? // Parent session
    let exercise: SessionExerciseFS? // Specific exercise to edit
    let machine: String?
    let date: Date?
    
    // Edit existing exercise in a session
    init(session: SessionFS, exercise: SessionExerciseFS) {
        self.session = session
        self.exercise = exercise
        self.machine = nil
        self.date = nil
    }
    
    // Add new exercise (machine) on a date (either existing session or new)
    init(machine: String, date: Date, session: SessionFS? = nil) {
        self.session = session
        self.exercise = nil
        self.machine = machine
        self.date = date
    }
}

