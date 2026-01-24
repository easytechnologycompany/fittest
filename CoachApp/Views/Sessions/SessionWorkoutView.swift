//
//  SessionWorkoutView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData
import Combine

struct SessionWorkoutView: View {
    @Bindable var session: Session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingAddExerciseSheet = false
    @State private var showingAddSubscriberSheet = false
    @State private var showingSubscriberSidebar = false
    
    @State private var rhythmEngine = RhythmEngine()
    
    // Countdown state (pre-workout)
    @State private var activeExerciseId: UUID?
    @State private var showCountdown = false
    @State private var countdownValue = 3
    @State private var countdownTimer: AnyCancellable?
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Main Content
                    VStack(spacing: 0) {
                        workoutHeader
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                if let exercises = session.exercises, !exercises.isEmpty {
                                    ForEach(exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                                        ExerciseCard(
                                            exercise: exercise,
                                            isActive: activeExerciseId == exercise.id,
                                            engine: rhythmEngine,
                                            onStart: { startSequence(for: exercise) },
                                            onStop: { stopSequence() },
                                            onDelete: { deleteExercise(exercise) }
                                        )
                                    }
                                } else {
                                    Text("No exercises added yet")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 50)
                                }
                                
                                Button(action: { showingAddExerciseSheet = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Exercise")
                                    }
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.orange)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.orange.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(AppTheme.orange, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    )
                                }
                                .padding()
                            }
                            .padding()
                        }
                    }
                    .frame(width: showingSubscriberSidebar ? geometry.size.width * 0.7 : geometry.size.width)
                    
                    // Sidebar
                    if showingSubscriberSidebar {
                        Divider()
                        SubscriberSidebar(session: session, isPresented: $showingSubscriberSidebar)
                            .frame(width: geometry.size.width * 0.3)
                            .background(AppTheme.secondaryBackgroundColor(for: colorScheme))
                            .transition(.move(edge: .trailing))
                    }
                }
            }
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation {
                        showingSubscriberSidebar.toggle()
                    }
                }) {
                    Image(systemName: "person.2.badge.gearshape")
                        .foregroundStyle(showingSubscriberSidebar ? AppTheme.orange : .primary)
                }
            }
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            ExerciseSelectionSheet(session: session)
        }
        .overlay {
            if showCountdown {
                Color.black.opacity(0.7).ignoresSafeArea()
                Text("\(countdownValue)")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.scale)
            }
        }
    }
    
    private var workoutHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(AppTheme.backgroundColor(for: colorScheme))
    }
    
    private func startSequence(for exercise: SessionExercise) {
        // Stop any existing
        if activeExerciseId != nil {
            stopSequence()
        }
        
        activeExerciseId = exercise.id
        
        // Start Countdown
        countdownValue = 3
        showCountdown = true
        
        countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                // Done
                showCountdown = false
                countdownTimer?.cancel()
                countdownTimer = nil
                
                // Start Rhythm Engine
                rhythmEngine.start(rhythm: exercise.rhythm)
            }
        }
    }
    
    private func stopSequence() {
        // Stop engine
        if rhythmEngine.isRunning {
             rhythmEngine.stop()
        }
        // Cancel countdown if needed
        countdownTimer?.cancel()
        countdownTimer = nil
        showCountdown = false
        
        // Don't clear activeExerciseId immediately if we want to show "Stopped" state?
        // But UI says "Go" if not active. 
        // Logic: specific exercise is active.
        // If we stop, does it become inactive? Usually yes.
        activeExerciseId = nil
    }
    
    private func deleteExercise(_ exercise: SessionExercise) {
        if activeExerciseId == exercise.id {
            stopSequence()
        }
        if let index = session.exercises?.firstIndex(where: { $0.id == exercise.id }) {
            session.exercises?.remove(at: index)
            modelContext.delete(exercise)
        }
    }
}

struct ExerciseCard: View {
    @Bindable var exercise: SessionExercise
    var isActive: Bool
    var engine: RhythmEngine
    var onStart: () -> Void
    var onStop: () -> Void
    var onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    if let machine = exercise.machineName, machine != exercise.name {
                        Text(machine)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                        .hoverEffect(.highlight)
                }
            }
            
            Divider().overlay(.white.opacity(0.3))
            
            // Parameters Grid
            Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    // Rhythm
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rhythm")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        HStack(spacing: 0) {
                            Button(action: { updateRhythm(by: -1) }) {
                                Image(systemName: "minus")
                                    .frame(width: 30, height: 36)
                                    .background(.white.opacity(0.2))
                            }
                            // Long press for larger steps?
                            // For simplicity, just tap -1 or -10? User request implies "increase rhythm". 10s steps are large. 
                            // Previous code was 10. I'll stick to 1s steps for granular control or 5?
                            // Screenshot showed "10s", "20s". 
                            // I'll keep 1s steps for flexibility as "Live Update" suggests fine tuning.
                            // Or keep 10? User example "increase... 20s".
                            // I'll use 5s steps? Or keep 10?
                            // I'll switch to 1s steps to show responsiveness, or 5.
                            // Let's do 1s steps because 10 to 20 is a huge jump live.
                            
                            Text("\(exercise.rhythm)s")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 50, height: 36)
                                .background(.white)
                                .foregroundStyle(AppTheme.blue)
                            
                            Button(action: { updateRhythm(by: 1) }) {
                                Image(systemName: "plus")
                                    .frame(width: 30, height: 36)
                                    .background(.white.opacity(0.2))
                            }
                        }
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        TextField("0", value: $exercise.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(height: 36)
                            .background(.white)
                            .foregroundStyle(AppTheme.blue)
                            .cornerRadius(8)
                            .focused($isFocused)
                    }
                    
                    // Intensity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        Picker("Intensity", selection: $exercise.intensity) {
                            Text("Low").tag("Low")
                            Text("Med").tag("Medium")
                            Text("High").tag("High")
                        }
                        .labelsHidden()
                        .frame(height: 36)
                        .background(.white)
                        .tint(AppTheme.blue)
                        .cornerRadius(8)
                    }
                }
            }
            
            Divider().overlay(.white.opacity(0.3))
            
            // Timer Area
            if isActive {
                VStack(spacing: 16) {
                    // Total Time Display
                    Text(formatDuration(engine.elapsedTime))
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: engine.elapsedTime))
                    
                    // Rhythm Phase (Secondary)
                    HStack(spacing: 8) {
                        Text(engine.phase.rawValue)
                            .fontWeight(.bold)
                        Text("\(engine.remainingSeconds)s")
                            .font(.system(.title3, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    
                    // Controls
                    HStack(spacing: 20) {
                        Button(action: { engine.lap() }) {
                            Text("Lap")
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.blue)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(.white)
                                .cornerRadius(20)
                        }
                        
                        Button(action: onStop) {
                            Text("Reset")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(.red)
                                .cornerRadius(20)
                        }
                    }
                    
                    // Laps List
                    if !engine.laps.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Laps")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            ForEach(Array(engine.laps.enumerated().reversed()), id: \.offset) { index, lapTime in
                                HStack {
                                    Text("Lap \(index + 1)")
                                        .font(.caption)
                                    Spacer()
                                    Text(formatDuration(lapTime))
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(.white.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                        .frame(maxHeight: 120)
                        .padding(.top, 8)
                    }
                    
                    // Progress Bar
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.white.opacity(0.3))
                            .frame(height: 4)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(.white)
                                    .frame(width: geo.size.width * engine.progress, height: 4)
                            }
                    }
                    .frame(height: 4)
                }
            } else {
                // Ready / Idle State
                HStack {
                    Text("READY")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Button(action: onStart) {
                        Text("GO")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundStyle(AppTheme.orange)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.white)
                            .cornerRadius(24)
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .padding(20)
        .modernCard(isOrange: true)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalCentiseconds = Int(duration * 100)
        let minutes = totalCentiseconds / 6000
        let seconds = (totalCentiseconds % 6000) / 100
        let centiseconds = totalCentiseconds % 100
        return String(format: "%02d:%02d:%02d", minutes, seconds, centiseconds)
    }
    
    private func updateRhythm(by amount: Int) {
        let newValue = exercise.rhythm + amount
        if newValue >= 1 { // Minimum 1s
            exercise.rhythm = newValue
            
            // Dynamic Intensity Logic
            // Faster rhythm = Higher intensity category (Speed-wise)
            if newValue < 5 {
                exercise.intensity = "High"
            } else if newValue < 10 {
                exercise.intensity = "Medium"
            } else {
                exercise.intensity = "Low"
            }
            
            if isActive {
                engine.updateRhythm(newValue)
            }
        }
    }
}

struct SubscriberSidebar: View {
    @Bindable var session: Session
    @Binding var isPresented: Bool
    @State private var showingAddSubscriber = false
    @Environment(\.modelContext) private var modelContext
    @Query private var allSubscribers: [Subscriber]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Subscribers")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddSubscriber = true }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    if let subscribers = session.subscribers {
                        ForEach(subscribers) { subscriber in
                            SubscriberHealthCard(subscriber: subscriber)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddSubscriber) {
            AddSubscriberSheet(session: session)
        }
    }
}

struct SubscriberHealthCard: View {
    let subscriber: Subscriber
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Initial or photo
                Circle()
                    .fill(AppTheme.orange.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .overlay(Text(subscriber.name.prefix(1)).foregroundStyle(AppTheme.orange))
                
                Text(subscriber.name)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if isExpanded {
                Divider()
                
                Group {
                    if !subscriber.injuries.isEmpty {
                        Label(subscriber.injuries, systemImage: "cross.case.fill")
                            .foregroundStyle(.red)
                    }
                    if !subscriber.healthConditions.isEmpty {
                        Label(subscriber.healthConditions, systemImage: "heart.text.square.fill")
                            .foregroundStyle(.orange)
                    }
                    if !subscriber.restrictions.isEmpty {
                        Label(subscriber.restrictions, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                    }
                    // Fallback if noting
                    if subscriber.injuries.isEmpty && subscriber.healthConditions.isEmpty && subscriber.restrictions.isEmpty {
                        Text("No health alerts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AddSubscriberSheet: View {
    @Bindable var session: Session
    @Environment(\.dismiss) var dismiss
    @Query private var allSubscribers: [Subscriber]
    
    var body: some View {
        NavigationStack {
            List(allSubscribers) { subscriber in
                HStack {
                    Text(subscriber.name)
                    Spacer()
                    if session.subscribers?.contains(where: { $0.id == subscriber.id }) == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.orange)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSubscriber(subscriber)
                }
            }
            .navigationTitle("Add Subscribers")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func toggleSubscriber(_ subscriber: Subscriber) {
        if session.subscribers?.contains(where: { $0.id == subscriber.id }) == true {
            session.subscribers?.removeAll(where: { $0.id == subscriber.id })
        } else {
            session.subscribers?.append(subscriber)
        }
    }
}
