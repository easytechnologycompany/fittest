//
//  MigrationView.swift
//  CoachApp
//
//  Created by Antigravity on 18/01/2026.
//

import SwiftUI

struct MigrationView: View {
    @ObservedObject var migrationService: MigrationService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo or Icon
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                    .symbolEffect(.pulse, options: .repeating)
                
                // Title
                Text("Upgrading Your Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                // Description
                Text("We're moving your data to cloud storage for better performance and reliability.")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Progress Section
                VStack(spacing: 16) {
                    // Progress Bar
                    ProgressView(value: migrationService.migrationProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.orange))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal, 40)
                    
                    // Percentage
                    Text("\(Int(migrationService.migrationProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                    
                    // Current Step
                    Text(migrationService.currentStep)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        .frame(height: 20)
                }
                .padding(.top, 20)
                
                // Error Message (if any)
                if let error = migrationService.migrationError {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Migration Error")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Retry") {
                            // Retry logic would go here
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.orange)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                    .padding(.horizontal, 40)
                }
                
                // Success Message
                if migrationService.migrationComplete && migrationService.migrationError == nil {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Migration Complete!")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        Text("Your data has been successfully upgraded.")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Info Text
                VStack(spacing: 8) {
                    Text("Please don't close the app")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    
                    Text("This may take a few minutes depending on your data size")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        .opacity(0.7)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    MigrationView(migrationService: MigrationService.shared)
}
