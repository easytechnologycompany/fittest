//
//  AppErrorTests.swift
//  CoachAppTests
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import XCTest
@testable import CoachApp

final class AppErrorTests: XCTestCase {
    
    func testDataModelError() {
        let error = AppError.dataModelError("Test error")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Data Model Error") ?? false)
        XCTAssertNotNil(error.recoverySuggestion)
    }
    
    func testSaveError() {
        let error = AppError.saveError("Failed to save")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Save Error") ?? false)
        XCTAssertNotNil(error.recoverySuggestion)
    }
    
    func testDeleteError() {
        let error = AppError.deleteError("Failed to delete")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Delete Error") ?? false)
        XCTAssertNotNil(error.recoverySuggestion)
    }
    
    func testValidationError() {
        let error = AppError.validationError("Invalid input")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Validation Error") ?? false)
        XCTAssertNotNil(error.recoverySuggestion)
    }
    
    func testErrorHandlerSafeExecute() {
        // Test successful execution
        let result = ErrorHandler.safeExecute({
            return "success"
        }, context: "test", defaultValue: "default")
        XCTAssertEqual(result, "success")
        
        // Test error handling
        let errorResult = ErrorHandler.safeExecute({
            throw AppError.validationError("Test")
        }, context: "test", defaultValue: "default")
        XCTAssertEqual(errorResult, "default")
    }
}

