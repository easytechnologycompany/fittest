//
//  SessionViewModel.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import Combine

/// View model for managing a single session with rhythm timer and results
class SessionViewModel: ObservableObject {
    @Published var session: SessionModel
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Rhythm timer integration
    let rhythmTimer: RhythmTimerViewModel

    // Email composer
    let emailComposer = EmailComposerViewModel()

    // Course info for email (passed during initialization)
    private let courseTitle: String

    var publicCourseTitle: String {
        courseTitle
    }
    private let cloudKitService = CloudKitService.shared

    init(session: SessionModel, courseTitle: String) {
        self.session = session
        self.courseTitle = courseTitle
        self.rhythmTimer = RhythmTimerViewModel(
            upSeconds: session.rhythmUpSeconds,
            downSeconds: session.rhythmDownSeconds
        )

        setupTimerObservation()
    }

    private func setupTimerObservation() {
        rhythmTimer.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Observe timer completion to save results
        rhythmTimer.$state
            .filter { $0 == .stopped }
            .sink { [weak self] _ in
                self?.saveSessionResults()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func saveSessionResults() {
        let results = generateResultsSummary()
        session.results = results

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await cloudKitService.saveSession(self.session)
                // Optionally mark as completed
                if session.completedAt == nil {
                    session.completedAt = Date()
                    try await cloudKitService.saveSession(session)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = self.cloudKitService.handleCloudKitError(error)
                }
            }
        }
    }

    func sendResultsByEmail() {
        emailComposer.sendSessionResults(
            courseTitle: courseTitle,
            sessionTitle: session.title,
            sessionDate: session.createdAt,
            rhythmUpSeconds: session.rhythmUpSeconds,
            rhythmDownSeconds: session.rhythmDownSeconds,
            equipment: session.equipmentSnapshot,
            results: session.results,
            completedAt: session.completedAt
        )
    }

    private func generateResultsSummary() -> String {
        let totalTime = rhythmTimer.totalTimeElapsed
        let rounds = rhythmTimer.totalRounds

        var summary = "Session completed!\n"
        summary += "Total time: \(formatDuration(totalTime))\n"
        summary += "Rounds completed: \(rounds)\n"

        if rounds > 0 {
            let averageTimePerRound = totalTime / Double(rounds)
            summary += "Average time per round: \(formatDuration(averageTimePerRound))\n"
        }

        return summary
    }

    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    func deleteSession() async throws {
        try await cloudKitService.deleteSession(session.id)
    }

    deinit {
        cancellables.removeAll()
    }
}
