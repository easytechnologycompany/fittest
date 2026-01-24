//
//  CourseRowView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 18/01/2026.
//

import SwiftUI

struct CourseRowView: View {
    let course: TrainingCourseFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(course.title.isEmpty ? "Untitled Course" : course.title)
                    .font(.headline)
                Spacer()
                Text(course.difficulty)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Group {
                            if course.difficulty.lowercased() == "beginner" {
                                AppTheme.primaryGradient(for: colorScheme)
                            } else {
                                difficultyColor(for: course.difficulty)
                            }
                        }
                    )
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .cornerRadius(6)
            }
            
            if let description = course.courseDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(course.days?.count ?? 0) days", systemImage: "calendar")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Label("\(course.durationMonths) month\(course.durationMonths > 1 ? "s" : "")", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let assignedIds = course.assignedSubscriberIds, !assignedIds.isEmpty {
                    Label("\(assignedIds.count) subscribers", systemImage: "person.2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
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
