//
//  SignatureStepView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine

struct SignatureStepView: View {
    @Binding var data: OnboardingData
    var onBack: () -> Void
    var onComplete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Signature")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Please sign below to complete your registration")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Signature capture area
            SignatureCaptureView(signatureData: $data.signatureData)
                .frame(height: 300)
                .padding(.horizontal)
            
            // Navigation Buttons
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(AppTheme.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.orange.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    if data.isSignatureValid {
                        onComplete()
                    }
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(data.isSignatureValid ? AppTheme.orange : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!data.isSignatureValid)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    SignatureStepView(data: .constant(OnboardingData()), onBack: {}, onComplete: {})
}
