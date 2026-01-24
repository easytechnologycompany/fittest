//
//  SignatureCaptureView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SignatureCaptureView: View {
    @Binding var signatureData: Data?
    
    // Store paths as arrays of points for easier conversion to CGPath
    @State private var completedStrokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var drawingSize: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Drawing area
            GeometryReader { geometry in
                ZStack {
                    // White background
                    Color.white
                        .ignoresSafeArea()
                    
                    // Draw all completed strokes
                    ForEach(0..<completedStrokes.count, id: \.self) { index in
                        drawPath(points: completedStrokes[index])
                            .stroke(Color.black, lineWidth: 2)
                    }
                    
                    // Draw current stroke
                    if !currentStroke.isEmpty {
                        drawPath(points: currentStroke)
                            .stroke(Color.black, lineWidth: 2)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = value.location
                            
                            if currentStroke.isEmpty {
                                currentStroke.append(point)
                            } else {
                                currentStroke.append(point)
                            }
                            
                            // Auto-save periodically
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                saveSignature(size: geometry.size)
                            }
                        }
                        .onEnded { _ in
                            if !currentStroke.isEmpty {
                                completedStrokes.append(currentStroke)
                                currentStroke = []
                                drawingSize = geometry.size
                                saveSignature(size: geometry.size)
                            }
                        }
                )
                .onAppear {
                    drawingSize = geometry.size
                }
                .onChange(of: geometry.size) { oldValue, newValue in
                    drawingSize = newValue
                }
            }
            
            // Clear button
            HStack {
                Button(action: clearSignature) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
        }
    }
    
    private func drawPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        
        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
    
    private func clearSignature() {
        completedStrokes.removeAll()
        currentStroke.removeAll()
        signatureData = nil
    }
    
    private func saveSignature(size: CGSize) {
        let allStrokes = completedStrokes + (currentStroke.isEmpty ? [] : [currentStroke])
        guard !allStrokes.isEmpty else { return }
        
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw all strokes
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.setLineCap(.round)
            context.cgContext.setLineJoin(.round)
            
            for stroke in allStrokes {
                guard let firstPoint = stroke.first else { continue }
                let cgPath = CGMutablePath()
                cgPath.move(to: firstPoint)
                for point in stroke.dropFirst() {
                    cgPath.addLine(to: point)
                }
                context.cgContext.addPath(cgPath)
                context.cgContext.strokePath()
            }
        }
        
        if let imageData = image.pngData() {
            Task { @MainActor in
                if let compressed = ImageCompressionHelper.compressSignature(imageData) {
                    signatureData = compressed
                } else {
                    signatureData = imageData
                }
            }
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocus()
        
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        NSColor.black.setStroke()
        
        for stroke in allStrokes {
            guard let firstPoint = stroke.first else { continue }
            let bezierPath = NSBezierPath()
            bezierPath.lineWidth = 2
            bezierPath.lineCapStyle = .round
            bezierPath.lineJoinStyle = .round
            bezierPath.move(to: firstPoint)
            for point in stroke.dropFirst() {
                bezierPath.line(to: point)
            }
            bezierPath.stroke()
        }
        
        image.unlockFocus()
        
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let imageData = bitmapImage.representation(using: .png, properties: [:]) {
            Task { @MainActor in
                if let compressed = ImageCompressionHelper.compressSignature(imageData) {
                    signatureData = compressed
                } else {
                    signatureData = imageData
                }
            }
        }
        #endif
    }
}

#Preview {
    SignatureCaptureView(signatureData: .constant(nil))
        .frame(height: 300)
}
