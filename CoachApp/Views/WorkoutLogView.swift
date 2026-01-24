//
//  WorkoutLogView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    @Environment(\.modelContext) private var modelContext
    let subscriber: Subscriber
    @Query private var workouts: [WorkoutLog]
    @State private var showingAddWorkout = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    init(subscriber: Subscriber) {
        self.subscriber = subscriber
        let subscriberID = subscriber.persistentModelID
        _workouts = Query(filter: #Predicate<WorkoutLog> { workout in
            workout.subscriber?.persistentModelID == subscriberID
        }, sort: \WorkoutLog.date, order: .reverse)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    NavigationLink {
                        WorkoutDetailView(workout: workout)
                    } label: {
                        WorkoutRowView(workout: workout)
                    }
                }
                .onDelete { offsets in
                    itemsToDelete = offsets
                    showingDeleteConfirmation = true
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddWorkout = true
                    } label: {
                        Label("Add Workout", systemImage: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWorkout = true
                    } label: {
                        Label("Add Workout", systemImage: "plus")
                    }
                }
                #endif
            }
            .platformSheet(isPresented: $showingAddWorkout) {
                AddWorkoutView(subscriber: subscriber)
            }
            .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    itemsToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let offsets = itemsToDelete {
                        deleteWorkouts(offsets: offsets)
                    }
                    itemsToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this workout? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        do {
            withAnimation {
                for index in offsets {
                    modelContext.delete(workouts[index])
                }
            }
            try modelContext.save()
        } catch {
            let appError = AppError.deleteError("Failed to delete workout: \(error.localizedDescription)")
            ErrorHandler.handle(appError, context: "WorkoutLogView.deleteWorkouts")
            errorMessage = appError.localizedDescription
        }
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            
            HStack {
                Label("\(workout.exercises?.count ?? 0) exercises", systemImage: "dumbbell")
                    .font(.caption)
                Spacer()
                if workout.duration > 0 {
                    Label(formatDuration(workout.duration), systemImage: "clock")
                        .font(.caption)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct WorkoutDetailView: View {
    let workout: WorkoutLog
    
    var body: some View {
        Form {
            Section("Workout Info") {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(workout.date.formatted(date: .complete, time: .omitted))
                        .foregroundColor(.secondary)
                }
                if workout.duration > 0 {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(workout.duration))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Exercises") {
                ForEach(Array((workout.exercises ?? []).enumerated()), id: \.offset) { index, exercise in
                    ExerciseRowView(exercise: exercise)
                }
            }
            
            if !workout.notes.isEmpty {
                Section("Notes") {
                    Text(workout.notes)
                }
            }
        }
        .navigationTitle("Workout")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            HStack {
                Text("\(exercise.sets) sets × \(exercise.reps) reps")
                if let weight = exercise.weight {
                    Text("• \(String(format: "%.1f", weight)) kg")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let subscriber: Subscriber
    
    @State private var date: Date = Date()
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 0
    @State private var notes: String = ""
    @State private var exercises: [Exercise] = []
    @State private var showingAddExercise = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var totalDuration: TimeInterval {
        TimeInterval(durationHours * 3600 + durationMinutes * 60)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Info") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Hours", selection: $durationHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        Picker("Minutes", selection: $durationMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section {
                    ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                        ExerciseRowView(exercise: exercise)
                    }
                    .onDelete(perform: deleteExercises)
                    
                    Button {
                        showingAddExercise = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                } header: {
                    Text("Exercises")
                }
                
                Section("Notes") {
                    TextField("Workout notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Workout")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .platformSheet(isPresented: $showingAddExercise) {
                AddExerciseView { exercise in
                    exercises.append(exercise)
                }
            }
        }
    }
    
    private func deleteExercises(offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func saveWorkout() {
        isLoading = true
        
        Task {
            do {
                let workout = WorkoutLog(
                    date: date,
                    duration: totalDuration,
                    notes: notes
                )
                workout.subscriber = subscriber
                
                await MainActor.run {
                    for exercise in exercises {
                        exercise.workout = workout
                        modelContext.insert(exercise)
                    }
                    modelContext.insert(workout)
                }
                
                try modelContext.save()
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to save workout: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AddWorkoutView.saveWorkout")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (Exercise) -> Void
    
    @State private var name: String = ""
    @State private var sets: Int = 1
    @State private var reps: Int = 10
    @State private var weight: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                    Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                    TextField("Weight (kg)", text: $weight)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                }
                
                Section("Notes") {
                    TextField("Exercise notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Exercise")
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
                        let exercise = Exercise(
                            name: name,
                            sets: sets,
                            reps: reps,
                            weight: Double(weight),
                            notes: notes
                        )
                        onSave(exercise)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    WorkoutLogView(subscriber: Subscriber())
        .modelContainer(for: WorkoutLog.self, inMemory: true)
}

