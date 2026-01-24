//
//  RhythmEngine.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

enum WorkoutRhythmPhase: String {
    case up = "UP"
    case down = "DOWN"
}

@Observable
class RhythmEngine {
    // MARK: - Published State
    var phase: WorkoutRhythmPhase = .up
    var remainingSeconds: Int = 10
    var progress: Double = 1.0 // 1.0 (full) to 0.0 (empty)
    var isRunning: Bool = false
    var elapsedTime: TimeInterval = 0
    var laps: [TimeInterval] = []
    
    // MARK: - Configuration
    var phaseDuration: Double = 10
    
    // MARK: - Internal State
    // Total Timer State
    private var totalTimerStart: Date?
    private var totalTimerAccumulated: TimeInterval = 0
    
    // Phase Timer State
    private var phaseTimerStart: Date?
    private var phaseTimerAccumulated: TimeInterval = 0
    
    private var timerTask: Task<Void, Never>?
    
    // MARK: - Public API
    
    /// Starts the engine with a given phase duration (in seconds).
    func start(rhythm: Int) {
        updateRhythm(rhythm)
        
        reset()
        resume()
    }
    
    /// Updates the rhythm duration live
    func updateRhythm(_ rhythm: Int) {
        let newDuration = rhythm > 0 ? Double(rhythm) : 10.0
        self.phaseDuration = newDuration
        // The tick logic will naturally adapt to the new duration
        // using the existing phase start time.
        // Triggers immediate UI update via tick if running
        if isRunning {
            Task { @MainActor in tick() }
        }
    }
    
    /// Resumes the timer from current state
    func resume() {
        guard !isRunning else { return }
        isRunning = true
        
        let now = Date()
        totalTimerStart = now
        phaseTimerStart = now
        
        timerTask = Task { @MainActor in
            while isRunning {
                tick()
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
    
    /// Pauses the timer
    func pause() {
        guard isRunning else { return }
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        
        let now = Date()
        
        // Capture Total State
        if let start = totalTimerStart {
            totalTimerAccumulated += now.timeIntervalSince(start)
        }
        totalTimerStart = nil
        
        // Capture Phase State
        if let start = phaseTimerStart {
            phaseTimerAccumulated += now.timeIntervalSince(start)
        }
        phaseTimerStart = nil
    }
    
    /// Records a lap
    func lap() {
        laps.append(elapsedTime)
    }
    
    /// Stops and resets the timer
    func stop() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        
        totalTimerAccumulated = 0
        totalTimerStart = nil
        
        phaseTimerAccumulated = 0
        phaseTimerStart = nil
        
        // Reset defaults
        phase = .up
        remainingSeconds = Int(phaseDuration)
        progress = 1.0
        elapsedTime = 0
        laps.removeAll()
    }
    
    // MARK: - Internal Logic
    
    private func reset() {
        stop()
    }
    
    private func tick() {
        let now = Date()
        
        // 1. Update Total Elapsed Time
        if let start = totalTimerStart {
            self.elapsedTime = totalTimerAccumulated + now.timeIntervalSince(start)
        } else {
            self.elapsedTime = totalTimerAccumulated
        }
        
        // 2. Update Phase Logic
        // Calculate theoretical time spent in current phase
        var currentPhaseElapsed: TimeInterval = phaseTimerAccumulated
        if let start = phaseTimerStart {
            currentPhaseElapsed += now.timeIntervalSince(start)
        }
        
        // Check for phase completion(s)
        // Loop to handle cases where we missed multiple phases (lag/background)
        // or if duration was shortened significantly
        while currentPhaseElapsed >= phaseDuration {
            currentPhaseElapsed -= phaseDuration
            
            // Switch Phase
            self.phase = (self.phase == .up) ? .down : .up
            
            // Adjust reference points to "consume" the duration
            // Instead of shifting Date, we shift the accumulated base relative to the logic
            // Ideally: phaseTimerStart moves forward by duration.
            if let start = phaseTimerStart {
                phaseTimerStart = start.addingTimeInterval(phaseDuration)
            } else {
                phaseTimerAccumulated -= phaseDuration
            }
        }
        
        // Update View State
        self.remainingSeconds = Int(ceil(phaseDuration - currentPhaseElapsed))
        self.progress = 1.0 - (currentPhaseElapsed / phaseDuration)
    }
}
