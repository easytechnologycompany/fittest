//
//  PhysicalDetail.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import Foundation
import SwiftData

@Model
final class PhysicalDetail {
    var dateRecorded: Date = Date()
    
    // Weight and Body Fat
    var weight: Double? // in kg
    var bodyFatPercentage: Double? // percentage
    var height: Double? // in cm
    
    // Body Measurements (in cm)
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var leftArm: Double?
    var rightArm: Double?
    var leftLeg: Double?
    var rightLeg: Double?
    
    // Progress Photo
    var photo: Data?
    
    // Relationship
    @Relationship(inverse: \Subscriber.physicalDetails) var subscriber: Subscriber?
    
    init(
        dateRecorded: Date = Date(),
        weight: Double? = nil,
        bodyFatPercentage: Double? = nil,
        height: Double? = nil,
        chest: Double? = nil,
        waist: Double? = nil,
        hips: Double? = nil,
        leftArm: Double? = nil,
        rightArm: Double? = nil,
        leftLeg: Double? = nil,
        rightLeg: Double? = nil,
        photo: Data? = nil
    ) {
        self.dateRecorded = dateRecorded
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.height = height
        self.chest = chest
        self.waist = waist
        self.hips = hips
        self.leftArm = leftArm
        self.rightArm = rightArm
        self.leftLeg = leftLeg
        self.rightLeg = rightLeg
        self.photo = photo
    }
}

