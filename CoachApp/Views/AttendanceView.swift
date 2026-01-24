//
//  AttendanceView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct AttendanceView: View {
    @Environment(\.colorScheme) var colorScheme
    let subscriber: SubscriberFS
    let attendanceRecords: [AttendanceFS]
    
    @State private var showingAddAttendance = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    var body: some View {
        List {
            if attendanceRecords.isEmpty {
                ContentUnavailableView(
                    "No Attendance Records",
                    systemImage: "calendar.badge.clock",
                    description: Text("Attendance history will appear here.")
                )
            } else {
                ForEach(attendanceRecords) { attendance in
                    NavigationLink {
                        AttendanceDetailView(attendance: attendance)
                    } label: {
                        AttendanceRowView(attendance: attendance)
                    }
                }
                .onDelete { offsets in
                    itemsToDelete = offsets
                    showingDeleteConfirmation = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle("Attendance")
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAddAttendance = true
                } label: {
                    Label("Add Attendance", systemImage: "plus")
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAttendance = true
                } label: {
                    Label("Add Attendance", systemImage: "plus")
                }
            }
            #endif
        }
        .platformSheet(isPresented: $showingAddAttendance) {
            AddAttendanceView(subscriber: subscriber)
        }
        .alert("Delete Attendance", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                itemsToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let offsets = itemsToDelete {
                    deleteAttendance(offsets: offsets)
                }
                itemsToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this attendance record? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteAttendance(offsets: IndexSet) {
        Task {
            do {
                for index in offsets {
                    let attendance = attendanceRecords[index]
                    if let id = attendance.id {
                        try await FirestoreService.shared.deleteAttendance(id)
                    }
                }
            } catch {
                await MainActor.run {
                    let appError = AppError.deleteError("Failed to delete attendance: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AttendanceView.deleteAttendance")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

struct AttendanceRowView: View {
    let attendance: AttendanceFS
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(attendance.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            
            HStack {
                if let checkIn = attendance.checkInTime {
                    Label(checkIn.formatted(date: .omitted, time: .shortened), systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                if let checkOut = attendance.checkOutTime {
                    Label(checkOut.formatted(date: .omitted, time: .shortened), systemImage: "arrow.up.circle")
                        .font(.caption)
                }
                if let duration = attendance.duration {
                    Spacer()
                    Label(formatDuration(duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct AttendanceDetailView: View {
    let attendance: AttendanceFS
    
    var body: some View {
        Form {
            Section("Date") {
                Text(attendance.date.formatted(date: .complete, time: .omitted))
            }
            
            Section("Check In/Out") {
                if let checkIn = attendance.checkInTime {
                    HStack {
                        Text("Check In")
                        Spacer()
                        Text(checkIn.formatted(date: .omitted, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let checkOut = attendance.checkOutTime {
                    HStack {
                        Text("Check Out")
                        Spacer()
                        Text(checkOut.formatted(date: .omitted, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let duration = attendance.duration {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(duration))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !attendance.notes.isEmpty {
                Section("Notes") {
                    Text(attendance.notes)
                }
            }
        }
        .navigationTitle("Attendance")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct AddAttendanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    let subscriber: SubscriberFS
    
    @State private var date: Date = Date()
    @State private var checkInTime: Date = Date()
    @State private var checkOutTime: Date?
    @State private var hasCheckOut: Bool = false
    @State private var notes: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Check In") {
                    DatePicker("Check In Time", selection: $checkInTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Check Out") {
                    Toggle("Record Check Out", isOn: $hasCheckOut)
                    if hasCheckOut {
                        DatePicker("Check Out Time", selection: Binding(
                            get: { checkOutTime ?? Date() },
                            set: { checkOutTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Notes") {
                    TextField("Attendance notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Attendance")
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
                        saveAttendance()
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
    
    private func saveAttendance() {
        isLoading = true
        
        Task {
            do {
                let attendance = AttendanceFS(
                    date: date,
                    checkInTime: checkInTime,
                    checkOutTime: hasCheckOut ? checkOutTime : nil,
                    notes: notes,
                    subscriberId: subscriber.id
                )
                
                try await FirestoreService.shared.addAttendance(attendance)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to save attendance: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AddAttendanceView.saveAttendance")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

// Add extension to calculate duration
extension AttendanceFS {
    var duration: TimeInterval? {
        guard let checkIn = checkInTime, let checkOut = checkOutTime else { return nil }
        return checkOut.timeIntervalSince(checkIn)
    }
}

#Preview {
    AttendanceView(
        subscriber: SubscriberFS(
            name: "Test User",
            email: "test@example.com",
            phone: "1234567890",
            subscriptionStartDate: Date(),
            planType: "Monthly",
            paymentStatus: "Active",
            injuries: "None",
            restrictions: "None",
            healthConditions: "None"
        ),
        attendanceRecords: []
    )
}

