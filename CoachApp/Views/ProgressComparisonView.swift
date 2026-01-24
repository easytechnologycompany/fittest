//
//  ProgressComparisonView.swift
//  CoachApp
//
//  Created by Zaid Aqrawi on 03/12/2025.
//

import SwiftUI
import Charts

struct ProgressComparisonView: View {
    @Environment(\.colorScheme) var colorScheme
    let subscriber: SubscriberFS
    let physicalDetails: [PhysicalDetailFS]
    let workoutLogs: [WorkoutLogFS]
    let goals: [GoalFS]
    
    @State private var selectedDuration: ComparisonDuration = .oneMonth
    @State private var selectedMetric: ProgressMetric = .weight
    
    enum ComparisonDuration: String, CaseIterable {
        case oneWeek = "1 Week"
        case oneMonth = "1 Month"
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case oneYear = "1 Year"
        case allTime = "All Time"
        
        var days: Int? {
            switch self {
            case .oneWeek: return 7
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .allTime: return nil
            }
        }
    }
    
    enum ProgressMetric: String, CaseIterable {
        case weight = "Weight"
        case bodyFat = "Body Fat %"
        case chest = "Chest"
        case waist = "Waist"
        case hips = "Hips"
        case arms = "Arms"
        case legs = "Legs"
        case exerciseWeight = "Exercise Weight"
    }
    
    var filteredPhysicalDetails: [PhysicalDetailFS] {
        guard let days = selectedDuration.days else {
            return physicalDetails
        }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return physicalDetails.filter { $0.dateRecorded >= cutoffDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Duration Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comparison Duration")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(ComparisonDuration.allCases, id: \.self) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Metric Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Metric to Compare")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ProgressMetric.allCases, id: \.self) { metric in
                                Button {
                                    selectedMetric = metric
                                } label: {
                                    Text(metric.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedMetric == metric
                                                ? AppTheme.primaryGradient(for: colorScheme)
                                                : AppTheme.secondaryBackgroundColor(for: colorScheme)
                                        )
                                        .foregroundColor(
                                            selectedMetric == metric
                                                ? AppTheme.gradientCardTextColor(for: colorScheme)
                                                : .primary
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Progress Chart
                if hasDataForMetric {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Progress Over Time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(chartData, id: \.date) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(AppTheme.orange)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(
                                    AppTheme.primaryGradient(for: colorScheme).opacity(0.3)
                                )
                                .interpolationMethod(.catmullRom)
                            }
                            
                            if let goalValue = currentGoalValue {
                                RuleMark(y: .value("Goal", goalValue))
                                    .foregroundStyle(AppTheme.orange.opacity(0.7))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            }
                        }
                        .frame(height: 250)
                        .padding()
                        .background(AppTheme.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(12)
                        .shadow(color: AppTheme.orange.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                
                // Comparison Summary
                if let comparison = calculateComparison() {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comparison Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ComparisonCard(
                                title: "Start Value",
                                value: formatValue(comparison.startValue),
                                unit: selectedMetric.unit
                            )
                            
                            ComparisonCard(
                                title: "Current Value",
                                value: formatValue(comparison.currentValue),
                                unit: selectedMetric.unit
                            )
                            
                            ComparisonCard(
                                title: "Change",
                                value: formatValue(comparison.change),
                                unit: selectedMetric.unit,
                                isChange: true
                            )
                            
                            if let goalValue = currentGoalValue {
                                ComparisonCard(
                                    title: "Goal",
                                    value: formatValue(goalValue),
                                    unit: selectedMetric.unit
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Add physical details or workout logs to see progress comparison.")
                    )
                    .frame(height: 200)
                }
            }
            .padding(.vertical)
        }
        .background(AppTheme.backgroundColor(for: colorScheme))
        .navigationTitle("Progress Comparison")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
    
    var hasDataForMetric: Bool {
        !chartData.isEmpty
    }
    
    var chartData: [(date: Date, value: Double)] {
        switch selectedMetric {
        case .weight:
            return filteredPhysicalDetails.compactMap { detail in
                guard let weight = detail.weight else { return nil }
                return (detail.dateRecorded, weight)
            }
        case .bodyFat:
            return filteredPhysicalDetails.compactMap { detail in
                guard let bodyFat = detail.bodyFatPercentage else { return nil }
                return (detail.dateRecorded, bodyFat)
            }
        case .chest:
            return filteredPhysicalDetails.compactMap { detail in
                guard let chest = detail.chest else { return nil }
                return (detail.dateRecorded, chest)
            }
        case .waist:
            return filteredPhysicalDetails.compactMap { detail in
                guard let waist = detail.waist else { return nil }
                return (detail.dateRecorded, waist)
            }
        case .hips:
            return filteredPhysicalDetails.compactMap { detail in
                guard let hips = detail.hips else { return nil }
                return (detail.dateRecorded, hips)
            }
        case .arms:
            return filteredPhysicalDetails.compactMap { detail in
                guard let leftArm = detail.leftArm,
                      let rightArm = detail.rightArm else { return nil }
                return (detail.dateRecorded, (leftArm + rightArm) / 2)
            }
        case .legs:
            return filteredPhysicalDetails.compactMap { detail in
                guard let leftLeg = detail.leftLeg,
                      let rightLeg = detail.rightLeg else { return nil }
                return (detail.dateRecorded, (leftLeg + rightLeg) / 2)
            }
        case .exerciseWeight:
            return exerciseWeightProgress
        }
    }
    
    var exerciseWeightProgress: [(date: Date, value: Double)] {
        // Get average exercise weight per workout
        var weightByDate: [Date: [Double]] = [:]
        
        for log in workoutLogs {
            guard let exercises = log.exercises else { continue }
            var weights: [Double] = []
            
            for exercise in exercises {
                if let weight = exercise.weight, weight > 0 {
                    weights.append(weight)
                }
            }
            
            if !weights.isEmpty {
                let avgWeight = weights.reduce(0, +) / Double(weights.count)
                weightByDate[log.date, default: []].append(avgWeight)
            }
        }
        
        return weightByDate.compactMap { date, weights in
            guard let days = selectedDuration.days else {
                return (date, weights.reduce(0, +) / Double(weights.count))
            }
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            guard date >= cutoffDate else { return nil }
            return (date, weights.reduce(0, +) / Double(weights.count))
        }.sorted { $0.date < $1.date }
    }
    
    var currentGoalValue: Double? {
        // Find active goal for the selected metric
        let activeGoals = goals.filter { !$0.isCompleted }
        for goal in activeGoals {
            if goalMatchesMetric(goal) {
                return goal.targetValue
            }
        }
        return nil
    }
    
    func goalMatchesMetric(_ goal: GoalFS) -> Bool {
        let goalUnit = goal.unit.lowercased()
        switch selectedMetric {
        case .weight:
            return goalUnit == "kg" || goalUnit == "lbs"
        case .bodyFat:
            return goalUnit == "%" || goalUnit.contains("percent")
        case .chest, .waist, .hips, .arms, .legs:
            return goalUnit == "cm" || goalUnit == "inches"
        case .exerciseWeight:
            return goalUnit == "kg" || goalUnit == "lbs"
        }
    }
    
    func calculateComparison() -> (startValue: Double, currentValue: Double, change: Double)? {
        let data = chartData
        guard data.count >= 2,
              let first = data.first,
              let last = data.last else { return nil }
        
        let startValue = first.value
        let currentValue = last.value
        let change = currentValue - startValue
        
        return (startValue, currentValue, change)
    }
    
    func formatValue(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

extension ProgressComparisonView.ProgressMetric {
    var unit: String {
        switch self {
        case .weight, .exerciseWeight:
            return "kg"
        case .bodyFat:
            return "%"
        case .chest, .waist, .hips, .arms, .legs:
            return "cm"
        }
    }
}

struct ComparisonCard: View {
    let title: String
    let value: String
    let unit: String
    var isChange: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isChange ? changeColor : AppTheme.textColor(for: colorScheme))
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }
            
            if isChange {
                Image(systemName: changeIcon)
                    .font(.caption)
                    .foregroundColor(changeColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .modernCard(isOrange: true)
    }
    
    var changeColor: Color {
        guard let doubleValue = Double(value) else { return AppTheme.orange }
        if doubleValue > 0 {
            return .green
        } else if doubleValue < 0 {
            return .red
        } else {
            return AppTheme.orange
        }
    }
    
    var changeIcon: String {
        guard let doubleValue = Double(value) else { return "minus" }
        if doubleValue > 0 {
            return "arrow.up.right"
        } else if doubleValue < 0 {
            return "arrow.down.right"
        } else {
            return "minus"
        }
    }
}

#Preview {
    ProgressComparisonView(subscriber: SubscriberFS(name: "Test", email: "", phone: "", subscriptionStartDate: Date(), planType: "", paymentStatus: "", injuries: "", restrictions: "", healthConditions: ""), physicalDetails: [], workoutLogs: [], goals: [])
}

