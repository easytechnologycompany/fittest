//
//  SheetPresentationHelper.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

/// Helper for presenting sheets that work correctly on iPhone, iPad, and Mac
extension View {
    /// Present a sheet with proper platform-specific configuration
    func platformSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
        return self.sheet(isPresented: isPresented) {
            content()
                .frame(minWidth: 500, minHeight: 400)
        }
        #else
        return self.sheet(isPresented: isPresented) {
            content()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        #endif
    }
    
    /// Present a sheet with custom detents for iOS
    func platformSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
        return self.sheet(isPresented: isPresented) {
            content()
                .frame(minWidth: 500, minHeight: 400)
        }
        #else
        return self.sheet(isPresented: isPresented) {
            content()
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
        }
        #endif
    }
}

