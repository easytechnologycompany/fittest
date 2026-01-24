//
//  CoachAppApp.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import SwiftData
import CloudKit
import FirebaseCore

@main
struct CoachAppApp: App {
    // Shared container will be loaded lazily or conditionally
    // For now, we keep it but typically we'd removing it if fully migrating
    // However, for migration logic, we usually need access to it.
    var sharedModelContainer: ModelContainer = {
        // Full SwiftData schema - all models tested and working
        let schema = Schema([
            Subscriber.self,
            PhysicalDetail.self,
            WorkoutLog.self,
            Exercise.self,
            Goal.self,
            GoalProgressEntry.self,
            Attendance.self,
            CoachNote.self,
            TrainingCourse.self,
            CourseDay.self,
            CourseExercise.self,
            Machine.self,
            Session.self,
            SessionExercise.self,
            WorkoutSession.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Initialize predefined machines on first launch
            initializePredefinedMachines(container: container)

            return container
        } catch {
            // Log the error and provide user-friendly guidance
            ErrorHandler.handle(error, context: "CoachAppApp.sharedModelContainer")

            #if DEBUG
            print("⚠️ SwiftData initialization failed.")
            print("💡 Try: Clean build folder (Cmd+Shift+K) or delete app from simulator")
            #endif

            fatalError("Could not create ModelContainer: \(error.localizedDescription)\n\nRecovery: Please delete and reinstall the app, or clean the build folder.")
        }
    }()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // Configure ExerciseDB API key at runtime (RapidAPI)
        // NOTE: If you rotate this key, update it here.
        ExerciseDBService.shared.setAPIKey("759a94c5dbmsh3a1cd523bb76d1ep165376jsnf6bb426c2a13")

        // CloudKit is enabled - data will sync to iCloud
        print("ℹ️ Using SwiftData with CloudKit - data will sync to iCloud")
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        #endif
    }

    /// Initialize predefined machines if they don't exist
    private static func initializePredefinedMachines(container: ModelContainer) {
        let context = ModelContext(container)

        // Check if machines already exist
        let descriptor = FetchDescriptor<Machine>()
        do {
            let existingMachines = try context.fetch(descriptor)
            if !existingMachines.isEmpty {
                // Machines already exist, skip initialization
                return
            }
        } catch {
            // If fetch fails, continue with initialization
        }

        // Create predefined machines
        let predefinedMachines = MachineDatabase.getAllMachines()
        for machineData in predefinedMachines {
            let machine = Machine(
                name: machineData.name,
                iconName: machineData.iconName,
                category: machineData.category,
                machineDescription: machineData.machineDescription,
                isCustom: false
            )
            context.insert(machine)
        }

        do {
            try context.save()
        } catch {
            ErrorHandler.handle(error, context: "CoachAppApp.initializePredefinedMachines")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
