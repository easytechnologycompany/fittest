import SwiftUI

struct EditDayView: View {
    @Environment(\.dismiss) private var dismiss
    
    let day: CourseDayFS
    let onUpdate: (CourseDayFS) -> Void
    
    @State private var dayName: String = ""
    @State private var workoutTitle: String = ""
    @State private var showingAddExercise = false
    @State private var exercises: [CourseExerciseFS] = []
    
    init(day: CourseDayFS, onUpdate: @escaping (CourseDayFS) -> Void) {
        self.day = day
        self.onUpdate = onUpdate
        _dayName = State(initialValue: day.workoutTitle ?? "")
        _workoutTitle = State(initialValue: day.workoutTitle ?? "")
        _exercises = State(initialValue: day.exercises ?? [])
    }
    
    var body: some View {
        Form {
            Section("Day Information") {
                HStack {
                    Text(LocalizedString.string(for: .courses, key: "Day Number"))
                    Spacer()
                    Text("\(day.dayNumber)")
                        .foregroundColor(.secondary)
                }
                TextField("Day Name", text: $dayName, prompt: Text("e.g., Push Day, Pull Day"))
                TextField("Workout Title", text: $workoutTitle)
            }
            
            Section {
                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    // Note: Order is not used in ExerciseRow but kept for reference
                    HStack {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("\(exercise.sets) sets x \(exercise.reps) reps")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)
                
                Button {
                    showingAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            } header: {
                Text(LocalizedString.string(for: .courses, key: "Exercises (Machines)"))
            } footer: {
                Text(LocalizedString.string(for: .courses, key: "Tap and hold to reorder exercises"))
            }
        }
        .navigationTitle("\(LocalizedString.string(for: .courses, key: "Day")) \(day.dayNumber)")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveDay()
                }
            }
        }
        .platformSheet(isPresented: $showingAddExercise) {
            AddCourseExerciseView { exercise in
                exercises.append(exercise)
            }
        }
    }
    
    private func deleteExercises(offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        // Update order indices
        for (index, _) in exercises.enumerated() {
            exercises[index].order = index
        }
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        // Update order indices
        for (index, _) in exercises.enumerated() {
            exercises[index].order = index
        }
    }
    
    private func saveDay() {
        var updatedDay = day
        updatedDay.workoutTitle = workoutTitle.isEmpty ? (dayName.isEmpty ? nil : dayName) : workoutTitle
        updatedDay.exercises = exercises
        
        onUpdate(updatedDay)
        dismiss()
    }
}


