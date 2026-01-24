//
//  AssignedCoursesView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct AssignedCoursesView: View {
    @Environment(\.colorScheme) var colorScheme
    let subscriber: SubscriberFS
    let allCourses: [TrainingCourseFS]
    
    @State private var showingAssignCourse = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var courseToUnassign: TrainingCourseFS?
    
    var assignedCourses: [TrainingCourseFS] {
        guard let subId = subscriber.id else { return [] }
        return allCourses.filter { course in
            course.assignedSubscriberIds?.contains(subId) ?? false
        }
    }
    
    var body: some View {
        Group {
            if assignedCourses.isEmpty {
                ContentUnavailableView(
                    "No Courses Assigned",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Assign training courses to this subscriber to help them reach their goals.")
                )
            } else {
                List {
                    ForEach(assignedCourses) { course in
                        NavigationLink {
                            CourseDetailView(course: course)
                        } label: {
                            CourseRowView(course: course)
                        }
                    }
                    .onDelete { offsets in
                        if let firstIndex = offsets.first {
                            courseToUnassign = assignedCourses[firstIndex]
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle("Assigned Courses")
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAssignCourse = true
                } label: {
                    Label("Assign Course", systemImage: "plus")
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAssignCourse = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                }
            }
            #endif
        }
        .platformSheet(isPresented: $showingAssignCourse) {
            AssignCoursesToSubscriberView(subscriber: subscriber, allCourses: allCourses)
        }
        .alert("Unassign Course", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                courseToUnassign = nil
            }
            Button("Unassign", role: .destructive) {
                if let course = courseToUnassign {
                    unassignCourse(course)
                }
                courseToUnassign = nil
            }
        } message: {
            Text("Are you sure you want to unassign this course?")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func unassignCourse(_ course: TrainingCourseFS) {
        guard let subId = subscriber.id else { return }
        var updatedCourse = course
        updatedCourse.assignedSubscriberIds?.removeAll { $0 == subId }
        
        Task {
            do {
                try await FirestoreService.shared.updateCourse(updatedCourse)
            } catch {
                await MainActor.run {
                    let appError = AppError.saveError("Failed to unassign course: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AssignedCoursesView.unassignCourse")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

struct AssignCoursesToSubscriberView: View {
    @Environment(\.dismiss) private var dismiss
    let subscriber: SubscriberFS
    let allCourses: [TrainingCourseFS]
    
    @State private var selectedCourseIds: Set<String> = []
    @State private var isLoading = false
    
    var unassignedCourses: [TrainingCourseFS] {
        guard let subId = subscriber.id else { return allCourses }
        return allCourses.filter { course in
            !(course.assignedSubscriberIds?.contains(subId) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if unassignedCourses.isEmpty {
                    ContentUnavailableView(
                        "All Courses Assigned",
                        systemImage: "checkmark.circle",
                        description: Text("This subscriber is already assigned to all available courses.")
                    )
                } else {
                    ForEach(unassignedCourses) { course in
                        Button {
                            if let id = course.id {
                                if selectedCourseIds.contains(id) {
                                    selectedCourseIds.remove(id)
                                } else {
                                    selectedCourseIds.insert(id)
                                }
                            }
                        } label: {
                            HStack {
                                CourseRowView(course: course)
                                Spacer()
                                if let id = course.id, selectedCourseIds.contains(id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.orange)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Assign Courses")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        assignSelectedCourses()
                    }
                    .disabled(selectedCourseIds.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func assignSelectedCourses() {
        guard let subId = subscriber.id else { return }
        isLoading = true
        
        Task {
            do {
                for courseId in selectedCourseIds {
                    if var course = allCourses.first(where: { $0.id == courseId }) {
                        if course.assignedSubscriberIds == nil {
                            course.assignedSubscriberIds = []
                        }
                        if !(course.assignedSubscriberIds?.contains(subId) ?? false) {
                            course.assignedSubscriberIds?.append(subId)
                            try await FirestoreService.shared.updateCourse(course)
                        }
                    }
                }
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Error handling could be improved here
                }
            }
        }
    }
}

#Preview {
    AssignedCoursesView(
        subscriber: SubscriberFS(
            name: "Test User",
            email: "test@example.com",
            phone: "1234567890",
            subscriptionStartDate: Date(),
            planType: "Monthly",
            paymentStatus: "Active",
            injuries: "None",
            restrictions: "None",
            healthConditions: "None"
        ),
        allCourses: []
    )
}

#Preview {
    AssignedCoursesView(
        subscriber: SubscriberFS(
            name: "Test User",
            email: "test@example.com",
            phone: "1234567890",
            subscriptionStartDate: Date(),
            planType: "Monthly",
            paymentStatus: "Active",
            injuries: "None",
            restrictions: "None",
            healthConditions: "None"
        ),
        allCourses: []
    )
}
