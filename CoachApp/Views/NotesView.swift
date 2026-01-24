//
//  NotesView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct NotesView: View {
    @Environment(\.colorScheme) var colorScheme
    let subscriber: SubscriberFS
    let notes: [CoachNoteFS]
    
    @State private var showingAddNote = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    var body: some View {
        List {
            if notes.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Coach notes will appear here.")
                )
            } else {
                ForEach(notes) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        NoteRowView(note: note)
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
        .navigationTitle("Notes")
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAddNote = true
                } label: {
                    Label("Add Note", systemImage: "plus")
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddNote = true
                } label: {
                    Label("Add Note", systemImage: "plus")
                }
            }
            #endif
        }
        .platformSheet(isPresented: $showingAddNote) {
            AddNoteView(subscriber: subscriber)
        }
        .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                itemsToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let offsets = itemsToDelete {
                    deleteNotes(offsets: offsets)
                }
                itemsToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        Task {
            do {
                for index in offsets {
                    let note = notes[index]
                    if let id = note.id {
                        try await FirestoreService.shared.deleteCoachNote(id)
                    }
                }
            } catch {
                await MainActor.run {
                    let appError = AppError.deleteError("Failed to delete note: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "NotesView.deleteNotes")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

struct NoteRowView: View {
    let note: CoachNoteFS
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                Spacer()
                Text(note.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !note.category.isEmpty && note.category != "General" {
                Text(note.category)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(categoryColor(for: note.category).opacity(0.2))
                    .foregroundColor(categoryColor(for: note.category))
                    .cornerRadius(4)
            }
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "progress":
            return .green
        case "concern":
            return .red
        case "achievement":
            return .blue
        default:
            return .gray
        }
    }
}

struct NoteDetailView: View {
    let note: CoachNoteFS
    
    var body: some View {
        Form {
            Section("Note Information") {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(note.date.formatted(date: .complete, time: .shortened))
                        .foregroundColor(.secondary)
                }
                
                if !note.category.isEmpty {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(note.category)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Content") {
                Text(note.content)
            }
        }
        .navigationTitle("Note")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let subscriber: SubscriberFS
    var note: CoachNoteFS?
    
    @State private var date: Date = Date()
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var category: String = "General"
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    let categories = ["General", "Progress", "Concern", "Achievement"]
    
    init(subscriber: SubscriberFS, note: CoachNoteFS? = nil) {
        self.subscriber = subscriber
        self.note = note
        if let note = note {
            _date = State(initialValue: note.date)
            _title = State(initialValue: note.title)
            _content = State(initialValue: note.content)
            _category = State(initialValue: note.category)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Note Information") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Content") {
                    TextField("Note content", text: $content, axis: .vertical)
                        .lineLimit(5...15)
                }
            }
            .navigationTitle(note == nil ? "Add Note" : "Edit Note")
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
                        saveNote()
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
    
    private func saveNote() {
        isLoading = true
        
        Task {
            do {
                if var existingNote = note {
                    existingNote.date = date
                    existingNote.title = title
                    existingNote.content = content
                    existingNote.category = category
                    try await FirestoreService.shared.updateCoachNote(existingNote)
                } else {
                    let newNote = CoachNoteFS(
                        date: date,
                        title: title,
                        content: content,
                        category: category,
                        subscriberId: subscriber.id
                    )
                    try await FirestoreService.shared.addCoachNote(newNote)
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let appError = AppError.saveError("Failed to save note: \(error.localizedDescription)")
                    ErrorHandler.handle(appError, context: "AddNoteView.saveNote")
                    errorMessage = appError.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NotesView(
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
        notes: []
    )
}


