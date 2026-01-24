//
//  IconPreviewView.swift
//  CoachApp
//
//  Icon Preview - Screenshot this to use as your app icon
//

import SwiftUI

struct IconPreviewView: View {
    var body: some View {
        ZStack {
            // Background
            AppTheme.blue
            
            // Main Icon Circle
            Circle()
                .fill(AppTheme.orange)
                .frame(width: 800, height: 800)
                .overlay(
                    // Dumbbell Icon
                    HStack(spacing: 120) {
                        // Left Weight
                        Circle()
                            .fill(AppTheme.orange)
                            .frame(width: 200, height: 200)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.blue, lineWidth: 8)
                            )
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.orange)
                            .frame(width: 240, height: 30)
                        
                        // Right Weight
                        Circle()
                            .fill(AppTheme.orange)
                            .frame(width: 200, height: 200)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.blue, lineWidth: 8)
                            )
                    }
                )
                .overlay(
                    // "GO" Text
                    VStack {
                        Spacer()
                        Text("GO")
                            .font(.system(size: 180, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.orange)
                            .padding(.bottom, 100)
                    }
                )
        }
        .frame(width: 1024, height: 1024)
        .ignoresSafeArea()
    }
}

#Preview {
    IconPreviewView()
}

