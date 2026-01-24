//
//  CourseDetailView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct CourseDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    let course: TrainingCourseFS
    @State private var showingEdit = false
    @State private var showingAssignSubscribers = false
    
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
        ScrollView {
            VStack(spacing: PlatformAdaptations.defaultSpacing * 1.25) {
                // Course Information Card
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedString.string(for: .courses, key: "Course Information"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    
                    InfoRow(label: LocalizedString.string(for: .common, key: "Title"), value: course.title.isEmpty ? LocalizedString.string(for: .courses, key: "Untitled Course") : course.title, isOnGradient: true, colorScheme: colorScheme)
                    if let description = course.courseDescription, !description.isEmpty {
                        InfoRow(label: LocalizedString.string(for: .common, key: "Description"), value: description, isOnGradient: true, colorScheme: colorScheme)
                    }
                    let monthKey = course.durationMonths > 1 ? "months" : "month"
                    InfoRow(label: LocalizedString.string(for: .courses, key: "Duration"), value: "\(course.durationMonths) \(LocalizedString.string(for: .courses, key: monthKey))", isOnGradient: true, colorScheme: colorScheme)
                    InfoRow(label: LocalizedString.string(for: .courses, key: "Total Days"), value: "\(course.days?.count ?? 0)", isOnGradient: true, colorScheme: colorScheme)
                    InfoRow(label: LocalizedString.string(for: .courses, key: "Difficulty"), value: LocalizedString.string(for: .courses, key: course.difficulty), isOnGradient: true, colorScheme: colorScheme)
                }
                .padding(PlatformAdaptations.cardPadding * 0.75)
                .background(AppTheme.primaryGradient(for: colorScheme))
                .modernCard(isOrange: true)
                .padding(.horizontal, PlatformAdaptations.cardPadding)
                
                // Course Days Grid
                if let days = course.days, !days.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedString.string(for: .courses, key: "Course Days"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                            .padding(.horizontal, PlatformAdaptations.cardPadding)
                        
                        LazyVGrid(columns: columns, spacing: PlatformAdaptations.defaultSpacing) {
                            ForEach(days.sorted(by: { $0.order < $1.order })) { day in
                                NavigationLink {
                                    DayDetailView(day: day)
                                } label: {
                                    DayCardView(day: day)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, PlatformAdaptations.cardPadding)
                    }
                } else {
                    ContentUnavailableView(
                        LocalizedString.string(for: .courses, key: "No Days Added"),
                        systemImage: "calendar.badge.plus",
                        description: Text(LocalizedString.string(for: .courses, key: "Add days to your course to get started."))
                    )
                    .frame(height: 200)
                }
                
                // Notes
                if let notes = course.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedString.string(for: .common, key: "Notes"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                            .padding(.horizontal, PlatformAdaptations.cardPadding)
                        
                        Text(notes)
                            .padding(PlatformAdaptations.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .modernCard(isOrange: true)
                            .padding(.horizontal, PlatformAdaptations.cardPadding)
                    }
                }
            }
            .padding(.vertical, PlatformAdaptations.defaultSpacing)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle(LocalizedString.string(for: .courses, key: "Course Details"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        showingAssignSubscribers = true
                    } label: {
                        Label("Assign to Subscribers", systemImage: "person.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditCourseView(course: course)
        }
        .sheet(isPresented: $showingAssignSubscribers) {
            AssignSubscribersView(course: course)
        }
    }
}
