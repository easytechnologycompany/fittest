//
//  ImageCompressionHelper.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Helper for compressing images before storing in database
struct ImageCompressionHelper {
    /// Maximum dimensions for profile photos
    static let maxProfilePhotoSize: CGFloat = 500
    /// Maximum dimensions for progress photos
    static let maxProgressPhotoSize: CGFloat = 800
    /// Maximum dimensions for signatures
    static let maxSignatureSize: CGFloat = 800
    /// JPEG compression quality (0.0 to 1.0)
    static let jpegQuality: CGFloat = 0.7
    
    /// Compress image data for profile photos
    @MainActor
    static func compressProfilePhoto(_ imageData: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData) else { return nil }
        return compressImage(image, maxSize: maxProfilePhotoSize)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: imageData) else { return nil }
        return compressImage(image, maxSize: maxProfilePhotoSize)
        #else
        return imageData
        #endif
    }
    
    /// Compress image data for progress photos
    @MainActor
    static func compressProgressPhoto(_ imageData: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData) else { return nil }
        return compressImage(image, maxSize: maxProgressPhotoSize)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: imageData) else { return nil }
        return compressImage(image, maxSize: maxProgressPhotoSize)
        #else
        return imageData
        #endif
    }
    
    /// Compress signature image data
    @MainActor
    static func compressSignature(_ imageData: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData) else { return nil }
        return compressImage(image, maxSize: maxSignatureSize)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: imageData) else { return nil }
        return compressImage(image, maxSize: maxSignatureSize)
        #else
        return imageData
        #endif
    }
    
    #if canImport(UIKit)
    private static func compressImage(_ image: UIImage, maxSize: CGFloat) -> Data? {
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        // Compress to JPEG
        return resizedImage.jpegData(compressionQuality: jpegQuality)
    }
    #elseif canImport(AppKit)
    private static func compressImage(_ image: NSImage, maxSize: CGFloat) -> Data? {
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let aspectRatio = size.width / size.height
        var newSize: NSSize
        
        if size.width > size.height {
            newSize = NSSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = NSSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        // Create resized image
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .sourceOver,
                   fraction: 1.0)
        resizedImage.unlockFocus()
        
        // Convert to JPEG
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: jpegQuality])
    }
    #endif
}
