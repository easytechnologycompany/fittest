import SwiftUI

struct SelectableMachineCardView: View {
    let machine: MachineFS
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var exerciseDBImage: String? = nil
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Machine Image/Icon
                ZStack {
                    if let imageUrl = exerciseDBImage ?? machine.exerciseDBImageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                Image(systemName: machine.iconName)
                                    .font(.system(size: 40, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(
                                        AppTheme.orange,
                                        AppTheme.orange.opacity(0.6),
                                        AppTheme.orange.opacity(0.3)
                                    )
                                    .frame(width: 100, height: 100)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.orange.opacity(colorScheme == .dark ? 0.2 : 0.15),
                                                AppTheme.orange.opacity(colorScheme == .dark ? 0.1 : 0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            @unknown default:
                                Image(systemName: machine.iconName)
                                    .font(.system(size: 40, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(
                                        AppTheme.orange,
                                        AppTheme.orange.opacity(0.6),
                                        AppTheme.orange.opacity(0.3)
                                    )
                                    .frame(width: 100, height: 100)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.orange.opacity(colorScheme == .dark ? 0.2 : 0.15),
                                                AppTheme.orange.opacity(colorScheme == .dark ? 0.1 : 0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    } else {
                        Image(systemName: machine.iconName)
                            .font(.system(size: 40, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(
                                AppTheme.gradientCardTextColor(for: colorScheme)
                            )
                            .frame(width: 100, height: 100)
                            .background(
                                LinearGradient(
                                    colors: [
                                        AppTheme.orange.opacity(colorScheme == .dark ? 0.25 : 0.18),
                                        AppTheme.orange.opacity(colorScheme == .dark ? 0.15 : 0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        AppTheme.orange.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    }
                    
                    // Selection indicator
                    if isSelected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(AppTheme.orange))
                                    .padding(4)
                            }
                        }
                        .frame(width: 100, height: 100)
                    }
                }
                
                // Machine Name
                Text(machine.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Category Badge
                Text(machine.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.orange.opacity(colorScheme == .dark ? 0.8 : 0.3))
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    .cornerRadius(6)
            }
            .padding(PlatformAdaptations.cardPadding)
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryGradient(for: colorScheme))
            .modernCard(isOrange: true)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AppTheme.orange : Color.clear,
                        lineWidth: 3
                    )
            )
        }
        .buttonStyle(.plain)
        .task {
            await loadExerciseDBImage()
        }
    }
    
    private func loadExerciseDBImage() async {
        // If machine already has an ExerciseDB image URL, use it directly
        if let imageUrl = machine.exerciseDBImageUrl, !imageUrl.isEmpty {
            await MainActor.run {
                self.exerciseDBImage = imageUrl
            }
            return
        }
        
        // If machine has ExerciseDB ID, fetch the exercise to get image
        if let exerciseDBId = machine.exerciseDBId,
           ExerciseDBService.shared.isConfigured {
            do {
                let exercise = try await ExerciseDBService.shared.fetchExerciseById(exerciseDBId)
                await MainActor.run {
                    if let imageUrl = exercise.imageUrl, !imageUrl.isEmpty {
                        self.exerciseDBImage = imageUrl
                    }
                }
            } catch {
                // Silently fail
            }
            return
        }
    }
}


