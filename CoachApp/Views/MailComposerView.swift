//
//  MailComposerView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import MessageUI
import Combine

/// SwiftUI wrapper for MFMailComposeViewController
struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let toRecipients: [String]?
    let completion: (MFMailComposeResult, Error?) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        if let recipients = toRecipients {
            composer.setToRecipients(recipients)
        }
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let completion: (MFMailComposeResult, Error?) -> Void

        init(completion: @escaping (MFMailComposeResult, Error?) -> Void) {
            self.completion = completion
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            completion(result, error)
            controller.dismiss(animated: true)
        }
    }
}

/// View model for handling email composition and sending
class EmailComposerViewModel: ObservableObject {
    @Published var isShowingComposer = false
    @Published var canSendMail = MFMailComposeViewController.canSendMail()
    @Published var errorMessage: String?
    @Published var subject: String = ""
    @Published var body: String = ""

    func sendSessionResults(courseTitle: String, sessionTitle: String, sessionDate: Date, rhythmUpSeconds: Int, rhythmDownSeconds: Int, equipment: [String], results: String?, completedAt: Date? = nil) {
        guard canSendMail else {
            errorMessage = LocalizedString.string(for: .common, key: "Set up a Mail account in iOS Mail to send email.")
            return
        }

        subject = "Session Details: \(sessionTitle)"
        body = createEmailBody(
            courseTitle: courseTitle,
            sessionTitle: sessionTitle,
            sessionDate: sessionDate,
            rhythmUpSeconds: rhythmUpSeconds,
            rhythmDownSeconds: rhythmDownSeconds,
            equipment: equipment,
            results: results,
            completedAt: completedAt
        )

        isShowingComposer = true

        // Note: The actual sending is handled by the MailComposerView
    }

    private func createEmailBody(courseTitle: String, sessionTitle: String, sessionDate: Date, rhythmUpSeconds: Int, rhythmDownSeconds: Int, equipment: [String], results: String?, completedAt: Date? = nil) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        var body = """
        ════════════════════════════════════════════════════
                    SESSION DETAILS REPORT
        ════════════════════════════════════════════════════
        
        """
        
        // Session Information Section
        body += """
        📋 SESSION INFORMATION
        ───────────────────────────────────────────────────
        Course:          \(courseTitle)
        Session Title:   \(sessionTitle)
        Created:         \(dateFormatter.string(from: sessionDate))
        """
        
        if let completedAt = completedAt {
            let duration = completedAt.timeIntervalSince(sessionDate)
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            
            body += """
            Completed:      \(dateFormatter.string(from: completedAt))
            Duration:       \(minutes) minutes \(seconds) seconds
            Status:         ✅ Completed
            """
        } else {
            body += """
            Status:         ⏳ In Progress
            """
        }
        
        body += "\n"
        
        // Rhythm Settings Section
        body += """
        ⏱️  RHYTHM SETTINGS
        ───────────────────────────────────────────────────
        Up Phase:        \(rhythmUpSeconds) seconds
        Down Phase:      \(rhythmDownSeconds) seconds
        Total Cycle:     \(rhythmUpSeconds + rhythmDownSeconds) seconds
        
        """
        
        // Equipment Section
        body += """
        🏋️  EQUIPMENT
        ───────────────────────────────────────────────────
        """
        if equipment.isEmpty {
            body += "No equipment specified for this session.\n"
        } else {
            for (index, item) in equipment.enumerated() {
                body += "\(index + 1). \(item)\n"
            }
        }
        
        body += "\n"
        
        // Results Section
        body += """
        📊 SESSION RESULTS
        ───────────────────────────────────────────────────
        """
        if let results = results, !results.isEmpty {
            body += results
        } else {
            body += "No results recorded for this session."
        }
        
        body += "\n\n"
        
        // Footer
        body += """
        ════════════════════════════════════════════════════
        Generated by Fit Fast
        \(Date().formatted(date: .abbreviated, time: .shortened))
        ════════════════════════════════════════════════════
        """

        return body
    }

    func sendWorkoutSessionDetails(subscriberName: String, machineName: String, date: Date, weight: Double?, enduranceTime: TimeInterval?, targetDuration: TimeInterval?, notes: String?, plusTenCount: Int) {
        guard canSendMail else {
            errorMessage = LocalizedString.string(for: .common, key: "Set up a Mail account in iOS Mail to send email.")
            return
        }

        subject = "Workout Session: \(machineName)"
        body = createWorkoutSessionEmailBody(
            subscriberName: subscriberName,
            machineName: machineName,
            date: date,
            weight: weight,
            enduranceTime: enduranceTime,
            targetDuration: targetDuration,
            notes: notes,
            plusTenCount: plusTenCount
        )

        isShowingComposer = true
    }
    
    func sendAllWorkoutSessions(subscriberName: String, sessions: [SessionFS]) {
        guard canSendMail else {
            errorMessage = LocalizedString.string(for: .common, key: "Set up a Mail account in iOS Mail to send email.")
            return
        }

        subject = "All Workout Sessions: \(subscriberName)"
        body = createAllSessionsEmailBody(subscriberName: subscriberName, sessions: sessions)
        isShowingComposer = true
    }

    private func createWorkoutSessionEmailBody(subscriberName: String, machineName: String, date: Date, weight: Double?, enduranceTime: TimeInterval?, targetDuration: TimeInterval?, notes: String?, plusTenCount: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short

        var body = """
        ════════════════════════════════════════════════════
                  WORKOUT SESSION DETAILS REPORT
        ════════════════════════════════════════════════════
        
        """
        
        // Session Information Section
        body += """
        📋 SESSION INFORMATION
        ───────────────────────────────────────────────────
        Subscriber:       \(subscriberName)
        Machine:          \(machineName)
        Date:             \(dateFormatter.string(from: date))
        
        """
        
        // Performance Data Section
        body += """
        💪 PERFORMANCE DATA
        ───────────────────────────────────────────────────
        """
        
        if let weight = weight {
            body += "Weight:            \(String(format: "%.1f", weight)) kg\n"
        } else {
            body += "Weight:            Not recorded\n"
        }
        
        if let enduranceTime = enduranceTime {
            let minutes = Int(enduranceTime) / 60
            let seconds = Int(enduranceTime) % 60
            body += "Endurance Time:    \(minutes) minutes \(seconds) seconds\n"
        } else {
            body += "Endurance Time:    Not recorded\n"
        }
        
        if let targetDuration = targetDuration {
            let minutes = Int(targetDuration) / 60
            let seconds = Int(targetDuration) % 60
            body += "Target Duration:   \(minutes) minutes \(seconds) seconds\n"
        }
        
        if plusTenCount > 0 {
            body += "Extended (+10s):   \(plusTenCount) time(s)\n"
        }
        
        body += "\n"
        
        // Notes Section
        if let notes = notes, !notes.isEmpty {
            body += """
            📝 NOTES
            ───────────────────────────────────────────────────
            \(notes)
            
            """
        }
        
        // Footer
        body += """
        ════════════════════════════════════════════════════
        Generated by Fit Fast
        \(Date().formatted(date: .abbreviated, time: .shortened))
        ════════════════════════════════════════════════════
        """

        return body
    }
    
    private func createAllSessionsEmailBody(subscriberName: String, sessions: [SessionFS]) -> String {
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateStyle = .full
        fullDateFormatter.timeStyle = .short
        
        let dateHeaderFormatter = DateFormatter()
        dateHeaderFormatter.dateFormat = "MMM d"
        
        
        // Let's use a dynamic list of machines found in sessions, plus some core ones, sorted.
        let sessionMachines = Set(sessions.flatMap { $0.exercises ?? [] }.map { $0.name })
        let coreMachines = ["Chest press", "Lat pull down", "Leg press", "Abdominal", "Back Extension", "Abduction", "Adduction"] 
        // Note: "Addiction" in code likely means "Adduction". "Induction" likely meant "Adduction" or "Abduction". 
        // I will use a combined sorted unique list.
        let allMachines = Array(sessionMachines.union(coreMachines)).sorted()

        // Helper function to pad string to fixed width (left-aligned)
        func padLeft(_ str: String, toWidth width: Int) -> String {
            let strLength = str.count
            if strLength >= width {
                return String(str.prefix(width))
            }
            return str + String(repeating: " ", count: width - strLength)
        }
        
        var body = """
        ════════════════════════════════════════════════════
              ALL WORKOUT SESSIONS SUMMARY REPORT
        ════════════════════════════════════════════════════
        
        """
        
        body += """
        📋 SUBSCRIBER INFORMATION
        ───────────────────────────────────────────────────
        Subscriber:       \(subscriberName)
        Total Sessions:   \(sessions.count)
        Report Date:      \(fullDateFormatter.string(from: Date()))
        
        """
        
        // Group sessions by date
        let groupedSessions = Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        
        let sortedDates = groupedSessions.keys.sorted(by: >)
        
        guard !sortedDates.isEmpty else {
            body += "\nNo sessions recorded.\n"
            body += """
            
            ════════════════════════════════════════════════════
            Generated by Fit Fast
            \(Date().formatted(date: .abbreviated, time: .shortened))
            ════════════════════════════════════════════════════
            """
            return body
        }
        
        // Create table header
        body += "\n"
        body += "┌─────────────────────"
        for _ in sortedDates {
            body += "┬─────────────────────"
        }
        body += "┐\n"
        
        // Header row: Machine | Date1 | Date2 | ...
        body += "│ Machine             "
        for date in sortedDates {
            let dateStr = dateHeaderFormatter.string(from: date)
            body += "│ \(padLeft(dateStr, toWidth: 19))"
        }
        body += "│\n"
        
        // Separator line
        body += "├─────────────────────"
        for _ in sortedDates {
            body += "┼─────────────────────"
        }
        body += "┤\n"
        
        // Data rows: One row per machine
        for machine in allMachines {
            body += "│ \(padLeft(machine, toWidth: 19))"
            
            for date in sortedDates {
                let daySessions = groupedSessions[date] ?? []
                let exercise = daySessions.flatMap { $0.exercises ?? [] }.first { $0.name == machine }
                
                var cellContent = ""
                if let ex = exercise {
                    var parts: [String] = []
                    
                    if let weight = ex.weight {
                        parts.append("\(Int(weight)) kg")
                    } else {
                        parts.append("- kg")
                    }
                    
                    if let target = ex.targetDuration {
                        // Using targetDuration as proxy for enduranceTime if that's what we have
                        let t = Int(target)
                        let minutes = t / 60
                        let seconds = t % 60
                        parts.append(String(format: "%02d:%02d", minutes, seconds))
                    }
                    
                    if let plusTen = ex.plusTenCount, plusTen > 0 {
                        parts.append("+10×\(plusTen)")
                    }
                    
                    if parts.isEmpty {
                        cellContent = "-"
                    } else {
                        cellContent = parts.joined(separator: " ")
                    }
                } else {
                    cellContent = "-"
                }
                
                body += "│ \(padLeft(cellContent, toWidth: 19))"
            }
            body += "│\n"
        }
        
        // Table footer
        body += "└─────────────────────"
        for _ in sortedDates {
            body += "┴─────────────────────"
        }
        body += "┘\n"
        
        // Footer
        body += """
        
        ════════════════════════════════════════════════════
        Generated by Fit Fast
        \(Date().formatted(date: .abbreviated, time: .shortened))
        ════════════════════════════════════════════════════
        """
        
        return body
    }

    func handleMailResult(_ result: MFMailComposeResult, error: Error?) {
        isShowingComposer = false

        switch result {
        case .sent:
            errorMessage = nil // Success, clear any previous error
        case .saved:
            errorMessage = LocalizedString.string(for: .common, key: "Email saved to drafts.")
        case .cancelled:
            errorMessage = nil // User cancelled, no error
        case .failed:
            let baseMessage = LocalizedString.string(for: .common, key: "Failed to send email")
            errorMessage = "\(baseMessage): \(error?.localizedDescription ?? "Unknown error")"
        @unknown default:
            errorMessage = "Unknown email result."
        }
    }
}
