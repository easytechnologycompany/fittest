//
//  GoalProgressCalculatorTests.swift
//  CoachAppTests
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import XCTest
@testable import CoachApp

final class GoalProgressCalculatorTests: XCTestCase {
    
    func testIncreaseGoalProgress() {
        // Test: Start 70kg -> Target 83kg, Current 76.5kg = 50% progress
        let progress = GoalProgressCalculator.calculateProgress(
            currentValue: 76.5,
            targetValue: 83.0,
            startingValue: 70.0,
            history: nil
        )
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Should be 50% progress")
    }
    
    func testDecreaseGoalProgress() {
        // Test: Start 83kg -> Target 70kg, Current 76.5kg = 50% progress
        let progress = GoalProgressCalculator.calculateProgress(
            currentValue: 76.5,
            targetValue: 70.0,
            startingValue: 83.0,
            history: nil
        )
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Should be 50% progress")
    }
    
    func testGoalCompleted() {
        // Test: Start 70kg -> Target 83kg, Current 83kg = 100% progress
        let progress = GoalProgressCalculator.calculateProgress(
            currentValue: 83.0,
            targetValue: 83.0,
            startingValue: 70.0,
            history: nil
        )
        XCTAssertEqual(progress, 1.0, accuracy: 0.01, "Should be 100% complete")
    }
    
    func testGoalNotStarted() {
        // Test: Start 70kg -> Target 83kg, Current 70kg = 0% progress
        let progress = GoalProgressCalculator.calculateProgress(
            currentValue: 70.0,
            targetValue: 83.0,
            startingValue: 70.0,
            history: nil
        )
        XCTAssertEqual(progress, 0.0, accuracy: 0.01, "Should be 0% progress")
    }
    
    func testProgressOverTarget() {
        // Test: Start 70kg -> Target 83kg, Current 90kg = 100% (capped)
        let progress = GoalProgressCalculator.calculateProgress(
            currentValue: 90.0,
            targetValue: 83.0,
            startingValue: 70.0,
            history: nil
        )
        XCTAssertEqual(progress, 1.0, accuracy: 0.01, "Should be capped at 100%")
    }
    
    func testProgressBelowStart() {
        // Test: Start 83kg -> Target 70kg, Current 60kg = 100% (capped)
        let progress = GoalProgressCalculator.calculateProgress(
            currentValue: 60.0,
            targetValue: 70.0,
            startingValue: 83.0,
            history: nil
        )
        XCTAssertEqual(progress, 1.0, accuracy: 0.01, "Should be capped at 100%")
    }
    
    func testZeroTargetValue() {
        // Test: Zero target should return 0 progress
        let progress = GoalProgressCalculator.calculateProgress(
            currentValue: 50.0,
            targetValue: 0.0,
            startingValue: 0.0,
            history: nil
        )
        XCTAssertEqual(progress, 0.0, accuracy: 0.01, "Should return 0 for zero target")
    }
}

