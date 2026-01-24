//
//  SubscriberOnboardingView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

/// Main coordinator view for multi-step subscriber onboarding
struct SubscriberOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var onboardingData: OnboardingData
    @Binding var currentStep: Int
    var onComplete: (() -> Void)? = nil
    var onDismissRequest: (() -> Void)? = nil
    
    let totalSteps = 5
    
    // Track completion to prevent draft saving on success
    @State private var isCompleted = false
    // Track if user explicitly discarded/cancelled
    @State private var isDiscarding = false
    
    // Save draft when step changes
    private func saveDraft() {
        SubscriberDraftManager.saveDraft(onboardingData, step: currentStep)
    }
    
    init(onboardingData: Binding<OnboardingData>, currentStep: Binding<Int>? = nil, onComplete: (() -> Void)? = nil, onDismissRequest: (() -> Void)? = nil) {
        self._onboardingData = onboardingData
        if let stepBinding = currentStep {
            self._currentStep = stepBinding
        } else {
            self._currentStep = Binding(
                get: { 0 },
                set: { _ in }
            )
        }
        self.onComplete = onComplete
        self.onDismissRequest = onDismissRequest
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.orange))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Step indicator text
                HStack {
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Current step view
                Group {
                    switch currentStep {
                    case 0:
                        BasicInfoStepView(data: $onboardingData, onNext: {
                            saveDraft()
                            withAnimation {
                                currentStep += 1
                            }
                        })
                    case 1:
                        PhysicalInfoStepView(data: $onboardingData, onNext: {
                            saveDraft()
                            if currentStep < totalSteps - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        })
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if currentStep > 0 {
                                     Button("Back") {
                                         saveDraft()
                                         withAnimation {
                                             currentStep -= 1
                                         }
                                     }
                                }
                            }
                        }
                    case 2:
                        HealthInfoStepView(data: $onboardingData, onBack: {
                            saveDraft()
                            withAnimation {
                                currentStep -= 1
                            }
                        }, onNext: {
                            saveDraft()
                            if currentStep < totalSteps - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        })
                    case 3:
                        FitnessGoalsStepView(data: $onboardingData, onBack: {
                            saveDraft()
                            withAnimation {
                                currentStep -= 1
                            }
                        }, onNext: {
                            saveDraft()
                            if currentStep < totalSteps - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        })
                    case 4:
                        SignatureStepView(data: $onboardingData, onBack: {
                            saveDraft()
                            withAnimation {
                                currentStep -= 1
                            }
                        }, onComplete: {
                            // Onboarding complete - call completion handler
                            // Don't dismiss here, let the parent view handle the transition
                            isCompleted = true
                            onComplete?()
                        })
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("New Subscriber")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        isDiscarding = true
                        SubscriberDraftManager.clearDraft()
                        // Call onDismissRequest if provided, otherwise dismiss directly
                        if let onDismissRequest = onDismissRequest {
                            onDismissRequest()
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.red) // Make "Discard" red to indicate destructive action
                }
            }
            .onChange(of: onboardingData) { oldValue, newValue in
                // Auto-save draft when data changes
                if !isDiscarding && !isCompleted {
                    saveDraft()
                }
            }
            .onDisappear {
                // Save draft when view disappears, but only if not completed AND not discarding
                if !isCompleted && !isDiscarding {
                    saveDraft()
                }
            }
        }
    }
}

/// Temporary data structure to hold onboarding data during the flow
struct OnboardingData: Codable, Equatable {
    // Basic Information
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var dateOfBirth: Date = Date()
    var gender: String = ""
    var photoData: Data?
    var planType: String = "Monthly"
    var howDidYouHearAboutUs: String = ""
    var referrerName: String = ""
    var otherReferralSource: String = ""
    
    // Physical Information
    var height: String = ""
    var weight: String = ""
    var age: String = ""
    var heartRate: String = ""
    var bodyFatPercentage: String = ""
    var muscleMassPercentage: String = ""
    var previousActivityLevel: String = "Sedentary"
    
    // Health Information (stored as arrays for Codable)
    private var selectedHealthConditionsArray: [String] = []
    var selectedHealthConditions: Set<String> {
        get { Set(selectedHealthConditionsArray) }
        set { selectedHealthConditionsArray = Array(newValue) }
    }
    var pastInjuries: String = ""
    var previousSurgeries: String = ""
    var allergies: String = ""
    var currentMedications: String = ""
    var pregnancyStatus: Bool = false
    
    // Fitness Goals (stored as arrays for Codable)
    private var selectedGoalsArray: [String] = []
    var selectedGoals: Set<String> {
        get { Set(selectedGoalsArray) }
        set { selectedGoalsArray = Array(newValue) }
    }
    
    // Signature
    var signatureData: Data? = nil
    
    // CodingKeys for proper encoding/decoding
    enum CodingKeys: String, CodingKey {
        case name, email, phone, dateOfBirth, gender, photoData, planType
        case howDidYouHearAboutUs, referrerName, otherReferralSource
        case height, weight, age, heartRate, bodyFatPercentage, muscleMassPercentage, previousActivityLevel
        case selectedHealthConditionsArray, pastInjuries, previousSurgeries, allergies, currentMedications, pregnancyStatus
        case selectedGoalsArray, signatureData
    }
    
    // Equatable conformance
    static func == (lhs: OnboardingData, rhs: OnboardingData) -> Bool {
        return lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.phone == rhs.phone &&
               lhs.dateOfBirth == rhs.dateOfBirth &&
               lhs.gender == rhs.gender &&
               lhs.photoData == rhs.photoData &&
               lhs.planType == rhs.planType &&
               lhs.howDidYouHearAboutUs == rhs.howDidYouHearAboutUs &&
               lhs.referrerName == rhs.referrerName &&
               lhs.otherReferralSource == rhs.otherReferralSource &&
               lhs.height == rhs.height &&
               lhs.weight == rhs.weight &&
               lhs.age == rhs.age &&
               lhs.heartRate == rhs.heartRate &&
               lhs.bodyFatPercentage == rhs.bodyFatPercentage &&
               lhs.muscleMassPercentage == rhs.muscleMassPercentage &&
               lhs.previousActivityLevel == rhs.previousActivityLevel &&
               lhs.selectedHealthConditionsArray.sorted() == rhs.selectedHealthConditionsArray.sorted() &&
               lhs.pastInjuries == rhs.pastInjuries &&
               lhs.previousSurgeries == rhs.previousSurgeries &&
               lhs.allergies == rhs.allergies &&
               lhs.currentMedications == rhs.currentMedications &&
               lhs.pregnancyStatus == rhs.pregnancyStatus &&
               lhs.selectedGoalsArray.sorted() == rhs.selectedGoalsArray.sorted() &&
               lhs.signatureData == rhs.signatureData
    }
    
    // Validation helpers
    var isPhysicalInfoValid: Bool {
        !height.isEmpty && !weight.isEmpty && !age.isEmpty
    }
    
    var isHealthInfoValid: Bool {
        true // Health info is optional
    }
    
    var isFitnessGoalsValid: Bool {
        !selectedGoals.isEmpty
    }
    
    var isSignatureValid: Bool {
        signatureData != nil
    }
}

#Preview {
    SubscriberOnboardingView(onboardingData: .constant(OnboardingData()), currentStep: .constant(0), onComplete: nil)
}
