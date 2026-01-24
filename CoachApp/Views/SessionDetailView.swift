//
//  SessionDetailView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI

struct SessionDetailView: View {
    @StateObject private var viewModel: SessionViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var showingMailComposer = false

    init(session: SessionModel, courseTitle: String) {
        _viewModel = StateObject(wrappedValue: SessionViewModel(session: session, courseTitle: courseTitle))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    if PlatformAdaptations.isIPad {
                        // iPad: Two-column layout for better space utilization
                        iPadLayout(geometry: geometry)
                    } else {
                        // iPhone: Vertical layout that fills width
                        iPhoneLayout(geometry: geometry)
                    }
                }
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.sendResultsByEmail()
                        if viewModel.emailComposer.canSendMail {
                            showingMailComposer = true
                        }
                    }) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.orange)
                    }
                    .disabled(!viewModel.emailComposer.canSendMail)
                }
            }
            .alert(LocalizedString.string(for: .common, key: "Cannot Send Email"), isPresented: .constant(viewModel.emailComposer.errorMessage != nil && !viewModel.emailComposer.canSendMail)) {
                Button(LocalizedString.string(for: .common, key: "OK")) {
                    viewModel.emailComposer.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.emailComposer.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                if viewModel.emailComposer.canSendMail {
                    MailComposerView(
                        subject: viewModel.emailComposer.subject,
                        body: viewModel.emailComposer.body,
                        toRecipients: nil,
                        completion: { result, error in
                            viewModel.emailComposer.handleMailResult(result, error: error)
                            showingMailComposer = false
                        }
                    )
                }
            }
            .alert(LocalizedString.string(for: .common, key: "Email Status"), isPresented: .constant(viewModel.emailComposer.errorMessage != nil && viewModel.emailComposer.canSendMail)) {
                Button(LocalizedString.string(for: .common, key: "OK")) {
                    viewModel.emailComposer.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.emailComposer.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - iPad Layout (Two-column)
    @ViewBuilder
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = 20
        let padding: CGFloat = 24
        let availableWidth = geometry.size.width - padding * 2
        let columnWidth = (availableWidth - spacing) / 2
        
        VStack(spacing: spacing) {
            // Top row: Session Header (full width)
            sessionHeaderCard
                .frame(maxWidth: .infinity)
            
            // Middle row: Timer and Equipment side by side
            HStack(alignment: .top, spacing: spacing) {
                // Rhythm Timer
                rhythmTimerCard
                    .frame(width: columnWidth)
                    .frame(minHeight: 300)
                
                // Equipment Snapshot
                equipmentCard
                    .frame(width: columnWidth)
                    .frame(minHeight: 300)
            }
            
            // Results and Email row
            HStack(alignment: .top, spacing: spacing) {
                // Results (if available)
                if let results = viewModel.session.results, !results.isEmpty {
                    resultsCard(results: results)
                        .frame(width: columnWidth)
                        .frame(minHeight: 150)
                } else {
                    // Empty space if no results
                    Spacer()
                        .frame(width: columnWidth)
                }
                
                // Email Button
                emailButtonCard
                    .frame(width: columnWidth)
                    .frame(minHeight: 150)
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
    }
    
    // MARK: - iPhone Layout (Vertical, full width)
    @ViewBuilder
    private func iPhoneLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = 16
        let padding: CGFloat = 16
        
        VStack(spacing: spacing) {
            sessionHeaderCard
                .frame(maxWidth: .infinity)
            
            rhythmTimerCard
                .frame(maxWidth: .infinity)
                .frame(minHeight: 250)
            
            equipmentCard
                .frame(maxWidth: .infinity)
            
            if let results = viewModel.session.results, !results.isEmpty {
                resultsCard(results: results)
                    .frame(maxWidth: .infinity)
            }
            
            emailButtonCard
                .frame(maxWidth: .infinity)
            
            // Spacer to push content to top and fill screen
            Spacer(minLength: 0)
        }
        .padding(padding)
        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
    }
    
    // MARK: - Card Components
    @ViewBuilder
    private var sessionHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.session.title)
                .font(PlatformAdaptations.isIPad ? .largeTitle : .title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textColor(for: colorScheme))

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppTheme.orange)
                Text(viewModel.session.createdAt.formatted(.dateTime.day().month().year().hour().minute()))
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }

            if let completedAt = viewModel.session.completedAt {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed \(completedAt.formatted(.dateTime.day().month().year().hour().minute()))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PlatformAdaptations.cardPadding)
        .modernCard(isOrange: true)
    }
    
    @ViewBuilder
    private var rhythmTimerCard: some View {
        RhythmTimerView(viewModel: viewModel.rhythmTimer)
            .padding(PlatformAdaptations.cardPadding)
            .modernCard(isOrange: true)
    }
    
    @ViewBuilder
    private var equipmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.session.equipmentSnapshot.isEmpty {
                Text("No equipment specified")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.session.equipmentSnapshot, id: \.self) { item in
                        HStack {
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(AppTheme.orange)
                                .frame(width: 20)
                            Text(item)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PlatformAdaptations.cardPadding)
        .modernCard(isOrange: true)
    }
    
    @ViewBuilder
    private func resultsCard(results: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.title2)
                .fontWeight(.bold)

            Text(results)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PlatformAdaptations.cardPadding)
        .modernCard(isOrange: true)
    }
    
    @ViewBuilder
    private var emailButtonCard: some View {
        Button(action: {
            viewModel.sendResultsByEmail()
            if viewModel.emailComposer.canSendMail {
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
        .disabled(!viewModel.emailComposer.canSendMail)
        .opacity(viewModel.emailComposer.canSendMail ? 1.0 : 0.6)
        .frame(maxWidth: .infinity)
        .modernCard(isOrange: true)
    }
}

struct RhythmTimerView: View {
    @ObservedObject var viewModel: RhythmTimerViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Current Phase Display
            VStack(spacing: 8) {
                Text(viewModel.currentPhase.displayName)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))

                Text("\(viewModel.remainingSeconds)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(AppTheme.orange)
                    .monospacedDigit()
            }

            // Timer Controls
            HStack(spacing: 20) {
                Button(action: {
                    switch viewModel.state {
                    case .stopped, .paused:
                        viewModel.start()
                    case .running:
                        viewModel.pause()
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                        Text(viewModel.state == .running ? "Pause" : "Start")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.orange)
                    .cornerRadius(12)
                }

                if viewModel.state != .stopped {
                    Button(action: { viewModel.stop() }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
            }

            // Stats
            VStack(spacing: 8) {
                HStack {
                    Text("Rounds:")
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    Spacer()
                    Text("\(viewModel.totalRounds)")
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.orange)
                }

                HStack {
                    Text("Total Time:")
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    Spacer()
                    Text(formatDuration(viewModel.totalTimeElapsed))
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.orange)
                }
            }
            .font(.caption)
        }
    }

    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60

        if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
