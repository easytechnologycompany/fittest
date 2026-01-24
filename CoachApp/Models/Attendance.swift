//
//  Attendance.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class Attendance {
    var date: Date = Date()
    var checkInTime: Date?
    var checkOutTime: Date?
    var notes: String = ""
    
    // Relationship
    @Relationship(inverse: \Subscriber.attendance) var subscriber: Subscriber?
    
    init(date: Date = Date(), checkInTime: Date? = nil, checkOutTime: Date? = nil, notes: String = "") {
        self.date = date
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.notes = notes
    }
    
    var duration: TimeInterval? {
        guard let checkIn = checkInTime, let checkOut = checkOutTime else { return nil }
        return checkOut.timeIntervalSince(checkIn)
    }
}

