//
//  CourseModel.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import CloudKit

/// CloudKit-based Course model
struct CourseModel: Identifiable, Hashable {
    static let recordType = "Course"

    let id: CKRecord.ID
    let record: CKRecord

    var title: String
    var createdAt: Date
    var equipment: [String]
    var notes: String?

    init(record: CKRecord) {
        self.id = record.recordID
        self.record = record
        self.title = record["title"] as? String ?? ""
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.equipment = record["equipment"] as? [String] ?? []
        self.notes = record["notes"] as? String
    }

    init(title: String, equipment: [String] = [], notes: String? = nil) {
        let record = CKRecord(recordType: Self.recordType)
        record["title"] = title
        record["createdAt"] = Date()
        record["equipment"] = equipment
        if let notes = notes {
            record["notes"] = notes
        }

        self.id = record.recordID
        self.record = record
        self.title = title
        self.createdAt = Date()
        self.equipment = equipment
        self.notes = notes
    }

    /// Update the record with current values
    func updatedRecord() -> CKRecord {
        let record = self.record
        record["title"] = title
        record["createdAt"] = createdAt
        record["equipment"] = equipment
        if let notes = notes {
            record["notes"] = notes
        } else {
            record["notes"] = nil
        }
        return record
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CourseModel, rhs: CourseModel) -> Bool {
        lhs.id == rhs.id
    }
}

/// CloudKit-based Session model
struct SessionModel: Identifiable, Hashable {
    static let recordType = "Session"

    let id: CKRecord.ID
    let record: CKRecord

    var courseRef: CKRecord.Reference
    var title: String
    var createdAt: Date
    var equipmentSnapshot: [String]
    var rhythmUpSeconds: Int
    var rhythmDownSeconds: Int
    var results: String?
    var completedAt: Date?

    init(record: CKRecord) {
        self.id = record.recordID
        self.record = record
        self.courseRef = record["courseRef"] as! CKRecord.Reference
        self.title = record["title"] as? String ?? ""
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.equipmentSnapshot = record["equipmentSnapshot"] as? [String] ?? []
        self.rhythmUpSeconds = record["rhythmUpSeconds"] as? Int ?? 10
        self.rhythmDownSeconds = record["rhythmDownSeconds"] as? Int ?? 10
        self.results = record["results"] as? String
        self.completedAt = record["completedAt"] as? Date
    }

    init(courseId: CKRecord.ID, title: String, equipmentSnapshot: [String], rhythmUpSeconds: Int = 10, rhythmDownSeconds: Int = 10) {
        let record = CKRecord(recordType: Self.recordType)
        let courseRef = CKRecord.Reference(recordID: courseId, action: .deleteSelf)
        record["courseRef"] = courseRef
        record["title"] = title
        record["createdAt"] = Date()
        record["equipmentSnapshot"] = equipmentSnapshot
        record["rhythmUpSeconds"] = rhythmUpSeconds
        record["rhythmDownSeconds"] = rhythmDownSeconds

        self.id = record.recordID
        self.record = record
        self.courseRef = courseRef
        self.title = title
        self.createdAt = Date()
        self.equipmentSnapshot = equipmentSnapshot
        self.rhythmUpSeconds = rhythmUpSeconds
        self.rhythmDownSeconds = rhythmDownSeconds
        self.results = nil
        self.completedAt = nil
    }

    /// Update the record with current values
    func updatedRecord() -> CKRecord {
        let record = self.record
        record["courseRef"] = courseRef
        record["title"] = title
        record["createdAt"] = createdAt
        record["equipmentSnapshot"] = equipmentSnapshot
        record["rhythmUpSeconds"] = rhythmUpSeconds
        record["rhythmDownSeconds"] = rhythmDownSeconds
        if let results = results {
            record["results"] = results
        }
        if let completedAt = completedAt {
            record["completedAt"] = completedAt
        }
        return record
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SessionModel, rhs: SessionModel) -> Bool {
        lhs.id == rhs.id
    }
}
