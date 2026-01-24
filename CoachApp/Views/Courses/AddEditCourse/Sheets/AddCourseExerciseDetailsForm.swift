import SwiftUI

struct AddCourseExerciseDetailsForm: View {
    @Binding var selectedMachine: MachineFS?
    @Binding var exerciseType: AddCourseExerciseView.ExerciseType
    @Binding var sets: Int
    @Binding var reps: Int
    @Binding var timeMinutes: Int
    @Binding var timeSeconds: Int
    @Binding var weight: String
    @Binding var restTime: String
    @Binding var notes: String
    let colorScheme: ColorScheme
    
    var body: some View {
        Form {
            Section {
                // Selected Machine Info
                HStack {
                    if let machine = selectedMachine {
                        if let imageUrl = machine.exerciseDBImageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: machine.iconName)
                                        .font(.title)
                                        .foregroundColor(AppTheme.orange)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: selectedMachine?.iconName ?? "dumbbell")
                                .font(.title)
                                .foregroundColor(AppTheme.orange)
                                .frame(width: 60, height: 60)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(machine.name)
                                .font(.headline)
                                .foregroundColor(AppTheme.orange)
                            Text(machine.category)
                                .font(.caption)
                                .foregroundColor(AppTheme.orange.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button {
                            selectedMachine = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.orange)
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.orange.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )
            }
            
            Section(LocalizedString.string(for: .courses, key: "Exercise Type")) {
                Picker(LocalizedString.string(for: .courses, key: "Exercise Type"), selection: $exerciseType) {
                    Text(LocalizedString.string(for: .courses, key: "Reps & Sets")).tag(AddCourseExerciseView.ExerciseType.repsSets)
                    Text(LocalizedString.string(for: .courses, key: "Time")).tag(AddCourseExerciseView.ExerciseType.time)
                }
                .pickerStyle(.segmented)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.orange.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )
            }
            
            Section(LocalizedString.string(for: .courses, key: "Exercise Details")) {
                if exerciseType == .repsSets {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .courses, key: "Sets"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        HStack {
                            Button {
                                if sets > 1 { sets -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                            Spacer()
                            Text("\(sets)")
                                .font(.headline)
                                .foregroundColor(AppTheme.orange)
                                .frame(minWidth: 40)
                            Spacer()
                            Button {
                                if sets < 20 { sets += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.backgroundColor(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .courses, key: "Reps"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        HStack {
                            Button {
                                if reps > 1 { reps -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                            Spacer()
                            Text("\(reps)")
                                .font(.headline)
                                .foregroundColor(AppTheme.orange)
                                .frame(minWidth: 40)
                            Spacer()
                            Button {
                                if reps < 100 { reps += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.backgroundColor(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .courses, key: "Weight (kg)"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        TextField(LocalizedString.string(for: .courses, key: "Enter weight"), text: $weight)
                            .foregroundColor(AppTheme.orange)
                            .tint(AppTheme.orange)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.backgroundColor(for: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .courses, key: "Minutes"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        HStack {
                            Button {
                                if timeMinutes > 0 { timeMinutes -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                            Spacer()
                            Text("\(timeMinutes)")
                                .font(.headline)
                                .foregroundColor(AppTheme.orange)
                                .frame(minWidth: 40)
                            Spacer()
                            Button {
                                if timeMinutes < 60 { timeMinutes += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.backgroundColor(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.string(for: .courses, key: "Seconds"))
                            .font(.caption)
                            .foregroundColor(AppTheme.orange.opacity(0.7))
                        HStack {
                            Button {
                                if timeSeconds > 0 { timeSeconds -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                            Spacer()
                            Text("\(timeSeconds)")
                                .font(.headline)
                                .foregroundColor(AppTheme.orange)
                                .frame(minWidth: 40)
                            Spacer()
                            Button {
                                if timeSeconds < 59 { timeSeconds += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.orange)
                                    .font(.title3)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.backgroundColor(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedString.string(for: .courses, key: "Rest Time (seconds)"))
                        .font(.caption)
                        .foregroundColor(AppTheme.orange.opacity(0.7))
                    TextField(LocalizedString.string(for: .courses, key: "Enter rest time"), text: $restTime)
                        .foregroundColor(AppTheme.orange)
                        .tint(AppTheme.orange)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.backgroundColor(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
            
            Section(LocalizedString.string(for: .common, key: "Notes")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedString.string(for: .courses, key: "Exercise Notes"))
                        .font(.caption)
                        .foregroundColor(AppTheme.orange.opacity(0.7))
                    TextField(LocalizedString.string(for: .courses, key: "Enter exercise notes"), text: $notes, axis: .vertical)
                        .foregroundColor(AppTheme.orange)
                        .tint(AppTheme.orange)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.backgroundColor(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.backgroundColor(for: colorScheme))
    }
}


