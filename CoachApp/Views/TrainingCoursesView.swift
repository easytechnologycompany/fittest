//
//  TrainingCoursesView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

struct TrainingCoursesView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var courses: [TrainingCourseFS] = []
    @State private var showingAddCourse = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var courseToDelete: TrainingCourseFS?
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()
    
    var columns: [GridItem] {
        #if os(macOS)
        return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        #else
        if PlatformAdaptations.isIPhone {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        } else {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        }
        #endif
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if courses.isEmpty {
                    ContentUnavailableView(
                        "No Courses",
                        systemImage: "book.fill",
                        description: Text(LocalizedString.string(for: .courses, key: "Add your first training course to get started."))
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: PlatformAdaptations.defaultSpacing) {
                        ForEach(courses) { course in
                            NavigationLink {
                                CourseDetailView(course: course)
                            } label: {
                                CourseCardView(course: course)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    courseToDelete = course
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(PlatformAdaptations.cardPadding)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle(LocalizedString.string(for: .courses, key: "Training Courses"))
            .onAppear {
                fetchCourses()
            }
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddCourse = true
                    } label: {
                        Label("Add Course", systemImage: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCourse = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                            .font(.title3)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddCourse) {
                AddEditCourseView()
            }
            .alert("Delete Course", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    courseToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let course = courseToDelete, let id = course.id {
                        deleteCourse(id)
                    }
                    courseToDelete = nil
                }
            } message: {
                Text(LocalizedString.string(for: .courses, key: "Are you sure you want to delete this course? This action cannot be undone."))
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
    
    private func fetchCourses() {
        FirestoreService.shared.fetchAllCourses()
            .sink { completion in
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            } receiveValue: { fetchedCourses in
                self.courses = fetchedCourses
                isLoading = false
            }
            .store(in: &cancellables)
    }
    
    private func deleteCourse(_ id: String) {
        Task {
            do {
                try await FirestoreService.shared.deleteCourse(id)
                fetchCourses() // Refresh list
            } catch {
                let appError = AppError.deleteError("Failed to delete course: \(error.localizedDescription)")
                ErrorHandler.handle(appError, context: "TrainingCoursesView.deleteCourse")
                errorMessage = appError.localizedDescription
            }
        }
    }
}
