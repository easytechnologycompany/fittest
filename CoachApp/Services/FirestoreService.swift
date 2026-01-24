//
//  FirestoreService.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 18/01/2026.
//

import Foundation
import FirebaseFirestore
import Combine

class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {
        // Enable offline persistence (it is enabled by default in recent SDKs for iOS/Android, 
        // but explicit settings can ensure it).
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
    
    // MARK: - Generic Delete
    func delete(id: String, from collection: String) {
        db.collection(collection).document(id).delete()
    }
    
    // MARK: - Specialized Fetchers
    
    func fetchSubscribers() -> AnyPublisher<[SubscriberFS], Error> {
        let subject = PassthroughSubject<[SubscriberFS], Error>()
        
        db.collection("subscribers").addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            let subscribers = documents.compactMap { doc -> SubscriberFS? in
                do {
                    return try doc.data(as: SubscriberFS.self)
                } catch {
                    print("⛔️ DECODING ERROR for subscriber \(doc.documentID): \(error)")
                    return nil
                }
            }
            subject.send(subscribers)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func fetchSessions(for subscriberId: String? = nil) -> AnyPublisher<[SessionFS], Error> {
        let subject = PassthroughSubject<[SessionFS], Error>()
        
        var query: Query = db.collection("sessions")
        
        if let subId = subscriberId {
            query = query.whereField("subscriberId", isEqualTo: subId)
        }
        
        query.order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Firestore fetchSessions Error: \(error.localizedDescription)")
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("⚠️ Firestore fetchSessions: No documents found")
                subject.send([])
                return
            }
            
            print("✅ Firestore fetchSessions: Found \(documents.count) documents. Attempting to decode...")
            
            let sessions = documents.compactMap { doc -> SessionFS? in
                do {
                    return try doc.data(as: SessionFS.self)
                } catch {
                    print("⛔️ DECODING ERROR for session \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            print("✅ Firestore fetchSessions: Successfully decoded \(sessions.count) sessions.")
            subject.send(sessions)
        }
        
        return subject.eraseToAnyPublisher()
    }

    func getSession(id: String) async throws -> SessionFS {
        let snapshot = try await db.collection("sessions").document(id).getDocument()
        return try snapshot.data(as: SessionFS.self)
    }
    
    func findSession(subscriberId: String, date: Date) async throws -> SessionFS? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        
        let snapshot = try await db.collection("sessions")
            .whereField("subscriberId", isEqualTo: subscriberId)
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .limit(to: 1)
            .getDocuments()
            
        return try snapshot.documents.first?.data(as: SessionFS.self)
    }
    
    func fetchMachines() -> AnyPublisher<[MachineFS], Error> {
        let subject = PassthroughSubject<[MachineFS], Error>()
        
        db.collection("machines").order(by: "name").addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            let machines = documents.compactMap { try? $0.data(as: MachineFS.self) }
            subject.send(machines)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func fetchWorkoutLogs(for subscriberId: String? = nil) -> AnyPublisher<[WorkoutLogFS], Error> {
        let subject = PassthroughSubject<[WorkoutLogFS], Error>()
        
        var query: Query = db.collection("workoutLogs")
        
        if let subId = subscriberId {
            query = query.whereField("subscriberId", isEqualTo: subId)
        }
        
        query.order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            let logs = documents.compactMap { try? $0.data(as: WorkoutLogFS.self) }
            subject.send(logs)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func fetchGoals() -> AnyPublisher<[GoalFS], Error> {
        let subject = PassthroughSubject<[GoalFS], Error>()
        
        db.collection("goals").addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            let goals = documents.compactMap { try? $0.data(as: GoalFS.self) }
            subject.send(goals)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func fetchAttendance() -> AnyPublisher<[AttendanceFS], Error> {
        let subject = PassthroughSubject<[AttendanceFS], Error>()
        
        db.collection("attendance").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            let records = documents.compactMap { try? $0.data(as: AttendanceFS.self) }
            subject.send(records)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Async/Await versions (Modern)
    
    @discardableResult
    func addSubscriber(_ subscriber: SubscriberFS) async throws -> DocumentReference {
        return try db.collection("subscribers").addDocument(from: subscriber)
    }
    
    func updateSubscriber(_ subscriber: SubscriberFS) async throws {
        guard let id = subscriber.id else { return }
        try db.collection("subscribers").document(id).setData(from: subscriber)
    }

    func deleteSubscriber(_ id: String) async throws {
        try await db.collection("subscribers").document(id).delete()
    }
    
    func deleteSubscriberAndData(subscriberId: String) async throws {
        // 1. Delete Subscriber
        try await deleteSubscriber(subscriberId)
        
        // 2. Cascade delete related collections
        let batch = db.batch()
        
        // Helper to queue deletes
        func queueDeletes(collection: String) async throws {
            let snapshot = try await db.collection(collection).whereField("subscriberId", isEqualTo: subscriberId).getDocuments()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
        }
        
        // We can't do essentially unlimited batch writing, but for a single user it's likely fine (limit 500).
        // Since we are doing await inside, we might want to do them sequentially or grouped if it gets large.
        // For simplicity now, we'll fetch then delete in separate calls or small batches if API allows.
        // Actually, batch.deleteDocument is just adding to the batch object.
        // We need to fetch references first.
        
        // Sessions
        let sessions = try await db.collection("sessions").whereField("subscriberId", isEqualTo: subscriberId).getDocuments()
        for doc in sessions.documents { batch.deleteDocument(doc.reference) }
        
        // Goals
        let goals = try await db.collection("goals").whereField("subscriberId", isEqualTo: subscriberId).getDocuments()
        for doc in goals.documents { batch.deleteDocument(doc.reference) }
        
        // Attendance
        let attendance = try await db.collection("attendance").whereField("subscriberId", isEqualTo: subscriberId).getDocuments()
        for doc in attendance.documents { batch.deleteDocument(doc.reference) }
        
        // WorkoutLogs
        let logs = try await db.collection("workoutLogs").whereField("subscriberId", isEqualTo: subscriberId).getDocuments()
        for doc in logs.documents { batch.deleteDocument(doc.reference) }
        
        // PhysicalDetails
        let details = try await db.collection("physicalDetails").whereField("subscriberId", isEqualTo: subscriberId).getDocuments()
        for doc in details.documents { batch.deleteDocument(doc.reference) }
        
        // CoachNotes
        let notes = try await db.collection("coachNotes").whereField("subscriberId", isEqualTo: subscriberId).getDocuments()
        for doc in notes.documents { batch.deleteDocument(doc.reference) }
        
        try await batch.commit()
    }
    
    // Machines
    @discardableResult
    func addMachine(_ machine: MachineFS) async throws -> DocumentReference {
        return try db.collection("machines").addDocument(from: machine)
    }
    
    func updateMachine(_ machine: MachineFS) async throws {
        guard let id = machine.id else { return }
        try db.collection("machines").document(id).setData(from: machine)
    }
    
    func deleteMachine(_ id: String) async throws {
        try await db.collection("machines").document(id).delete()
    }
    
    func resetMachines() async throws {
        // 1. Fetch all existing machines
        let snapshot = try await db.collection("machines").getDocuments()
        let documents = snapshot.documents
        
        // 2. Delete in batches of 400 to respect Firestore limit of 500
        let batchSize = 400
        var batch = db.batch()
        var count = 0
        
        for doc in documents {
            batch.deleteDocument(doc.reference)
            count += 1
            
            if count >= batchSize {
                try await batch.commit()
                batch = db.batch()
                count = 0
            }
        }
        
        // Commit any remaining deletions
        if count > 0 {
            try await batch.commit()
        }
        
        // 3. Add default machines (fresh batch)
        batch = db.batch()
        for name in ExerciseHelper.defaultExercises {
            let newDocRef = db.collection("machines").document()
            let machine = MachineFS(
                id: newDocRef.documentID,
                name: name,
                iconName: "dumbbell.fill",
                category: "General",
                machineDescription: "",
                isCustom: false
            )
            try batch.setData(from: machine, forDocument: newDocRef)
        }
        try await batch.commit()
    }
    
    // Sessions
    @discardableResult
    func addSession(_ session: SessionFS) async throws -> DocumentReference {
        return try db.collection("sessions").addDocument(from: session)
    }
    
    func updateSession(_ session: SessionFS) async throws {
        guard let id = session.id else { return }
        try db.collection("sessions").document(id).setData(from: session)
    }
    
    // Auxiliary
    @discardableResult
    func addPhysicalDetail(_ detail: PhysicalDetailFS) async throws -> DocumentReference {
        return try db.collection("physicalDetails").addDocument(from: detail)
    }
    
    @discardableResult
    func addWorkoutLog(_ log: WorkoutLogFS) async throws -> DocumentReference {
        return try db.collection("workoutLogs").addDocument(from: log)
    }
    
    @discardableResult
    func addGoal(_ goal: GoalFS) async throws -> DocumentReference {
        return try db.collection("goals").addDocument(from: goal)
    }
    
    @discardableResult
    func addAttendance(_ attendance: AttendanceFS) async throws -> DocumentReference {
        return try db.collection("attendance").addDocument(from: attendance)
    }
    
    @discardableResult
    func addCoachNote(_ note: CoachNoteFS) async throws -> DocumentReference {
        return try db.collection("coachNotes").addDocument(from: note)
    }

    // MARK: - Update & Delete Helpers

    func updateGoal(_ goal: GoalFS) async throws {
        guard let id = goal.id else { return }
        try db.collection("goals").document(id).setData(from: goal)
    }

    func deleteGoal(_ id: String) async throws {
        try await db.collection("goals").document(id).delete()
    }

    func deletePhysicalDetail(_ id: String) async throws {
        try await db.collection("physicalDetails").document(id).delete()
    }
    
    func deleteAttendance(_ id: String) async throws {
        try await db.collection("attendance").document(id).delete()
    }

    func updateCoachNote(_ note: CoachNoteFS) async throws {
        guard let id = note.id else { return }
        try db.collection("coachNotes").document(id).setData(from: note)
    }

    func deleteCoachNote(_ id: String) async throws {
        try await db.collection("coachNotes").document(id).delete()
    }

    // MARK: - Training Courses
    func fetchAllCourses() -> AnyPublisher<[TrainingCourseFS], Error> {
        let subject = PassthroughSubject<[TrainingCourseFS], Error>()
        
        db.collection("trainingCourses")
            .order(by: "createdDate", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                let courses = snapshot?.documents.compactMap { try? $0.data(as: TrainingCourseFS.self) } ?? []
                subject.send(courses)
            }
        
        return subject.eraseToAnyPublisher()
    }
    
    func addCourse(_ course: TrainingCourseFS) async throws -> String {
        let docRef = try db.collection("trainingCourses").addDocument(from: course)
        return docRef.documentID
    }
    
    func updateCourse(_ course: TrainingCourseFS) async throws {
        guard let id = course.id else { return }
        try db.collection("trainingCourses").document(id).setData(from: course)
    }

    func deleteCourse(_ id: String) async throws {
        try await db.collection("trainingCourses").document(id).delete()
    }
    
    // MARK: - Migration Helper Methods (return document IDs)
    
    /// Save subscriber and return document ID
    func saveSubscriber(_ subscriber: SubscriberFS) async throws -> String {
        if let id = subscriber.id, !id.isEmpty {
            try db.collection("subscribers").document(id).setData(from: subscriber)
            return id
        } else {
            let docRef = try db.collection("subscribers").addDocument(from: subscriber)
            return docRef.documentID
        }
    }
    
    /// Save machine and return document ID
    func saveMachine(_ machine: MachineFS) async throws -> String {
        if let id = machine.id, !id.isEmpty {
            try db.collection("machines").document(id).setData(from: machine)
            return id
        } else {
            let docRef = try db.collection("machines").addDocument(from: machine)
            return docRef.documentID
        }
    }
    
    /// Save course and return document ID
    func saveCourse(_ course: TrainingCourseFS) async throws {
        if let id = course.id, !id.isEmpty {
            try db.collection("trainingCourses").document(id).setData(from: course)
        } else {
            _ = try db.collection("trainingCourses").addDocument(from: course)
        }
    }
    
    /// Save physical detail and return document ID
    func savePhysicalDetail(_ detail: PhysicalDetailFS) async throws -> String {
        if let id = detail.id, !id.isEmpty {
            try db.collection("physicalDetails").document(id).setData(from: detail)
            return id
        } else {
            let docRef = try db.collection("physicalDetails").addDocument(from: detail)
            return docRef.documentID
        }
    }
    
    /// Save goal and return document ID
    func saveGoal(_ goal: GoalFS) async throws -> String {
        if let id = goal.id, !id.isEmpty {
            try db.collection("goals").document(id).setData(from: goal)
            return id
        } else {
            let docRef = try db.collection("goals").addDocument(from: goal)
            return docRef.documentID
        }
    }
    
    /// Save attendance and return document ID
    func saveAttendance(_ attendance: AttendanceFS) async throws -> String {
        if let id = attendance.id, !id.isEmpty {
            try db.collection("attendance").document(id).setData(from: attendance)
            return id
        } else {
            let docRef = try db.collection("attendance").addDocument(from: attendance)
            return docRef.documentID
        }
    }
    
    /// Save coach note and return document ID
    func saveCoachNote(_ note: CoachNoteFS) async throws -> String {
        if let id = note.id, !id.isEmpty {
            try db.collection("coachNotes").document(id).setData(from: note)
            return id
        } else {
            let docRef = try db.collection("coachNotes").addDocument(from: note)
            return docRef.documentID
        }
    }
    
    /// Save workout log and return document ID
    func saveWorkoutLog(_ log: WorkoutLogFS) async throws -> String {
        if let id = log.id, !id.isEmpty {
            try db.collection("workoutLogs").document(id).setData(from: log)
            return id
        } else {
            let docRef = try db.collection("workoutLogs").addDocument(from: log)
            return docRef.documentID
        }
    }
    
    /// Save session and return document ID
    func saveSession(_ session: SessionFS) async throws -> String {
        if let id = session.id, !id.isEmpty {
            try db.collection("sessions").document(id).setData(from: session)
            return id
        } else {
            let docRef = try db.collection("sessions").addDocument(from: session)
            return docRef.documentID
        }
    }
    
    /// Save workout session and return document ID
    func saveWorkoutSession(_ session: WorkoutSessionFS) async throws -> String {
        if let id = session.id, !id.isEmpty {
            try db.collection("workoutSessions").document(id).setData(from: session)
            return id
        } else {
            let docRef = try db.collection("workoutSessions").addDocument(from: session)
            return docRef.documentID
        }
    }

    // MARK: - Legacy Migration (Rescue Data)
    func migrateLegacyWorkoutSessions() async throws {
        // 1. Fetch all legacy workout sessions
        let snapshot = try await db.collection("workoutSessions").getDocuments()
        let legacySessions = snapshot.documents.compactMap { try? $0.data(as: WorkoutSessionFS.self) }
        
        if legacySessions.isEmpty { return }
        
        print("🚑 Found \(legacySessions.count) legacy workout sessions to rescue.")
        
        for legacy in legacySessions {
            // Check if this session already exists in 'sessions' collection (by date/subscriber)
            // We use findSession(subscriberId:date:)
            
            // Logic:
            // Convert legacy (single machine) to SessionFS (session with 1 exercise)
            
             var exercise = SessionExerciseFS(
                name: legacy.machineName,
                machineName: legacy.machineName,
                machineCategory: "Unknown",
                rhythm: 0,
                weight: legacy.weight,
                intensity: "Normal",
                targetDuration: legacy.targetDuration, // Double?
                enduranceTime: legacy.enduranceTime, // Double?
                isCompleted: true,
                orderIndex: 0,
                notes: legacy.notes,
                plusTenCount: legacy.plusTenCount
            )
            
            // Check if a session exists for this subscriber on this date
            if var existingSession = try await findSession(subscriberId: legacy.subscriberId, date: legacy.date) {
                // Determine if we should append
                // Check if this exercise is already there (simple check: machineName + weight + endurance match?)
                
                var exercises = existingSession.exercises ?? []
                // deduplication check
                let isDuplicate = exercises.contains { ex in
                    ex.machineName == legacy.machineName &&
                    ex.enduranceTime == legacy.enduranceTime &&
                    ex.weight == legacy.weight
                }
                
                if !isDuplicate {
                     // Append
                     exercise.orderIndex = exercises.count
                     exercises.append(exercise)
                     existingSession.exercises = exercises
                     try await updateSession(existingSession)
                     print("   -> Merged legacy session into existing session.")
                }
                
            } else {
                // Create new session
                let newSession = SessionFS(
                    date: legacy.date,
                    status: "Completed",
                    title: "Workout",
                    subscriberId: legacy.subscriberId,
                    exercises: [exercise]
                )
                try await addSession(newSession)
                print("   -> Created new session from legacy session.")
            }
            
             // Delete the legacy document to prevent re-migration
             if let id = legacy.id {
                 try await db.collection("workoutSessions").document(id).delete()
             }
        }
    }
    // MARK: - Data Fixes
    
    func fixLegacyExerciseNames() async {
        print("🔧 Starting Legacy Exercise Name Fix...")
        do {
            let snapshot = try await db.collection("sessions").getDocuments()
            print("🔧 Found \(snapshot.documents.count) sessions to check.")
            
            let batch = db.batch()
            var updateCount = 0
            
            for doc in snapshot.documents {
                if var session = try? doc.data(as: SessionFS.self), let exercises = session.exercises {
                    var hasChanges = false
                    var updatedExercises = exercises
                    
                    for (index, exercise) in exercises.enumerated() {
                        var newName = exercise.name
                        
                        // Mapping Rules
                        if exercise.name == "Back Exstenstion" { newName = "Back Extension" }
                        else if exercise.name == "Back extension" { newName = "Back Extension" } // Casing fix
                        else if exercise.name == "Addiction" { newName = "Adduction" }
                        else if exercise.name == "Addiction in" { newName = "Adduction" }
                        else if exercise.name == "Abduction out" { newName = "Abduction" }
                        else if exercise.name == "Dumbells" { newName = "Dumbbells" }
                        
                        if newName != exercise.name {
                            print("🔧 Fixing: \(exercise.name) -> \(newName) in session \(doc.documentID)")
                            updatedExercises[index].name = newName
                            hasChanges = true
                        }
                    }
                    
                    if hasChanges {
                        session.exercises = updatedExercises
                        try batch.setData(from: session, forDocument: doc.reference)
                        updateCount += 1
                    }
                }
            }
            
            if updateCount > 0 {
                try await batch.commit()
                print("✅ Successfully updated \(updateCount) sessions with fixed exercise names.")
            } else {
                print("✅ No sessions needed fixing.")
            }
            
        } catch {
            print("⛔️ Error fixing legacy names: \(error)")
        }
    }
}
