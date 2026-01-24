//
//  CoachNote.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class CoachNote {
    var date: Date = Date()
    var title: String = ""
    var content: String = ""
    var category: String = "General" // e.g., "Progress", "Concern", "Achievement", "General"
    
    // Relationship
    @Relationship(inverse: \Subscriber.notes) var subscriber: Subscriber?
    
    init(date: Date = Date(), title: String = "", content: String = "", category: String = "General") {
        self.date = date
        self.title = title
        self.content = content
        self.category = category
    }
}

