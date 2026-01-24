//
//  SubscriberModelTests.swift
//  CoachAppTests
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import XCTest
import SwiftData
@testable import CoachApp

final class SubscriberModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        let schema = Schema([Subscriber.self, Goal.self, PhysicalDetail.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    func testSubscriberCreation() {
        let subscriber = Subscriber(
            name: "Test User",
            email: "test@example.com",
            phone: "1234567890"
        )
        
        XCTAssertEqual(subscriber.name, "Test User")
        XCTAssertEqual(subscriber.email, "test@example.com")
        XCTAssertEqual(subscriber.phone, "1234567890")
        XCTAssertEqual(subscriber.planType, "Monthly")
        XCTAssertEqual(subscriber.paymentStatus, "Active")
    }
    
    func testSubscriberRelationships() {
        let subscriber = Subscriber(name: "Test User")
        let goal = Goal(title: "Test Goal", targetValue: 100, currentValue: 50, unit: "kg")
        goal.subscriber = subscriber
        
        modelContext.insert(subscriber)
        modelContext.insert(goal)
        
        XCTAssertNotNil(subscriber.goals)
        XCTAssertEqual(subscriber.goals?.count, 1)
        XCTAssertEqual(subscriber.goals?.first?.title, "Test Goal")
    }
    
    func testSubscriberCascadeDelete() {
        let subscriber = Subscriber(name: "Test User")
        let goal = Goal(title: "Test Goal", targetValue: 100, currentValue: 50, unit: "kg")
        goal.subscriber = subscriber
        
        modelContext.insert(subscriber)
        modelContext.insert(goal)
        
        modelContext.delete(subscriber)
        
        // Goals should be deleted due to cascade rule
        let fetchDescriptor = FetchDescriptor<Goal>()
        let goals = try? modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(goals?.count, 0)
    }
}

