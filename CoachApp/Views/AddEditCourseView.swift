import SwiftUI
import SwiftData


struct AddEditCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var course: TrainingCourseFS?
    
    @State private var title: String = ""
    @State private var courseDescription: String = ""
    @State private var durationMonths: Int = 1
    @State private var difficulty: String = "Beginner"
    @State private var notes: String = ""
    @State private var days: [CourseDayFS] = []
    
    @State private var showingAddDay = false
    @State private var selectedDayForEdit: CourseDayFS?
    @State private var showingCreateMachine = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    let difficulties = ["Beginner", "Intermediate", "Advanced"]
    let monthOptions = Array(1...12)
    
    init(course: TrainingCourseFS? = nil) {
        self.course = course
        if let course = course {
            _title = State(initialValue: course.title)
            _courseDescription = State(initialValue: course.courseDescription ?? "")
            _durationMonths = State(initialValue: course.durationMonths)
            _difficulty = State(initialValue: course.difficulty)
            _notes = State(initialValue: course.notes ?? "")
            _days = State(initialValue: course.days ?? [])
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizedString.string(for: .courses, key: "Course Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .courses, key: "Course Title"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        TextField(LocalizedString.string(for: .courses, key: "Enter course title"), text: $title)
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
                        Text(LocalizedString.string(for: .common, key: "Description"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        TextField(LocalizedString.string(for: .courses, key: "Enter course description"), text: $courseDescription, axis: .vertical)
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .courses, key: "Duration"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        Picker("", selection: $durationMonths) {
                            ForEach(monthOptions, id: \.self) { months in
                                let monthKey = months > 1 ? "months" : "month"
                                Text("\(months) \(LocalizedString.string(for: .courses, key: monthKey))").tag(months)
                            }
                        }
                        .foregroundColor(AppTheme.orange)
                        .pickerStyle(.menu)
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
                        Text(LocalizedString.string(for: .courses, key: "Difficulty"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        Picker("", selection: $difficulty) {
                            ForEach(difficulties, id: \.self) { difficulty in
                                Text(LocalizedString.string(for: .courses, key: difficulty)).tag(difficulty)
                            }
                        }
                        .foregroundColor(AppTheme.orange)
                        .pickerStyle(.menu)
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
                
                Section {
                    if days.isEmpty {
                        Text(LocalizedString.string(for: .courses, key: "No Days Added"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(days.sorted(by: { $0.order < $1.order })) { day in
                            DayRow(day: day)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.backgroundColor(for: colorScheme))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .onTapGesture {
                                    selectedDayForEdit = day
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
#if os(iOS)
                                .listRowSeparator(.hidden)
#endif
                        }
                        .onDelete(perform: deleteDays)
                    }
                    
                    Button {
                        showingAddDay = true
                    } label: {
                        Label(LocalizedString.string(for: .courses, key: "Add Day"), systemImage: "plus")
                    }
                    .buttonStyle(GradientButtonStyle())
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
#if os(iOS)
                    .listRowSeparator(.hidden)
#endif
                } header: {
                    Text(LocalizedString.string(for: .courses, key: "Course Days"))
                }
                
                Section(LocalizedString.string(for: .common, key: "Notes")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .common, key: "Notes"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        TextField(LocalizedString.string(for: .courses, key: "Enter course notes"), text: $notes, axis: .vertical)
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
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle(course == nil ? LocalizedString.string(for: .courses, key: "New Course") : LocalizedString.string(for: .courses, key: "Edit Course"))
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
                        saveCourse()
                    }
                    .disabled(title.isEmpty || isLoading)
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
            .sheet(isPresented: $showingAddDay) {
                AddDayView { newDay in
                    var updatedDay = newDay
                    updatedDay.order = days.count
                    days.append(updatedDay)
                }
            }
            .sheet(item: $selectedDayForEdit) { day in
                NavigationStack {
                    EditDayView(day: day) { updatedDay in
                        if let index = days.firstIndex(where: { $0.id == day.id }) {
                            days[index] = updatedDay
                        }
                    }
                }
            }
        }
    }
    
    private func deleteDays(offsets: IndexSet) {
        days.remove(atOffsets: offsets)
        // Update order
        for (index, _) in days.enumerated() {
            days[index].order = index
        }
    }
    
    private func saveCourse() {
        isLoading = true
        
        var updatedCourse = course ?? TrainingCourseFS(
            title: title,
            courseDescription: courseDescription.isEmpty ? nil : courseDescription,
            durationMonths: durationMonths,
            difficulty: difficulty,
            notes: notes.isEmpty ? nil : notes,
            days: days
        )
        
        if course != nil {
            updatedCourse.title = title
            updatedCourse.courseDescription = courseDescription.isEmpty ? nil : courseDescription
            updatedCourse.durationMonths = durationMonths
            updatedCourse.difficulty = difficulty
            updatedCourse.notes = notes.isEmpty ? nil : notes
            updatedCourse.days = days
        }
        
        Task {
            do {
                try await FirestoreService.shared.saveCourse(updatedCourse)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to save course: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AddEditCourseView.saveCourse")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}
#Preview {
    AddEditCourseView()
        .modelContainer(for: TrainingCourse.self, inMemory: true)
}
