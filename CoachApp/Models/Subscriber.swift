//
//  Subscriber.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class Subscriber {
    // Basic Info
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var dateOfBirth: Date?
    var gender: String? // e.g., "Male", "Female", "Other", "Prefer not to say"
    var photo: Data?
    
    // Subscription Info
    var subscriptionStartDate: Date = Date()
    var planType: String = "Monthly" // e.g., "Monthly", "3-Month", "Annual"
    var paymentStatus: String = "Active" // e.g., "Active", "Pending", "Expired"
    
    // Medical Info
    var injuries: String = ""
    var restrictions: String = ""
    var healthConditions: String = ""
    
    // Onboarding - Physical Information
    var onboardingHeight: Double? // in cm
    var onboardingWeight: Double? // in kg
    var onboardingAge: Int?
    var onboardingHeartRate: Int? // bpm
    var onboardingBodyFatPercentage: Double? // percentage
    var onboardingMuscleMassPercentage: Double? // percentage
    var onboardingPreviousActivityLevel: String? // e.g., "Sedentary", "Light", "Moderate", "Active", "Very Active"
    
    // Onboarding - Health Information (comma-separated strings)
    var onboardingHealthConditions: String? // Comma-separated list of selected conditions
    var onboardingPastInjuries: String?
    var onboardingPreviousSurgeries: String?
    var onboardingAllergies: String?
    var onboardingCurrentMedications: String?
    var onboardingPregnancyStatus: Bool? // for women
    
    // Onboarding - Fitness Goals (comma-separated string)
    var onboardingFitnessGoals: String? // Comma-separated list of selected goals
    
    // Onboarding - Signature
    var signatureData: Data? // Compressed signature image
    
    // Onboarding - Referral Information
    var howDidYouHearAboutUs: String? // e.g., "Snapchat", "Instagram", "Facebook", "Referred by a friend", "Other"
    var referrerName: String? // Name of the person who referred (if applicable)
    
    // Relationships
    @Relationship(deleteRule: .cascade) var physicalDetails: [PhysicalDetail]?
    @Relationship(deleteRule: .cascade) var workouts: [WorkoutLog]?
    @Relationship(deleteRule: .cascade) var goals: [Goal]?
    @Relationship(deleteRule: .cascade) var attendance: [Attendance]?
    @Relationship(deleteRule: .cascade) var notes: [CoachNote]?

    @Relationship(deleteRule: .cascade) var workoutSessions: [WorkoutSession]?
    @Relationship(inverse: \TrainingCourse.assignedSubscribers) var assignedCourses: [TrainingCourse]?
    @Relationship(inverse: \Session.subscribers) var sessions: [Session]?
    
    init(
        name: String = "",
        email: String = "",
        phone: String = "",
        dateOfBirth: Date? = nil,
        gender: String? = nil,
        photo: Data? = nil,
        subscriptionStartDate: Date = Date(),
        planType: String = "Monthly",
        paymentStatus: String = "Active",
        injuries: String = "",
        restrictions: String = "",
        healthConditions: String = "",
        onboardingHeight: Double? = nil,
        onboardingWeight: Double? = nil,
        onboardingAge: Int? = nil,
        onboardingHeartRate: Int? = nil,
        onboardingBodyFatPercentage: Double? = nil,
        onboardingMuscleMassPercentage: Double? = nil,
        onboardingPreviousActivityLevel: String? = nil,
        onboardingHealthConditions: String? = nil,
        onboardingPastInjuries: String? = nil,
        onboardingPreviousSurgeries: String? = nil,
        onboardingAllergies: String? = nil,
        onboardingCurrentMedications: String? = nil,
        onboardingPregnancyStatus: Bool? = nil,
        onboardingFitnessGoals: String? = nil,
        signatureData: Data? = nil,
        howDidYouHearAboutUs: String? = nil,
        referrerName: String? = nil
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.photo = photo
        self.subscriptionStartDate = subscriptionStartDate
        self.planType = planType
        self.paymentStatus = paymentStatus
        self.injuries = injuries
        self.restrictions = restrictions
        self.healthConditions = healthConditions
        self.onboardingHeight = onboardingHeight
        self.onboardingWeight = onboardingWeight
        self.onboardingAge = onboardingAge
        self.onboardingHeartRate = onboardingHeartRate
        self.onboardingBodyFatPercentage = onboardingBodyFatPercentage
        self.onboardingMuscleMassPercentage = onboardingMuscleMassPercentage
        self.onboardingPreviousActivityLevel = onboardingPreviousActivityLevel
        self.onboardingHealthConditions = onboardingHealthConditions
        self.onboardingPastInjuries = onboardingPastInjuries
        self.onboardingPreviousSurgeries = onboardingPreviousSurgeries
        self.onboardingAllergies = onboardingAllergies
        self.onboardingCurrentMedications = onboardingCurrentMedications
        self.onboardingPregnancyStatus = onboardingPregnancyStatus
        self.onboardingFitnessGoals = onboardingFitnessGoals
        self.signatureData = signatureData
        self.howDidYouHearAboutUs = howDidYouHearAboutUs
        self.referrerName = referrerName
        self.physicalDetails = []
        self.workouts = []
        self.goals = []
        self.attendance = []
        self.notes = []
    }
    
    /// Check if onboarding has been completed
    var hasCompletedOnboarding: Bool {
        return signatureData != nil
    }
}

