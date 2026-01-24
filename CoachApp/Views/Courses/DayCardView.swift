//
//  DayCardView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct DayCardView: View {
    let day: CourseDayFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let dayName = day.dayName, !dayName.isEmpty {
                    Text(dayName)
                        .font(.headline)
                        .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                } else {
                    Text("\(LocalizedString.string(for: .courses, key: "Day")) \(day.dayNumber)")
                        .font(.headline)
                        .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                }
                Spacer()
            }
            
            if let workoutTitle = day.workoutTitle, !workoutTitle.isEmpty {
                Text(workoutTitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "dumbbell")
                    .font(.caption)
                Text("\(day.exercises?.count ?? 0) \(LocalizedString.string(for: .courses, key: "exercises"))")
                    .font(.caption)
            }
            .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
        }
        .padding(PlatformAdaptations.cardPadding)
        .frame(height: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.primaryGradient(for: colorScheme))
        .modernCard(isOrange: true)
    }
}
