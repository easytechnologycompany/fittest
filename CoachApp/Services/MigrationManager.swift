//
//  MigrationManager.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 18/01/2026.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import FirebaseFirestore

class MigrationManager: ObservableObject {
    static let shared = MigrationManager()
    
    @AppStorage("hasMigratedToFirestore") private var hasMigratedToFirestore: Bool = false
    @Published var isMigrating: Bool = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationError: String?
    
    private init() {}
    
    func checkAndMigrate(container: ModelContainer) async {
        guard !hasMigratedToFirestore else { return }
        
        await performMigration(container: container)
    }
    
    @MainActor
    private func performMigration(container: ModelContainer) async {
        isMigrating = true
        migrationProgress = 0.0
        
        let context = ModelContext(container)
        
        do {
            // 1. Fetch all Subscribers
            let subscriberDescriptor = FetchDescriptor<Subscriber>()
            let swiftDataSubscribers = try context.fetch(subscriberDescriptor)
            
            let totalItems = Double(swiftDataSubscribers.count)
            var processedItems = 0.0
            
            // 2. Iterate and upload
            // Note: We are doing this serially to be safe, but could be batched.
            for subscriber in swiftDataSubscribers {
                try await migrateSubscriber(subscriber, context: context)
                
                processedItems += 1
                migrationProgress = processedItems / totalItems
            }
            
            // 3. Mark as complete
            hasMigratedToFirestore = true
            isMigrating = false
            print("✅ Migration Completed Successfully")
            
        } catch {
            print("❌ Migration Failed: \(error.localizedDescription)")
            migrationError = error.localizedDescription
            isMigrating = false
        }
    }
    
    private func migrateSubscriber(_ sdSubscriber: Subscriber, context: ModelContext) async throws {
        // 1. Create SubscriberFS
        // Note: We use nil for photoUrl as we are not handling binary upload here yet.
        let fsSubscriber = SubscriberFS(
            id: nil, // Generates new ID
            name: sdSubscriber.name,
            email: sdSubscriber.email,
            phone: sdSubscriber.phone,
            dateOfBirth: sdSubscriber.dateOfBirth,
            gender: sdSubscriber.gender,
            photoUrl: nil,
            subscriptionStartDate: sdSubscriber.subscriptionStartDate,
            planType: sdSubscriber.planType,
            paymentStatus: sdSubscriber.paymentStatus,
            injuries: sdSubscriber.injuries,
            restrictions: sdSubscriber.restrictions,
            healthConditions: sdSubscriber.healthConditions,
            onboardingHeight: sdSubscriber.onboardingHeight,
            onboardingWeight: sdSubscriber.onboardingWeight,
            onboardingAge: sdSubscriber.onboardingAge,
            onboardingHeartRate: sdSubscriber.onboardingHeartRate,
            onboardingBodyFatPercentage: sdSubscriber.onboardingBodyFatPercentage,
            onboardingMuscleMassPercentage: sdSubscriber.onboardingMuscleMassPercentage,
            onboardingPreviousActivityLevel: sdSubscriber.onboardingPreviousActivityLevel,
            onboardingHealthConditions: sdSubscriber.onboardingHealthConditions,
            onboardingPastInjuries: sdSubscriber.onboardingPastInjuries,
            onboardingPreviousSurgeries: sdSubscriber.onboardingPreviousSurgeries,
            onboardingAllergies: sdSubscriber.onboardingAllergies,
            onboardingCurrentMedications: sdSubscriber.onboardingCurrentMedications,
            onboardingPregnancyStatus: sdSubscriber.onboardingPregnancyStatus,
            onboardingFitnessGoals: sdSubscriber.onboardingFitnessGoals,
            howDidYouHearAboutUs: sdSubscriber.howDidYouHearAboutUs,
            referrerName: sdSubscriber.referrerName
        )
        
        // 2. Add to Firestore and get new ID
        let subRef = try await FirestoreService.shared.addSubscriber(fsSubscriber)
        let newSubscriberID = subRef.documentID
        print("Migrated subscriber: \(fsSubscriber.name) -> ID: \(newSubscriberID)")
        
        // 3. Migrate Children
        
        // Physical Details
        if let details = sdSubscriber.physicalDetails {
            for detail in details {
                let fsDetail = PhysicalDetailFS(
                    dateRecorded: detail.dateRecorded,
                    weight: detail.weight,
                    bodyFatPercentage: detail.bodyFatPercentage,
                    height: detail.height,
                    chest: detail.chest,
                    waist: detail.waist,
                    hips: detail.hips,
                    leftArm: detail.leftArm,
                    rightArm: detail.rightArm,
                    leftLeg: detail.leftLeg,
                    rightLeg: detail.rightLeg,
                    photoUrl: nil,
                    subscriberId: newSubscriberID
                )
                try await FirestoreService.shared.addPhysicalDetail(fsDetail)
            }
        }
        
        // Goals
        if let goals = sdSubscriber.goals {
            for goal in goals {
                let fsProgress = goal.progressHistory?.map { GoalProgressEntryFS(value: $0.value, date: $0.date) }
                let fsGoal = GoalFS(
                    title: goal.title,
                    goalDescription: goal.goalDescription,
                    targetDate: goal.targetDate,
                    targetValue: goal.targetValue,
                    currentValue: goal.currentValue,
                    startingValue: goal.startingValue,
                    startingDate: goal.startingDate,
                    unit: goal.unit,
                    isCompleted: goal.isCompleted,
                    completedDate: goal.completedDate,
                    createdDate: goal.createdDate,
                    subscriberId: newSubscriberID,
                    progressHistory: fsProgress
                )
                try await FirestoreService.shared.addGoal(fsGoal)
            }
        }
        
        // Sessions
        // Note: This relies on `Session.subscribers`. In SwiftData it's Many-to-Many. 
        // In FirestoreFS, we use `subscriberId` in `SessionFS` (One-to-Many representation usually).
        // If sessions are shared, this simple migration duplicates them per subscriber or needs a join table.
        // Assuming sessions are 1-1 with subscribers (Personal Training usually), or we just duplicate for now.
        if let sessions = sdSubscriber.sessions {
            for session in sessions {
                let fsExercises = session.exercises?.map { ex in
                    SessionExerciseFS(
                        name: ex.name,
                        machineName: ex.machineName,
                        machineCategory: ex.machineCategory,
                        rhythm: ex.rhythm,
                        weight: ex.weight,
                        intensity: ex.intensity,
                        targetDuration: ex.targetDuration.map { Double($0) },
                        isCompleted: ex.isCompleted,
                        orderIndex: ex.orderIndex
                    )
                }
                
                let fsSession = SessionFS(
                    date: session.date,
                    status: session.status,
                    title: session.title,
                    subscriberId: newSubscriberID,
                    exercises: fsExercises
                )
                try await FirestoreService.shared.addSession(fsSession)
            }
        }
        
        // Coach Notes
        if let notes = sdSubscriber.notes {
            for note in notes {
                let fsNote = CoachNoteFS(
                    date: note.date,
                    title: note.title,
                    content: note.content,
                    category: note.category,
                    subscriberId: newSubscriberID
                )
                try await FirestoreService.shared.addCoachNote(fsNote)
            }
        }

        // Attendance
        if let attendances = sdSubscriber.attendance {
            for att in attendances {
                let fsAtt = AttendanceFS(
                    date: att.date,
                    checkInTime: att.checkInTime,
                    checkOutTime: att.checkOutTime,
                    notes: att.notes,
                    subscriberId: newSubscriberID
                )
                try await FirestoreService.shared.addAttendance(fsAtt)
            }
        }
    }
}
