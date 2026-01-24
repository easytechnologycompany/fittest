import SwiftUI
import Combine

struct SessionsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var subscribers: [SubscriberFS] = []
    @State private var subscriberSessions: [SessionFS] = []
    @State private var machines: [String] = []
    
    // Selection
    @State private var selectedSubscriber: SubscriberFS?
    @AppStorage("pendingSubscriberSelection") private var pendingSubscriberID: String = ""
    
    // New Session Wizard State
    @State private var showingNewSessionSheet = false
    @State private var wizardSubscriber: SubscriberFS?
    @State private var wizardMachine: String = "Chest press"
    @State private var wizardDate: Date = Date()
    @State private var navigateToEditor = false
    
    // Email State
    @State private var showingMailComposer = false
    @StateObject private var emailComposer = EmailComposerViewModel()
    
    @State private var refreshTrigger = UUID()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                Divider()
                contentView
            }
            .navigationTitle("Sessions")
            .onAppear(perform: setupSubscriptions)
            .onChange(of: selectedSubscriber) { oldValue, newValue in
                if let sub = newValue {
                    fetchSessions(for: sub)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExerciseOrderChanged"))) { _ in
                refreshTrigger = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SessionsTabSelected"))) { _ in
                handlePendingSelection()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarItems
                }
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                wizardSheet
            }
            .sheet(isPresented: $showingMailComposer) {
                mailComposerSheet
            }
            .alert(LocalizedString.string(for: .common, key: "Email Status"), isPresented: .constant(emailComposer.errorMessage != nil)) {
                Button(LocalizedString.string(for: .common, key: "OK")) {
                    emailComposer.errorMessage = nil
                }
            } message: {
                if let errorMessage = emailComposer.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            if subscribers.isEmpty {
                Text("No subscribers found")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                HStack {
                    Text("Subscriber:")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(subscribers) { sub in
                            Button(sub.name) {
                                selectedSubscriber = sub
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedSubscriber?.name ?? "Select Subscriber")
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.orange)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(AppTheme.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.backgroundColor(for: colorScheme).opacity(0.5))
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            if let subscriber = selectedSubscriber {
                SubscriberSessionsView(
                    subscriber: subscriber,
                    sessions: subscriberSessions,
                    availableExercises: machines,
                    showAddButton: false
                )
                .id(subscriber.id)
                .id(refreshTrigger)
            } else {
                emptyStateView
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.orange.opacity(0.5))
            
            Text("Select a subscriber to view their sessions")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var trailingToolbarItems: some View {
        HStack(spacing: 16) {
            if let subscriber = selectedSubscriber {
                Menu {
                    Button(action: {
                        Task {
                            await sendAllSessionsByEmail(for: subscriber)
                        }
                    }) {
                        Label("Send All Sessions by Email", systemImage: "envelope.fill")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        wizardSubscriber = subscriber
                        showingNewSessionSheet = true
                    }) {
                        Label("New Session", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppTheme.orange)
                }
            } else {
                Button(action: {
                    showingNewSessionSheet = true
                }) {
                    Label("New Session", systemImage: "plus")
                }
            }
        }
    }
    
    @ViewBuilder
    private var wizardSheet: some View {
        NavigationStack {
            Form {
                Section("Who is training?") {
                    Picker("Subscriber", selection: $wizardSubscriber) {
                        Text("Select Subscriber").tag(nil as SubscriberFS?)
                        ForEach(subscribers) { sub in
                            Text(sub.name).tag(sub as SubscriberFS?)
                        }
                    }
                }
                
                Section("Session Details") {
                    Picker("Machine", selection: $wizardMachine) {
                        ForEach(machines, id: \.self) { machine in
                            Text(machine).tag(machine)
                        }
                    }
                    
                    DatePicker("Date", selection: $wizardDate, displayedComponents: [.date])
                }
                
                Section {
                    Button("Start Session") {
                        if wizardSubscriber != nil {
                            navigateToEditor = true
                        }
                    }
                    .disabled(wizardSubscriber == nil)
                    .foregroundStyle(wizardSubscriber == nil ? .gray : AppTheme.orange)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNewSessionSheet = false }
                }
            }
            .navigationDestination(isPresented: $navigateToEditor) {
                if let sub = wizardSubscriber {
                    WorkoutSessionDetailView(
                        config: SessionEditorConfig(machine: wizardMachine, date: wizardDate),
                        subscriber: sub
                    )
                    .onDisappear {
                        showingNewSessionSheet = false
                        selectedSubscriber = sub
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    @ViewBuilder
    private var mailComposerSheet: some View {
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
    
    private func setupSubscriptions() {
        FirestoreService.shared.fetchSubscribers()
            .sink { _ in } receiveValue: { subs in
                self.subscribers = subs
                handlePendingSelection()
                if selectedSubscriber == nil, let first = subs.first {
                    selectedSubscriber = first
                }
            }
            .store(in: &cancellables)
            
        FirestoreService.shared.fetchMachines()
            .sink { _ in } receiveValue: { machines in
                let fetchedNames = machines.map { $0.name }
                let defaults = ExerciseHelper.defaultExercises
                // Combine defaults and fetched machines, removing duplicates
                let all = Set(defaults).union(fetchedNames)
                self.machines = ExerciseHelper.applyOrdering(to: Array(all))
            }
            .store(in: &cancellables)
    }
    
    private func fetchSessions(for subscriber: SubscriberFS) {
        guard let subId = subscriber.id else { return }
        FirestoreService.shared.fetchSessions(for: subId)
            .sink { _ in } receiveValue: { sessions in
                self.subscriberSessions = sessions
            }
            .store(in: &cancellables)
    }
    
    private func handlePendingSelection() {
        if !pendingSubscriberID.isEmpty {
            if let subscriber = subscribers.first(where: { $0.id == pendingSubscriberID }) {
                selectedSubscriber = subscriber
                pendingSubscriberID = ""
            }
        }
    }
    
    private func sendAllSessionsByEmail(for subscriber: SubscriberFS) async {
        guard emailComposer.canSendMail else {
            emailComposer.errorMessage = LocalizedString.string(for: .common, key: "Set up a Mail account in iOS Mail to send email.")
            return
        }
        
        guard let subId = subscriber.id else { return }
        
        FirestoreService.shared.fetchSessions(for: subId)
            .first()
            .sink { completion in
                if case .failure(let error) = completion {
                    self.emailComposer.errorMessage = "Failed to fetch sessions: \(error.localizedDescription)"
                }
            } receiveValue: { sessions in
                let sortedSessions = sessions.sorted(by: { $0.date > $1.date })
                if sortedSessions.isEmpty {
                    self.emailComposer.errorMessage = "No sessions to send."
                } else {
                    self.emailComposer.sendAllWorkoutSessions(
                        subscriberName: subscriber.name,
                        sessions: sortedSessions
                    )
                    self.showingMailComposer = true
                }
            }
            .store(in: &cancellables)
    }
}

#Preview {
    SessionsView()
}
