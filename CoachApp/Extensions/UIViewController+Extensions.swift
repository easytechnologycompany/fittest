//
//  UIViewController+Extensions.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

#if os(iOS)
import UIKit

extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }
        
        // Check parent
        if let parent = self.parent, let tabBarController = parent.findTabBarController() {
            return tabBarController
        }
        
        // Check presenting view controller
        if let presenting = self.presentingViewController, let tabBarController = presenting.findTabBarController() {
            return tabBarController
        }
        
        // Check navigation controller's parent
        if let navController = self.navigationController, let parent = navController.parent as? UITabBarController {
            return parent
        }
        
        return nil
    }
    
    static func findRootTabBarController() -> UITabBarController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        return rootViewController.findTabBarController()
    }
    
    /// Get the topmost view controller in the hierarchy
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        return self
    }
}
#endif

