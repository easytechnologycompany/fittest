//
//  TabBarVisibilityHelper.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

#if os(iOS)
import UIKit

struct TabBarAccessor: UIViewControllerRepresentable {
    var callback: (UITabBarController?) -> Void
    
    func makeUIViewController(context: Context) -> TabBarAccessorViewController {
        TabBarAccessorViewController(callback: callback)
    }
    
    func updateUIViewController(_ uiViewController: TabBarAccessorViewController, context: Context) {
        uiViewController.callback = callback
    }
}

class TabBarAccessorViewController: UIViewController {
    var callback: (UITabBarController?) -> Void
    
    init(callback: @escaping (UITabBarController?) -> Void) {
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        callback(tabBarController)
    }
}

struct HideTabBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                TabBarAccessor { tabBarController in
                    tabBarController?.tabBar.isHidden = true
                }
                .frame(width: 0, height: 0)
            )
    }
}

struct ShowTabBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                TabBarAccessor { tabBarController in
                    tabBarController?.tabBar.isHidden = false
                }
                .frame(width: 0, height: 0)
            )
    }
}

extension View {
    func hideTabBar() -> some View {
        modifier(HideTabBar())
    }
    
    func showTabBar() -> some View {
        modifier(ShowTabBar())
    }
}
#endif

