//
//  CourseExporter.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
import Photos
#elseif canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

struct CourseExporter {
    #if os(iOS)
    private static func loadLogoImage() -> UIImage? {
        return UIImage(named: "logo")
    }
    #elseif os(macOS)
    private static func loadLogoImage() -> NSImage? {
        return NSImage(named: "logo")
    }
    #endif
    
    static func exportAsPDF(course: TrainingCourseFS) {
#if os(iOS)
        let pdfMetaData = [
            kCGPDFContextCreator: "Fit Fast",
            kCGPDFContextAuthor: "Gym Coach",
            kCGPDFContextTitle: course.title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72
            
            // Logo
            if let logoImage = loadLogoImage() {
                let logoSize = CGSize(width: 60, height: 60)
                let logoRect = CGRect(x: pageWidth - 72 - logoSize.width, y: yPosition, width: logoSize.width, height: logoSize.height)
                logoImage.draw(in: logoRect)
                yPosition += 70
            }
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 30)
            course.title.draw(in: titleRect, withAttributes: titleAttributes)
            yPosition += 40
            
            // Description
            if let description = course.courseDescription, !description.isEmpty {
                let descAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.gray
                ]
                let descRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 60)
                description.draw(in: descRect, withAttributes: descAttributes)
                yPosition += 70
            }
            
            // Course Info
            let infoText = "Duration: \(course.durationMonths) month\(course.durationMonths > 1 ? "s" : "") | Difficulty: \(course.difficulty)"
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
            let infoRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 20)
            infoText.draw(in: infoRect, withAttributes: infoAttributes)
            yPosition += 30
            
            // Days
            if let days = course.days, !days.isEmpty {
                for day in days.sorted(by: { $0.order < $1.order }) {
                    if yPosition > pageHeight - 150 {
                        context.beginPage()
                        yPosition = 72
                        // Logo on new page
                        if let logoImage = loadLogoImage() {
                            let logoSize = CGSize(width: 60, height: 60)
                            let logoRect = CGRect(x: pageWidth - 72 - logoSize.width, y: yPosition, width: logoSize.width, height: logoSize.height)
                            logoImage.draw(in: logoRect)
                            yPosition += 70
                        }
                    }
                    
                    // Day Header
                    let dayTitle = "Day \(day.dayNumber): \(day.workoutTitle ?? "Workout")"
                    let dayTitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 16),
                        .foregroundColor: UIColor.black
                    ]
                    let dayTitleRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 20)
                    dayTitle.draw(in: dayTitleRect, withAttributes: dayTitleAttributes)
                    yPosition += 30
                    
                    // Exercises for this day
                    if let exercises = day.exercises, !exercises.isEmpty {
                        for (index, exercise) in exercises.sorted(by: { $0.order < $1.order }).enumerated() {
                            if yPosition > pageHeight - 100 {
                                context.beginPage()
                                yPosition = 72
                                // Logo on new page
                                if let logoImage = loadLogoImage() {
                                    let logoSize = CGSize(width: 60, height: 60)
                                    let logoRect = CGRect(x: pageWidth - 72 - logoSize.width, y: yPosition, width: logoSize.width, height: logoSize.height)
                                    logoImage.draw(in: logoRect)
                                    yPosition += 70
                                }
                            }
                            
                            let exerciseText = "  \(index + 1). \(exercise.name)\n     Sets: \(exercise.sets) × Reps: \(exercise.reps)"
                            var exerciseDetails = exerciseText
                            if let weight = exercise.weight {
                                exerciseDetails += " | Weight: \(String(format: "%.1f", weight)) kg"
                            }
                            if let restTime = exercise.restTime {
                                exerciseDetails += " | Rest: \(restTime)s"
                            }
                            if let notes = exercise.notes, !notes.isEmpty {
                                exerciseDetails += "\n     Notes: \(notes)"
                            }
                            
                            let exerciseAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 11),
                                .foregroundColor: UIColor.black
                            ]
                            let exerciseRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 50)
                            exerciseDetails.draw(in: exerciseRect, withAttributes: exerciseAttributes)
                            yPosition += 60
                        }
                    }
                    yPosition += 20 // Space between days
                }
            }
        }
        
        // Save PDF
        savePDF(data: data, filename: "\(course.title).pdf")
#elseif os(macOS)
        // macOS PDF export
        let pdfData = createPDFData(course: course)
        savePDF(data: pdfData, filename: "\(course.title).pdf")
#endif
    }
    
    static func exportAsImage(course: TrainingCourseFS) {
#if os(iOS)
        let size = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            var yPosition: CGFloat = 100
            
            // Logo
            if let logoImage = loadLogoImage() {
                let logoSize = CGSize(width: 120, height: 120)
                let logoRect = CGRect(x: size.width - 100 - logoSize.width, y: yPosition, width: logoSize.width, height: logoSize.height)
                logoImage.draw(in: logoRect)
                yPosition += 130
            }
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: 100, y: yPosition, width: size.width - 200, height: 60)
            course.title.draw(in: titleRect, withAttributes: titleAttributes)
            yPosition += 80
            
            // Description
            if let description = course.courseDescription, !description.isEmpty {
                let descAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24),
                    .foregroundColor: UIColor.gray
                ]
                let descRect = CGRect(x: 100, y: yPosition, width: size.width - 200, height: 120)
                description.draw(in: descRect, withAttributes: descAttributes)
                yPosition += 140
            }
            
            // Course Info
            let infoText = "Duration: \(course.durationMonths) month\(course.durationMonths > 1 ? "s" : "") | Difficulty: \(course.difficulty)"
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22),
                .foregroundColor: UIColor.darkGray
            ]
            let infoRect = CGRect(x: 100, y: yPosition, width: size.width - 200, height: 40)
            infoText.draw(in: infoRect, withAttributes: infoAttributes)
            yPosition += 60
            
            // Days
            if let days = course.days, !days.isEmpty {
                for day in days.sorted(by: { $0.order < $1.order }) {
                    if yPosition > size.height - 300 {
                        break
                    }
                    
                    // Day Header
                    let dayTitle = "Day \(day.dayNumber): \(day.workoutTitle ?? "Workout")"
                    let dayTitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 32),
                        .foregroundColor: UIColor.black
                    ]
                    let dayTitleRect = CGRect(x: 100, y: yPosition, width: size.width - 200, height: 40)
                    dayTitle.draw(in: dayTitleRect, withAttributes: dayTitleAttributes)
                    yPosition += 60
                    
                    // Exercises for this day
                    if let exercises = day.exercises, !exercises.isEmpty {
                        for (index, exercise) in exercises.sorted(by: { $0.order < $1.order }).enumerated() {
                            if yPosition > size.height - 200 {
                                break
                            }
                            
                            let exerciseText = "  \(index + 1). \(exercise.name)\n     Sets: \(exercise.sets) × Reps: \(exercise.reps)"
                            var exerciseDetails = exerciseText
                            if let weight = exercise.weight {
                                exerciseDetails += " | Weight: \(String(format: "%.1f", weight)) kg"
                            }
                            if let restTime = exercise.restTime {
                                exerciseDetails += " | Rest: \(restTime)s"
                            }
                            if let notes = exercise.notes, !notes.isEmpty {
                                exerciseDetails += "\n     Notes: \(notes)"
                            }
                            
                            let exerciseAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 22),
                                .foregroundColor: UIColor.black
                            ]
                            let exerciseRect = CGRect(x: 100, y: yPosition, width: size.width - 200, height: 100)
                            exerciseDetails.draw(in: exerciseRect, withAttributes: exerciseAttributes)
                            yPosition += 120
                        }
                    }
                    yPosition += 40 // Space between days
                }
            }
        }
        
        // Save Image
        if let imageData = image.pngData() {
            saveImage(data: imageData, filename: "\(course.title).png")
        }
#elseif os(macOS)
        // macOS Image export
        if let image = createImage(course: course),
           let imageData = image.tiffRepresentation,
           let pngData = NSBitmapImageRep(data: imageData)?.representation(using: .png, properties: [:]) {
            saveImage(data: pngData, filename: "\(course.title).png")
        }
#endif
    }
    
    private static func savePDF(data: Data, filename: String) {
#if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        
        // Configure for iPad - needs popover source
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            let topViewController = rootViewController.topMostViewController()
            
            // For iPad, configure popover presentation
            if let popover = activityVC.popoverPresentationController {
                // Try to find a navigation bar button first
                if let navController = topViewController.navigationController,
                   let visibleVC = navController.visibleViewController {
                    // Try to use navigation bar button
                    if let barButtonItem = visibleVC.navigationItem.rightBarButtonItem {
                        popover.barButtonItem = barButtonItem
                    } else {
                        // Fallback to view center
                        popover.sourceView = visibleVC.view
                        popover.sourceRect = CGRect(x: visibleVC.view.bounds.midX, y: visibleVC.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                } else {
                    // Fallback to view center
                    popover.sourceView = topViewController.view
                    popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
            }
            
            topViewController.present(activityVC, animated: true)
        }
#elseif os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = filename
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? data.write(to: url)
            }
        }
#endif
    }
    
    private static func saveImage(data: Data, filename: String) {
#if os(iOS)
        if let image = UIImage(data: data) {
            // Request photo library permission
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized || status == .limited {
                    // Save to photo library
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }, completionHandler: { success, error in
                        DispatchQueue.main.async {
                            if success {
                                print("Image saved to photo library successfully")
                            } else if let error = error {
                                print("Error saving image: \(error.localizedDescription)")
                            }
                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        print("Photo library access denied")
                    }
                }
            }
        }
#elseif os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = filename
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? data.write(to: url)
            }
        }
#endif
    }
    
#if os(macOS)
    private static func createPDFData(course: TrainingCourseFS) -> Data {
        let pdfMetaData: [CFString: Any] = [
            kCGPDFContextCreator: "Fit Fast",
            kCGPDFContextAuthor: "Gym Coach",
            kCGPDFContextTitle: course.title
        ]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData) else {
            print("Error: Failed to create CGDataConsumer")
            return Data()
        }
        var mediaBox = pageRect
        
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, pdfMetaData as CFDictionary) else {
            print("Error: Failed to create CGContext")
            return Data()
        }
        context.beginPDFPage(nil)
        
        var yPosition: CGFloat = pageHeight - 72
        
        // Logo
        if let logoImage = loadLogoImage() {
            let logoSize = NSSize(width: 60, height: 60)
            let logoRect = NSRect(x: pageWidth - 72 - logoSize.width, y: yPosition - logoSize.height, width: logoSize.width, height: logoSize.height)
            logoImage.draw(in: logoRect)
            yPosition -= 70
        }
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let titleRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 30)
        course.title.draw(in: titleRect, withAttributes: titleAttributes)
        yPosition -= 40
        
        // Description
        if let description = course.courseDescription, !description.isEmpty {
            let descFont = NSFont.systemFont(ofSize: 12)
            let descAttributes: [NSAttributedString.Key: Any] = [
                .font: descFont,
                .foregroundColor: NSColor.gray
            ]
            let descRect = CGRect(x: 72, y: yPosition - 60, width: pageWidth - 144, height: 60)
            description.draw(in: descRect, withAttributes: descAttributes)
            yPosition -= 70
        }
        
        // Course Info
        let infoText = "Duration: \(course.durationMonths) month\(course.durationMonths > 1 ? "s" : "") | Difficulty: \(course.difficulty)"
        let infoFont = NSFont.systemFont(ofSize: 11)
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: infoFont,
            .foregroundColor: NSColor.darkGray
        ]
        let infoRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 20)
        infoText.draw(in: infoRect, withAttributes: infoAttributes)
        yPosition -= 30
        
        // Days
        if let days = course.days, !days.isEmpty {
            for day in days.sorted(by: { $0.order < $1.order }) {
                if yPosition < 150 {
                    context.endPDFPage()
                    context.beginPDFPage(nil)
                    yPosition = pageHeight - 72
                    // Logo on new page
                    if let logoImage = loadLogoImage() {
                        let logoSize = NSSize(width: 60, height: 60)
                        let logoRect = NSRect(x: pageWidth - 72 - logoSize.width, y: yPosition - logoSize.height, width: logoSize.width, height: logoSize.height)
                        logoImage.draw(in: logoRect)
                        yPosition -= 70
                    }
                }
                
                // Day Header
                let dayTitle = "Day \(day.dayNumber): \(day.workoutTitle ?? "Workout")"
                let dayTitleFont = NSFont.boldSystemFont(ofSize: 16)
                let dayTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: dayTitleFont,
                    .foregroundColor: NSColor.black
                ]
                let dayTitleRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 20)
                dayTitle.draw(in: dayTitleRect, withAttributes: dayTitleAttributes)
                yPosition -= 30
                
                // Exercises for this day
                let exercises = day.exercises
                if !(exercises?.isEmpty ?? true) {
                    for (index, exercise) in exercises.sorted(by: { $0.order < $1.order }).enumerated() {
                        if yPosition < 100 {
                            context.endPDFPage()
                            context.beginPDFPage(nil)
                            yPosition = pageHeight - 72
                            // Logo on new page
                            if let logoImage = loadLogoImage() {
                                let logoSize = NSSize(width: 60, height: 60)
                                let logoRect = NSRect(x: pageWidth - 72 - logoSize.width, y: yPosition - logoSize.height, width: logoSize.width, height: logoSize.height)
                                logoImage.draw(in: logoRect)
                                yPosition -= 70
                            }
                        }
                        
                        let exerciseText = "  \(index + 1). \(exercise.name)\n     Sets: \(exercise.sets) × Reps: \(exercise.reps)"
                        var exerciseDetails = exerciseText
                        if let weight = exercise.weight {
                            exerciseDetails += " | Weight: \(String(format: "%.1f", weight)) kg"
                        }
                        if let restTime = exercise.restTime {
                            exerciseDetails += " | Rest: \(restTime)s"
                        }
                        if let notes = exercise.notes, !notes.isEmpty {
                            exerciseDetails += "\n     Notes: \(notes)"
                        }
                        
                        let exerciseFont = NSFont.systemFont(ofSize: 11)
                        let exerciseAttributes: [NSAttributedString.Key: Any] = [
                            .font: exerciseFont,
                            .foregroundColor: NSColor.black
                        ]
                        let exerciseRect = CGRect(x: 72, y: yPosition - 50, width: pageWidth - 144, height: 50)
                        exerciseDetails.draw(in: exerciseRect, withAttributes: exerciseAttributes)
                        yPosition -= 60
                    }
                }
                yPosition -= 20 // Space between days
            }
        }
        
        context.endPDFPage()
        context.closePDF()
        
        return mutableData as Data
    }
    
    private static func createImage(course: TrainingCourseFS) -> NSImage? {
        let size = NSSize(width: 1200, height: 1600)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        var yPosition: CGFloat = size.height - 100
        
        // Logo
        if let logoImage = loadLogoImage() {
            let logoSize = NSSize(width: 120, height: 120)
            let logoRect = NSRect(x: size.width - 100 - logoSize.width, y: yPosition - logoSize.height, width: logoSize.width, height: logoSize.height)
            logoImage.draw(in: logoRect)
            yPosition -= 130
        }
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 48)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let titleRect = NSRect(x: 100, y: yPosition, width: size.width - 200, height: 60)
        course.title.draw(in: titleRect, withAttributes: titleAttributes)
        yPosition -= 80
        
        // Description
        if let description = course.courseDescription, !description.isEmpty {
            let descFont = NSFont.systemFont(ofSize: 24)
            let descAttributes: [NSAttributedString.Key: Any] = [
                .font: descFont,
                .foregroundColor: NSColor.gray
            ]
            let descRect = NSRect(x: 100, y: yPosition - 120, width: size.width - 200, height: 120)
            description.draw(in: descRect, withAttributes: descAttributes)
            yPosition -= 140
        }
        
        // Course Info
        let infoText = "Duration: \(course.durationMonths) month\(course.durationMonths > 1 ? "s" : "") | Difficulty: \(course.difficulty)"
        let infoFont = NSFont.systemFont(ofSize: 22)
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: infoFont,
            .foregroundColor: NSColor.darkGray
        ]
        let infoRect = NSRect(x: 100, y: yPosition, width: size.width - 200, height: 40)
        infoText.draw(in: infoRect, withAttributes: infoAttributes)
        yPosition -= 60
        
        // Days
        if let days = course.days, !days.isEmpty {
            for day in days.sorted(by: { $0.order < $1.order }) {
                if yPosition < 300 {
                    break
                }
                
                // Day Header
                let dayTitle = "Day \(day.dayNumber): \(day.workoutTitle ?? "Workout")"
                let dayTitleFont = NSFont.boldSystemFont(ofSize: 32)
                let dayTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: dayTitleFont,
                    .foregroundColor: NSColor.black
                ]
                let dayTitleRect = NSRect(x: 100, y: yPosition, width: size.width - 200, height: 40)
                dayTitle.draw(in: dayTitleRect, withAttributes: dayTitleAttributes)
                yPosition -= 60
                
                // Exercises for this day
                let exercises = day.exercises
                if !(exercises?.isEmpty ?? true) {
                    for (index, exercise) in exercises.sorted(by: { $0.order < $1.order }).enumerated() {
                        if yPosition < 200 {
                            break
                        }
                        
                        let exerciseText = "  \(index + 1). \(exercise.name)\n     Sets: \(exercise.sets) × Reps: \(exercise.reps)"
                        var exerciseDetails = exerciseText
                        if let weight = exercise.weight {
                            exerciseDetails += " | Weight: \(String(format: "%.1f", weight)) kg"
                        }
                        if let restTime = exercise.restTime {
                            exerciseDetails += " | Rest: \(restTime)s"
                        }
                        if let notes = exercise.notes, !notes.isEmpty {
                            exerciseDetails += "\n     Notes: \(notes)"
                        }
                        
                        let exerciseFont = NSFont.systemFont(ofSize: 22)
                        let exerciseAttributes: [NSAttributedString.Key: Any] = [
                            .font: exerciseFont,
                            .foregroundColor: NSColor.black
                        ]
                        let exerciseRect = NSRect(x: 100, y: yPosition - 100, width: size.width - 200, height: 100)
                        exerciseDetails.draw(in: exerciseRect, withAttributes: exerciseAttributes)
                        yPosition -= 120
                    }
                }
                yPosition -= 40 // Space between days
            }
        }
        
        image.unlockFocus()
        return image
    }
#endif
}

