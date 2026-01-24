//
//  PlansView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData
import Combine
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PlansView: View {
    @StateObject private var firestoreService = FirestoreService.shared
    @State private var subscribers: [SubscriberFS] = []
    @State private var showingAddPlan = false
    @State private var cancellables = Set<AnyCancellable>()
    
    let planTypes = ["Monthly", "3-Month", "6-Month", "Annual"]
    
    var planGroups: [String: [SubscriberFS]] {
        Dictionary(grouping: subscribers) { $0.planType ?? "Unknown" }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(planTypes, id: \.self) { planType in
                    Section {
                        let planSubscribers = planGroups[planType] ?? []
                        ForEach(planSubscribers) { subscriber in
                            NavigationLink {
                                SubscriberDetailView(subscriber: subscriber)
                            } label: {
                                PlanSubscriberRow(subscriber: subscriber)
                            }
                        }
                    } header: {
                        HStack {
                            Text(planType)
                            Spacer()
                            Text("\(planGroups[planType]?.count ?? 0)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    if subscribers.isEmpty {
                        ContentUnavailableView(
                            "No Subscribers",
                            systemImage: "person.2",
                            description: Text("Add subscribers to see them organized by plan type.")
                        )
                        .frame(height: 200)
                    }
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddPlan = true
                    } label: {
                        Label("Add Subscriber", systemImage: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlan = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                #endif
            }
            .platformSheet(isPresented: $showingAddPlan) {
                AddEditSubscriberView()
            }
            .onAppear {
                setupSubscription()
            }
        }
    }
    
    private func setupSubscription() {
        firestoreService.fetchSubscribers()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching subscribers: \(error)")
                }
            } receiveValue: { fetchedSubscribers in
                self.subscribers = fetchedSubscribers
            }
            .store(in: &cancellables)
    }
}

struct PlanSubscriberRow: View {
    let subscriber: SubscriberFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if let photoUrl = subscriber.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
                    .font(.headline)
                Text(subscriber.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(subscriber.paymentStatus ?? "Unknown")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(paymentStatusColor(for: subscriber.paymentStatus ?? "Unknown"))
                .foregroundColor(.white)
                .cornerRadius(6)
        }
    }
    
    private func paymentStatusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "pending":
            return .orange
        case "expired":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    PlansView()
}

