//
//  DayDetailView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct DayDetailView: View {
    let day: CourseDayFS
    @Environment(\.colorScheme) var colorScheme
    
    var exerciseColumns: [GridItem] {
        #if os(macOS)
        return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        #else
        if PlatformAdaptations.isIPhone {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        } else {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        }
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: PlatformAdaptations.defaultSpacing * 1.25) {
                // Day Information Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedString.string(for: .courses, key: "Day Information"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    
                    InfoRow(label: "Day Number", value: "\(day.dayNumber)", isOnGradient: true, colorScheme: colorScheme)
                    if let dayName = day.dayName, !dayName.isEmpty {
                        InfoRow(label: "Day Name", value: dayName, isOnGradient: true, colorScheme: colorScheme)
                    }
                    if let workoutTitle = day.workoutTitle, !workoutTitle.isEmpty {
                        InfoRow(label: "Workout Title", value: workoutTitle, isOnGradient: true, colorScheme: colorScheme)
                    }
                }
                .padding(PlatformAdaptations.cardPadding)
                .background(AppTheme.primaryGradient(for: colorScheme))
                .modernCard(isOrange: true)
                .padding(.horizontal, PlatformAdaptations.cardPadding)
                
                // Exercises Grid
                if let exercises = day.exercises, !exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedString.string(for: .courses, key: "Exercises"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal, PlatformAdaptations.cardPadding)
                        
                        LazyVGrid(columns: exerciseColumns, spacing: PlatformAdaptations.defaultSpacing) {
                            ForEach(exercises.sorted(by: { $0.order < $1.order })) { exercise in
                                ExerciseCardView(exercise: exercise)
                            }
                        }
                        .padding(.horizontal, PlatformAdaptations.cardPadding)
                    }
                } else {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell",
                        description: Text(LocalizedString.string(for: .courses, key: "Add exercises to this day."))
                    )
                    .frame(height: 200)
                }
            }
            .padding(.vertical, PlatformAdaptations.defaultSpacing)
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle(day.dayName?.isEmpty == false ? day.dayName ?? "\(LocalizedString.string(for: .courses, key: "Day")) \(day.dayNumber)" : "\(LocalizedString.string(for: .courses, key: "Day")) \(day.dayNumber)")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
}
