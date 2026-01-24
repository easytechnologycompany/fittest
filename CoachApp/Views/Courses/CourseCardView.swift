//
//  CourseCardView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct CourseCardView: View {
    let course: TrainingCourseFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                Spacer()
                Text(course.difficulty)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Group {
                            if course.difficulty.lowercased() == "beginner" {
                                AppTheme.orange.opacity(colorScheme == .dark ? 0.8 : 0.3)
                            } else {
                                difficultyColor(for: course.difficulty).opacity(colorScheme == .dark ? 0.8 : 0.3)
                            }
                        }
                    )
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    .cornerRadius(8)
            }
            
            Text(course.title.isEmpty ? "Untitled Course" : course.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                .lineLimit(2)
            
            if let description = course.courseDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                    .lineLimit(3)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("\(course.days?.count ?? 0) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                    Spacer()
                    Label("\(course.durationMonths) month\(course.durationMonths > 1 ? "s" : "")", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                }
            }
        }
        .padding(PlatformAdaptations.cardPadding)
        .frame(height: 180)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.primaryGradient(for: colorScheme))
        .modernCard(isOrange: true)
    }
    
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner":
            return .green
        case "intermediate":
            return .orange
        case "advanced":
            return .red
        default:
            return .gray
        }
    }
}
