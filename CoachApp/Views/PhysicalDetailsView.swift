//
//  PhysicalDetailsView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Charts
import PhotosUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PhysicalDetailsView: View {
    @Environment(\.colorScheme) var colorScheme
    let subscriber: SubscriberFS
    let physicalDetails: [PhysicalDetailFS]
    
    @State private var showingAddDetail = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    // Sort details locally for display
    var sortedDetails: [PhysicalDetailFS] {
        physicalDetails.sorted { $0.dateRecorded > $1.dateRecorded }
    }
    
    var body: some View {
        List {
            if !physicalDetails.isEmpty {
                Section("Weight Progress") {
                    if let weightData = weightChartData, !weightData.isEmpty {
                        Chart(weightData) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Weight", data.value)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Date", data.date),
                                y: .value("Weight", data.value)
                            )
                            .foregroundStyle(
                                .blue.opacity(0.3)
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 200)
                    } else {
                        ContentUnavailableView(
                            "No Weight Data",
                            systemImage: "scalemass",
                            description: Text("Add weight records to see your progress.")
                        )
                        .frame(height: 120)
                    }
                }
                
                Section("Body Fat Progress") {
                    if let bodyFatData = bodyFatChartData, !bodyFatData.isEmpty {
                        Chart(bodyFatData) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Body Fat %", data.value)
                            )
                            .foregroundStyle(.orange)
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 200)
                    } else {
                        ContentUnavailableView(
                            "No Body Fat Data",
                            systemImage: "percent",
                            description: Text("Add body fat percentage to see your progress.")
                        )
                        .frame(height: 120)
                    }
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "No Physical Records",
                        systemImage: "figure.arms.open",
                        description: Text("Tap Add to create your first physical detail record.")
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            
            Section {
                ForEach(sortedDetails) { detail in
                    NavigationLink {
                        PhysicalDetailDetailView(detail: detail)
                    } label: {
                        PhysicalDetailRowView(detail: detail)
                    }
                }
                .onDelete { offsets in
                    itemsToDelete = offsets
                    showingDeleteConfirmation = true
                }
            } header: {
                HStack {
                    Text("Records")
                    Spacer()
                    Button(action: { showingAddDetail = true }) {
                        Label("Add", systemImage: "plus")
                            .font(.caption)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle("Physical Details")
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAddDetail = true
                } label: {
                    Label("Add Detail", systemImage: "plus")
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddDetail = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            #endif
        }
        .platformSheet(isPresented: $showingAddDetail) {
            AddPhysicalDetailView(subscriber: subscriber)
        }
        .alert("Delete Physical Detail", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                itemsToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let offsets = itemsToDelete {
                    deleteDetails(offsets: offsets)
                }
                itemsToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this physical detail record? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // Ensure chart data is chronological (ascending by date) regardless of list sort
    private var weightChartData: [ChartData]? {
        let data = physicalDetails
            .compactMap { detail -> ChartData? in
                guard let weight = detail.weight else { return nil }
                return ChartData(date: detail.dateRecorded, value: weight)
            }
            .sorted { $0.date < $1.date }
        return data.isEmpty ? nil : data
    }
    
    private var bodyFatChartData: [ChartData]? {
        let data = physicalDetails
            .compactMap { detail -> ChartData? in
                guard let bodyFat = detail.bodyFatPercentage else { return nil }
                return ChartData(date: detail.dateRecorded, value: bodyFat)
            }
            .sorted { $0.date < $1.date }
        return data.isEmpty ? nil : data
    }
    
    private func deleteDetails(offsets: IndexSet) {
        Task {
            do {
                for index in offsets {
                    if let id = sortedDetails[index].id {
                        try await FirestoreService.shared.deletePhysicalDetail(id)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete physical detail: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct PhysicalDetailRowView: View {
    let detail: PhysicalDetailFS
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(detail.dateRecorded.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            
            HStack {
                if let weight = detail.weight {
                    Label("\(String(format: "%.1f", weight)) kg", systemImage: "scalemass")
                        .font(.caption)
                }
                if let height = detail.height {
                    Label("\(String(format: "%.1f", height)) cm", systemImage: "ruler")
                        .font(.caption)
                }
                if let bodyFat = detail.bodyFatPercentage {
                    Label("\(String(format: "%.1f", bodyFat))%", systemImage: "percent")
                        .font(.caption)
                }
            }
        }
    }
}

struct PhysicalDetailDetailView: View {
    let detail: PhysicalDetailFS
    
    var body: some View {
        Form {
            Section("Date") {
                Text(detail.dateRecorded.formatted(date: .complete, time: .omitted))
            }
            
            Section("Weight & Body Fat") {
                if let weight = detail.weight {
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(String(format: "%.1f", weight)) kg")
                            .foregroundColor(.secondary)
                    }
                }
                if let height = detail.height {
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(String(format: "%.1f", height)) cm")
                            .foregroundColor(.secondary)
                    }
                }
                if let bodyFat = detail.bodyFatPercentage {
                    HStack {
                        Text("Body Fat")
                        Spacer()
                        Text("\(String(format: "%.1f", bodyFat))%")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Measurements (cm)") {
                if let chest = detail.chest {
                    MeasurementRow(label: "Chest", value: chest)
                }
                if let waist = detail.waist {
                    MeasurementRow(label: "Waist", value: waist)
                }
                if let hips = detail.hips {
                    MeasurementRow(label: "Hips", value: hips)
                }
                if let leftArm = detail.leftArm {
                    MeasurementRow(label: "Left Arm", value: leftArm)
                }
                if let rightArm = detail.rightArm {
                    MeasurementRow(label: "Right Arm", value: rightArm)
                }
                if let leftLeg = detail.leftLeg {
                    MeasurementRow(label: "Left Leg", value: leftLeg)
                }
                if let rightLeg = detail.rightLeg {
                    MeasurementRow(label: "Right Leg", value: rightLeg)
                }
            }
            
            #if canImport(UIKit)
            if let photoBase64 = detail.photoBase64, let photoData = Data(base64Encoded: photoBase64), let uiImage = UIImage(data: photoData) {
                Section("Photo") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            #elseif canImport(AppKit)
            if let photoBase64 = detail.photoBase64, let photoData = Data(base64Encoded: photoBase64), let nsImage = NSImage(data: photoData) {
                Section("Photo") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            #endif
        }
        .navigationTitle("Physical Detail")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

struct MeasurementRow: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(String(format: "%.1f", value)) cm")
                .foregroundColor(.secondary)
        }
    }
}

struct AddPhysicalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let subscriber: SubscriberFS
    
    @State private var dateRecorded: Date = Date()
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var bodyFatPercentage: String = ""
    @State private var chest: String = ""
    @State private var waist: String = ""
    @State private var hips: String = ""
    @State private var leftArm: String = ""
    @State private var rightArm: String = ""
    @State private var leftLeg: String = ""
    @State private var rightLeg: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isCompressingPhoto = false
    
    var body: some View {
        NavigationStack {
            Form {
                dateSection
                weightBodyFatSection
                measurementsSection
                photoSection
            }
            .navigationTitle("Add Physical Detail")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDetail()
                    }
                    .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(AppTheme.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(12)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - View Sections
    
    private var dateSection: some View {
        Section("Date") {
            DatePicker("Recorded Date", selection: $dateRecorded, displayedComponents: .date)
        }
    }
    
    private var weightBodyFatSection: some View {
        Section("Weight & Body Fat") {
            decimalTextField("Weight (kg)", text: $weight)
            decimalTextField("Height (cm)", text: $height)
            decimalTextField("Body Fat %", text: $bodyFatPercentage)
        }
    }
    
    private var measurementsSection: some View {
        Section("Measurements (cm)") {
            decimalTextField("Chest", text: $chest)
            decimalTextField("Waist", text: $waist)
            decimalTextField("Hips", text: $hips)
            decimalTextField("Left Arm", text: $leftArm)
            decimalTextField("Right Arm", text: $rightArm)
            decimalTextField("Left Leg", text: $leftLeg)
            decimalTextField("Right Leg", text: $rightLeg)
        }
    }
    
    private var photoSection: some View {
        Section("Progress Photo") {
            photoPickerView
            if isCompressingPhoto {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Compressing photo...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var photoPickerView: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            HStack {
                #if canImport(UIKit)
                if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                #elseif canImport(AppKit)
                if let photoData = photoData, let nsImage = NSImage(data: photoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                #endif
                Text("Select Photo")
            }
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                isCompressingPhoto = true
                defer { isCompressingPhoto = false }
                
                do {
                    if let data = try await newValue?.loadTransferable(type: Data.self) {
                        // Compress image on main actor (required for UIKit)
                        photoData = await MainActor.run {
                            ImageCompressionHelper.compressProgressPhoto(data) ?? data
                        }
                    } else {
                        // Clear photo if picker cleared
                        if newValue == nil { photoData = nil }
                    }
                } catch {
                    errorMessage = "Failed to load photo: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func decimalTextField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .modifier(DecimalTextFieldModifier())
    }
    
    // Locale-aware parsing with simple normalization (commas/spaces)
    private func parseDouble(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        // Replace common decimal comma with dot if needed
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        // Try fast path
        if let value = Double(normalized) { return value }
        // Fallback to NumberFormatter for locale cases
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        return formatter.number(from: trimmed)?.doubleValue
    }
    
    private func saveDetail() {
        // Validate measurements
        if let weightValue = parseDouble(weight), !ValidationHelper.isValidMeasurement(weightValue, min: 0, max: 500) {
            errorMessage = "Weight must be between 0 and 500 kg"
            return
        }
        
        if let bodyFatValue = parseDouble(bodyFatPercentage), !ValidationHelper.isValidMeasurement(bodyFatValue, min: 0, max: 100) {
            errorMessage = "Body fat percentage must be between 0 and 100%"
            return
        }
        
        isLoading = true
        
        guard let subscriberID = subscriber.id else {
            errorMessage = "Subscriber ID missing"
            isLoading = false
            return
        }
        
        let photoBase64: String? = photoData?.base64EncodedString()
        
        let detail = PhysicalDetailFS(
            id: nil,
            dateRecorded: dateRecorded,
            weight: parseDouble(weight),
            bodyFatPercentage: parseDouble(bodyFatPercentage),
            height: parseDouble(height),
            chest: parseDouble(chest),
            waist: parseDouble(waist),
            hips: parseDouble(hips),
            leftArm: parseDouble(leftArm),
            rightArm: parseDouble(rightArm),
            leftLeg: parseDouble(leftLeg),
            rightLeg: parseDouble(rightLeg),
            photoUrl: nil,
            photoBase64: photoBase64,
            subscriberId: subscriberID,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            do {
                _ = try await FirestoreService.shared.addPhysicalDetail(detail)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to save physical detail: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AddPhysicalDetailView.saveDetail")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

// MARK: - Decimal Text Field Modifier
struct DecimalTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .keyboardType(.decimalPad)
            .textInputAutocapitalization(.never)
        #else
        content
        #endif
    }
}

#Preview {
    PhysicalDetailsView(
        subscriber: SubscriberFS(
            name: "Preview User",
            email: "preview@example.com",
            phone: "1234567890",
            subscriptionStartDate: Date(),
            planType: "Monthly",
            paymentStatus: "Active",
            injuries: "None",
            restrictions: "None",
            healthConditions: "None"
        ),
        physicalDetails: []
    )
}
