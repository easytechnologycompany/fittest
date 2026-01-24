import SwiftUI
import Combine

struct AddCourseExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State var allMachines: [MachineFS] = []
    @State private var cancellables = Set<AnyCancellable>()
    
    let onSave: (CourseExerciseFS) -> Void
    
    @State private var selectedMachine: MachineFS? = nil
    @State private var exerciseType: ExerciseType = .repsSets
    @State private var sets: Int = 1
    @State private var reps: Int = 10
    @State private var timeMinutes: Int = 0
    @State private var timeSeconds: Int = 0
    @State private var weight: String = ""
    @State private var restTime: String = ""
    @State private var notes: String = ""
    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    @State var isLoadingFromExerciseDB = false
    @State private var syncErrorMessage: String?
    
    enum ExerciseType {
        case repsSets
        case time
    }
    
    var categories: [String] {
        Array(Set(allMachines.map { $0.category })).sorted()
    }
    
    var filteredMachines: [MachineFS] {
        var machines = allMachines
        
        if !searchText.isEmpty {
            machines = machines.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.machineDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            machines = machines.filter { $0.category == category }
        }
        
        return machines
    }
    
    var columns: [GridItem] {
#if os(macOS)
        return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
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
            Group {
                if selectedMachine != nil {
                    AddCourseExerciseDetailsForm(
                        selectedMachine: $selectedMachine,
                        exerciseType: $exerciseType,
                        sets: $sets,
                        reps: $reps,
                        timeMinutes: $timeMinutes,
                        timeSeconds: $timeSeconds,
                        weight: $weight,
                        restTime: $restTime,
                        notes: $notes,
                        colorScheme: colorScheme
                    )
                } else {
                    AddCourseExerciseMachineSelectionView(
                        colorScheme: colorScheme,
                        searchText: $searchText,
                        selectedCategory: $selectedCategory,
                        categories: categories,
                        filteredMachines: filteredMachines,
                        columns: columns,
                        selectedMachine: $selectedMachine
                    )
                }
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle(LocalizedString.string(for: .machines, key: "Select Machine"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.orange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(buildExercise())
                        dismiss()
                    }
                    .disabled(selectedMachine == nil)
                    .foregroundColor(AppTheme.orange)
                }
            }
        }
        .onAppear {
            fetchMachines()
        }
    }
    
    private func fetchMachines() {
        FirestoreService.shared.fetchMachines()
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching machines: \(error)")
                }
            } receiveValue: { machines in
                self.allMachines = machines
            }
            .store(in: &cancellables)
    }
    
    private func buildExercise() -> CourseExerciseFS {
        guard let selectedMachine else {
            return CourseExerciseFS(name: "Unknown", sets: 1, reps: 10, order: 0)
        }
        
        if exerciseType == .repsSets {
            return CourseExerciseFS(
                name: selectedMachine.name,
                sets: sets,
                reps: reps,
                weight: Double(weight),
                restTime: Int(restTime),
                notes: notes,
                order: 0,
                machineId: selectedMachine.id,
                machineName: selectedMachine.name
            )
        } else {
            let totalSeconds = (timeMinutes * 60) + timeSeconds
            return CourseExerciseFS(
                name: selectedMachine.name,
                sets: 0,
                reps: totalSeconds,
                weight: Double(weight),
                restTime: Int(restTime),
                notes: notes,
                order: 0,
                machineId: selectedMachine.id,
                machineName: selectedMachine.name
            )
        }
    }
}


