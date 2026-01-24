//
//  CloudKitService.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import CloudKit
import Combine

/// CloudKit service for managing Course and Session records
class CloudKitService {
    static let shared = CloudKitService()

    // MARK: - Configuration
    /// CloudKit is enabled
    static var isCloudKitDisabled: Bool = false

    private let container: CKContainer?
    private let privateDatabase: CKDatabase?
    
    // In-memory storage for testing when CloudKit is disabled
    private var inMemoryCourses: [CourseModel] = []
    private var inMemorySessions: [SessionModel] = []

    private init() {
        if Self.isCloudKitDisabled {
            container = nil
            privateDatabase = nil
            print("⚠️ CloudKit is DISABLED - Using in-memory storage for testing")
        } else {
            container = CKContainer.default()
            privateDatabase = container?.privateCloudDatabase
        }
    }

    // MARK: - Account Status

    func getAccountStatus() async throws -> CKAccountStatus {
        if Self.isCloudKitDisabled {
            return .available // Return available for testing
        }
        guard let container = container else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        return try await container.accountStatus()
    }
    

    // MARK: - Course Operations

    func saveCourse(_ course: CourseModel) async throws {
        if Self.isCloudKitDisabled {
            // In-memory storage
            if let index = inMemoryCourses.firstIndex(where: { $0.id == course.id }) {
                // Update existing
                inMemoryCourses[index] = course
            } else {
                // Add new
                inMemoryCourses.append(course)
            }
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        let record = course.updatedRecord()
        let _ = try await privateDatabase.save(record)
    }

    func fetchCourses() async throws -> [CourseModel] {
        if Self.isCloudKitDisabled {
            // Return in-memory courses sorted by creation date
            return inMemoryCourses.sorted { $0.createdAt > $1.createdAt }
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        
        let query = CKQuery(recordType: CourseModel.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let (matchResults, _) = try await privateDatabase.records(matching: query)

        return matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return CourseModel(record: record)
            case .failure:
                return nil
            }
        }
    }

    func updateCourse(_ courseId: CKRecord.ID, title: String? = nil, equipment: [String]? = nil, notes: String? = nil) async throws {
        if Self.isCloudKitDisabled {
            // In-memory storage
            guard let index = inMemoryCourses.firstIndex(where: { $0.id == courseId }) else {
                throw NSError(domain: "CloudKitService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Course not found"])
            }
            let oldCourse = inMemoryCourses[index]
            // Create updated course with new values
            let updatedTitle = title ?? oldCourse.title
            let updatedEquipment = equipment ?? oldCourse.equipment
            let updatedNotes = notes ?? oldCourse.notes
            
            // Create new record with updated values
            let newRecord = CKRecord(recordType: CourseModel.recordType, recordID: courseId)
            newRecord["title"] = updatedTitle
            newRecord["createdAt"] = oldCourse.createdAt
            newRecord["equipment"] = updatedEquipment
            if let updatedNotes = updatedNotes {
                newRecord["notes"] = updatedNotes
            }
            
            let updatedCourse = CourseModel(record: newRecord)
            inMemoryCourses[index] = updatedCourse
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        
        let record = try await privateDatabase.record(for: courseId)

        if let title = title {
            record["title"] = title
        }
        if let equipment = equipment {
            record["equipment"] = equipment
        }
        if let notes = notes {
            record["notes"] = notes
        } else {
            record["notes"] = nil
        }

        let _ = try await privateDatabase.save(record)
    }

    func deleteCourse(_ courseId: CKRecord.ID) async throws {
        if Self.isCloudKitDisabled {
            // In-memory storage
            inMemoryCourses.removeAll { $0.id == courseId }
            // Also delete associated sessions
            inMemorySessions.removeAll { $0.courseRef.recordID == courseId }
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        try await privateDatabase.deleteRecord(withID: courseId)
    }

    // MARK: - Session Operations

    func createSession(from courseId: CKRecord.ID, title: String, rhythmUpSeconds: Int = 10, rhythmDownSeconds: Int = 10) async throws -> SessionModel {
        if Self.isCloudKitDisabled {
            // In-memory storage
            // Find the course to get equipment
            guard let course = inMemoryCourses.first(where: { $0.id == courseId }) else {
                throw NSError(domain: "CloudKitService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Course not found"])
            }
            
            let session = SessionModel(
                courseId: courseId,
                title: title,
                equipmentSnapshot: course.equipment,
                rhythmUpSeconds: rhythmUpSeconds,
                rhythmDownSeconds: rhythmDownSeconds
            )
            inMemorySessions.append(session)
            return session
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        
        // Fetch the course to get current equipment
        let courseRecord = try await privateDatabase.record(for: courseId)
        let equipmentSnapshot = courseRecord["equipment"] as? [String] ?? []

        let session = SessionModel(
            courseId: courseId,
            title: title,
            equipmentSnapshot: equipmentSnapshot,
            rhythmUpSeconds: rhythmUpSeconds,
            rhythmDownSeconds: rhythmDownSeconds
        )

        let savedRecord = try await privateDatabase.save(session.updatedRecord())
        return SessionModel(record: savedRecord)
    }

    func fetchSessions(for courseId: CKRecord.ID) async throws -> [SessionModel] {
        if Self.isCloudKitDisabled {
            // In-memory storage
            return inMemorySessions
                .filter { $0.courseRef.recordID == courseId }
                .sorted { $0.createdAt > $1.createdAt }
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        
        let courseRef = CKRecord.Reference(recordID: courseId, action: .deleteSelf)
        let predicate = NSPredicate(format: "courseRef == %@", courseRef)
        let query = CKQuery(recordType: SessionModel.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let (matchResults, _) = try await privateDatabase.records(matching: query)

        return matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return SessionModel(record: record)
            case .failure:
                return nil
            }
        }
    }

    func saveSession(_ session: SessionModel) async throws {
        if Self.isCloudKitDisabled {
            // In-memory storage
            if let index = inMemorySessions.firstIndex(where: { $0.id == session.id }) {
                inMemorySessions[index] = session
            } else {
                inMemorySessions.append(session)
            }
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        let record = session.updatedRecord()
        let _ = try await privateDatabase.save(record)
    }

    func saveSessionResults(_ sessionId: CKRecord.ID, results: String, completedAt: Date? = nil) async throws {
        if Self.isCloudKitDisabled {
            // In-memory storage
            guard let index = inMemorySessions.firstIndex(where: { $0.id == sessionId }) else {
                throw NSError(domain: "CloudKitService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Session not found"])
            }
            let oldSession = inMemorySessions[index]
            // Create new record with updated values
            let newRecord = CKRecord(recordType: SessionModel.recordType, recordID: sessionId)
            newRecord["courseRef"] = oldSession.courseRef
            newRecord["title"] = oldSession.title
            newRecord["createdAt"] = oldSession.createdAt
            newRecord["equipmentSnapshot"] = oldSession.equipmentSnapshot
            newRecord["rhythmUpSeconds"] = oldSession.rhythmUpSeconds
            newRecord["rhythmDownSeconds"] = oldSession.rhythmDownSeconds
            newRecord["results"] = results
            if let completedAt = completedAt {
                newRecord["completedAt"] = completedAt
            }
            let updatedSession = SessionModel(record: newRecord)
            inMemorySessions[index] = updatedSession
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        let record = try await privateDatabase.record(for: sessionId)
        record["results"] = results
        if let completedAt = completedAt {
            record["completedAt"] = completedAt
        }
        let _ = try await privateDatabase.save(record)
    }

    func deleteSession(_ sessionId: CKRecord.ID) async throws {
        if Self.isCloudKitDisabled {
            // In-memory storage
            inMemorySessions.removeAll { $0.id == sessionId }
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        try await privateDatabase.deleteRecord(withID: sessionId)
    }

    // MARK: - Utility Methods

    func fetchRecord(_ recordId: CKRecord.ID) async throws -> CKRecord {
        if Self.isCloudKitDisabled {
            // Try to find in courses first
            if let course = inMemoryCourses.first(where: { $0.id == recordId }) {
                return course.record
            }
            // Then try sessions
            if let session = inMemorySessions.first(where: { $0.id == recordId }) {
                return session.record
            }
            throw NSError(domain: "CloudKitService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Record not found"])
        }
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not initialized"])
        }
        return try await privateDatabase.record(for: recordId)
    }

    // MARK: - Error Handling

    func handleCloudKitError(_ error: Error) -> String {
        let ckError = error as? CKError
        switch ckError?.code {
        case .networkUnavailable:
            return "Network connection unavailable. Changes will sync when connection is restored."
        case .networkFailure:
            return "Network error occurred. Please check your connection."
        case .serviceUnavailable:
            return "iCloud service is temporarily unavailable."
        case .notAuthenticated:
            return "Not signed in to iCloud. Please sign in to sync data."
        case .permissionFailure:
            return "Permission denied. Please check iCloud permissions."
        case .quotaExceeded:
            return "iCloud storage quota exceeded."
        case .zoneBusy:
            return "iCloud is busy. Please try again later."
        case .limitExceeded:
            return "Request limit exceeded. Please try again later."
        default:
            return "An error occurred. Please try again."
        }
    }
}
