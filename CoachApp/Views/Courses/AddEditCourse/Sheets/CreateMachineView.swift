import SwiftUI

struct CreateMachineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let onSave: (MachineFS) -> Void
    
    @State private var name: String = ""
    @State private var category: String = "Strength"
    @State private var description: String = ""
    @State private var iconName: String = "dumbbell"
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    let categories = ["Strength", "Cardio", "Free Weights", "Cable", "Functional"]
    let commonIcons = [
        "dumbbell", "dumbbell.fill", "figure.strengthtraining.traditional",
        "figure.strengthtraining.functional", "figure.arms.open", "figure.run",
        "bicycle", "cable.connector", "figure.rower", "figure.stairs"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Machine Information") {
                    TextField("Machine Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Icon") {
                    Picker("Icon", selection: $iconName) {
                        ForEach(commonIcons, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                Text(icon)
                            }
                            .tag(icon)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(LocalizedString.string(for: .machines, key: "Create Machine"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createMachine()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func createMachine() {
        isLoading = true
        
        let newMachine = MachineFS(
            name: name,
            iconName: iconName,
            category: category,
            machineDescription: description,
            isCustom: true
        )
        
        Task {
            do {
                _ = try await FirestoreService.shared.saveMachine(newMachine)
                
                await MainActor.run {
                    isLoading = false
                    onSave(newMachine)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to create machine: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "CreateMachineView.createMachine")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}


