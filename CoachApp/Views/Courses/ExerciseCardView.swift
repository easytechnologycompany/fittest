//
//  ExerciseCardView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct ExerciseCardView: View {
    let exercise: CourseExerciseFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Machine name and icon
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    .lineLimit(2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "repeat")
                        .font(.caption2)
                    Text("\(exercise.sets) \(LocalizedString.string(for: .courses, key: "sets")) × \(exercise.reps) \(LocalizedString.string(for: .courses, key: "reps"))")
                        .font(.caption)
                }
                
                if let weight = exercise.weight {
                    HStack {
                        Image(systemName: "scalemass")
                            .font(.caption2)
                        Text("\(String(format: "%.1f", weight)) kg")
                            .font(.caption)
                    }
                }
                
                if let restTime = exercise.restTime {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(LocalizedString.string(for: .courses, key: "Rest:")) \(formatRestTime(restTime))")
                            .font(.caption)
                    }
                }
            }
            .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
            
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(PlatformAdaptations.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.primaryGradient(for: colorScheme))
        .modernCard(isOrange: true)
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            return "\(seconds / 60)m"
        }
    }
}
