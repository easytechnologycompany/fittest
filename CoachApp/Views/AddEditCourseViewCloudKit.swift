//
//  AddEditCourseViewCloudKit.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct AddEditCourseViewCloudKit: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    let course: CourseModel?

    @State private var title: String = ""
    @State private var equipment: [String] = []
    @State private var notes: String = ""
    @State private var newEquipmentItem: String = ""
    @State private var showingAddEquipment = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false

    // Predefined equipment suggestions
    private let suggestedEquipment = [
        "Treadmill", "Elliptical", "Stationary Bike", "Rowing Machine", "Stair Climber",
        "Bench Press", "Leg Press", "Lat Pulldown", "Cable Crossover", "Shoulder Press",
        "Leg Extension", "Leg Curl", "Seated Row", "Chest Press", "Tricep Pushdown",
        "Bicep Curl", "Calf Raise", "Smith Machine", "Pull-up Bar", "Dip Station",
        "Dumbbells", "Barbell", "Kettlebell", "Resistance Bands", "Medicine Ball"
    ]

    init(course: CourseModel? = nil) {
        self.course = course
        if let course = course {
            _title = State(initialValue: course.title)
            _equipment = State(initialValue: course.equipment)
            _notes = State(initialValue: course.notes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Course Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Course Title")
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        TextField("Enter course title", text: $title)
                            .foregroundColor(AppTheme.orange)
                            .tint(AppTheme.orange)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.backgroundColor(for: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        TextField("Enter course description", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundColor(AppTheme.orange)
                            .tint(AppTheme.orange)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.backgroundColor(for: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("Equipment") {
                    if equipment.isEmpty {
                        Text("No equipment added yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(equipment, id: \.self) { item in
                            HStack {
                                Text(item)
                                Spacer()
                                Button(action: { removeEquipment(item) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    Button(action: { showingAddEquipment = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.orange)
                            Text("Add Equipment")
                                .foregroundColor(AppTheme.orange)
                        }
                    }
                }
            }
            .navigationTitle(course == nil ? "New Course" : "Edit Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCourse()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if course != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
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
            .alert("Delete Course", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteCourse()
                }
            } message: {
                Text("Are you sure you want to delete this course? This action cannot be undone.")
            }
            .sheet(isPresented: $showingAddEquipment) {
                AddEquipmentView(
                    suggestedEquipment: suggestedEquipment.filter { !equipment.contains($0) },
                    onAdd: { newItem in
                        if !newItem.isEmpty && !equipment.contains(newItem) {
                            equipment.append(newItem)
                        }
                        showingAddEquipment = false
                    },
                    onCancel: {
                        showingAddEquipment = false
                    }
                )
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }

    private func saveCourse() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                if let course = course {
                    // Update existing course
                    try await CloudKitService.shared.updateCourse(
                        course.id,
                        title: title,
                        equipment: equipment,
                        notes: notes.isEmpty ? nil : notes
                    )
                } else {
                    // Create new course
                    let newCourse = CourseModel(
                        title: title,
                        equipment: equipment,
                        notes: notes.isEmpty ? nil : notes
                    )
                    try await CloudKitService.shared.saveCourse(newCourse)
                }

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = CloudKitService.shared.handleCloudKitError(error)
                }
            }
        }
    }

    private func deleteCourse() {
        guard let course = course else { return }

        isLoading = true

        Task {
            do {
                try await CloudKitService.shared.deleteCourse(course.id)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = CloudKitService.shared.handleCloudKitError(error)
                }
            }
        }
    }

    private func removeEquipment(_ item: String) {
        equipment.removeAll { $0 == item }
    }
}

struct AddEquipmentView: View {
    let suggestedEquipment: [String]
    let onAdd: (String) -> Void
    let onCancel: () -> Void

    @State private var selectedItem: String = ""
    @State private var customItem: String = ""
    @FocusState private var isCustomFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                if !suggestedEquipment.isEmpty {
                    Section("Suggested Equipment") {
                        ForEach(suggestedEquipment, id: \.self) { item in
                            Button(action: { selectedItem = item }) {
                                HStack {
                                    Text(item)
                                    Spacer()
                                    if selectedItem == item {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppTheme.orange)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Custom Equipment") {
                    TextField("Enter custom equipment", text: $customItem)
                        .focused($isCustomFieldFocused)
                        .onChange(of: customItem) { _, newValue in
                            if !newValue.isEmpty {
                                selectedItem = newValue
                            }
                        }
                }
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let itemToAdd = customItem.isEmpty ? selectedItem : customItem
                        onAdd(itemToAdd)
                    }
                    .disabled(selectedItem.isEmpty)
                }
            }
            .onAppear {
                if !suggestedEquipment.isEmpty {
                    selectedItem = suggestedEquipment[0]
                } else {
                    isCustomFieldFocused = true
                }
            }
        }
    }
}
