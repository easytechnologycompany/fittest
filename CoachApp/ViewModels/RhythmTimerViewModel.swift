//
//  RhythmTimerViewModel.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import Combine
import UIKit

/// Timer phase enumeration
enum RhythmPhase {
    case up
    case down

    var displayName: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        }
    }

    var next: RhythmPhase {
        switch self {
        case .up: return .down
        case .down: return .up
        }
    }
}

/// Timer state enumeration
enum TimerState {
    case stopped
    case running
    case paused
}

/// Rhythm timer view model with proper lifecycle handling
class RhythmTimerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPhase: RhythmPhase = .up
    @Published var remainingSeconds: Int = 10
    @Published var state: TimerState = .stopped
    @Published var totalRounds: Int = 0
    @Published var currentRound: Int = 0
    @Published var totalTimeElapsed: TimeInterval = 0

    // MARK: - Configuration
    let upSeconds: Int
    let downSeconds: Int
    let maxRounds: Int? // nil means unlimited

    // MARK: - Private Properties
    private var timer: Timer?
    private var timerTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var lastTimestamp: Date?
    private var pausedTimeRemaining: Int = 10
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Persistence Keys
    private let phaseKey = "rhythmTimer.phase"
    private let remainingKey = "rhythmTimer.remaining"
    private let stateKey = "rhythmTimer.state"
    private let timestampKey = "rhythmTimer.timestamp"
    private let roundsKey = "rhythmTimer.rounds"
    private let totalTimeKey = "rhythmTimer.totalTime"

    // MARK: - Initialization
    init(upSeconds: Int = 10, downSeconds: Int = 10, maxRounds: Int? = nil) {
        self.upSeconds = upSeconds
        self.downSeconds = downSeconds
        self.maxRounds = maxRounds

        setupNotifications()
        restoreState()
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Methods
    func start() {
        guard state != .running else { return }

        state = .running
        lastTimestamp = Date()

        if state == .paused {
            // Resume from paused state
            remainingSeconds = pausedTimeRemaining
        } else {
            // Start fresh
            currentPhase = .up
            remainingSeconds = upSeconds
            currentRound = 0
            totalTimeElapsed = 0
        }

        startTimer()
        saveState()
        startBackgroundTask()
    }

    func pause() {
        guard state == .running else { return }

        state = .paused
        pausedTimeRemaining = remainingSeconds
        stopTimer()
        endBackgroundTask()
        saveState()
    }

    func stop() {
        state = .stopped
        stopTimer()
        endBackgroundTask()
        clearState()
    }

    func reset() {
        stop()
        currentPhase = .up
        remainingSeconds = upSeconds
        currentRound = 0
        totalTimeElapsed = 0
        pausedTimeRemaining = upSeconds
    }

    // MARK: - Private Methods
    private func startTimer() {
        stopTimer() // Ensure any existing timer is stopped

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await MainActor.run {
                        self?.tick()
                    }
                } catch {
                    break
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .running else { return }

        remainingSeconds -= 1
        totalTimeElapsed += 1

        if remainingSeconds <= 0 {
            completePhase()
        }

        saveState()
    }

    private func completePhase() {
        currentPhase = currentPhase.next
        remainingSeconds = currentPhase == .up ? upSeconds : downSeconds

        if currentPhase == .up {
            // Completed a full cycle (down -> up)
            currentRound += 1
            totalRounds = currentRound

            // Check if we've reached max rounds
            if let maxRounds = maxRounds, currentRound >= maxRounds {
                stop()
                return
            }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleBackgroundTransition()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleForegroundTransition()
            }
            .store(in: &cancellables)
    }

    private func handleBackgroundTransition() {
        // Save current state when going to background
        saveState()
        endBackgroundTask()
    }

    private func handleForegroundTransition() {
        // Restore state and adjust for time spent in background
        restoreState()
        adjustForBackgroundTime()
    }

    private func adjustForBackgroundTime() {
        guard state == .running,
              let lastTimestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date else {
            return
        }

        let timeInBackground = Date().timeIntervalSince(lastTimestamp)
        let secondsInBackground = Int(timeInBackground)

        if secondsInBackground > 0 {
            var secondsToSubtract = secondsInBackground

            while secondsToSubtract > 0 && state == .running {
                let subtractAmount = min(secondsToSubtract, remainingSeconds)
                remainingSeconds -= subtractAmount
                totalTimeElapsed += TimeInterval(subtractAmount)
                secondsToSubtract -= subtractAmount

                if remainingSeconds <= 0 {
                    completePhase()
                    if state != .running { break }
                }
            }

            saveState()
        }
    }

    private func startBackgroundTask() {
        endBackgroundTask() // End any existing task

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "RhythmTimer") {
            // Handle expiration
            self.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func saveState() {
        UserDefaults.standard.set(currentPhase == .up ? "up" : "down", forKey: phaseKey)
        UserDefaults.standard.set(remainingSeconds, forKey: remainingKey)
        UserDefaults.standard.set(state == .running ? "running" : (state == .paused ? "paused" : "stopped"), forKey: stateKey)
        UserDefaults.standard.set(Date(), forKey: timestampKey)
        UserDefaults.standard.set(currentRound, forKey: roundsKey)
        UserDefaults.standard.set(totalTimeElapsed, forKey: totalTimeKey)
    }

    private func restoreState() {
        if let phaseString = UserDefaults.standard.string(forKey: phaseKey) {
            currentPhase = phaseString == "up" ? .up : .down
        }

        remainingSeconds = UserDefaults.standard.integer(forKey: remainingKey)
        pausedTimeRemaining = remainingSeconds

        if let stateString = UserDefaults.standard.string(forKey: stateKey) {
            switch stateString {
            case "running": state = .running
            case "paused": state = .paused
            default: state = .stopped
            }
        }

        currentRound = UserDefaults.standard.integer(forKey: roundsKey)
        totalRounds = currentRound
        totalTimeElapsed = UserDefaults.standard.double(forKey: totalTimeKey)
    }

    private func clearState() {
        let keys = [phaseKey, remainingKey, stateKey, timestampKey, roundsKey, totalTimeKey]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    private func cleanup() {
        stopTimer()
        endBackgroundTask()
        cancellables.removeAll()
    }
}
