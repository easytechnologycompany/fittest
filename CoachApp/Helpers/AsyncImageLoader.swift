//
//  AsyncImageLoader.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

/// Helper for loading images asynchronously from URLs
struct AsyncExerciseImage: View {
    let imageUrl: String?
    let placeholder: String
    @State private var image: Image?
    @State private var isLoading = true
    @State private var loadError: Error?
    
    init(imageUrl: String?, placeholder: String = "photo") {
        self.imageUrl = imageUrl
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: placeholder)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let imageUrl = imageUrl, let url = getFullImageURL(imageUrl) else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            #if canImport(UIKit)
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = Image(uiImage: uiImage)
                    self.isLoading = false
                }
            }
            #elseif canImport(AppKit)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    self.image = Image(nsImage: nsImage)
                    self.isLoading = false
                }
            }
            #endif
        } catch {
            await MainActor.run {
                self.loadError = error
                self.isLoading = false
            }
        }
    }
    
    private func getFullImageURL(_ imageName: String) -> URL? {
        // ExerciseDB image URLs - may need adjustment based on actual API
        // Common patterns:
        // - Full URL already provided
        // - Relative path that needs base URL
        if imageName.hasPrefix("http") {
            return URL(string: imageName)
        } else {
            // Try common ExerciseDB image base URLs
            let baseURLs = [
                "https://exercisedb.p.rapidapi.com/images/",
                "https://edb-images.s3.amazonaws.com/",
                "https://exercisedb-images.s3.amazonaws.com/"
            ]
            
            for baseURL in baseURLs {
                if let url = URL(string: baseURL + imageName) {
                    return url
                }
            }
            
            return nil
        }
    }
}

/// Image cache for ExerciseDB images
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("ExerciseDBImages")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getImageData(for url: String) -> Data? {
        // Check memory cache
        if let data = cache.object(forKey: url as NSString) {
            return data as Data
        }
        
        // Check disk cache
        if let fileURL = getFileURL(for: url),
           let data = try? Data(contentsOf: fileURL) {
            // Store in memory cache
            cache.setObject(data as NSData, forKey: url as NSString)
            return data
        }
        
        return nil
    }
    
    func setImageData(_ data: Data, for url: String) {
        // Store in memory cache
        cache.setObject(data as NSData, forKey: url as NSString)
        
        // Store on disk
        if let fileURL = getFileURL(for: url) {
            try? data.write(to: fileURL)
        }
    }
    
    private func getFileURL(for url: String) -> URL? {
        let fileName = url.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
