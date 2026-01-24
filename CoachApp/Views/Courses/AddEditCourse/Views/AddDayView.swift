import SwiftUI

struct AddDayView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (CourseDayFS) -> Void
    
    @State private var dayName: String = ""
    @State private var workoutTitle: String = ""
    @State private var dayNumber: Int = 1
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Day Information") {
                    TextField(LocalizedString.string(for: .courses, key: "Day Name"), text: $dayName, prompt: Text(LocalizedString.string(for: .courses, key: "e.g., Push Day, Pull Day")))
                    Stepper("Day Number: \(dayNumber)", value: $dayNumber, in: 1...365)
                    TextField("Workout Title (optional)", text: $workoutTitle)
                }
                
                Section {
                    Text(LocalizedString.string(for: .courses, key: "You can add exercises (machines) to this day after saving."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(LocalizedString.string(for: .courses, key: "Add Day"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let day = CourseDayFS(
                            dayNumber: dayNumber,
                            dayName: dayName.isEmpty ? nil : dayName,
                            workoutTitle: workoutTitle.isEmpty ? nil : workoutTitle,
                            order: dayNumber - 1,
                            exercises: []
                        )
                        
                        onSave(day)
                        dismiss()
                    }
                }
            }
        }
    }
}


