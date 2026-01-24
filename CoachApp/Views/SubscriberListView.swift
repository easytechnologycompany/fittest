//
//  SubscriberListView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
// import SwiftData // Removed SwiftData dependency for list
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SubscriberListView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = SubscriberViewModel()
    
    @State private var searchText = ""
    @State private var showingAddSubscriber = false
    @State private var showingDeleteConfirmation = false
    @State private var subscriberToDelete: SubscriberFS?
    
    var filteredSubscribers: [SubscriberFS] {
        if searchText.isEmpty {
            return viewModel.subscribers
        } else {
            return viewModel.subscribers.filter { subscriber in
                subscriber.name.localizedCaseInsensitiveContains(searchText) ||
                subscriber.email.localizedCaseInsensitiveContains(searchText) ||
                subscriber.phone.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var gridColumns: [GridItem] {
        #if os(macOS)
        return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        #else
        // Default to iPad (3 columns), fallback to iPhone (2 columns)
        if PlatformAdaptations.isIPhone {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        } else {
            // iPad default: 3 columns
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        }
        #endif
    }
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List {
                ForEach(filteredSubscribers) { subscriber in
                    NavigationLink {
                        SubscriberDetailView(subscriber: subscriber)
                    } label: {
                        SubscriberRowView(subscriber: subscriber)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let subscriber = filteredSubscribers[index]
                        viewModel.deleteSubscriber(subscriber)
                    }
                }
            }
            .navigationTitle("Subscribers")
            .searchable(text: $searchText, prompt: "Search subscribers")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingAddSubscriber = true }) {
                        Label("Add Subscriber", systemImage: "plus")
                    }
                }
            }
            .platformSheet(isPresented: $showingAddSubscriber) {
                // TODO: Update AddEditSubscriberView
                Text("Add Subscriber (Coming Soon)")
            }
        } detail: {
            Text("Select a subscriber")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.secondary)
        }
        #else
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading subscribers...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if filteredSubscribers.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Subscribers" : "No Subscribers Found",
                        systemImage: "person.2",
                        description: Text(searchText.isEmpty ? "Add your first subscriber to get started." : "Try adjusting your search.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: PlatformAdaptations.defaultSpacing) {
                        ForEach(filteredSubscribers) { subscriber in
                            NavigationLink {
                                SubscriberDetailView(subscriber: subscriber)
                            } label: {
                                SubscriberCardView(subscriber: subscriber)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    subscriberToDelete = subscriber
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(PlatformAdaptations.cardPadding)
                }
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle("Subscribers")
            .searchable(text: $searchText, prompt: "Search subscribers")
            .showTabBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubscriber = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.primaryGradient(for: colorScheme))
                    }
                }
            }
            .platformSheet(isPresented: $showingAddSubscriber) {
                AddEditSubscriberView()
            }
            .alert("Delete Subscriber", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    subscriberToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let subscriber = subscriberToDelete {
                        viewModel.deleteSubscriber(subscriber)
                    }
                    subscriberToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this subscriber? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onAppear {
            viewModel.fetchSubscribers()
        }
        #endif
    }
}

// Grid Card View for Subscribers
struct SubscriberCardView: View {
    let subscriber: SubscriberFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Photo Placeholder (AsyncImage later)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                
                Spacer()
                
                Text(subscriber.paymentStatus ?? "Unknown")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Group {
                            if (subscriber.paymentStatus ?? "").lowercased() == "active" {
                                AppTheme.orange.opacity(0.3)
                            } else {
                                paymentStatusColor(for: subscriber.paymentStatus ?? "Unknown").opacity(0.3)
                            }
                        }
                    )
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(subscriber.planType ?? "Unknown")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
            }
        }
        .padding(PlatformAdaptations.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .background(AppTheme.orange)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 10, x: 0, y: 4)
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

// Legacy Row View (kept for macOS)
struct SubscriberRowView: View {
    let subscriber: SubscriberFS
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscriber.name.isEmpty ? "Unnamed" : subscriber.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                Text(subscriber.email)
                    .font(.caption)
                    .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                HStack {
                    Label(subscriber.planType ?? "Unknown", systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(AppTheme.gradientCardSecondaryTextColor(for: colorScheme))
                    Spacer()
                    Text(subscriber.paymentStatus ?? "Unknown")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Group {
                                if (subscriber.paymentStatus ?? "").lowercased() == "active" {
                                    AppTheme.primaryGradient(for: colorScheme)
                                } else {
                                    paymentStatusColor(for: subscriber.paymentStatus ?? "Unknown")
                                }
                            }
                        )
                        .foregroundColor(AppTheme.gradientCardTextColor(for: colorScheme))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .modernCard(isOrange: true)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
    SubscriberListView()
}

