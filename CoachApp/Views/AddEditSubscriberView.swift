//
//  AddEditSubscriberView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct AddEditSubscriberView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = ""
    @State private var subscriptionStartDate: Date = Date()
    @State private var planType: String = "Monthly"
    @State private var paymentStatus: String = "Active"
    @State private var injuries: String = ""
    @State private var restrictions: String = ""
    @State private var healthConditions: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isCompressingPhoto = false
    @State private var emailError: String?
    @State private var phoneError: String?
    
    // Dismissal confirmation
    @State private var showingDismissConfirmation = false
    
    // Onboarding state
    @State private var onboardingData = OnboardingData()
    @State private var showOnboarding = false
    @State private var onboardingStep: Int = 0

    
    let planTypes = ["Monthly", "3-Month", "6-Month", "Annual"]
    let paymentStatuses = ["Active", "Pending", "Expired"]
    let genders = ["Male", "Female", "Other", "Prefer not to say"]
    
    var subscriber: SubscriberFS?
    
    init(subscriber: SubscriberFS? = nil) {
        self.subscriber = subscriber
        if let subscriber = subscriber {
            _name = State(initialValue: subscriber.name)
            _email = State(initialValue: subscriber.email)
            _phone = State(initialValue: subscriber.phone)
            _dateOfBirth = State(initialValue: subscriber.dateOfBirth ?? Date())
            _gender = State(initialValue: subscriber.gender ?? "")
            _subscriptionStartDate = State(initialValue: subscriber.subscriptionStartDate ?? Date())
            _planType = State(initialValue: subscriber.planType ?? "Monthly")
            _paymentStatus = State(initialValue: subscriber.paymentStatus ?? "Active")
            _injuries = State(initialValue: subscriber.injuries ?? "")
            _restrictions = State(initialValue: subscriber.restrictions ?? "")
            _healthConditions = State(initialValue: subscriber.healthConditions ?? "")
            // _photoData // Firestore uses URL, but for now we might have loaded it separately or just skip
        }
    }
    
    var body: some View {
        ZStack {
            if subscriber == nil {
                // Show onboarding for new subscribers
                SubscriberOnboardingView(
                    onboardingData: $onboardingData,
                    currentStep: $onboardingStep,
                    onComplete: {
                        // Onboarding completed - Save immediately
                        saveNewSubscriberFromOnboarding()
                    },
                    onDismissRequest: {
                        // Check if there's any data entered
                        if hasEnteredData() {
                            showingDismissConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                )
                .onAppear {
                    // Load draft data if it exists
                    let draftResult = SubscriberDraftManager.loadDraft()
                    if let draft = draftResult.data {
                        onboardingData = draft
                        onboardingStep = draftResult.step
                    }
                }
            } else {
                // Show basic info form for editing
                basicInfoForm
            }
        }
        .interactiveDismissDisabled(subscriber == nil ? hasEnteredData() : hasEnteredDataForEditing())
        .alert("Discard Changes?", isPresented: $showingDismissConfirmation) {
            Button("Cancel", role: .cancel) {
                showingDismissConfirmation = false
            }
            Button("Discard", role: .destructive) {
                if subscriber == nil {
                    SubscriberDraftManager.clearDraft()
                }
                dismiss()
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    // Check if user has entered any data (for new subscriber onboarding)
    private func hasEnteredData() -> Bool {
        return !onboardingData.name.isEmpty ||
               !onboardingData.email.isEmpty ||
               !onboardingData.phone.isEmpty ||
               !onboardingData.height.isEmpty ||
               !onboardingData.weight.isEmpty ||
               !onboardingData.age.isEmpty ||
               onboardingData.photoData != nil ||
               !onboardingData.selectedHealthConditions.isEmpty ||
               !onboardingData.selectedGoals.isEmpty ||
               onboardingData.signatureData != nil ||
               SubscriberDraftManager.hasDraft()
    }
    
    // Check if user has entered any data (for editing existing subscriber)
    private func hasEnteredDataForEditing() -> Bool {
        return !name.isEmpty ||
               !email.isEmpty ||
               !phone.isEmpty ||
               photoData != nil ||
               !injuries.isEmpty ||
               !restrictions.isEmpty ||
               !healthConditions.isEmpty
    }
    
    private var basicInfoForm: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name *", text: $name)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Phone Number", text: $phone)
#if os(iOS)
                            .keyboardType(.phonePad)
#endif
                            .onChange(of: phone) { oldValue, newValue in
                                if !newValue.isEmpty {
                                    phoneError = ValidationHelper.isValidPhone(newValue) ? nil : "Invalid phone number"
                                } else {
                                    phoneError = nil
                                }
                            }
                        if let phoneError = phoneError {
                            Text(phoneError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    Picker("Gender", selection: $gender) {
                        Text("Select Gender").tag("")
                        ForEach(genders, id: \.self) { genderOption in
                            Text(genderOption).tag(genderOption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
#if os(iOS)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
#endif
                            .onChange(of: email) { oldValue, newValue in
                                if !newValue.isEmpty {
                                    emailError = ValidationHelper.isValidEmail(newValue) ? nil : "Invalid email format"
                                } else {
                                    emailError = nil
                                }
                            }
                        if let emailError = emailError {
                            Text(emailError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            #if canImport(UIKit)
                            if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }
                            #elseif canImport(AppKit)
                            if let photoData = photoData, let nsImage = NSImage(data: photoData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }
                            #endif
                            Text("Select Photo")
                        }
                    }
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        Task {
                            isCompressingPhoto = true
                            defer { isCompressingPhoto = false }
                            
                            do {
                                if let data = try await newValue?.loadTransferable(type: Data.self) {
                                    // Compress image on main actor (required for UIKit)
                                    photoData = await MainActor.run {
                                        ImageCompressionHelper.compressProfilePhoto(data) ?? data
                                    }
                                } else {
                                    // Clear photo if picker cleared
                                    if newValue == nil { photoData = nil }
                                }
                            } catch {
                                errorMessage = "Failed to load photo: \(error.localizedDescription)"
                            }
                        }
                    }
                    
                    if isCompressingPhoto {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Compressing photo...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Subscription") {
                    DatePicker("Start Date", selection: $subscriptionStartDate, displayedComponents: .date)
                    Picker("Plan Type", selection: $planType) {
                        ForEach(planTypes, id: \.self) { plan in
                            Text(plan).tag(plan)
                        }
                    }
                    Picker("Payment Status", selection: $paymentStatus) {
                        ForEach(paymentStatuses, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                }
                
                Section("Medical Information") {
                    TextField("Injuries", text: $injuries, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Restrictions", text: $restrictions, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Health Conditions", text: $healthConditions, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(subscriber == nil ? "Add Subscriber" : "Edit Subscriber")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasEnteredDataForEditing() {
                            showingDismissConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSubscriber()
                    }
                    .disabled(name.isEmpty || isLoading || emailError != nil || phoneError != nil)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasEnteredDataForEditing() {
                            showingDismissConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSubscriber()
                    }
                    .disabled(name.isEmpty || isLoading || emailError != nil || phoneError != nil)
                }
                #endif
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
            .interactiveDismissDisabled(hasEnteredDataForEditing())
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func saveSubscriber() {
        // Validate inputs
        if !email.isEmpty && !ValidationHelper.isValidEmail(email) {
            emailError = "Invalid email format"
            return
        }
        
        if !phone.isEmpty && !ValidationHelper.isValidPhone(phone) {
            phoneError = "Invalid phone number"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if var subscriber = subscriber {
                    // Update existing subscriber
                    subscriber.name = name
                    subscriber.email = email
                    subscriber.phone = phone
                    subscriber.dateOfBirth = dateOfBirth
                    subscriber.gender = gender.isEmpty ? nil : gender
                    subscriber.subscriptionStartDate = subscriptionStartDate
                    subscriber.planType = planType
                    subscriber.paymentStatus = paymentStatus
                    subscriber.injuries = injuries
                    subscriber.restrictions = restrictions
                    subscriber.healthConditions = healthConditions
                    
                    try await FirestoreService.shared.updateSubscriber(subscriber)
                } else {
                    // Should be handled by saveNewSubscriberFromOnboarding usually, but fallback if someone hacks a way to this screen without onboarding for new
                    // But here we are in basicInfoForm which is shown if subscriber != nil OR if we decide to show it.
                    // Actually, logic above shows Onboarding if subscriber == nil.
                    // So this block is ONLY for editing existing users effectively.
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to save subscriber: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AddEditSubscriberView.saveSubscriber")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
    
    private func saveNewSubscriberFromOnboarding() {
        isLoading = true
        
        Task {
            do {
                // Safely convert strings to numbers
                let height = onboardingData.height.isEmpty ? nil : Double(onboardingData.height)
                let weight = onboardingData.weight.isEmpty ? nil : Double(onboardingData.weight)
                let age = onboardingData.age.isEmpty ? nil : Int(onboardingData.age)
                let heartRate = onboardingData.heartRate.isEmpty ? nil : Int(onboardingData.heartRate)
                let bodyFat = onboardingData.bodyFatPercentage.isEmpty ? nil : Double(onboardingData.bodyFatPercentage)
                let muscleMass = onboardingData.muscleMassPercentage.isEmpty ? nil : Double(onboardingData.muscleMassPercentage)
                
                // Determine the final referral source value
                let referralSource: String? = {
                    if onboardingData.howDidYouHearAboutUs.isEmpty {
                        return nil
                    } else if onboardingData.howDidYouHearAboutUs == "Other" {
                        return onboardingData.otherReferralSource.isEmpty ? "Other" : onboardingData.otherReferralSource
                    } else {
                        return onboardingData.howDidYouHearAboutUs
                    }
                }()
                
                let newSubscriber = SubscriberFS(
                    id: nil,
                    name: onboardingData.name,
                    email: onboardingData.email,
                    phone: onboardingData.phone,
                    dateOfBirth: onboardingData.dateOfBirth,
                    gender: onboardingData.gender.isEmpty ? nil : onboardingData.gender,
                    photoUrl: nil, // TODO: Upload photo to Storage
                    subscriptionStartDate: Date(),
                    planType: onboardingData.planType,
                    paymentStatus: "Active",
                    injuries: "", 
                    restrictions: "",
                    healthConditions: "",
                    onboardingHeight: height,
                    onboardingWeight: weight,
                    onboardingAge: age,
                    onboardingHeartRate: heartRate,
                    onboardingBodyFatPercentage: bodyFat,
                    onboardingMuscleMassPercentage: muscleMass,
                    onboardingPreviousActivityLevel: onboardingData.previousActivityLevel.isEmpty ? nil : onboardingData.previousActivityLevel,
                    onboardingHealthConditions: onboardingData.selectedHealthConditions.isEmpty ? nil : onboardingData.selectedHealthConditions.joined(separator: ", "),
                    onboardingPastInjuries: onboardingData.pastInjuries.isEmpty ? nil : onboardingData.pastInjuries,
                    onboardingPreviousSurgeries: onboardingData.previousSurgeries.isEmpty ? nil : onboardingData.previousSurgeries,
                    onboardingAllergies: onboardingData.allergies.isEmpty ? nil : onboardingData.allergies,
                    onboardingCurrentMedications: onboardingData.currentMedications.isEmpty ? nil : onboardingData.currentMedications,
                    onboardingPregnancyStatus: onboardingData.pregnancyStatus ? true : nil,
                    onboardingFitnessGoals: onboardingData.selectedGoals.isEmpty ? nil : onboardingData.selectedGoals.joined(separator: ", "),
                    howDidYouHearAboutUs: referralSource,
                    referrerName: onboardingData.referrerName.isEmpty ? nil : onboardingData.referrerName
                )
                
                let ref = try await FirestoreService.shared.addSubscriber(newSubscriber)
                
                // Create initial PhysicalDetail record
                if let height = height, let weight = weight {
                    let physicalDetail = PhysicalDetailFS(
                        dateRecorded: Date(),
                        weight: weight,
                        bodyFatPercentage: bodyFat,
                        height: height,
                        subscriberId: ref.documentID
                    )
                    try await FirestoreService.shared.addPhysicalDetail(physicalDetail)
                }
                
                // Clear draft after successful save
                await MainActor.run {
                    SubscriberDraftManager.clearDraft()
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    AddEditSubscriberView()
}

