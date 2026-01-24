import SwiftUI
import Combine

struct AssignSubscribersView: View {
    @Environment(\.dismiss) private var dismiss
    
    let course: TrainingCourseFS
    @State private var allSubscribers: [SubscriberFS] = []
    @State private var selectedSubscriberIds: Set<String> = []
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()
    
    init(course: TrainingCourseFS) {
        self.course = course
        _selectedSubscriberIds = State(initialValue: Set(course.assignedSubscriberIds ?? []))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(allSubscribers) { subscriber in
                            Toggle(isOn: Binding(
                                get: { 
                                    if let id = subscriber.id {
                                        return selectedSubscriberIds.contains(id)
                                    }
                                    return false
                                },
                                set: { isAssigned in
                                    if let id = subscriber.id {
                                        if isAssigned {
                                            selectedSubscriberIds.insert(id)
                                        } else {
                                            selectedSubscriberIds.remove(id)
                                        }
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
                                        .font(.headline)
                                    Text(subscriber.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assign Subscribers")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAssignments()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                fetchSubscribers()
            }
        }
    }
    
    private func fetchSubscribers() {
        FirestoreService.shared.fetchSubscribers()
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching subscribers: \(error)")
                }
                isLoading = false
            } receiveValue: { subscribers in
                self.allSubscribers = subscribers.sorted(by: { $0.name < $1.name })
                isLoading = false
            }
            .store(in: &cancellables)
    }
    
    private func saveAssignments() {
        var updatedCourse = course
        updatedCourse.assignedSubscriberIds = Array(selectedSubscriberIds)
        
        Task {
            do {
                try await FirestoreService.shared.saveCourse(updatedCourse)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving course assignments: \(error)")
            }
        }
    }
}

