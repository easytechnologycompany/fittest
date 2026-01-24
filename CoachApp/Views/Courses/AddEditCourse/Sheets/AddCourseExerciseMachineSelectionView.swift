import SwiftUI

struct AddCourseExerciseMachineSelectionView: View {
    let colorScheme: ColorScheme
    @Binding var searchText: String
    @Binding var selectedCategory: String?
    let categories: [String]
    let filteredMachines: [MachineFS]
    let columns: [GridItem]
    @Binding var selectedMachine: MachineFS?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: PlatformAdaptations.defaultSpacing) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.blue)
                    TextField("Search machines...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(AppTheme.blue)
                        .tint(AppTheme.blue)
                }
                .padding(PlatformAdaptations.cardPadding)
                .modernCard(isOrange: false)
                
                // Category Filter
                if !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button {
                                selectedCategory = nil
                            } label: {
                                Text(LocalizedString.string(for: .machines, key: "All"))
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategory == nil ?
                                        AppTheme.orange.opacity(colorScheme == .dark ? 0.8 : 0.3) :
                                        Color(.systemGray5)
                                    )
                                    .foregroundColor(
                                        selectedCategory == nil ?
                                        AppTheme.blue :
                                        .primary
                                    )
                                    .cornerRadius(8)
                            }
                            
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    selectedCategory = selectedCategory == category ? nil : category
                                } label: {
                                    Text(category)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == category ?
                                            AppTheme.orange.opacity(colorScheme == .dark ? 0.8 : 0.3) :
                                            Color(.systemGray5)
                                        )
                                        .foregroundColor(
                                            selectedCategory == category ?
                                            AppTheme.blue :
                                            .primary
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, PlatformAdaptations.cardPadding)
                    }
                }
            }
            .padding(PlatformAdaptations.cardPadding)
            .background(AppTheme.backgroundColor(for: colorScheme))
            
            // Machines Grid
            if filteredMachines.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Machines" : "No Machines Found",
                    systemImage: "dumbbell",
                    description: Text(searchText.isEmpty ? "No machines available." : "Try adjusting your search or filters.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.backgroundColor(for: colorScheme))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: PlatformAdaptations.defaultSpacing) {
                        ForEach(filteredMachines) { machine in
                            SelectableMachineCardView(
                                machine: machine,
                                isSelected: selectedMachine?.id == machine.id
                            ) {
                                selectedMachine = machine
                            }
                        }
                    }
                    .padding(PlatformAdaptations.cardPadding)
                }
                .background(AppTheme.backgroundColor(for: colorScheme))
            }
        }
    }
}


