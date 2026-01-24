//
//  AppTheme.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// Extension to easily use Hex codes in SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// App Theme Colors
struct AppTheme {
    // Primary Colors
    static let orange = Color(hex: "#FF914D")         // Orange - primary accent
    static let blue = Color(hex: "#2A4762")          // Blue - primary dark color
    static let darkBlue = Color(hex: "#1a2f3f")       // Darker blue - for dark mode backgrounds
    static let lightBlue = Color(hex: "#4a6b85")      // Lighter blue - for gradients
    static let celeste = Color(hex: "#d2d3ce")        // Light pale gray - subtle backgrounds
    static let ceilingWhite = Color(hex: "#e9ebe6")    // Off-white - main backgrounds
    
    // Legacy support - keeping old names for compatibility
    static var pear: Color { orange }
    static var richBlack: Color { blue }
    static var darkGreen: Color { darkBlue }
    static var laurelLeaf: Color { Color.secondary }
    
    // Adaptive Colors for Light/Dark Mode
    static func textColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ceilingWhite : blue
    }
    
    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        return blue // Always Navy Blue
    }
    
    static func secondaryBackgroundColor(for colorScheme: ColorScheme) -> Color {
        return blue // Always Navy Blue
    }
    
    static func cardBackgroundColor(for colorScheme: ColorScheme) -> Color {
        #if os(macOS)
        return colorScheme == .dark ? orange.opacity(0.8) : orange.opacity(0.3)
        #else
        return colorScheme == .dark ? orange.opacity(0.8) : orange.opacity(0.3)
        #endif
    }
    
    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.secondary : Color.secondary
    }
    
    /// Text color for text inside gradient cards - white in dark mode for better contrast
    static func gradientCardTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : blue
    }
    
    /// Secondary text color for text inside gradient cards
    static func gradientCardSecondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(0.8) : Color.secondary
    }
    
    // Primary color (replaces gradients) - adaptive
    static func primaryColor(for colorScheme: ColorScheme) -> Color {
        return orange
    }
    
    // Legacy support - returns solid color instead of gradient
    static func primaryGradient(for colorScheme: ColorScheme) -> Color {
        return orange
    }
    
    static func primaryGradientReversed(for colorScheme: ColorScheme) -> Color {
        return orange
    }
    
    // Legacy support - uses light mode by default
    static var primaryGradient: Color {
        orange
    }
    
    static var primaryGradientReversed: Color {
        orange
    }
}

// View Modifiers for consistent styling
struct GradientBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.primaryGradient(for: colorScheme))
    }
}

struct GradientButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(AppTheme.primaryGradient(for: colorScheme))
            .foregroundColor(AppTheme.textColor(for: colorScheme))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct GradientCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                AppTheme.orange.opacity(colorScheme == .dark ? 0.8 : 0.3)
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
    }
}

// New unified card style matching screenshot design
struct ModernCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let isOrange: Bool
    
    func body(content: Content) -> some View {
        if isOrange {
            // Orange cards: solid background, no border, subtle shadow
            content
                .background(AppTheme.orange)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 10, x: 0, y: 4)
        } else {
            // White/light cards: subtle border and shadow for floating effect
            content
                .background(
                    colorScheme == .dark 
                        ? AppTheme.cardBackgroundColor(for: colorScheme)
                        : Color.white
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark 
                                ? AppTheme.orange.opacity(0.3)
                                : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 6, x: 0, y: 2)
        }
    }
}

extension View {
    func gradientBackground() -> some View {
        modifier(GradientBackgroundModifier())
    }
    
    func gradientCard() -> some View {
        modifier(GradientCardStyle())
    }
    
    func modernCard(isOrange: Bool = true) -> some View {
        modifier(ModernCardStyle(isOrange: isOrange))
    }
}

