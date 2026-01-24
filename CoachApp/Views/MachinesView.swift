//
//  MachinesView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

struct MachinesView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var machines: [MachineFS] = []
    
    @State private var showingAddExercise = false
    @State private var editingExerciseId: String?
    @State private var editingOrderNumber: Int?
    @State private var editedName: String = ""
    @State private var editedOrder: Int = 1
    @State private var errorMessage: String?
    @State private var draggedExerciseId: String?
    @State private var exerciseToDelete: MachineFS?
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = true
    
    // Subscriber to handle updates
    @State private var cancellables = Set<AnyCancellable>()
    
    private func loadMachines() {
        isLoading = true
        FirestoreService.shared.fetchMachines()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = "Failed to load exercises: \(error.localizedDescription)"
                    self.isLoading = false
                }
            } receiveValue: { fetchedMachines in
                self.machines = self.applyOrdering(to: fetchedMachines)
                self.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    private func applyOrdering(to machines: [MachineFS]) -> [MachineFS] {
        let machineNames = machines.map { $0.name }
        let orderedNames = ExerciseHelper.applyOrdering(to: machineNames)
        
        // Reconstruct sorted list of machines based on ordered names
        var sortedMachines: [MachineFS] = []
        for name in orderedNames {
            if let machine = machines.first(where: { $0.name == name }) {
                sortedMachines.append(machine)
            }
        }
        
        // Append any machines that might have been missed (e.g. duplicate names edge case)
        for machine in machines {
            if !sortedMachines.contains(where: { $0.id == machine.id }) {
                sortedMachines.append(machine)
            }
        }
        
        return sortedMachines
    }
    
    private func updateLocalOrdering() {
        let names = machines.map { $0.name }
        UserDefaults.standard.set(names, forKey: "exerciseOrder")
        NotificationCenter.default.post(name: NSNotification.Name("ExerciseOrderChanged"), object: nil)
    }
    
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
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading && machines.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: PlatformAdaptations.defaultSpacing) {
                            ForEach(Array(machines.enumerated()), id: \.element.id) { index, machine in
                                ExerciseSessionCardView(
                                    exerciseName: machine.name,
                                    orderNumber: index + 1,
                                    sessionCount: 0, // Not fetching counts efficiently yet
                                    isEditing: editingExerciseId == machine.id,
                                    isEditingOrder: editingOrderNumber == index + 1,
                                    editedName: $editedName,
                                    editedOrder: $editedOrder,
                                    isDragging: draggedExerciseId == machine.id,
                                    onEdit: {
                                        editingExerciseId = machine.id
                                        editedName = machine.name
                                    },
                                    onEditOrder: {
                                        editingOrderNumber = index + 1
                                        editedOrder = index + 1
                                    },
                                    onSave: {
                                        if let id = machine.id {
                                            updateExerciseName(id: id, newName: editedName)
                                        }
                                    },
                                    onSaveOrder: {
                                        if let id = machine.id {
                                            updateExerciseOrder(machineId: id, newOrder: editedOrder)
                                        }
                                    },
                                    onCancel: {
                                        editingExerciseId = nil
                                        editingOrderNumber = nil
                                        editedName = ""
                                    },
                                    onDelete: {
                                        exerciseToDelete = machine
                                        showingDeleteConfirmation = true
                                    }
                                )
                                .draggable(machine.id ?? "") {
                                    ExerciseSessionCardView(
                                        exerciseName: machine.name,
                                        orderNumber: index + 1,
                                        sessionCount: 0,
                                        isEditing: false,
                                        isEditingOrder: false,
                                        editedName: .constant(machine.name),
                                        editedOrder: .constant(index + 1),
                                        isDragging: true,
                                        onEdit: {},
                                        onEditOrder: {},
                                        onSave: {},
                                        onSaveOrder: {},
                                        onCancel: {},
                                        onDelete: {}
                                    )
                                    .opacity(0.8)
                                    .scaleEffect(1.1)
                                    .shadow(radius: 10)
                                }
                                .dropDestination(for: String.self) { droppedItems, location in
                                    guard let droppedId = droppedItems.first,
                                          let sourceIndex = machines.firstIndex(where: { $0.id == droppedId }),
                                          let targetIndex = machines.firstIndex(where: { $0.id == machine.id }),
                                          sourceIndex != targetIndex else {
                                        return false
                                    }
                                    
                                    // Reorder
                                    var newOrder = machines
                                    let item = newOrder.remove(at: sourceIndex)
                                    newOrder.insert(item, at: targetIndex)
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        machines = newOrder
                                    }
                                    
                                    updateLocalOrdering()
                                    return true
                                }
                            }
                        }
                        .padding(PlatformAdaptations.cardPadding)
                    }
                }
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle("Exercises")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    HStack {
                        Button {
                            showingResetConfirmation = true
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button {
                            showingAddExercise = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                        }
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddExercise = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                        }
                        
                        Button(role: .destructive) {
                            showingResetConfirmation = true
                        } label: {
                            Label("Reset Exercises", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button {
                             Task {
                                 await FirestoreService.shared.fixLegacyExerciseNames()
                                 loadMachines() // Refresh
                             }
                        } label: {
                            Label("Fix Duplicate Ex.", systemImage: "hammer.fill")
                        }
                    } label: {
                         Image(systemName: "ellipsis.circle")
                             .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                             .font(.title3)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseNameView {}
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Delete Exercise?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    exerciseToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let machine = exerciseToDelete {
                        deleteExercise(machine)
                    }
                    exerciseToDelete = nil
                }
            } message: {
                if let machine = exerciseToDelete {
                    Text("This will delete '\(machine.name)'. This action cannot be undone.")
                }
            }
            .alert("Reset Exercises?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetExercises()
                }
            } message: {
                Text("This will DELETE ALL existing exercises and reset them to the default list. This action cannot be undone.")
            }
            .onAppear {
                loadMachines()
            }
        }
    }
    
    @State private var showingResetConfirmation = false
    
    private func resetExercises() {
        isLoading = true
        Task {
            do {
                try await FirestoreService.shared.resetMachines()
                // Reload happens via snapshot listener
            } catch {
                errorMessage = "Failed to reset: \(error.localizedDescription)"
                loadMachines()
            }
        }
    }
    
    private func updateExerciseName(id: String, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Exercise name cannot be empty."
            return
        }
        
        guard let index = machines.firstIndex(where: { $0.id == id }) else { return }
        var machine = machines[index]
        
        // Check uniqueness
        if machines.contains(where: { $0.name.lowercased() == trimmedName.lowercased() && $0.id != id }) {
            errorMessage = "An exercise with this name already exists."
            return
        }
        
        machine.name = trimmedName
        
        // Optimistic update
        machines[index] = machine
        editingExerciseId = nil
        
        Task {
            do {
                try await FirestoreService.shared.updateMachine(machine)
                updateLocalOrdering()
            } catch {
                errorMessage = "Failed to update: \(error.localizedDescription)"
                // Revert or reload? Reloading is safer.
                loadMachines()
            }
        }
    }
    
    private func updateExerciseOrder(machineId: String, newOrder: Int) {
        guard newOrder >= 1 && newOrder <= machines.count else {
            errorMessage = "Order must be between 1 and \(machines.count)."
            return
        }
        
        guard let currentIndex = machines.firstIndex(where: { $0.id == machineId }) else { return }
        let targetIndex = newOrder - 1
        
        guard currentIndex != targetIndex else {
            editingOrderNumber = nil
            return
        }
        
        var newOrderList = machines
        let item = newOrderList.remove(at: currentIndex)
        newOrderList.insert(item, at: targetIndex)
        
        withAnimation {
            machines = newOrderList
        }
        
        editingOrderNumber = nil
        updateLocalOrdering()
    }
    
    private func deleteExercise(_ machine: MachineFS) {
        guard let id = machine.id else { return }
        
        // Optimistic remove
        if let index = machines.firstIndex(where: { $0.id == id }) {
            machines.remove(at: index)
        }
        
        Task {
            do {
                try await FirestoreService.shared.deleteMachine(id)
                updateLocalOrdering()
            } catch {
                errorMessage = "Failed to delete: \(error.localizedDescription)"
                loadMachines()
            }
        }
    }
}

struct ExerciseSessionCardView: View {
    let exerciseName: String
    let orderNumber: Int
    let sessionCount: Int
    let isEditing: Bool
    let isEditingOrder: Bool
    @Binding var editedName: String
    @Binding var editedOrder: Int
    let isDragging: Bool
    let onEdit: () -> Void
    let onEditOrder: () -> Void
    let onSave: () -> Void
    let onSaveOrder: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isOrderFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Order Number Badge (editable) - Center Top
            if isEditingOrder {
                VStack(spacing: 4) {
                    TextField("", value: $editedOrder, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 40, height: 32)
                        .background(AppTheme.orange)
                        .cornerRadius(16)
                        .focused($isOrderFieldFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isOrderFieldFocused = true
                            }
                        }
                        .onSubmit {
                            onSaveOrder()
                        }
                    
                    // Save/Cancel buttons below the number field
                    HStack(spacing: 8) {
                        Button {
                            onSaveOrder()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .frame(width: 20, height: 20)
                                .background(Color.green.opacity(0.2))
                                .clipShape(Circle())
                        }
                        Button {
                            onCancel()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .frame(width: 20, height: 20)
                                .background(Color.red.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, -8)
            } else {
                Button {
                    onEditOrder()
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.orange)
                            .frame(width: 32, height: 32)
                        
                        Text("\(orderNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.top, -8)
            }
            
            // Exercise Icon
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                .frame(width: 80, height: 80)
                .background(AppTheme.orange.opacity(colorScheme == .dark ? 0.3 : 0.2))
                .clipShape(Circle())
            
            // Exercise Name (editable)
            if isEditing {
                VStack(spacing: 8) {
                    TextField("Exercise Name", text: $editedName)
                        .textFieldStyle(.plain)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.8))
                        .cornerRadius(10)
                        .focused($isTextFieldFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldFocused = true
                            }
                        }
                        .onSubmit {
                            if !editedName.trimmingCharacters(in: .whitespaces).isEmpty {
                                onSave()
                            }
                        }
                    
                    // Edit Actions
                    HStack(spacing: 16) {
                        Button {
                            onCancel()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                Text("Cancel")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                        }
                        
                        Button {
                            onSave()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                Text("Save")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.orange)
                            .cornerRadius(8)
                        }
                        .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text(exerciseName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    // Session Count
                    if sessionCount > 0 {
                        Label("\(sessionCount) session\(sessionCount == 1 ? "" : "s")", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                    }
                }
            }
        }
        .padding(PlatformAdaptations.cardPadding)
        .frame(maxWidth: .infinity)
        .background(AppTheme.primaryGradient(for: colorScheme))
        .modernCard(isOrange: true)
        .opacity(isDragging ? 0.5 : 1.0)
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing && !isDragging {
                onEdit()
            }
        }
        .overlay(alignment: .topTrailing) {
            if !isEditing {
                HStack(spacing: 4) {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(AppTheme.orange)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
            }
        }
    }
}

struct AddExerciseNameView: View {
    @Environment(\.dismiss) private var dismiss
    
    // We need to fetch existing machines to check for duplicates
    @State private var existingMachines: [MachineFS] = []
    
    let onExerciseAdded: (() -> Void)?
    
    @State private var exerciseName: String = ""
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    init(onExerciseAdded: (() -> Void)? = nil) {
        self.onExerciseAdded = onExerciseAdded
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Exercise Name")
                } footer: {
                    Text("This exercise will be available when creating new workout sessions.")
                }
            }
            .navigationTitle("Add Exercise")
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
                    Button("Add") {
                        addExercise()
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                fetchExistingMachines()
            }
        }
    }
    
    private func fetchExistingMachines() {
        FirestoreService.shared.fetchMachines()
            .first()
            .replaceError(with: [])
            .sink { machines in
                self.existingMachines = machines
            }
            .store(in: &cancellables)
    }
    
    private func addExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Exercise name cannot be empty."
            return
        }
        
        guard !existingMachines.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            errorMessage = "An exercise with this name already exists."
            return
        }
        
        Task {
            // Create a new MachineFS
            let newMachine = MachineFS(
                name: trimmedName,
                iconName: "dumbbell",
                category: "General",
                machineDescription: "",
                isCustom: true
            )
            
            do {
                try await FirestoreService.shared.addMachine(newMachine)
                
                // Add to local order preference so it appears at the end (or we can insert it specifically)
                // Existing view refreshes via listener
                onExerciseAdded?()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add exercise: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    MachinesView()
}

