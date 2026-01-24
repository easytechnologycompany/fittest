//
//  ProgressHistoryView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct ProgressHistoryView: View {
    let goal: GoalFS
    @Environment(\.dismiss) private var dismiss
    
    var sortedHistory: [GoalProgressEntryFS] {
        (goal.progressHistory ?? []).sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            if sortedHistory.isEmpty {
                ContentUnavailableView(
                    LocalizedString.string(for: .goals, key: "No Progress History"),
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text(LocalizedString.string(for: .goals, key: "Progress updates will appear here"))
                )
            } else {
                ForEach(sortedHistory) { entry in
                    let progress = GoalProgressCalculator.calculateProgressAtEntry(
                        entry,
                        goal: goal,
                        history: sortedHistory
                    )
                    ProgressHistoryRow(
                        entry: entry,
                        goal: goal,
                        progress: progress,
                        progressColor: GoalProgressCalculator.progressColor(for: progress),
                        showDivider: false
                    )
                }
            }
        }
        .navigationTitle(LocalizedString.string(for: .goals, key: "Progress History"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct ProgressHistoryRow: View {
    let entry: GoalProgressEntryFS
    let goal: GoalFS
    let progress: Double
    let progressColor: Color
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(String(format: "%.1f", entry.value)) \(goal.unit)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(progressColor.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.vertical, 4)
            
            if showDivider {
                Divider()
            }
        }
    }
}


