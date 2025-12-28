//
//  ScheduleBuilder_View.swift
//  Tent_Guard
//
//  Created on 12/27/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ScheduleBuilder_View: View {
    let tent: Tent
    @Environment(\.modelContext) private var modelContext
    @State private var selectedWeek: Date = Date().startOfWeek()
    @State private var userSchedule: User_Schedule?
    @State private var gapSchedule: Gap_Schedule?
    @State private var showingTimePicker = false
    @State private var selectedDay: Int = 0
    @State private var selectedStartTime: Date = Date()
    @State private var selectedEndTime: Date = Date().addingTimeInterval(3600)
    @State private var isLoading = false
    
    // Days of the week
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Week Selector
                    weekSelector
                    
                    // Schedule Input Section
                    scheduleInputSection
                    
                    // Gap Detection Section
                    gapDetectionSection
                }
                .padding()
            }
        }
        .navigationTitle("Schedule Builder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserSchedule()
            generateGaps()
        }
        .onChange(of: selectedWeek) { _, _ in
            loadUserSchedule()
            generateGaps()
        }
        .sheet(isPresented: $showingTimePicker) {
            timePickerSheet
        }
    }
    
    // MARK: - Week Selector
    private var weekSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation {
                        selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeek) ?? selectedWeek
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeek) ?? selectedWeek
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Schedule Input Section
    private var scheduleInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Availability")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(0..<7, id: \.self) { dayIndex in
                dayScheduleCard(dayIndex: dayIndex)
            }
        }
    }
    
    private func dayScheduleCard(dayIndex: Int) -> some View {
        let dayRanges = userSchedule?.getRangesForDay(dayIndex) ?? []
        let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: selectedWeek) ?? selectedWeek
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(daysOfWeek[dayIndex])
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(width: 50)
                
                Text(dayDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    selectedDay = dayIndex
                    // Set default times for the selected day
                    let calendar = Calendar.current
                    let dayStart = calendar.startOfDay(for: dayDate)
                    selectedStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayStart) ?? dayStart
                    selectedEndTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dayStart) ?? dayStart
                    showingTimePicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            if dayRanges.isEmpty {
                Text("No availability set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(dayRanges.enumerated()), id: \.offset) { index, range in
                    HStack {
                        Text(timeString(from: range.startTime))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("→")
                            .foregroundColor(.secondary)
                        
                        Text(timeString(from: range.endTime))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: {
                            removeTimeRange(range)
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Gap Detection Section
    private var gapDetectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Schedule Gaps")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let gapSchedule = gapSchedule {
                    Text("\(gapSchedule.totalGaps) gaps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let gapSchedule = gapSchedule, !gapSchedule.gaps.isEmpty {
                let uncoveredGaps = gapSchedule.getUncoveredGaps()
                let understaffedGaps = gapSchedule.getUnderstaffedGaps()
                
                if !uncoveredGaps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Uncovered Gaps")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        ForEach(Array(uncoveredGaps.enumerated()), id: \.offset) { index, gap in
                            gapCard(gap: gap, isUncovered: true)
                        }
                    }
                }
                
                if !understaffedGaps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Understaffed Gaps")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ForEach(Array(understaffedGaps.enumerated()), id: \.offset) { index, gap in
                            gapCard(gap: gap, isUncovered: false)
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("No gaps in schedule!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            }
        }
    }
    
    private func gapCard(gap: GapInfo, isUncovered: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gap.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text(timeString(from: gap.timeRange.startTime))
                    Text("→")
                        .foregroundColor(.secondary)
                    Text(timeString(from: gap.timeRange.endTime))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if isUncovered {
                    Text("Uncovered")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(6)
                } else {
                    Text("\(gap.missingCount) needed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(6)
                }
                
                Text("\(gap.currentCount)/\(gap.requiredCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isUncovered ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Time Picker Sheet
    private var timePickerSheet: some View {
        NavigationStack {
            Form {
                Section("Start Time") {
                    DatePicker("Start", selection: $selectedStartTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("End Time") {
                    DatePicker("End", selection: $selectedEndTime, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Add Availability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingTimePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTimeRange()
                        showingTimePicker = false
                    }
                    .disabled(selectedEndTime <= selectedStartTime)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private var weekRangeString: String {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: selectedWeek) ?? selectedWeek
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: selectedWeek)) - \(formatter.string(from: weekEnd))"
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadUserSchedule() {
        guard let currentUser = getCurrentUser() else { return }
        
        let userID = currentUser.user_id
        let tentID = tent.id
        
        let descriptor = FetchDescriptor<User_Schedule>(
            predicate: #Predicate<User_Schedule> { schedule in
                schedule.user_id == userID &&
                schedule.tent_id == tentID &&
                schedule.weekStartDate == selectedWeek
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            userSchedule = existing
        } else {
            // Create new schedule
            let newSchedule = User_Schedule(
                user_id: currentUser.user_id,
                tent_id: tent.id,
                weekStartDate: selectedWeek,
                availableRanges: [],
                schedule_status: "draft"
            )
            modelContext.insert(newSchedule)
            userSchedule = newSchedule
            try? modelContext.save()
        }
    }
    
    private func getCurrentUser() -> Users? {
        guard let firebaseUser = AuthenticationManager.shared.currentUser else { return nil }
        let uid = firebaseUser.uid
        
        let descriptor = FetchDescriptor<Users>(
            predicate: #Predicate<Users> { $0.firebaseUID == uid }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    private func addTimeRange() {
        guard let schedule = userSchedule else { return }
        
        // Ensure times are on the correct day
        let calendar = Calendar.current
        let dayDate = calendar.date(byAdding: .day, value: selectedDay, to: selectedWeek) ?? selectedWeek
        let dayStart = calendar.startOfDay(for: dayDate)
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: selectedStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: selectedEndTime)
        
        guard let startTime = calendar.date(bySettingHour: startComponents.hour ?? 9, minute: startComponents.minute ?? 0, second: 0, of: dayStart),
              let endTime = calendar.date(bySettingHour: endComponents.hour ?? 17, minute: endComponents.minute ?? 0, second: 0, of: dayStart) else {
            return
        }
        
        let timeRange = TimeRange(startTime: startTime, endTime: endTime)
        schedule.add_available_range(range: timeRange)
        
        try? modelContext.save()
        loadUserSchedule()
        generateGaps()
    }
    
    private func removeTimeRange(_ range: TimeRange) {
        guard let schedule = userSchedule else { return }
        schedule.remove_available_range(range: range)
        try? modelContext.save()
        loadUserSchedule()
        generateGaps()
    }
    
    private func generateGaps() {
        guard getCurrentUser() != nil else { return }
        
        isLoading = true
        
        // Get all user schedules for this tent and week
        let tentID = tent.id
        
        let descriptor = FetchDescriptor<User_Schedule>(
            predicate: #Predicate<User_Schedule> { schedule in
                schedule.tent_id == tentID &&
                schedule.weekStartDate == selectedWeek
            }
        )
        
        guard let allUserSchedules = try? modelContext.fetch(descriptor) else {
            isLoading = false
            return
        }
        
        // Generate schedule slots
        let slots = ScheduleGenerator.generateSchedule(
            userSchedules: allUserSchedules,
            tentCapacity: tent.tent_required_count,
            weekStartDate: selectedWeek
        )
        
        // Detect gaps
        let gaps = ScheduleGenerator.detectGaps(
            slots: slots,
            weekStartDate: selectedWeek,
            tentCapacity: tent.tent_required_count
        )
        
        // Save or update gap schedule
        let gapDescriptor = FetchDescriptor<Gap_Schedule>(
            predicate: #Predicate<Gap_Schedule> { gap in
                gap.tent_id == tentID &&
                gap.weekStartDate == selectedWeek
            }
        )
        
        if let existing = try? modelContext.fetch(gapDescriptor).first {
            existing.gaps = gaps
        } else {
            let newGapSchedule = Gap_Schedule(tent_id: tentID, weekStartDate: selectedWeek, gaps: gaps)
            modelContext.insert(newGapSchedule)
        }
        
        try? modelContext.save()
        
        // Reload gap schedule
        if let updated = try? modelContext.fetch(gapDescriptor).first {
            gapSchedule = updated
        }
        
        isLoading = false
    }
}

// MARK: - Date Extension
extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}

