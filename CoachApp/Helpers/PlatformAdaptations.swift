//
//  PlatformAdaptations.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Platform-specific UI adaptations and helpers
struct PlatformAdaptations {
    /// Check if running on iPad
    static var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    /// Check if running on iPhone
    static var isIPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }
    
    /// Check if running on Mac
    static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    /// Optimal column count for grid layouts - optimized for iPad as default
    static func gridColumns(minWidth: CGFloat = 150) -> [GridItem] {
        // Default to iPad (3 columns), fallback to Mac or iPhone
        if isMac {
            return [GridItem(.adaptive(minimum: minWidth * 1.5), spacing: 20)]
        } else if isIPhone {
            return [GridItem(.adaptive(minimum: minWidth), spacing: 16)]
        } else {
            // iPad: Optimized adaptive layout
            // Use larger minimum width for the bold cards to breathe
            return [GridItem(.adaptive(minimum: 220), spacing: 20)]
        }
    }
    
    /// Optimal padding for cards - optimized for iPad as default
    static var cardPadding: CGFloat {
        if isMac {
            return 20
        } else if isIPhone {
            return 12
        } else {
            // iPad default
            return 16
        }
    }
    
    /// Optimal spacing for VStack/HStack - optimized for iPad as default
    static var defaultSpacing: CGFloat {
        if isMac {
            return 20
        } else if isIPhone {
            return 12
        } else {
            // iPad default
            return 16
        }
    }
}

/// View modifier to add proper sheet presentation for all platforms
struct AdaptiveSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> AnyView
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                self.content()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    /// Apply adaptive sheet presentation that works on iPhone, iPad, and Mac
    func adaptiveSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.sheet(isPresented: isPresented) {
            content()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    /// Apply proper navigation bar title display mode for each platform
    func adaptiveNavigationTitle(_ title: String) -> some View {
        #if os(iOS)
        return self.navigationTitle(title)
            .navigationBarTitleDisplayMode(PlatformAdaptations.isIPad ? .large : .inline)
        #else
        return self.navigationTitle(title)
        #endif
    }
    
    /// Apply toolbar item placement that works on all platforms
    func adaptiveToolbar<Content: View>(@ToolbarContentBuilder content: () -> Content) -> some View {
        #if os(macOS)
        return self.toolbar {
            ToolbarItem(placement: .automatic) {
                content()
            }
        }
        #else
        return self.toolbar {
            content()
        }
        #endif
    }
}

