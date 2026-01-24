//
//  PhysicalInfoStepView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

struct PhysicalInfoStepView: View {
    @Binding var data: OnboardingData
    var onNext: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    let activityLevels = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Physical Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Please provide your physical measurements and activity level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Height
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height (cm)")
                            .font(.headline)
                        TextField("Enter height", text: $data.height)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg)")
                            .font(.headline)
                        TextField("Enter weight", text: $data.weight)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Age
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.headline)
                        TextField("Enter age", text: $data.age)
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Heart Rate
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Heart Rate (bpm)")
                            .font(.headline)
                        TextField("Enter heart rate", text: $data.heartRate)
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Body Fat Percentage
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Body Fat Percentage (%)")
                            .font(.headline)
                        TextField("Enter body fat %", text: $data.bodyFatPercentage)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Muscle Mass Percentage
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Muscle Mass Percentage (%)")
                            .font(.headline)
                        TextField("Enter muscle mass %", text: $data.muscleMassPercentage)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Previous Activity Level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Previous Activity Level")
                            .font(.headline)
                        Picker("Activity Level", selection: $data.previousActivityLevel) {
                            ForEach(activityLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Next Button
                Button(action: {
                    if data.isPhysicalInfoValid {
                        onNext()
                    }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(data.isPhysicalInfoValid ? AppTheme.orange : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!data.isPhysicalInfoValid)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    PhysicalInfoStepView(data: .constant(OnboardingData()), onNext: {})
}
