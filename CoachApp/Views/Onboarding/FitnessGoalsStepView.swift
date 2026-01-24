//
//  FitnessGoalsStepView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

struct FitnessGoalsStepView: View {
    @Binding var data: OnboardingData
    var onBack: () -> Void
    var onNext: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    let fitnessGoals = [
        "Weight Loss",
        "Muscle Gain",
        "Body Toning",
        "Improving Overall Health",
        "Post-Injury Body Strengthening",
        "Increasing Activity Level & Strength"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Fitness Goals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Select all fitness goals that apply to you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(fitnessGoals, id: \.self) { goal in
                        FitnessGoalCard(
                            goal: goal,
                            isSelected: data.selectedGoals.contains(goal),
                            onTap: {
                                if data.selectedGoals.contains(goal) {
                                    data.selectedGoals.remove(goal)
                                } else {
                                    data.selectedGoals.insert(goal)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
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
                    
                    Button(action: {
                        if data.isFitnessGoalsValid {
                            onNext()
                        }
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(data.isFitnessGoalsValid ? AppTheme.orange : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!data.isFitnessGoalsValid)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

struct FitnessGoalCard: View {
    let goal: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.orange : .secondary)
                    .font(.title3)
                
                Text(goal)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
            }
            .padding()
            .background(
                isSelected ?
                AppTheme.orange.opacity(colorScheme == .dark ? 0.3 : 0.15) :
                AppTheme.orange.opacity(colorScheme == .dark ? 0.15 : 0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.orange : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
            .shadow(
                color: isSelected ? AppTheme.orange.opacity(colorScheme == .dark ? 0.5 : 0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FitnessGoalsStepView(data: .constant(OnboardingData()), onBack: {}, onNext: {})
}
