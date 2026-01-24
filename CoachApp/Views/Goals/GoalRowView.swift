import SwiftUI

struct GoalRowView: View {
    let goal: GoalFS
    @Environment(\.colorScheme) var colorScheme
    @State private var isUpdating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                    if !goal.goalDescription.isEmpty {
                        Text(goal.goalDescription)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    if !goal.isCompleted {
                        Button(action: {
                            markAsComplete()
                        }) {
                            HStack(spacing: 4) {
                                if isUpdating {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                }
                                Text(LocalizedString.string(for: .goals, key: "Mark Complete"))
                                    .font(.caption)
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isUpdating)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
            }
            
            // Current vs Target Comparison
            HStack(spacing: 20) {
                // Current Value
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString.string(for: .goals, key: "Current"))
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", goal.currentValue))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        Text(goal.unit)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                }
                
                // Arrow
                Image(systemName: "arrow.right")
                    .foregroundColor(AppTheme.orange)
                    .font(.title3)
                
                // Target Value
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString.string(for: .goals, key: "Target"))
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", goal.targetValue))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.orange)
                        Text(goal.unit)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                }
                
                Spacer()
                
                // Progress Percentage
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(goal.progress >= 1.0 ? .green : AppTheme.orange)
                    Text(LocalizedString.string(for: .goals, key: "Complete"))
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.secondaryBackgroundColor(for: colorScheme))
            )
            
            // Progress Bar
            ProgressView(value: goal.progress)
                .tint(goal.progress >= 1.0 ? .green : AppTheme.orange)
            
            // Footer
            HStack {
                Label(goal.targetDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                Spacer()
                if goal.targetDate < Date() && !goal.isCompleted {
                    Text(LocalizedString.string(for: .goals, key: "Overdue"))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                } else if goal.isCompleted {
                    Text(LocalizedString.string(for: .goals, key: "Achieved!"))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func markAsComplete() {
        var updatedGoal = goal
        updatedGoal.isCompleted = true
        updatedGoal.completedDate = Date()
        
        isUpdating = true
        Task {
            do {
                try await FirestoreService.shared.updateGoal(updatedGoal)
                await MainActor.run {
                    isUpdating = false
                }
            } catch {
                print("Error updating goal: \(error)")
                await MainActor.run {
                    isUpdating = false
                }
            }
        }
    }
}

