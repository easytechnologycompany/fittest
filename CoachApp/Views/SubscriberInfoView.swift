//
//  SubscriberInfoView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct SubscriberInfoView: View {
    let subscriber: SubscriberFS
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Photo
                    VStack(spacing: 16) {
                        if let photoUrl = subscriber.photoUrl, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.orange, lineWidth: 3))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(AppTheme.orange)
                        }
                        
                        Text(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                    }
                    .padding(.top)
                    
                    // Basic Information
                    InfoSection(title: "Basic Information") {
                        InfoRow(label: "Name", value: subscriber.name.isEmpty ? "N/A" : subscriber.name, colorScheme: colorScheme)
                        InfoRow(label: "Email", value: subscriber.email.isEmpty ? "N/A" : subscriber.email, colorScheme: colorScheme)
                        InfoRow(label: "Phone", value: subscriber.phone.isEmpty ? "N/A" : subscriber.phone, colorScheme: colorScheme)
                        if let dateOfBirth = subscriber.dateOfBirth {
                            InfoRow(label: "Date of Birth", value: dateOfBirth.formatted(date: .long, time: .omitted), colorScheme: colorScheme)
                        }
                        if let gender = subscriber.gender, !gender.isEmpty {
                            InfoRow(label: "Gender", value: gender, colorScheme: colorScheme)
                        }
                    }
                    
                    // Subscription Information
                    InfoSection(title: "Subscription Information") {
                        InfoRow(label: "Plan Type", value: subscriber.planType ?? "Unknown", colorScheme: colorScheme)
                        InfoRow(label: "Status", value: subscriber.paymentStatus ?? "Unknown", colorScheme: colorScheme)
                        InfoRow(label: "Start Date", value: subscriber.subscriptionStartDate?.formatted(date: .long, time: .omitted) ?? "N/A", colorScheme: colorScheme)
                    }
                    
                    // Referral Information
                    if let referralSource = subscriber.howDidYouHearAboutUs, !referralSource.isEmpty {
                        InfoSection(title: "Referral Information") {
                            InfoRow(label: "How did you hear about us?", value: referralSource, colorScheme: colorScheme)
                            if let referrerName = subscriber.referrerName, !referrerName.isEmpty {
                                InfoRow(label: "Referrer Name", value: referrerName, colorScheme: colorScheme)
                            }
                        }
                    }
                    
                    // Physical Information (Onboarding)
                    if subscriber.onboardingHeight != nil || subscriber.onboardingWeight != nil || subscriber.onboardingAge != nil {
                        InfoSection(title: "Physical Information") {
                            if let height = subscriber.onboardingHeight {
                                InfoRow(label: "Height", value: "\(String(format: "%.1f", height)) cm", colorScheme: colorScheme)
                            }
                            if let weight = subscriber.onboardingWeight {
                                InfoRow(label: "Weight", value: "\(String(format: "%.1f", weight)) kg", colorScheme: colorScheme)
                            }
                            if let age = subscriber.onboardingAge {
                                InfoRow(label: "Age", value: "\(age) years", colorScheme: colorScheme)
                            }
                            if let heartRate = subscriber.onboardingHeartRate {
                                InfoRow(label: "Heart Rate", value: "\(heartRate) bpm", colorScheme: colorScheme)
                            }
                            if let bodyFat = subscriber.onboardingBodyFatPercentage {
                                InfoRow(label: "Body Fat Percentage", value: "\(String(format: "%.1f", bodyFat))%", colorScheme: colorScheme)
                            }
                            if let muscleMass = subscriber.onboardingMuscleMassPercentage {
                                InfoRow(label: "Muscle Mass Percentage", value: "\(String(format: "%.1f", muscleMass))%", colorScheme: colorScheme)
                            }
                            if let activityLevel = subscriber.onboardingPreviousActivityLevel, !activityLevel.isEmpty {
                                InfoRow(label: "Previous Activity Level", value: activityLevel, colorScheme: colorScheme)
                            }
                        }
                    }
                    
                    // Health Information
                    if subscriber.onboardingHealthConditions != nil || subscriber.onboardingPastInjuries != nil || subscriber.onboardingPreviousSurgeries != nil || subscriber.onboardingAllergies != nil || subscriber.onboardingCurrentMedications != nil {
                        InfoSection(title: "Health Information") {
                            if let conditions = subscriber.onboardingHealthConditions, !conditions.isEmpty {
                                InfoRow(label: "Health Conditions", value: conditions, colorScheme: colorScheme)
                            }
                            if let injuries = subscriber.onboardingPastInjuries, !injuries.isEmpty {
                                InfoRow(label: "Past Injuries", value: injuries, colorScheme: colorScheme)
                            }
                            if let surgeries = subscriber.onboardingPreviousSurgeries, !surgeries.isEmpty {
                                InfoRow(label: "Previous Surgeries", value: surgeries, colorScheme: colorScheme)
                            }
                            if let allergies = subscriber.onboardingAllergies, !allergies.isEmpty {
                                InfoRow(label: "Allergies", value: allergies, colorScheme: colorScheme)
                            }
                            if let medications = subscriber.onboardingCurrentMedications, !medications.isEmpty {
                                InfoRow(label: "Current Medications", value: medications, colorScheme: colorScheme)
                            }
                            if let pregnancyStatus = subscriber.onboardingPregnancyStatus {
                                InfoRow(label: "Pregnancy Status", value: pregnancyStatus ? "Yes" : "No", colorScheme: colorScheme)
                            }
                        }
                    }
                    
                    // Fitness Goals
                    if let goals = subscriber.onboardingFitnessGoals, !goals.isEmpty {
                        InfoSection(title: "Fitness Goals") {
                            InfoRow(label: "Goals", value: goals, colorScheme: colorScheme)
                        }
                    }
                    
                    // Medical Information (General)
                    // Robustly checks for any existing data before showing the section
                    if (subscriber.injuries?.isEmpty == false) || (subscriber.restrictions?.isEmpty == false) || (subscriber.healthConditions?.isEmpty == false) {
                        InfoSection(title: "Medical Information") {
                             if let injuries = subscriber.injuries, !injuries.isEmpty {
                                InfoRow(label: "Injuries", value: injuries, colorScheme: colorScheme)
                            }
                            if let restrictions = subscriber.restrictions, !restrictions.isEmpty {
                                InfoRow(label: "Restrictions", value: restrictions, colorScheme: colorScheme)
                            }
                            if let conditions = subscriber.healthConditions, !conditions.isEmpty {
                                InfoRow(label: "Health Conditions", value: conditions, colorScheme: colorScheme)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle("Subscriber Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                Text("Export Options (Coming Soon)")
                // ExportOptionsSheet logic needs updating for SubscriberFS
                .presentationDetents([.height(150)])
            }
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(AppTheme.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
        }
    }
}


struct ExportOptionsSheet: View {
    let onExportImage: () -> Void
    let onCancel: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Options")
                .font(.headline)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
                .padding(.top)
            
            VStack(spacing: 12) {
                Button(action: onExportImage) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Export as Image")
                        Spacer()
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
            }
            .padding(.bottom)
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
    }
}

#Preview {
    SubscriberInfoView(
        subscriber: SubscriberFS(
            name: "John Doe",
            email: "john@example.com",
            phone: "1234567890",
            subscriptionStartDate: Date(),
            planType: "Monthly",
            paymentStatus: "Active",
            injuries: "None",
            restrictions: "None",
            healthConditions: "None"
        )
    )
}

