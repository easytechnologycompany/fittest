//
//  TabBarVisibilityModifier.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct TabBarVisibilityModifier: ViewModifier {
    let isHidden: Bool
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .toolbar(isHidden ? .hidden : .visible, for: .tabBar)
        #else
        content
        #endif
    }
}

extension View {
    func tabBarHidden(_ hidden: Bool = true) -> some View {
        modifier(TabBarVisibilityModifier(isHidden: hidden))
    }
}

