# CoachApp (Fit Fast)

## Overview
CoachApp (internally known as "Fit Fast") is a comprehensive digital management platform designed specifically for personal trainers and fitness coaches. Built with modern Apple technologies (SwiftUI, SwiftData, CloudKit), it serves as an all-in-one assistant to streamline the daily operations of a coaching business.

## The Problem It Solves
Personal trainers often face significant administrative friction that detracts from their core value—training clients. CoachApp addresses these specific pain points:

1.  ** fragmented Client Data**: replacing the need for scattered paper logs, spreadsheets, and chat messages by checking all client data (contact info, health metrics, attendance) in one secure place.
2.  **Inefficient Workout Planning**: Solves the complexity of designing and distributing personalized workout plans. It allows coaches to build reusable "Training Courses" and specific "Sessions" with detailed exercise instructions.
3.  **Progress Tracking Blindspots**: determining if a client is actually improving can be difficult with raw numbers. The app provides visual tracking of physical details (weight, measurements) and goal progress, making it easy to demonstrate results.
4.  **Exercise Library Management**: instead of manually describing exercises, the app integrates with an external Exercise Database (RapidAPI) and allows for custom machine definitions, standardizing exercise instruction.
5.  **Multi-Device Synchronization**: Solves the issue of data silos by using CloudKit to sync data seamlessly across a coach's iPhone, iPad, and Mac.

## Key Features

### 👥 Subscriber Management
- **Detailed Profiles**: Store personal info, notes, and physical details.
- **Physical Tracking**: Log and visualize changes in weight, body fat, and measurements over time.
- **Attendance**: Track session attendance and history.

### 🏋️‍♂️ Workout Engineering
- **Training Courses**: Design multi-day/week training programs (e.g., "Beginner Hypertrophy").
- **Session Planning**: Create individual workout sessions with specific exercises, sets, reps, and machines.
- **Smart Timer**: Integrated "Rhythm Timer" for tempo-controlled training.

### 📚 Resource Library
- **Exercise Database**: Access to thousands of exercises via API integration.
- **Machine Database**: Manage gym-specific equipment profiles.

### ☁️ Tech Stack
- **SwiftUI**: Modern, responsive user interface.
- **SwiftData**: Robust local data persistence.
- **CloudKit**: Automatic data synchronization and backup.
- **Firebase**: Backend services for specific features (Auth/Functions where applicable).
