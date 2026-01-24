import SwiftUI

struct ExerciseRow: View {
    let exercise: CourseExerciseFS
    let order: Int
    @Environment(\.colorScheme) var colorScheme
    
    var isTimeBased: Bool {
        exercise.sets == 0 && exercise.reps > 0
    }
    
    var timeDisplay: String {
        let totalSeconds = exercise.reps
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(order + 1). \(exercise.name)")
                .font(.headline)
                .foregroundColor(AppTheme.orange)
            HStack {
                if isTimeBased {
                    Text("\(LocalizedString.string(for: .courses, key: "Duration:")) \(timeDisplay)")
                        .foregroundColor(AppTheme.orange.opacity(0.8))
                } else {
                    Text("\(exercise.sets) \(LocalizedString.string(for: .courses, key: "sets")) × \(exercise.reps) \(LocalizedString.string(for: .courses, key: "reps"))")
                        .foregroundColor(AppTheme.orange.opacity(0.8))
                    if let weight = exercise.weight {
                        Text("• \(String(format: "%.1f", weight)) kg")
                            .foregroundColor(AppTheme.orange.opacity(0.6))
                    }
                }
            }
            .font(.caption)
            // Note: We don't have the full machine object in CourseExerciseFS, just machineName and machineId.
            // But we can show the machineName if it's different from exercise name, or just use it.
        }
    }
}


