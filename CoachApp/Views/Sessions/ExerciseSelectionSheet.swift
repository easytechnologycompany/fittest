//
//  ExerciseSelectionSheet.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData
import Combine

struct ExerciseSelectionSheet: View {
    @Bindable var session: Session
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // We can fetch machines as a source of exercises
    @Query(sort: \Machine.name) private var machines: [Machine]
    
    // We can also have a predefined list or fetch from ExerciseDB if integrated
    // For now, let's allow typing a name or picking a machine
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Type", selection: $selectedTab) {
                    Text("Machines").tag(0)
                    Text("Custom").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    List {
                        ForEach(searchResults) { machine in
                            Button(action: { addMachine(machine) }) {
                                HStack {
                                    Image(systemName: machine.iconName)
                                        .foregroundStyle(AppTheme.orange)
                                    VStack(alignment: .leading) {
                                        Text(machine.name)
                                            .font(.headline)
                                        Text(machine.category)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search machines")
                } else {
                    Form {
                        Section("New Exercise") {
                            TextField("Exercise Name", text: $searchText)
                            
                            Button("Add Custom Exercise") {
                                addCustomExercise(name: searchText)
                            }
                            .disabled(searchText.isEmpty)
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    var searchResults: [Machine] {
        if searchText.isEmpty {
            return machines
        } else {
            return machines.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func addMachine(_ machine: Machine) {
        let exercise = SessionExercise(
            name: machine.name,
            machineName: machine.name,
            machineCategory: machine.category,
            orderIndex: (session.exercises?.count ?? 0)
        )
        session.exercises?.append(exercise)
        // modelContext.insert(exercise) - appended to session relationship should handle insert
        dismiss()
    }
    
    private func addCustomExercise(name: String) {
        let exercise = SessionExercise(
            name: name,
            orderIndex: (session.exercises?.count ?? 0)
        )
        session.exercises?.append(exercise)
        dismiss()
    }
}
