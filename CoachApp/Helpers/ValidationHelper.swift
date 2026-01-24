//
//  ValidationHelper.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation

/// Helper for input validation
struct ValidationHelper {
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate phone number (basic validation)
    static func isValidPhone(_ phone: String) -> Bool {
        // Remove common phone number characters
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        return cleaned.count >= 7 && cleaned.count <= 15
    }
    
    /// Validate that a value is within a reasonable range
    static func isValidMeasurement(_ value: Double, min: Double = 0, max: Double = 1000) -> Bool {
        return value >= min && value <= max
    }
    
    /// Validate date is not in the future (for records)
    static func isValidRecordDate(_ date: Date) -> Bool {
        return date <= Date()
    }
    
    /// Validate date is in the future (for goals)
    static func isValidFutureDate(_ date: Date) -> Bool {
        return date > Date()
    }
}
