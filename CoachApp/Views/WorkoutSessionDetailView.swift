//
//  WorkoutSessionDetailView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 17/12/2025.
//

import SwiftUI

struct WorkoutSessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("pendingSubscriberSelection") private var pendingSubscriberID: String = ""
    @AppStorage("requestedRootTab") private var requestedRootTab: Int = -1
    
    // Config
    let config: SessionEditorConfig
    let subscriber: SubscriberFS
    
    // Form State
    @State private var weight: Double = 30
    @State private var targetDuration: TimeInterval? = nil // Nil = Stopwatch, or Value = 60s etc
    @State private var notes: String = "" // Notes are on SessionFS, session-wide?
                                          // Or per exercise? SessionExerciseFS doesn't have notes.
                                          // WorkoutSession (SD) had notes.
                                          // Let's check FirestoreModels.swift for SessionFS notes.
                                          // Step 234: SessionFS has `title`, `status`. No generic `notes`?
                                          // WorkoutLog has notes. SessionExerciseFS has `targetDuration`, `weight`, `rhythm`.
                                          // Let's assume for now we don't save notes for single exercise unless we add it to model later.
                                          // Or we use `title` as notes?
                                          // Re-checking Step 229: WorkoutSession had `notes`.
                                          // I should probably add `notes` to `SessionExerciseFS` if specific to exercise, or `SessionFS` if specific to session.
                                          // For now, I'll Comment out notes or store it in local state but not save it if no field.
                                          // Actually, `SessionExerciseFS` doesn't have notes. I will skip notes for now or use `intensity` field?
    
    // Timer State
    @State private var isRunning = false
    @State private var elapsedSeconds: TimeInterval = 0
    @State private var timer: Timer?
    @State private var countdownTimer: Timer?
    @State private var showCountdown = false
    @State private var countdownValue = 3
    
    // Rhythm State
    @State private var currentRep = 1
    @State private var rhythmPhase: RhythmPhase = .up
    @State private var rhythmSeconds: Double = 0 // 0 to rhythmDuration
    @State private var rhythmDuration: Double = 10 // Default 10s, adjustable
    
    // +10s Feature
    @State private var plusTenActive = false
    @State private var plusTenCountdown = 10
    @State private var plusTenAccumulator: Double = 0
    @State private var plusTenCount: Int = 0
    
    // UI State
    @State private var showingSummary = false
    @State private var showGo = false
    @State private var showingMailComposer = false
    @StateObject private var emailComposer = EmailComposerViewModel()
    @State private var showErrorAlert = false
    @State private var errorMessage: String?
    
    enum RhythmPhase: String {
        case up = "UP"
        case down = "DOWN"
    }
    
    // Initializer
    init(config: SessionEditorConfig, subscriber: SubscriberFS) {
        self.config = config
        self.subscriber = subscriber
        
        // Pre-fill if editing existing exercise
        if let exercise = config.exercise {
            _weight = State(initialValue: exercise.weight ?? 30)
            if let duration = exercise.targetDuration {
                _elapsedSeconds = State(initialValue: TimeInterval(duration))
                _targetDuration = State(initialValue: TimeInterval(duration))
            }
            _plusTenCount = State(initialValue: exercise.plusTenCount ?? 0)
            _notes = State(initialValue: exercise.notes ?? "")
        } else {
            // New defaults
             _weight = State(initialValue: 30)
        }
    }
    
    var machineName: String {
        config.machine ?? config.exercise?.name ?? "Unknown Machine"
    }
    
    var sessionDate: Date {
        config.date ?? config.session?.date ?? Date()
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height
                
                if isLandscape || geo.size.width > 600 {
                    HStack(alignment: .top, spacing: 20) {
                        leftPane
                            .frame(maxWidth: .infinity)
                        rightPane
                            .frame(maxWidth: .infinity)
                    }
                    .padding(PlatformAdaptations.isIPad ? 24 : 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            leftPane
                            rightPane
                        }
                        .padding(16)
                    }
                }
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle("Session: \(machineName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        openNewSessionInMainSessionsView()
                    } label: {
                        Label("New Session", systemImage: "plus")
                    }
                    .disabled(subscriber.id == nil)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSession() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        sendWorkoutSessionByEmail()
                        if emailComposer.canSendMail {
                            showingMailComposer = true
                        }
                    }) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.orange)
                    }
                    .disabled(!emailComposer.canSendMail)
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
            .sheet(isPresented: $showingSummary) {
                SummaryView(
                    weight: weight,
                    time: elapsedSeconds,
                    onSave: {
                        dismiss() // Close sheet
                        saveSession() // Save and close editor
                    },
                    onDiscard: {
                        showingSummary = false
                        resetTimer()
                    },
                    onAddTenSeconds: {
                        showingSummary = false
                        addTenSecondsAndRestart()
                    }
                )
                .presentationDetents([.fraction(0.4)])
            }
            .sheet(isPresented: $showingMailComposer) {
                if emailComposer.canSendMail {
                    MailComposerView(
                        subject: emailComposer.subject,
                        body: emailComposer.body,
                        toRecipients: nil,
                        completion: { result, error in
                            emailComposer.handleMailResult(result, error: error)
                            showingMailComposer = false
                        }
                    )
                }
            }
            .alert(LocalizedString.string(for: .common, key: "Cannot Send Email"), isPresented: .constant(emailComposer.errorMessage != nil && !emailComposer.canSendMail)) {
                Button(LocalizedString.string(for: .common, key: "OK")) {
                    emailComposer.errorMessage = nil
                }
            } message: {
                if let errorMessage = emailComposer.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Error Saving Session", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                let msg = errorMessage ?? "Unknown error occurred while saving."
                Text(msg)
            }
            .overlay {
                if showCountdown || showGo {
                    ZStack {
                        // Blurred Background
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                        
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        if showCountdown {
                            Text("\(countdownValue)")
                                .font(.system(size: 120, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 250, height: 250)
                                .background(AppTheme.orange)
                                .clipShape(Circle())
                                .shadow(radius: 20)
                                .transition(.scale.combined(with: .opacity))
                                .id("countdown-\(countdownValue)")
                        } else if showGo {
                             Text("GO!")
                                .font(.system(size: 100, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 250, height: 250)
                                .background(AppTheme.orange)
                                .clipShape(Circle())
                                .shadow(radius: 20)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .zIndex(100)
                }
            }
        }
    }
    
    // MARK: - Left Pane
    private var leftPane: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(AppTheme.orange)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack(spacing: PlatformAdaptations.isIPad ? 24 : 16) {
                    // Rhythm Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("Rhythm Guide")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Spacer()
                            
                            if !isRunning && elapsedSeconds == 0 {
                                HStack(spacing: 8) {
                                    Button(action: { if rhythmDuration > 5 { rhythmDuration -= 5 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    
                                    Text("\(Int(rhythmDuration))s")
                                        .font(.subheadline)
                                        .monospacedDigit()
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    
                                    Button(action: { rhythmDuration += 5 }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                .padding(4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }
                            
                            if plusTenActive {
                                Text("+\(plusTenCountdown)s")
                                    .font(.system(size: 30, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                                    .transition(.scale)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rep \(currentRep)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: 12)
                                .cornerRadius(6)
                        }
                    }
                    .padding(PlatformAdaptations.cardPadding)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    .opacity(isRunning ? 1.0 : 0.9)
                    
                    // Medical Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medical Information")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        // Robustly check for existing data
                        if (subscriber.injuries?.isEmpty ?? true) && (subscriber.healthConditions?.isEmpty ?? true) && (subscriber.restrictions?.isEmpty ?? true) {
                            Text("No conditions provided")
                                .italic()
                                .foregroundStyle(.white.opacity(0.6))
                        } else {
                            if let injuries = subscriber.injuries, !injuries.isEmpty {
                                Label(injuries, systemImage: "cross.case.fill").foregroundStyle(.white)
                            }
                            if let healthConditions = subscriber.healthConditions, !healthConditions.isEmpty {
                                Label(healthConditions, systemImage: "heart.text.square.fill").foregroundStyle(.white)
                            }
                            if let restrictions = subscriber.restrictions, !restrictions.isEmpty {
                                Label(restrictions, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(PlatformAdaptations.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.15))
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    
                    // Notes Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session Notes")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        TextField("Enter notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundStyle(.white)
                    }
                    .padding(PlatformAdaptations.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    
                    Button(action: {
                        sendWorkoutSessionByEmail()
                        if emailComposer.canSendMail {
                            showingMailComposer = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                            Text(LocalizedString.string(for: .common, key: "Send Session Details"))
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(PlatformAdaptations.cardPadding)
                    }
                    .disabled(!emailComposer.canSendMail)
                    .opacity(emailComposer.canSendMail ? 1.0 : 0.6)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(PlatformAdaptations.cardPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Right Pane
    private var rightPane: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(AppTheme.orange)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack(spacing: PlatformAdaptations.isIPad ? 24 : 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(machineName)
                            .font(PlatformAdaptations.isIPad ? .system(size: 48, weight: .black) : .largeTitle)
                            .fontWeight(.black)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(PlatformAdaptations.cardPadding)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading) {
                        Text("Weight (kg)")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        HStack {
                            Button(action: { if weight > 0 { weight -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                            
                            TextField("Weight", value: $weight, format: .number)
                                .font(.system(size: PlatformAdaptations.isIPad ? 40 : 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .foregroundStyle(.white)
                                .frame(width: PlatformAdaptations.isIPad ? 120 : 100)
                            
                            Button(action: { weight += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(PlatformAdaptations.cardPadding)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(PlatformAdaptations.cardPadding)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    
                    VStack(spacing: 16) {
                        if !isRunning && elapsedSeconds == 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    Text("Target:")
                                        .foregroundStyle(.white.opacity(0.8))
                                    ForEach([30, 40, 60, 90, 120], id: \.self) { sec in
                                        Button("\(sec)s") {
                                            targetDuration = TimeInterval(sec)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(targetDuration == TimeInterval(sec) ? .white : .white.opacity(0.5))
                                        .foregroundStyle(targetDuration == TimeInterval(sec) ? AppTheme.orange : .white)
                                    }
                                    Button("None") { targetDuration = nil }
                                        .buttonStyle(.bordered)
                                        .tint(targetDuration == nil ? .white : .white.opacity(0.5))
                                        .foregroundStyle(targetDuration == nil ? AppTheme.orange : .white)
                                }
                            }
                        }
                        
                        Text(formatDuration(elapsedSeconds))
                            .font(.system(size: PlatformAdaptations.isIPad ? 90 : 70, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: elapsedSeconds))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        Button(action: activatePlusTen) {
                            Text("+10s")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(canAddTen ? Color.white : Color.white.opacity(0.3))
                                .foregroundStyle(AppTheme.orange)
                                .cornerRadius(20)
                        }
                        .disabled(!canAddTen)
                        
                        HStack(spacing: 30) {
                            if !isRunning && elapsedSeconds > 0 {
                                Button(action: resetTimer) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                                .transition(.scale)
                            }
                            
                            Button(action: isRunning ? pauseTimer : startTimerSequence) {
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, height: 80)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            if elapsedSeconds > 0 || isRunning {
                                Button(action: finishSession) {
                                    Image(systemName: "square.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(PlatformAdaptations.cardPadding)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(PlatformAdaptations.cardPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Logic
    
    private var canAddTen: Bool {
        return isRunning && elapsedSeconds >= 40 && !plusTenActive
    }
    
    private func startTimerSequence() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        showCountdown = true
        countdownValue = 1
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if self.countdownValue < 3 {
                self.countdownValue += 1
            } else {
                t.invalidate()
                self.countdownTimer = nil
                withAnimation { 
                    self.showCountdown = false 
                    self.showGo = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { self.showGo = false }
                }
                self.startWorkout()
            }
        }
    }
    
    private func startWorkout() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            tick()
        }
    }
    
    private func tick() {
        let dt = 0.01
        elapsedSeconds += dt
        
        if let target = targetDuration {
            if elapsedSeconds >= target {
                elapsedSeconds = target
                finishSession()
                return
            }
        }
        
        if rhythmSeconds < rhythmDuration {
            rhythmSeconds += dt
        } else {
            rhythmSeconds = 0
            if rhythmPhase == .up {
                rhythmPhase = .down
            } else {
                rhythmPhase = .up
                currentRep += 1
            }
        }
        
        if plusTenActive {
            plusTenAccumulator += dt
            if plusTenAccumulator >= 1.0 {
                plusTenAccumulator -= 1.0
                if plusTenCountdown > 0 {
                    plusTenCountdown -= 1
                } else {
                    plusTenActive = false
                }
            }
        }
    }
    
    private func activatePlusTen() {
        if let target = targetDuration {
            targetDuration = target + 10
        }
        plusTenCount += 1
        plusTenActive = true
        plusTenCountdown = 10
        plusTenAccumulator = 0
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func finishSession() {
        pauseTimer()
        showingSummary = true
    }
    
    private func resetTimer() {
        elapsedSeconds = 0
        rhythmSeconds = 0
        rhythmPhase = .up
        currentRep = 1
        plusTenActive = false
        plusTenCount = 0
        countdownTimer?.invalidate()
        countdownTimer = nil
        showCountdown = false
        showGo = false
    }
    
    private func addTenSecondsAndRestart() {
        elapsedSeconds += 10
        if let target = targetDuration {
            targetDuration = target + 10
        }
        startWorkout()
    }
    
    private func saveSession() {
        Task {
            do {
                // Construct SessionExerciseFS
                var newExercise = SessionExerciseFS(
                    name: machineName,
                    machineName: machineName,
                    machineCategory: "Unknown",
                    rhythm: Int(rhythmDuration),
                    weight: weight,
                    intensity: "Normal",
                    targetDuration: targetDuration, // Save the GOAL
                    enduranceTime: elapsedSeconds,  // Save the ACTUAL time
                    isCompleted: true,
                    orderIndex: 0,
                    notes: notes,
                    plusTenCount: plusTenCount
                )
                
                // If editing exisiting exercise in existing session:
                if let existingSession = config.session, let existingExercise = config.exercise {
                    // Update specific exercise in the session
                    var updatedSession = existingSession
                    
                    // Fetch fresh copy if possible to avoid stale overwrite
                    if let sessionId = existingSession.id {
                        if let freshSession = try? await FirestoreService.shared.getSession(id: sessionId) {
                            updatedSession = freshSession
                        }
                    }
                    
                    var exercises = updatedSession.exercises ?? []
                    
                    newExercise.id = existingExercise.id
                    
                    if let index = exercises.firstIndex(where: { $0.id == existingExercise.id }) {
                        exercises[index] = newExercise
                    } else {
                        exercises.append(newExercise)
                    }
                    updatedSession.exercises = exercises
                    
                    try await FirestoreService.shared.updateSession(updatedSession)
                } 
                // If adding new exercise to existing session (or new session):
                else if let session = config.session {
                    // Add to existing session
                    var updatedSession = session
                    
                    // CRITICAL FIX: Fetch latest session from Firestore to avoid overwriting recent changes (Stale UI)
                    if let sessionId = session.id {
                        if let freshSession = try? await FirestoreService.shared.getSession(id: sessionId) {
                            updatedSession = freshSession
                        }
                    }
                    
                    var exercises = updatedSession.exercises ?? []
                    newExercise.orderIndex = exercises.count
                    exercises.append(newExercise)
                    updatedSession.exercises = exercises
                    
                    try await FirestoreService.shared.updateSession(updatedSession)
                } else if let date = config.date {
                    // Create NEW session for date
                    // CRITICAL FIX: Check if a session ALREADY exists for this date/subscriber to avoid duplicates
                    // This happens if the UI is stale and doesn't know about a session just created by another machine action
                    var sessionToUse: SessionFS?
                    
                    if let subId = subscriber.id {
                         sessionToUse = try await FirestoreService.shared.findSession(subscriberId: subId, date: date)
                    }
                    
                    if var existingSessionOnServer = sessionToUse {
                        // Update the EXISTING session we found
                        var exercises = existingSessionOnServer.exercises ?? []
                        newExercise.orderIndex = exercises.count
                        exercises.append(newExercise)
                        existingSessionOnServer.exercises = exercises
                        
                        try await FirestoreService.shared.updateSession(existingSessionOnServer)
                    } else {
                        // TRULY New Session
                        let newSession = SessionFS(
                            date: date,
                            status: "Completed",
                            title: "Workout",
                            subscriberId: subscriber.id ?? "",
                            exercises: [newExercise]
                        )
                        _ = try await FirestoreService.shared.addSession(newSession)
                    }
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func openNewSessionInMainSessionsView() {
        guard let subscriberID = subscriber.id else { return }
        
        pendingSubscriberID = subscriberID
        requestedRootTab = 3
        
        NotificationCenter.default.post(name: NSNotification.Name("SessionsTabSelected"), object: nil)
        
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dismiss()
        }
    }
    
    private func sendWorkoutSessionByEmail() {
        // ... Placeholder ...
        // emailComposer.sendWorkoutSessionDetails(...)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        let ms = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", m, s, ms)
    }
}

// Summary Sheet
struct SummaryView: View {
    let weight: Double
    let time: TimeInterval
    let onSave: () -> Void
    let onDiscard: () -> Void
    let onAddTenSeconds: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Session Summary")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                VStack {
                    Text("\(Int(weight)) kg")
                        .font(.title2)
                        .fontWeight(.heavy)
                    Text("Weight")
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text(formatDuration(time))
                        .font(.title2)
                        .fontWeight(.heavy)
                    Text("Time")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            HStack(spacing: 20) {
                Button("Discard", role: .destructive, action: onDiscard)
                    .buttonStyle(.bordered)
                
                Button("+10 seconds", action: onAddTenSeconds)
                    .buttonStyle(.bordered)
                    .tint(AppTheme.orange)
                
                Button("Save Session", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.orange)
            }
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        let ms = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", m, s, ms)
    }
}
