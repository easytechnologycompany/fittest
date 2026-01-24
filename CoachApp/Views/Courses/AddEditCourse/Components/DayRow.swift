import SwiftUI

struct DayRow: View {
    let day: CourseDayFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(LocalizedString.string(for: .courses, key: "Day")) \(day.dayNumber)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(day.exercises?.count ?? 0) \(LocalizedString.string(for: .courses, key: "exercises"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let workoutTitle = day.workoutTitle, !workoutTitle.isEmpty {
                Text(workoutTitle)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // Show machines used in this day
            let machines = Array(Set(day.exercises?.compactMap { $0.machineName } ?? [])).sorted()
            if !machines.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(machines.prefix(5), id: \.self) { machineName in
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell") // Default icon as we don't have icon in list
                                    .font(.caption2)
                                Text(machineName)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.orange.opacity(colorScheme == .dark ? 0.8 : 0.3))
                            .foregroundColor(AppTheme.blue)
                            .cornerRadius(6)
                        }
                        if machines.count > 5 {
                            Text("+\(machines.count - 5) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}


