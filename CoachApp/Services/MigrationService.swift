//
//  MigrationService.swift
//  CoachApp
//
//  Created by Antigravity on 18/01/2026.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class MigrationService: ObservableObject {
    static let shared = MigrationService()
    
    @Published var isMigrating: Bool = false
    @Published var migrationProgress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var migrationComplete: Bool = false
    @Published var migrationError: String?
    
    private let userDefaultsKey = "hasCompletedFirestoreMigration"
    private let migrationDateKey = "migrationCompletionDate"
    
    private var totalSteps: Double = 10.0
    private var currentStepNumber: Double = 0.0
    
    // ID mappings for relationship preservation
    private var subscriberIdMap: [PersistentIdentifier: String] = [:]
    private var machineIdMap: [PersistentIdentifier: String] = [:]
    
    private init() {}
    
    /// Check if migration has already been completed
    func hasMigrationCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
    
    /// Mark migration as complete
    private func markMigrationComplete() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        UserDefaults.standard.set(Date(), forKey: migrationDateKey)
        migrationComplete = true
    }
    
    /// Reset migration status (for testing only)
    func resetMigrationStatus() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: migrationDateKey)
        migrationComplete = false
    }
    
    /// Main migration entry point
    func checkAndMigrate(modelContext: ModelContext) async {
        guard !hasMigrationCompleted() else {
            print("✅ Migration already completed")
            return
        }
        
        print("🚀 Starting Firestore migration...")
        isMigrating = true
        migrationProgress = 0.0
        migrationError = nil
        
        do {
            try await migrateAllData(modelContext: modelContext)
            markMigrationComplete()
            print("✅ Migration completed successfully!")
        } catch {
            migrationError = error.localizedDescription
            ErrorHandler.handle(error, context: "MigrationService.checkAndMigrate")
            print("❌ Migration failed: \(error.localizedDescription)")
        }
        
        isMigrating = false
    }
    
    /// Migrate all data in correct order
    private func migrateAllData(modelContext: ModelContext) async throws {
        // Step 1: Migrate Machines
        try await updateProgress(step: "Migrating machines...", stepNumber: 1)
        try await migrateMachines(modelContext: modelContext)
        
        // Step 2: Migrate Subscribers
        try await updateProgress(step: "Migrating subscribers...", stepNumber: 2)
        try await migrateSubscribers(modelContext: modelContext)
        
        // Step 3: Migrate Training Courses
        try await updateProgress(step: "Migrating training courses...", stepNumber: 3)
        try await migrateCourses(modelContext: modelContext)
        
        // Step 4: Migrate Physical Details
        try await updateProgress(step: "Migrating physical details...", stepNumber: 4)
        try await migratePhysicalDetails(modelContext: modelContext)
        
        // Step 5: Migrate Goals
        try await updateProgress(step: "Migrating goals...", stepNumber: 5)
        try await migrateGoals(modelContext: modelContext)
        
        // Step 6: Migrate Attendance
        try await updateProgress(step: "Migrating attendance records...", stepNumber: 6)
        try await migrateAttendance(modelContext: modelContext)
        
        // Step 7: Migrate Coach Notes
        try await updateProgress(step: "Migrating coach notes...", stepNumber: 7)
        try await migrateCoachNotes(modelContext: modelContext)
        
        // Step 8: Migrate Workout Logs
        try await updateProgress(step: "Migrating workout logs...", stepNumber: 8)
        try await migrateWorkoutLogs(modelContext: modelContext)
        
        // Step 9: Migrate Sessions
        try await updateProgress(step: "Migrating sessions...", stepNumber: 9)
        try await migrateSessions(modelContext: modelContext)
        
        // Step 10: Migrate Workout Sessions
        try await updateProgress(step: "Migrating workout sessions...", stepNumber: 10)
        try await migrateWorkoutSessions(modelContext: modelContext)
        
        // Complete
        try await updateProgress(step: "Migration complete!", stepNumber: 10)
    }
    
    // MARK: - Migration Methods
    
    private func migrateMachines(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<Machine>()
        let machines = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(machines.count) machines...")
        
        for machine in machines {
            let machineFS = MachineFS(
                name: machine.name,
                iconName: machine.iconName,
                category: machine.category,
                machineDescription: machine.machineDescription,
                isCustom: machine.isCustom
            )
            
            let docRef = try await FirestoreService.shared.saveMachine(machineFS)
            machineIdMap[machine.persistentModelID] = docRef
        }
        
        print("✅ Migrated \(machines.count) machines")
    }
    
    private func migrateSubscribers(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<Subscriber>()
        let subscribers = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(subscribers.count) subscribers...")
        
        for subscriber in subscribers {
            let subscriberFS = SubscriberFS(
                name: subscriber.name,
                email: subscriber.email,
                phone: subscriber.phone,
                dateOfBirth: subscriber.dateOfBirth,
                gender: subscriber.gender,
                photoUrl: nil, // TODO: Upload photo to Storage and set URL
                subscriptionStartDate: subscriber.subscriptionStartDate,
                planType: subscriber.planType,
                paymentStatus: subscriber.paymentStatus,
                injuries: subscriber.injuries,
                restrictions: subscriber.restrictions,
                healthConditions: subscriber.healthConditions
            )
            
            let docId = try await FirestoreService.shared.saveSubscriber(subscriberFS)
            subscriberIdMap[subscriber.persistentModelID] = docId
        }
        
        print("✅ Migrated \(subscribers.count) subscribers")
    }
    
    private func migrateCourses(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<TrainingCourse>()
        let courses = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(courses.count) training courses...")
        
        for course in courses {
            // Convert days
            var daysFS: [CourseDayFS] = []
            if let days = course.days {
                for day in days.sorted(by: { $0.order < $1.order }) {
                    // Convert exercises for this day
                    var exercisesFS: [CourseExerciseFS] = []
                    if let exercises = day.exercises {
                        for exercise in exercises.sorted(by: { $0.order < $1.order }) {
                            let exerciseFS = CourseExerciseFS(
                                name: exercise.name,
                                sets: exercise.sets,
                                reps: exercise.reps,
                                weight: exercise.weight,
                                restTime: exercise.restTime,
                                notes: exercise.notes,
                                order: exercise.order,
                                machineId: exercise.machine != nil ? machineIdMap[exercise.machine!.persistentModelID] : nil,
                                machineName: exercise.machine?.name
                            )
                            exercisesFS.append(exerciseFS)
                        }
                    }
                    
                    let dayFS = CourseDayFS(
                        dayNumber: day.dayNumber,
                        workoutTitle: day.workoutTitle,
                        order: day.order,
                        exercises: exercisesFS
                    )
                    daysFS.append(dayFS)
                }
            }
            
            // Convert assigned subscriber IDs
            var assignedSubscriberIds: [String] = []
            if let assignedSubscribers = course.assignedSubscribers {
                for subscriber in assignedSubscribers {
                    if let firestoreId = subscriberIdMap[subscriber.persistentModelID] {
                        assignedSubscriberIds.append(firestoreId)
                    }
                }
            }
            
            let courseFS = TrainingCourseFS(
                title: course.title,
                courseDescription: course.courseDescription,
                durationMonths: course.durationMonths,
                difficulty: course.difficulty,
                notes: course.notes,
                days: daysFS,
                assignedSubscriberIds: assignedSubscriberIds.isEmpty ? nil : assignedSubscriberIds
            )
            
            try await FirestoreService.shared.saveCourse(courseFS)
        }
        
        print("✅ Migrated \(courses.count) training courses")
    }
    
    private func migratePhysicalDetails(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<PhysicalDetail>()
        let details = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(details.count) physical details...")
        
        for detail in details {
            guard let subscriber = detail.subscriber,
                  let subscriberId = subscriberIdMap[subscriber.persistentModelID] else {
                print("⚠️ Skipping physical detail - subscriber not found")
                continue
            }
            
            let detailFS = PhysicalDetailFS(
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
                photoBase64: detail.photo != nil ? detail.photo!.base64EncodedString() : nil,
                subscriberId: subscriberId
            )
            
            _ = try await FirestoreService.shared.savePhysicalDetail(detailFS)
        }
        
        print("✅ Migrated \(details.count) physical details")
    }
    
    private func migrateGoals(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<Goal>()
        let goals = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(goals.count) goals...")
        
        for goal in goals {
            guard let subscriber = goal.subscriber,
                  let subscriberId = subscriberIdMap[subscriber.persistentModelID] else {
                print("⚠️ Skipping goal - subscriber not found")
                continue
            }
            
            // Convert progress history
            var progressHistoryFS: [GoalProgressEntryFS] = []
            if let progressHistory = goal.progressHistory {
                for entry in progressHistory {
                    let entryFS = GoalProgressEntryFS(
                        value: entry.value,
                        date: entry.date
                    )
                    progressHistoryFS.append(entryFS)
                }
            }
            
            let goalFS = GoalFS(
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
                subscriberId: subscriberId,
                progressHistory: progressHistoryFS.isEmpty ? nil : progressHistoryFS
            )
            
            _ = try await FirestoreService.shared.saveGoal(goalFS)
        }
        
        print("✅ Migrated \(goals.count) goals")
    }
    
    private func migrateAttendance(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<Attendance>()
        let records = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(records.count) attendance records...")
        
        for record in records {
            guard let subscriber = record.subscriber,
                  let subscriberId = subscriberIdMap[subscriber.persistentModelID] else {
                print("⚠️ Skipping attendance - subscriber not found")
                continue
            }
            
            let attendanceFS = AttendanceFS(
                date: record.date,
                checkInTime: record.checkInTime,
                checkOutTime: record.checkOutTime,
                notes: record.notes,
                subscriberId: subscriberId
            )
            
            _ = try await FirestoreService.shared.saveAttendance(attendanceFS)
        }
        
        print("✅ Migrated \(records.count) attendance records")
    }
    
    private func migrateCoachNotes(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<CoachNote>()
        let notes = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(notes.count) coach notes...")
        
        for note in notes {
            guard let subscriber = note.subscriber,
                  let subscriberId = subscriberIdMap[subscriber.persistentModelID] else {
                print("⚠️ Skipping coach note - subscriber not found")
                continue
            }
            
            let noteFS = CoachNoteFS(
                date: note.date,
                title: note.title,
                content: note.content,
                category: note.category,
                subscriberId: subscriberId
            )
            
            _ = try await FirestoreService.shared.saveCoachNote(noteFS)
        }
        
        print("✅ Migrated \(notes.count) coach notes")
    }
    
    private func migrateWorkoutLogs(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<WorkoutLog>()
        let logs = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(logs.count) workout logs...")
        
        for log in logs {
            guard let subscriber = log.subscriber,
                  let subscriberId = subscriberIdMap[subscriber.persistentModelID] else {
                print("⚠️ Skipping workout log - subscriber not found")
                continue
            }
            
            // Convert exercises - WorkoutLog uses Exercise model without machine relationship
            var exercisesFS: [WorkoutExerciseFS] = []
            if let exercises = log.exercises {
                for exercise in exercises {
                    let exerciseFS = WorkoutExerciseFS(
                        name: exercise.name,
                        sets: exercise.sets,
                        reps: exercise.reps,
                        weight: exercise.weight,
                        notes: exercise.notes
                    )
                    exercisesFS.append(exerciseFS)
                }
            }
            
            let logFS = WorkoutLogFS(
                date: log.date,
                duration: log.duration,
                notes: log.notes,
                subscriberId: subscriberId,
                exercises: exercisesFS.isEmpty ? nil : exercisesFS
            )
            
            _ = try await FirestoreService.shared.saveWorkoutLog(logFS)
        }
        
        print("✅ Migrated \(logs.count) workout logs")
    }
    
    private func migrateSessions(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<Session>()
        let sessions = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(sessions.count) sessions...")
        
        for session in sessions {
            // Sessions can have multiple subscribers, take the first one or skip if none
            guard let subscriber = session.subscribers?.first,
                  let subscriberId = subscriberIdMap[subscriber.persistentModelID] else {
                print("⚠️ Skipping session - no subscriber found")
                continue
            }
            
            // Convert exercises
            var exercisesFS: [SessionExerciseFS] = []
            if let exercises = session.exercises {
                for exercise in exercises {
                    let exerciseFS = SessionExerciseFS(
                        name: exercise.name,
                        machineName: exercise.machineName,
                        machineCategory: exercise.machineCategory,
                        rhythm: exercise.rhythm,
                        weight: exercise.weight,
                        intensity: exercise.intensity,
                        targetDuration: exercise.targetDuration.map { Double($0) },
                        isCompleted: exercise.isCompleted,
                        orderIndex: exercise.orderIndex
                    )
                    exercisesFS.append(exerciseFS)
                }
            }
            
            let sessionFS = SessionFS(
                date: session.date,
                status: session.status,
                title: session.title,
                subscriberId: subscriberId,
                exercises: exercisesFS.isEmpty ? nil : exercisesFS
            )
            
            _ = try await FirestoreService.shared.saveSession(sessionFS)
        }
        
        print("✅ Migrated \(sessions.count) sessions")
    }
    
    private func migrateWorkoutSessions(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<WorkoutSession>()
        let sessions = try modelContext.fetch(descriptor)
        
        print("📦 Migrating \(sessions.count) workout sessions...")
        
        for session in sessions {
            guard let subscriber = session.subscriber,
                  let subscriberId = subscriberIdMap[subscriber.persistentModelID] else {
                print("⚠️ Skipping workout session - subscriber not found")
                continue
            }
            
            let sessionFS = WorkoutSessionFS(
                subscriberId: subscriberId,
                machineName: session.machineName,
                date: session.date,
                weight: session.weight,
                enduranceTime: session.enduranceTime,
                targetDuration: session.targetDuration,
                notes: session.notes,
                plusTenCount: session.plusTenCount
            )
            
            _ = try await FirestoreService.shared.saveWorkoutSession(sessionFS)
        }
        
        print("✅ Migrated \(sessions.count) workout sessions")
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(step: String, stepNumber: Double) async throws {
        currentStep = step
        currentStepNumber = stepNumber
        migrationProgress = stepNumber / totalSteps
        print("📊 Progress: \(Int(migrationProgress * 100))% - \(step)")
        
        // Small delay to allow UI to update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}
