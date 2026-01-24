//
//  CourseViewModel.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import Combine

/// View model for managing courses with CloudKit
class CourseViewModel: ObservableObject {
    @Published var courses: [CourseModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let cloudKitService = CloudKitService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadCourses()
    }

    func loadCourses() {
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            do {
                let fetchedCourses = try await self?.cloudKitService.fetchCourses()
                await MainActor.run {
                    self?.courses = fetchedCourses ?? []
                    self?.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self?.errorMessage = self?.cloudKitService.handleCloudKitError(error)
                    self?.isLoading = false
                }
            }
        }
    }

    func saveCourse(title: String, equipment: [String], notes: String?) async throws -> CourseModel {
        let course = CourseModel(title: title, equipment: equipment, notes: notes)
        try await cloudKitService.saveCourse(course)
        return course
    }

    func updateCourse(_ course: CourseModel, title: String? = nil, equipment: [String]? = nil, notes: String? = nil) async throws {
        try await cloudKitService.updateCourse(
            course.id,
            title: title,
            equipment: equipment,
            notes: notes
        )
    }

    func deleteCourse(_ course: CourseModel) async throws {
        try await cloudKitService.deleteCourse(course.id)
        await MainActor.run {
            courses.removeAll { $0.id == course.id }
        }
    }

    func refresh() {
        loadCourses()
    }
}

/// View model for managing a single course and its sessions
class CourseDetailViewModel: ObservableObject {
    @Published var course: CourseModel
    @Published var sessions: [SessionModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let cloudKitService = CloudKitService.shared

    init(course: CourseModel) {
        self.course = course
        loadSessions()
    }

    func loadSessions() {
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let fetchedSessions = try await self.cloudKitService.fetchSessions(for: self.course.id)
                await MainActor.run {
                    self.sessions = fetchedSessions
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = self.cloudKitService.handleCloudKitError(error)
                    self.isLoading = false
                }
            }
        }
    }

    func createSession(title: String, rhythmUpSeconds: Int = 10, rhythmDownSeconds: Int = 10) async throws -> SessionModel {
        let session = try await cloudKitService.createSession(
            from: course.id,
            title: title,
            rhythmUpSeconds: rhythmUpSeconds,
            rhythmDownSeconds: rhythmDownSeconds
        )

        await MainActor.run {
            sessions.insert(session, at: 0) // Add to beginning since sorted by creation date
        }

        return session
    }

    func updateCourse(title: String? = nil, equipment: [String]? = nil, notes: String? = nil) async throws {
        try await cloudKitService.updateCourse(
            course.id,
            title: title,
            equipment: equipment,
            notes: notes
        )

        // Update local course model
        if let title = title {
            course.title = title
        }
        if let equipment = equipment {
            course.equipment = equipment
        }
        if let notes = notes {
            course.notes = notes
        } else {
            course.notes = nil
        }

        await MainActor.run {
            self.objectWillChange.send()
        }
    }

    func deleteCourse() async throws {
        try await cloudKitService.deleteCourse(course.id)
    }

    func refresh() {
        loadSessions()
    }
}
