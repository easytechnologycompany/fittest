//
//  SubscriberDetailViewModel.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import Combine
import FirebaseFirestore

class SubscriberDetailViewModel: ObservableObject {
    @Published var physicalDetails: [PhysicalDetailFS] = []
    @Published var goals: [GoalFS] = []
    @Published var sessions: [SessionFS] = []
    @Published var courses: [TrainingCourseFS] = []
    @Published var attendanceRecords: [AttendanceFS] = []
    @Published var coachNotes: [CoachNoteFS] = []
    @Published var workoutLogs: [WorkoutLogFS] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var subscriberId: String?
    
    func loadData(for subscriberId: String) {
        self.subscriberId = subscriberId
        isLoading = true
        
        // Fetch sessions
        FirestoreService.shared.fetchSessions(for: subscriberId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] sessions in
                self?.sessions = sessions
            }
            .store(in: &cancellables)
            
        // Fetch courses
        FirestoreService.shared.fetchAllCourses()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] courses in
                self?.courses = courses
            }
            .store(in: &cancellables)
            
        fetchPhysicalDetails(subscriberId: subscriberId)
        fetchGoals(subscriberId: subscriberId)
        fetchAttendance(subscriberId: subscriberId)
        fetchCoachNotes(subscriberId: subscriberId)
        fetchWorkoutLogs(subscriberId: subscriberId)
        
        isLoading = false
    }
    
    // MARK: - Ad-hoc Fetchers (Should ideally be in FirestoreService)
    
    private func fetchPhysicalDetails(subscriberId: String) {
        Firestore.firestore().collection("physicalDetails")
            .whereField("subscriberId", isEqualTo: subscriberId)
            .order(by: "dateRecorded", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.physicalDetails = snapshot?.documents.compactMap { try? $0.data(as: PhysicalDetailFS.self) } ?? []
            }
    }
    
    private func fetchGoals(subscriberId: String) {
        Firestore.firestore().collection("goals")
            .whereField("subscriberId", isEqualTo: subscriberId)
            .order(by: "targetDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.goals = snapshot?.documents.compactMap { try? $0.data(as: GoalFS.self) } ?? []
            }
    }
    
    private func fetchAttendance(subscriberId: String) {
         Firestore.firestore().collection("attendance")
            .whereField("subscriberId", isEqualTo: subscriberId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.attendanceRecords = snapshot?.documents.compactMap { try? $0.data(as: AttendanceFS.self) } ?? []
            }
    }
    
    private func fetchCoachNotes(subscriberId: String) {
        Firestore.firestore().collection("coachNotes")
            .whereField("subscriberId", isEqualTo: subscriberId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.coachNotes = snapshot?.documents.compactMap { try? $0.data(as: CoachNoteFS.self) } ?? []
            }
    }
    private func fetchWorkoutLogs(subscriberId: String) {
        Firestore.firestore().collection("workoutLogs")
            .whereField("subscriberId", isEqualTo: subscriberId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.workoutLogs = snapshot?.documents.compactMap { try? $0.data(as: WorkoutLogFS.self) } ?? []
            }
    }
}
