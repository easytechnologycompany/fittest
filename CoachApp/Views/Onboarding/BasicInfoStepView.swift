//
//  BasicInfoStepView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 17/12/2025.
//

import SwiftUI
import PhotosUI

struct BasicInfoStepView: View {
    @Binding var data: OnboardingData
    var onNext: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoIsLoading = false
    @State private var emailError: String?
    @State private var phoneError: String?
    
    let genders = ["Male", "Female", "Other", "Prefer not to say"]
    let planTypes = ["Monthly", "3-Month", "6-Month", "Annual"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Basic Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Let's start with the basics")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 24) {
                    // Photo Picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        VStack(spacing: 8) {
                            if let photoData = data.photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.orange, lineWidth: 2))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text(data.photoData == nil ? "Add Photo" : "Change Photo")
                                .font(.caption)
                                .foregroundColor(AppTheme.orange)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let newValue {
                                photoIsLoading = true
                                if let data = try? await newValue.loadTransferable(type: Data.self) {
                                    // Compress on main actor
                                    self.data.photoData = await MainActor.run {
                                        ImageCompressionHelper.compressProfilePhoto(data) ?? data
                                    }
                                }
                                photoIsLoading = false
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name *")
                                .font(.headline)
                            TextField("Enter full name", text: $data.name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                        }
                        
                        // Phone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                            TextField("Enter phone number", text: $data.phone)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .onChange(of: data.phone) { _, newValue in
                                    if !newValue.isEmpty {
                                        phoneError = ValidationHelper.isValidPhone(newValue) ? nil : "Invalid phone number"
                                    } else {
                                        phoneError = nil
                                    }
                                }
                            if let phoneError {
                                Text(phoneError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                            TextField("Enter email address", text: $data.email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: data.email) { _, newValue in
                                    if !newValue.isEmpty {
                                        emailError = ValidationHelper.isValidEmail(newValue) ? nil : "Invalid email format"
                                    } else {
                                        emailError = nil
                                    }
                                }
                            if let emailError {
                                Text(emailError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // DOB
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .font(.headline)
                            DatePicker("", selection: $data.dateOfBirth, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.headline)
                            Picker("Gender", selection: $data.gender) {
                                Text("Select Gender").tag("")
                                ForEach(genders, id: \.self) { gender in
                                    Text(gender).tag(gender)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Plan Type
                        VStack(alignment: .leading, spacing: 8) {
                             Text("Plan Type")
                                 .font(.headline)
                             Picker("Plan Type", selection: $data.planType) {
                                 ForEach(planTypes, id: \.self) { plan in
                                     Text(plan).tag(plan)
                                 }
                             }
                             .pickerStyle(.menu)
                             .frame(maxWidth: .infinity, alignment: .leading)
                             .padding(.vertical, 8)
                             .padding(.horizontal, 12)
                             .background(Color(.secondarySystemBackground))
                             .cornerRadius(8)
                         }
                        
                        // How did you hear about us?
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString.string(for: .subscribers, key: "How did you hear about us?"))
                                .font(.headline)
                            Picker(LocalizedString.string(for: .subscribers, key: "How did you hear about us?"), selection: $data.howDidYouHearAboutUs) {
                                Text(LocalizedString.string(for: .subscribers, key: "Select an option")).tag("")
                                Text(LocalizedString.string(for: .subscribers, key: "Snapchat")).tag("Snapchat")
                                Text(LocalizedString.string(for: .subscribers, key: "Instagram")).tag("Instagram")
                                Text(LocalizedString.string(for: .subscribers, key: "Facebook")).tag("Facebook")
                                Text(LocalizedString.string(for: .subscribers, key: "Referred by a friend")).tag("Referred by a friend")
                                Text(LocalizedString.string(for: .subscribers, key: "Other")).tag("Other")
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            
                            // Show referrer name field if "Referred by a friend" is selected
                            if data.howDidYouHearAboutUs == "Referred by a friend" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(LocalizedString.string(for: .subscribers, key: "Friend's Name"))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField(LocalizedString.string(for: .subscribers, key: "Enter friend's name"), text: $data.referrerName)
                                        .textFieldStyle(.roundedBorder)
                                }
                                .padding(.top, 8)
                            }
                            
                            // Show "Other" text field if "Other" is selected
                            if data.howDidYouHearAboutUs == "Other" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(LocalizedString.string(for: .subscribers, key: "Please specify"))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField(LocalizedString.string(for: .subscribers, key: "Please specify"), text: $data.otherReferralSource)
                                        .textFieldStyle(.roundedBorder)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Next Button
                Button(action: {
                    if isFormValid {
                        onNext()
                    }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? AppTheme.orange : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    var isFormValid: Bool {
        !data.name.isEmpty 
        && emailError == nil 
        && phoneError == nil
    }
}
