//
//  AppError.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation

/// Application-wide error types
enum AppError: LocalizedError {
    case dataModelError(String)
    case saveError(String)
    case deleteError(String)
    case validationError(String)
    case cloudKitError(String)
    case fileExportError(String)
    
    var errorDescription: String? {
        switch self {
        case .dataModelError(let message):
            return "Data Model Error: \(message)"
        case .saveError(let message):
            return "Save Error: \(message)"
        case .deleteError(let message):
            return "Delete Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .cloudKitError(let message):
            return "CloudKit Error: \(message)"
        case .fileExportError(let message):
            return "Export Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataModelError:
            return "Please try restarting the app. If the problem persists, contact support."
        case .saveError:
            return "Please check your input and try again."
        case .deleteError:
            return "The item may have already been deleted. Please refresh and try again."
        case .validationError:
            return "Please check the required fields and try again."
        case .cloudKitError:
            return "Please check your internet connection and iCloud settings."
        case .fileExportError:
            return "Please ensure you have sufficient storage space and try again."
        }
    }
}

/// Error handling utilities
struct ErrorHandler {
    /// Handle and log errors
    static func handle(_ error: Error, context: String = "") {
        #if DEBUG
        print("❌ Error in \(context): \(error.localizedDescription)")
        if let appError = error as? AppError {
            print("   Recovery: \(appError.recoverySuggestion ?? "None")")
        }
        #endif
        
        // In production, you might want to send to crash reporting service
        // Crashlytics.shared().recordError(error)
    }
    
    /// Safely execute a throwing operation with error handling
    static func safeExecute<T>(
        _ operation: () throws -> T,
        context: String = "",
        defaultValue: T? = nil
    ) -> T? {
        do {
            return try operation()
        } catch {
            handle(error, context: context)
            return defaultValue
        }
    }
}

