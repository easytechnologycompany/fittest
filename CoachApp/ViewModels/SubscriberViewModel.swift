//
//  SubscriberViewModel.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 18/01/2026.
//

import Foundation
import Combine
import SwiftUI

class SubscriberViewModel: ObservableObject {
    @Published var subscribers: [SubscriberFS] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchSubscribers()
    }
    
    func fetchSubscribers() {
        isLoading = true
        FirestoreService.shared.fetchSubscribers()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] subscribers in
                self?.isLoading = false
                self?.subscribers = subscribers
            }
            .store(in: &cancellables)
    }
    
    func addSubscriber(_ subscriber: SubscriberFS) async {
        do {
            try await FirestoreService.shared.addSubscriber(subscriber)
            // No need to manually append, the listener will update the list
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteSubscriber(_ subscriber: SubscriberFS) {
        guard let id = subscriber.id else { return }
        Task {
            do {
                try await FirestoreService.shared.deleteSubscriberAndData(subscriberId: id)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete subscriber: \(error.localizedDescription)"
                }
            }
        }
    }
}
