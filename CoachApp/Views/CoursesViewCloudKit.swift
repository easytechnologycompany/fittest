//
//  CoursesViewCloudKit.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct CoursesViewCloudKit: View {
    @StateObject private var viewModel = CourseViewModel()
    @Environment(\.colorScheme) var colorScheme

    @State private var showingAddCourse = false
    @State private var searchText = ""

    var filteredCourses: [CourseModel] {
        if searchText.isEmpty {
            return viewModel.courses
        } else {
            return viewModel.courses.filter { course in
                course.title.localizedCaseInsensitiveContains(searchText) ||
                (course.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                course.equipment.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if filteredCourses.isEmpty {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No Courses" : "No Courses Found",
                            systemImage: "book",
                            description: Text(searchText.isEmpty ? "Create your first training course to get started." : "Try adjusting your search.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    }
                } else {
                    LazyVGrid(columns: PlatformAdaptations.gridColumns(minWidth: 300), spacing: PlatformAdaptations.defaultSpacing) {
                        ForEach(filteredCourses) { course in
                            /* NavigationLink {
                                CourseDetailViewCloudKit(course: course)
                            } label: { */
                                CourseCardViewCloudKit(course: course)
                            // }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(PlatformAdaptations.cardPadding)
                }
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle("Courses")
            .searchable(text: $searchText, prompt: "Search courses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCourse = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.orange)
                    }
                }
            }
            /* .sheet(isPresented: $showingAddCourse) {
                AddEditCourseViewCloudKit()
            } */
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .refreshable {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadCourses()
        }
    }
}

struct CourseCardViewCloudKit: View {
    let course: CourseModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                        .lineLimit(2)

                    if let notes = course.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                            .lineLimit(2)
                    }
                }
                Spacer()
            }

            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(AppTheme.orange)
                    .font(.caption)
                Text("\(course.equipment.count) equipment")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .font(.caption)
                Text(course.createdAt.formatted(.dateTime.day().month().year()))
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .modernCard(isOrange: true)
    }
}
