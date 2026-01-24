//
//  SubscriberExporter.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
import Photos
#elseif canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

struct SubscriberExporter {
    #if os(iOS)
    private static func loadLogoImage() -> UIImage? {
        return UIImage(named: "logo")
    }
    #elseif os(macOS)
    private static func loadLogoImage() -> NSImage? {
        return NSImage(named: "logo")
    }
    #endif
    
    static func exportAsImage(subscriber: Subscriber) {
#if os(iOS)
        let imageWidth: CGFloat = 1200
        let topMargin: CGFloat = 100
        let bottomMargin: CGFloat = 200 // Space for signature at bottom
        let sectionSpacing: CGFloat = 40
        
        // Calculate total height needed for all content
        var totalHeight: CGFloat = topMargin + bottomMargin
        
        // Title (Name)
        totalHeight += 80
        
        // Basic Information
        let basicItems = getBasicInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeight(items: basicItems) + sectionSpacing
        
        // Subscription Information
        let subscriptionItems = getSubscriptionInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeight(items: subscriptionItems) + sectionSpacing
        
        // Physical Information
        let physicalItems = getPhysicalInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeight(items: physicalItems) + sectionSpacing
        
        // Health Information
        let healthItems = getHealthInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeight(items: healthItems) + sectionSpacing
        
        // Medical Information
        let medicalItems = getMedicalInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeight(items: medicalItems) + sectionSpacing
        
        // Fitness Goals
        let goalsText = subscriber.onboardingFitnessGoals?.isEmpty == false ? subscriber.onboardingFitnessGoals! : "N/A"
        totalHeight += estimateSectionHeight(items: [("Goals", goalsText)]) + sectionSpacing
        
        // Signature
        totalHeight += 200
        
        // Create single image with calculated height
        let imageHeight = max(1600, totalHeight)
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            
            var yPos = topMargin
            
            // 1. Signature - at top
            if let signatureData = subscriber.signatureData, let signatureImage = UIImage(data: signatureData) {
                drawSignatureSectionImage(signatureImage: signatureImage, width: imageWidth, height: imageHeight, fromTop: true)
            } else {
                drawSignatureSectionImage(signatureImage: nil, width: imageWidth, height: imageHeight, fromTop: true)
            }
            
            // Calculate signature height for spacing (title + spacing + signature + extra spacing)
            let signatureHeight: CGFloat = 40 + 15 + 105 + sectionSpacing
            yPos += signatureHeight
            
            // 2. Fitness Goals
            yPos = drawSectionImage(title: "Fitness Goals", items: [("Goals", goalsText)], yPosition: yPos, width: imageWidth, fromTop: true)
            yPos += sectionSpacing
            
            // 3. Medical Information
            yPos = drawSectionImage(title: "Medical Information", items: medicalItems, yPosition: yPos, width: imageWidth, fromTop: true)
            yPos += sectionSpacing
            
            // 4. Health Information
            yPos = drawSectionImage(title: "Health Information", items: healthItems, yPosition: yPos, width: imageWidth, fromTop: true)
            yPos += sectionSpacing
            
            // 5. Physical Information
            yPos = drawSectionImage(title: "Physical Information", items: physicalItems, yPosition: yPos, width: imageWidth, fromTop: true)
            yPos += sectionSpacing
            
            // 6. Subscription Information
            yPos = drawSectionImage(title: "Subscription Information", items: subscriptionItems, yPosition: yPos, width: imageWidth, fromTop: true)
            yPos += sectionSpacing
            
            // 7. Basic Information
            yPos = drawSectionImage(title: "Basic Information", items: basicItems, yPosition: yPos, width: imageWidth, fromTop: true)
            yPos += sectionSpacing
            
            // 8. Title (Name) - at bottom
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.black
            ]
            let titleText = subscriber.name.isEmpty ? "Subscriber Information" : subscriber.name
            let titleRect = CGRect(x: 100, y: imageHeight - bottomMargin - 60, width: imageWidth - 200, height: 60)
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
        }
        
        // Save single image
        let baseFilename = subscriber.name.isEmpty ? "Subscriber" : subscriber.name
        if let imageData = image.pngData() {
            saveImage(data: imageData, filename: "\(baseFilename).png")
        }
#elseif os(macOS)
        let imageWidth: CGFloat = 1200
        let topMargin: CGFloat = 100
        let bottomMargin: CGFloat = 200 // Space for signature at bottom
        let sectionSpacing: CGFloat = 40
        
        // Calculate total height needed for all content
        var totalHeight: CGFloat = topMargin + bottomMargin
        
        // Title (Name)
        totalHeight += 80
        
        // Basic Information
        let basicItems = getBasicInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeightMac(items: basicItems) + sectionSpacing
        
        // Subscription Information
        let subscriptionItems = getSubscriptionInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeightMac(items: subscriptionItems) + sectionSpacing
        
        // Physical Information
        let physicalItems = getPhysicalInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeightMac(items: physicalItems) + sectionSpacing
        
        // Health Information
        let healthItems = getHealthInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeightMac(items: healthItems) + sectionSpacing
        
        // Medical Information
        let medicalItems = getMedicalInfoItems(subscriber: subscriber)
        totalHeight += estimateSectionHeightMac(items: medicalItems) + sectionSpacing
        
        // Fitness Goals
        let goalsText = subscriber.onboardingFitnessGoals?.isEmpty == false ? subscriber.onboardingFitnessGoals! : "N/A"
        totalHeight += estimateSectionHeightMac(items: [("Goals", goalsText)]) + sectionSpacing
        
        // Signature
        totalHeight += 200
        
        // Create single image with calculated height
        let imageHeight = max(1600, totalHeight)
        let imageSize = NSSize(width: imageWidth, height: imageHeight)
        let image = NSImage(size: imageSize)
        
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: imageSize).fill()
        
        var yPos = topMargin
        
        // 1. Signature - at top
        if let signatureData = subscriber.signatureData, let signatureImage = NSImage(data: signatureData) {
            drawSignatureSectionImageMac(signatureImage: signatureImage, width: imageWidth, height: imageHeight, fromTop: true)
        } else {
            drawSignatureSectionImageMac(signatureImage: nil, width: imageWidth, height: imageHeight, fromTop: true)
        }
        
        // Calculate signature height for spacing (title + spacing + signature + extra spacing)
        let signatureHeight: CGFloat = 40 + 15 + 105 + sectionSpacing
        yPos += signatureHeight
        
        // 2. Fitness Goals
        yPos = drawSectionImageMac(title: "Fitness Goals", items: [("Goals", goalsText)], yPosition: yPos, width: imageWidth, fromTop: true)
        yPos += sectionSpacing
        
        // 3. Medical Information
        yPos = drawSectionImageMac(title: "Medical Information", items: medicalItems, yPosition: yPos, width: imageWidth, fromTop: true)
        yPos += sectionSpacing
        
        // 4. Health Information
        yPos = drawSectionImageMac(title: "Health Information", items: healthItems, yPosition: yPos, width: imageWidth, fromTop: true)
        yPos += sectionSpacing
        
        // 5. Physical Information
        yPos = drawSectionImageMac(title: "Physical Information", items: physicalItems, yPosition: yPos, width: imageWidth, fromTop: true)
        yPos += sectionSpacing
        
        // 6. Subscription Information
        yPos = drawSectionImageMac(title: "Subscription Information", items: subscriptionItems, yPosition: yPos, width: imageWidth, fromTop: true)
        yPos += sectionSpacing
        
        // 7. Basic Information
        yPos = drawSectionImageMac(title: "Basic Information", items: basicItems, yPosition: yPos, width: imageWidth, fromTop: true)
        yPos += sectionSpacing
        
        // 8. Title (Name) - at bottom
        let titleFont = NSFont.boldSystemFont(ofSize: 48)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let titleText = subscriber.name.isEmpty ? "Subscriber Information" : subscriber.name
        let titleRect = NSRect(x: 100, y: imageHeight - bottomMargin - 60, width: imageWidth - 200, height: 60)
        titleText.draw(in: titleRect, withAttributes: titleAttributes)
        
        image.unlockFocus()
        
        // Save single image
        let baseFilename = subscriber.name.isEmpty ? "Subscriber" : subscriber.name
        if let imageData = image.tiffRepresentation,
           let pngData = NSBitmapImageRep(data: imageData)?.representation(using: .png, properties: [:]) {
            saveImage(data: pngData, filename: "\(baseFilename).png")
        }
#endif
    }
    
    // MARK: - Helper Methods
    
    private static func getBasicInfoItems(subscriber: Subscriber) -> [(String, String)] {
        var items: [(String, String)] = []
        // Always include all fields, show N/A if empty
        items.append(("Name", subscriber.name.isEmpty ? "N/A" : subscriber.name))
        items.append(("Email", subscriber.email.isEmpty ? "N/A" : subscriber.email))
        items.append(("Phone", subscriber.phone.isEmpty ? "N/A" : subscriber.phone))
        if let dateOfBirth = subscriber.dateOfBirth {
            items.append(("Date of Birth", dateOfBirth.formatted(date: .long, time: .omitted)))
        } else {
            items.append(("Date of Birth", "N/A"))
        }
        if let gender = subscriber.gender, !gender.isEmpty {
            items.append(("Gender", gender))
        } else {
            items.append(("Gender", "N/A"))
        }
        return items
    }
    
    private static func getSubscriptionInfoItems(subscriber: Subscriber) -> [(String, String)] {
        return [
            ("Plan Type", subscriber.planType),
            ("Status", subscriber.paymentStatus),
            ("Start Date", subscriber.subscriptionStartDate.formatted(date: .long, time: .omitted))
        ]
    }
    
    private static func getPhysicalInfoItems(subscriber: Subscriber) -> [(String, String)] {
        var items: [(String, String)] = []
        // Always include all fields, show N/A if empty
        if let height = subscriber.onboardingHeight {
            items.append(("Height", "\(String(format: "%.1f", height)) cm"))
        } else {
            items.append(("Height", "N/A"))
        }
        if let weight = subscriber.onboardingWeight {
            items.append(("Weight", "\(String(format: "%.1f", weight)) kg"))
        } else {
            items.append(("Weight", "N/A"))
        }
        if let age = subscriber.onboardingAge {
            items.append(("Age", "\(age) years"))
        } else {
            items.append(("Age", "N/A"))
        }
        if let heartRate = subscriber.onboardingHeartRate {
            items.append(("Heart Rate", "\(heartRate) bpm"))
        } else {
            items.append(("Heart Rate", "N/A"))
        }
        if let bodyFat = subscriber.onboardingBodyFatPercentage {
            items.append(("Body Fat Percentage", "\(String(format: "%.1f", bodyFat))%"))
        } else {
            items.append(("Body Fat Percentage", "N/A"))
        }
        if let muscleMass = subscriber.onboardingMuscleMassPercentage {
            items.append(("Muscle Mass Percentage", "\(String(format: "%.1f", muscleMass))%"))
        } else {
            items.append(("Muscle Mass Percentage", "N/A"))
        }
        if let activityLevel = subscriber.onboardingPreviousActivityLevel, !activityLevel.isEmpty {
            items.append(("Previous Activity Level", activityLevel))
        } else {
            items.append(("Previous Activity Level", "N/A"))
        }
        return items
    }
    
    private static func getHealthInfoItems(subscriber: Subscriber) -> [(String, String)] {
        var items: [(String, String)] = []
        // Always include all fields, show N/A if empty
        if let conditions = subscriber.onboardingHealthConditions, !conditions.isEmpty {
            items.append(("Health Conditions", conditions))
        } else {
            items.append(("Health Conditions", "N/A"))
        }
        if let injuries = subscriber.onboardingPastInjuries, !injuries.isEmpty {
            items.append(("Past Injuries", injuries))
        } else {
            items.append(("Past Injuries", "N/A"))
        }
        if let surgeries = subscriber.onboardingPreviousSurgeries, !surgeries.isEmpty {
            items.append(("Previous Surgeries", surgeries))
        } else {
            items.append(("Previous Surgeries", "N/A"))
        }
        if let allergies = subscriber.onboardingAllergies, !allergies.isEmpty {
            items.append(("Allergies", allergies))
        } else {
            items.append(("Allergies", "N/A"))
        }
        if let medications = subscriber.onboardingCurrentMedications, !medications.isEmpty {
            items.append(("Current Medications", medications))
        } else {
            items.append(("Current Medications", "N/A"))
        }
        if let pregnancyStatus = subscriber.onboardingPregnancyStatus {
            items.append(("Pregnancy Status", pregnancyStatus ? "Yes" : "No"))
        } else {
            items.append(("Pregnancy Status", "N/A"))
        }
        return items
    }
    
    private static func getMedicalInfoItems(subscriber: Subscriber) -> [(String, String)] {
        var items: [(String, String)] = []
        // Always include all fields, show N/A if empty
        if !subscriber.injuries.isEmpty {
            items.append(("Injuries", subscriber.injuries))
        } else {
            items.append(("Injuries", "N/A"))
        }
        if !subscriber.restrictions.isEmpty {
            items.append(("Restrictions", subscriber.restrictions))
        } else {
            items.append(("Restrictions", "N/A"))
        }
        if !subscriber.healthConditions.isEmpty {
            items.append(("Health Conditions", subscriber.healthConditions))
        } else {
            items.append(("Health Conditions", "N/A"))
        }
        return items
    }
    
    private static func getNotesItems(subscriber: Subscriber) -> [(String, String)] {
        var items: [(String, String)] = []
        // Get all coach notes for this subscriber
        if let notes = subscriber.notes, !notes.isEmpty {
            // Sort notes by date (most recent first)
            let sortedNotes = notes.sorted { $0.date > $1.date }
            for note in sortedNotes {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                let dateString = dateFormatter.string(from: note.date)
                let noteText = "\(dateString) - \(note.title): \(note.content)"
                items.append((note.category, noteText))
            }
        }
        return items
    }
    
    // MARK: - Image Export Helpers
    
    private static func estimateSectionHeight(items: [(String, String)]) -> CGFloat {
        let titleHeight: CGFloat = 60
        let itemHeight: CGFloat = 40
        let itemSpacing: CGFloat = 10
        return titleHeight + (CGFloat(items.count) * (itemHeight + itemSpacing)) + 20
    }
    
#if os(macOS)
    private static func estimateSectionHeightMac(items: [(String, String)]) -> CGFloat {
        let titleHeight: CGFloat = 60
        let itemHeight: CGFloat = 40
        let itemSpacing: CGFloat = 10
        return titleHeight + (CGFloat(items.count) * (itemHeight + itemSpacing)) + 20
    }
#endif
    
#if os(iOS)
    private static func drawSectionImage(title: String, items: [(String, String)], yPosition: CGFloat, width: CGFloat, fromTop: Bool = false) -> CGFloat {
        var currentY = yPosition

        if fromTop {
            // Drawing from top to bottom
            // Section Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: 100, y: currentY, width: width - 200, height: 40)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            currentY += 60

            // Items
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22),
                .foregroundColor: UIColor.black
            ]

            for (label, value) in items {
                let itemText = "\(label): \(value)"
                let itemRect = CGRect(x: 120, y: currentY, width: width - 240, height: 30)
                itemText.draw(in: itemRect, withAttributes: itemAttributes)
                currentY += 40
            }

            currentY += 20 // Space after section
        } else {
            // Drawing from bottom to top (original behavior)
            // Section Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: 100, y: currentY - 40, width: width - 200, height: 40)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            currentY -= 60

            // Items
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22),
                .foregroundColor: UIColor.black
            ]

            for (label, value) in items {
                let itemText = "\(label): \(value)"
                let itemRect = CGRect(x: 120, y: currentY - 30, width: width - 240, height: 30)
                itemText.draw(in: itemRect, withAttributes: itemAttributes)
                currentY -= 40
            }

            currentY -= 20 // Space after section
        }
        
        return currentY
    }
    
    private static func drawSignatureSectionImage(signatureImage: UIImage?, width: CGFloat, height: CGFloat, fromTop: Bool = false) {
        let signatureHeight: CGFloat = 105 // 30% smaller than original 150 (150 * 0.7 = 105)
        let titleHeight: CGFloat = 40
        let spacing: CGFloat = 15
        
        if fromTop {
            // Draw signature at top of the image
            let topMargin: CGFloat = 100
            let titleY = topMargin
            let signatureY = titleY + titleHeight + spacing

            // Section Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: 100, y: titleY, width: width - 200, height: titleHeight)
            "Signature".draw(in: titleRect, withAttributes: titleAttributes)

            // Draw signature image (30% smaller)
            if let signatureImage = signatureImage {
                let signatureWidth = min(width - 200, signatureImage.size.width * (signatureHeight / signatureImage.size.height))
                let signatureRect = CGRect(x: 100, y: signatureY, width: signatureWidth, height: signatureHeight)
                signatureImage.draw(in: signatureRect)
            } else {
                // Draw "Not available" text
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22),
                    .foregroundColor: UIColor.gray
                ]
                let textRect = CGRect(x: 100, y: signatureY, width: width - 200, height: signatureHeight)
                "Not available".draw(in: textRect, withAttributes: textAttributes)
            }
        } else {
            // Draw signature at bottom of the image (original behavior)
            let bottomMargin: CGFloat = 100
            let signatureY = height - bottomMargin - signatureHeight
            let titleY = signatureY - titleHeight - spacing

            // Section Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: 100, y: titleY, width: width - 200, height: titleHeight)
            "Signature".draw(in: titleRect, withAttributes: titleAttributes)

            // Draw signature image (30% smaller)
            if let signatureImage = signatureImage {
                let signatureWidth = min(width - 200, signatureImage.size.width * (signatureHeight / signatureImage.size.height))
                let signatureRect = CGRect(x: 100, y: signatureY, width: signatureWidth, height: signatureHeight)
                signatureImage.draw(in: signatureRect)
            } else {
                // Draw "Not available" text
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22),
                    .foregroundColor: UIColor.gray
                ]
                let textRect = CGRect(x: 100, y: signatureY, width: width - 200, height: signatureHeight)
                "Not available".draw(in: textRect, withAttributes: textAttributes)
            }
        }
    }
#endif
    
    private static func saveImage(data: Data, filename: String) {
#if os(iOS)
        if let image = UIImage(data: data) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized || status == .limited {
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
    private static func createImage(subscriber: Subscriber) -> NSImage? {
        // Calculate dynamic height based on content
        let baseHeight: CGFloat = 200
        let sectionHeight: CGFloat = 150
        let numSections: CGFloat = 8
        let signatureHeight: CGFloat = 200
        let calculatedHeight = baseHeight + (sectionHeight * numSections) + signatureHeight
        let size = NSSize(width: 1200, height: max(1600, calculatedHeight))
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        var yPosition: CGFloat = size.height - 100
        
        // Profile Photo (if available)
        if let photoData = subscriber.photo, let photoImage = NSImage(data: photoData) {
            let photoSize = NSSize(width: 150, height: 150)
            let photoRect = NSRect(x: 100, y: yPosition - photoSize.height, width: photoSize.width, height: photoSize.height)
            photoImage.draw(in: photoRect)
            yPosition -= 160
        }
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 48)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let titleText = subscriber.name.isEmpty ? "Subscriber Information" : subscriber.name
        let titleRect = NSRect(x: 100, y: yPosition, width: size.width - 200, height: 60)
        titleText.draw(in: titleRect, withAttributes: titleAttributes)
        yPosition -= 80
        
        // Basic Information - Name, Email, Phone, Date of Birth, Gender
        let basicItems = getBasicInfoItems(subscriber: subscriber)
        yPosition = drawSectionImageMac(title: "Basic Information", items: basicItems, yPosition: yPosition, width: size.width)
        
        // Subscription Information
        let subscriptionItems = getSubscriptionInfoItems(subscriber: subscriber)
        yPosition = drawSectionImageMac(title: "Subscription Information", items: subscriptionItems, yPosition: yPosition, width: size.width)
        
        // Physical Information - ALWAYS include (all fields with N/A if empty)
        let physicalItems = getPhysicalInfoItems(subscriber: subscriber)
        yPosition = drawSectionImageMac(title: "Physical Information", items: physicalItems, yPosition: yPosition, width: size.width)
        
        // Health Information - ALWAYS include (all fields with N/A if empty)
        let healthItems = getHealthInfoItems(subscriber: subscriber)
        yPosition = drawSectionImageMac(title: "Health Information", items: healthItems, yPosition: yPosition, width: size.width)
        
        // Medical Information - ALWAYS include (all fields with N/A if empty)
        let medicalItems = getMedicalInfoItems(subscriber: subscriber)
        yPosition = drawSectionImageMac(title: "Medical Information", items: medicalItems, yPosition: yPosition, width: size.width)
        
        // Fitness Goals - ALWAYS include
        let goalsText = subscriber.onboardingFitnessGoals?.isEmpty == false ? subscriber.onboardingFitnessGoals! : "N/A"
        yPosition = drawSectionImageMac(title: "Fitness Goals", items: [("Goals", goalsText)], yPosition: yPosition, width: size.width)
        
        // Referral Information (if available)
        if let referralSource = subscriber.howDidYouHearAboutUs, !referralSource.isEmpty {
            var referralItems: [(String, String)] = [("How did you hear about us?", referralSource)]
            if let referrer = subscriber.referrerName, !referrer.isEmpty {
                referralItems.append(("Referrer Name", referrer))
            }
            yPosition = drawSectionImageMac(title: "Referral Information", items: referralItems, yPosition: yPosition, width: size.width)
        }
        
        // Notes - Coach Notes
        let notesItems = getNotesItems(subscriber: subscriber)
        if !notesItems.isEmpty {
            yPosition = drawSectionImageMac(title: "Notes", items: notesItems, yPosition: yPosition, width: size.width)
        }
        
        // Signature - ALWAYS include at bottom
        if let signatureData = subscriber.signatureData, let signatureImage = NSImage(data: signatureData) {
            drawSignatureSectionImageMac(signatureImage: signatureImage, width: size.width, height: size.height)
        } else {
            drawSignatureSectionImageMac(signatureImage: nil, width: size.width, height: size.height)
        }
        
        image.unlockFocus()
        return image
    }
    
    private static func drawSignatureSectionImageMac(signatureImage: NSImage?, width: CGFloat, height: CGFloat, fromTop: Bool = false) {
        let signatureHeight: CGFloat = 105 // 30% smaller than original 150 (150 * 0.7 = 105)
        let titleHeight: CGFloat = 40
        let spacing: CGFloat = 15
        
        if fromTop {
            // Draw signature at top of the image
            let topMargin: CGFloat = 100
            let titleY = topMargin
            let signatureY = titleY + titleHeight + spacing

            // Section Title
            let titleFont = NSFont.boldSystemFont(ofSize: 32)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: NSColor.black
            ]
            let titleRect = NSRect(x: 100, y: titleY, width: width - 200, height: titleHeight)
            "Signature".draw(in: titleRect, withAttributes: titleAttributes)

            // Draw signature image (30% smaller)
            if let signatureImage = signatureImage {
                let signatureWidth = min(width - 200, signatureImage.size.width * (signatureHeight / signatureImage.size.height))
                let signatureRect = NSRect(x: 100, y: signatureY, width: signatureWidth, height: signatureHeight)
                signatureImage.draw(in: signatureRect)
            } else {
                // Draw "Not available" text
                let textFont = NSFont.systemFont(ofSize: 22)
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: textFont,
                    .foregroundColor: NSColor.gray
                ]
                let textRect = NSRect(x: 100, y: signatureY, width: width - 200, height: signatureHeight)
                "Not available".draw(in: textRect, withAttributes: textAttributes)
            }
        } else {
            // Draw signature at bottom of the image (original behavior)
            let bottomMargin: CGFloat = 100
            let signatureY = height - bottomMargin - signatureHeight
            let titleY = signatureY - titleHeight - spacing

            // Section Title
            let titleFont = NSFont.boldSystemFont(ofSize: 32)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: NSColor.black
            ]
            let titleRect = NSRect(x: 100, y: titleY, width: width - 200, height: titleHeight)
            "Signature".draw(in: titleRect, withAttributes: titleAttributes)

            // Draw signature image (30% smaller)
            if let signatureImage = signatureImage {
                let signatureWidth = min(width - 200, signatureImage.size.width * (signatureHeight / signatureImage.size.height))
                let signatureRect = NSRect(x: 100, y: signatureY, width: signatureWidth, height: signatureHeight)
                signatureImage.draw(in: signatureRect)
            } else {
                // Draw "Not available" text
                let textFont = NSFont.systemFont(ofSize: 22)
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: textFont,
                    .foregroundColor: NSColor.gray
                ]
                let textRect = NSRect(x: 100, y: signatureY, width: width - 200, height: signatureHeight)
                "Not available".draw(in: textRect, withAttributes: textAttributes)
            }
        }
    }
    
    private static func drawSectionImageMac(title: String, items: [(String, String)], yPosition: CGFloat, width: CGFloat, fromTop: Bool = false) -> CGFloat {
        var currentY = yPosition
        
        if fromTop {
            // Drawing from top to bottom
            let titleFont = NSFont.boldSystemFont(ofSize: 32)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: NSColor.black
            ]
            let titleRect = NSRect(x: 100, y: currentY, width: width - 200, height: 40)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            currentY += 60
            
            let itemFont = NSFont.systemFont(ofSize: 22)
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: itemFont,
                .foregroundColor: NSColor.black
            ]
            
            for (label, value) in items {
                let itemText = "\(label): \(value)"
                let itemRect = NSRect(x: 120, y: currentY, width: width - 240, height: 30)
                itemText.draw(in: itemRect, withAttributes: itemAttributes)
                currentY += 40
            }
            
            currentY += 20
        } else {
            // Drawing from bottom to top (original behavior)
            let titleFont = NSFont.boldSystemFont(ofSize: 32)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: NSColor.black
            ]
            let titleRect = NSRect(x: 100, y: currentY, width: width - 200, height: 40)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            currentY -= 60
            
            let itemFont = NSFont.systemFont(ofSize: 22)
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: itemFont,
                .foregroundColor: NSColor.black
            ]
            
            for (label, value) in items {
                let itemText = "\(label): \(value)"
                let itemRect = NSRect(x: 120, y: currentY - 30, width: width - 240, height: 30)
                itemText.draw(in: itemRect, withAttributes: itemAttributes)
                currentY -= 40
            }
            
            currentY -= 20
        }
        
        return currentY
    }
#endif
}

