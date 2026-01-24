//
//  HealthInfoStepView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

struct HealthInfoStepView: View {
    @Binding var data: OnboardingData
    var onBack: () -> Void
    var onNext: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    let healthConditions = [
        "Diabetes",
        "High Blood Pressure",
        "Heart Disease",
        "Heart Valve Issues",
        "Heart Function Problems",
        "Brain Function Problems",
        "Herniated Disc",
        "Joint Dislocation",
        "Lower Back Disc Herniation",
        "Joint Pain",
        "Shoulder Pain",
        "Back Pain",
        "Knee Pain",
        "Dislocation / Osteoarthritis"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Health Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Please select any health conditions that apply to you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Health Conditions Checkboxes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health Conditions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(healthConditions, id: \.self) { condition in
                            HealthConditionRow(
                                condition: condition,
                                isSelected: data.selectedHealthConditions.contains(condition),
                                onToggle: {
                                    if data.selectedHealthConditions.contains(condition) {
                                        data.selectedHealthConditions.remove(condition)
                                    } else {
                                        data.selectedHealthConditions.insert(condition)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical)
                    
                    // Past Injuries
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Past Injuries or Chronic Body Pains")
                            .font(.headline)
                        TextField("Describe any past injuries or chronic pains", text: $data.pastInjuries, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    // Previous Surgeries
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Previous Surgeries")
                            .font(.headline)
                        TextField("List any previous surgeries", text: $data.previousSurgeries, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    // Allergies
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Allergies")
                            .font(.headline)
                        TextField("List any allergies", text: $data.allergies, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    // Current Medications
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Medications")
                            .font(.headline)
                        TextField("List current medications", text: $data.currentMedications, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    // Pregnancy Status
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Pregnancy Status (for women)", isOn: $data.pregnancyStatus)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Navigation Buttons
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Text("Back")
                            .font(.headline)
                            .foregroundColor(AppTheme.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.orange.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: onNext) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.orange)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

struct HealthConditionRow: View {
    let condition: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? AppTheme.orange : .secondary)
                    .font(.title3)
                
                Text(condition)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .font(.body)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                AppTheme.orange.opacity(colorScheme == .dark ? 0.15 : 0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppTheme.orange : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

#Preview {
    HealthInfoStepView(data: .constant(OnboardingData()), onBack: {}, onNext: {})
}
