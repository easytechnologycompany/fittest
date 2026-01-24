//
//  DashboardViewModel.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 18/01/2026.
//

import Foundation
import Combine
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var subscribers: [SubscriberFS] = []
    @Published var courses: [TrainingCourseFS] = []
    @Published var workoutLogs: [WorkoutLogFS] = []
    @Published var goals: [GoalFS] = []
    @Published var attendanceRecords: [AttendanceFS] = []
    @Published var sessions: [SessionFS] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchAllData()
    }
    
    func fetchAllData() {
        isLoading = true
        
        // Use a dispatch group or just fire all requests?
        // Combine's Zip or Merge could work, but independent sinks are fine for real-time updates.
        
        fetchSubscribers()
        fetchCourses()
        fetchWorkoutLogs()
        fetchGoals()
        fetchAttendance()
        fetchSessions()
    }
    
    private func fetchSubscribers() {
        FirestoreService.shared.fetchSubscribers()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Subscribers: " + error.localizedDescription
                }
            } receiveValue: { [weak self] subscribers in
                self?.subscribers = subscribers
            }
            .store(in: &cancellables)
    }
    
    private func fetchCourses() {
        FirestoreService.shared.fetchAllCourses()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Courses: " + error.localizedDescription
                }
            } receiveValue: { [weak self] courses in
                self?.courses = courses
            }
            .store(in: &cancellables)
    }
    
    private func fetchSessions() {
        // Dashboard needs count of "Total Workouts" -> which might be WorkoutLogs or Sessions
        // The original view used WorkoutLog.
        // We have fetchSessions in FirestoreService.
        // We also need fetchWorkoutLogs if we are tracking those separately.
        // Let's assume Sessions are the main "Workout" unit now? 
        // Or if we still use WorkoutLogFS.
        // Reviewing FirestoreService showed fetchSessions.
        // Let's bind what we have.
        
        // RECOVERY: Migrate legacy 'workoutSessions' to 'sessions' if any exist
        Task {
            try? await FirestoreService.shared.migrateLegacyWorkoutSessions()
        }
        
        FirestoreService.shared.fetchSessions()
             .receive(on: DispatchQueue.main)
             .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Sessions: " + error.localizedDescription
                }
             } receiveValue: { [weak self] sessions in
                 self?.sessions = sessions
                 self?.isLoading = false
             }
             .store(in: &cancellables)
    }
    
    // We need generic fetchers for Goals, Attendance, WorkoutLogs if specialized ones don't exist.
    // I will use the generic fetchCollection from FirestoreService if available, or just add specific ones.
    // Checking FirestoreService again would be clearer, but I recall seeing generic helpers or I can add them.
    // For now, I'll add listeners for Goals and Attendance inside logic here if needed, 
    // but better to keep it in FirestoreService.
    // Use FirestoreService.shared.db to create listeners if specific methods aren't there.
    
    func fetchGoals() {
        FirestoreService.shared.fetchGoals()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Goals: " + error.localizedDescription
                }
            } receiveValue: { [weak self] goals in
                self?.goals = goals
            }
            .store(in: &cancellables)
    }
    
    func fetchAttendance() {
        FirestoreService.shared.fetchAttendance()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Attendance: " + error.localizedDescription
                }
            } receiveValue: { [weak self] records in
                self?.attendanceRecords = records
            }
            .store(in: &cancellables)
    }
    
    func fetchWorkoutLogs() {
        FirestoreService.shared.fetchWorkoutLogs()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Workout Logs: " + error.localizedDescription
                }
            } receiveValue: { [weak self] logs in
                self?.workoutLogs = logs
            }
            .store(in: &cancellables)
    }
}
