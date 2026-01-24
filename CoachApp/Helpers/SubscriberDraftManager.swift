//
//  SubscriberDraftManager.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation

/// Manages draft subscriber data persistence
class SubscriberDraftManager {
    private static let draftKey = "subscriberDraftData"
    private static let draftStepKey = "subscriberDraftStep"
    
    /// Save draft onboarding data
    static func saveDraft(_ data: OnboardingData, step: Int) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            UserDefaults.standard.set(encoded, forKey: draftKey)
            UserDefaults.standard.set(step, forKey: draftStepKey)
        }
    }
    
    /// Load draft onboarding data
    static func loadDraft() -> (data: OnboardingData?, step: Int) {
        guard let data = UserDefaults.standard.data(forKey: draftKey),
              let decoded = try? JSONDecoder().decode(OnboardingData.self, from: data) else {
            return (nil, 0)
        }
        let step = UserDefaults.standard.integer(forKey: draftStepKey)
        return (decoded, step)
    }
    
    /// Clear draft data
    static func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
        UserDefaults.standard.removeObject(forKey: draftStepKey)
    }
    
    /// Check if draft exists
    static func hasDraft() -> Bool {
        return UserDefaults.standard.data(forKey: draftKey) != nil
    }
}

