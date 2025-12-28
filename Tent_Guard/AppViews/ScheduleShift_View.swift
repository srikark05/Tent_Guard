//
//  ScheduleShift_View.swift
//  Tent_Guard
//
//  Created on 12/27/25.
//

import SwiftUI
import SwiftData

struct ScheduleShift_View: View {
    let tent: Tent
    @Environment(\.modelContext) private var modelContext
    @State private var selectedWeek: Date = Date().startOfWeek()
    @State private var scheduleSlots: [ScheduleSlot] = []
    @State private var userMap: [UUID: Users] = [:]
    @State private var isLoading = false
    
    // Days of the week
    private let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Generating schedule...")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Week Selector
                        weekSelector
                        
                        // Schedule Timeline for each day
                        ForEach(0..<7, id: \.self) { dayIndex in
                            dayTimelineView(dayIndex: dayIndex)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Shift Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSchedule()
        }
        .onChange(of: selectedWeek) { _, _ in
            loadSchedule()
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
    
    // MARK: - Day Timeline View
    private func dayTimelineView(dayIndex: Int) -> some View {
        let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: selectedWeek) ?? selectedWeek
        let daySlots = getSlotsForDay(dayIndex: dayIndex)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Day Header
            HStack {
                Text(daysOfWeek[dayIndex])
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(dayDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !daySlots.isEmpty {
                    Text("\(daySlots.count) shift\(daySlots.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if daySlots.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No shifts scheduled")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                // Timeline
                timelineView(daySlots: daySlots, dayDate: dayDate)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Timeline View
    private func timelineView(daySlots: [ScheduleSlot], dayDate: Date) -> some View {
        VStack(spacing: 0) {
            // Group slots by hour for better display
            ForEach(0..<24, id: \.self) { hour in
                hourRow(hour: hour, daySlots: daySlots, dayDate: dayDate)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func hourRow(hour: Int, daySlots: [ScheduleSlot], dayDate: Date) -> some View {
        let dayStart = Calendar.current.startOfDay(for: dayDate)
        guard let hourStart = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: dayStart),
              let hourEnd = Calendar.current.date(bySettingHour: hour, minute: 59, second: 59, of: dayStart) else {
            return AnyView(EmptyView())
        }
        
        // Find slots that overlap with this hour
        let hourRange = TimeRange(startTime: hourStart, endTime: hourEnd)
        let overlappingSlots = daySlots.filter { slot in
            slot.timeRange.overlaps(with: hourRange)
        }
        
        return AnyView(
            HStack(alignment: .top, spacing: 12) {
                // Hour label
                Text(hourLabel(hour))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                
                // Slot indicators
                if overlappingSlots.isEmpty {
                    // Empty hour - show gray bar
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 40)
                        .cornerRadius(4)
                        .overlay(
                            Text("No coverage")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        )
                } else {
                    // Show slots for this hour
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(overlappingSlots.enumerated()), id: \.offset) { index, slot in
                            slotIndicator(slot: slot, hourStart: hourStart, hourEnd: hourEnd)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        )
    }
    
    private func slotIndicator(slot: ScheduleSlot, hourStart: Date, hourEnd: Date) -> some View {
        let slotStart = max(slot.timeRange.startTime, hourStart)
        let slotEnd = min(slot.timeRange.endTime, hourEnd)
        
        // Calculate width percentage within the hour
        let hourDuration: TimeInterval = 3600
        let slotDuration = slotEnd.timeIntervalSince(slotStart)
        let widthPercentage = min(1.0, max(0.1, slotDuration / hourDuration))
        
        return VStack(alignment: .leading, spacing: 4) {
            // Time range
            HStack {
                Text(timeString(from: slot.timeRange.startTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
                Text("→")
                    .font(.caption2)
                Text(timeString(from: slot.timeRange.endTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            
            // Assigned users
            if slot.assignedUsers.isEmpty {
                Text("Unassigned")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(slot.assignedUsers.prefix(3), id: \.self) { userID in
                        if let user = userMap[userID] {
                            Text(userDisplayName(user))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                    if slot.assignedUsers.count > 3 {
                        Text("+\(slot.assignedUsers.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Capacity indicator
            HStack {
                Text("\(slot.assignedUsers.count)/\(slot.requiredCount)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                
                if slot.isFilled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                } else if slot.isUnderstaffed {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(slotColor(slot: slot))
        .cornerRadius(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func slotColor(slot: ScheduleSlot) -> Color {
        if slot.isFilled {
            return Color.green
        } else if slot.isUnderstaffed {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
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
    
    private func getSlotsForDay(dayIndex: Int) -> [ScheduleSlot] {
        let calendar = Calendar.current
        let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: selectedWeek) ?? selectedWeek
        let dayStart = calendar.startOfDay(for: dayDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        return scheduleSlots.filter { slot in
            slot.timeRange.startTime >= dayStart && slot.timeRange.startTime < dayEnd
        }
    }
    
    private func userDisplayName(_ user: Users) -> String {
        if let firstName = user.firstName, let lastName = user.lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = user.firstName {
            return firstName
        } else {
            return user.email
        }
    }
    
    private func loadSchedule() {
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
        
        // Load user map for displaying names
        loadUserMap(userIDs: allUserSchedules.map { $0.user_id })
        
        // Generate schedule slots
        let slots = ScheduleGenerator.generateSchedule(
            userSchedules: allUserSchedules,
            tentCapacity: tent.tent_required_count,
            weekStartDate: selectedWeek
        )
        
        scheduleSlots = slots
        isLoading = false
    }
    
    private func loadUserMap(userIDs: [UUID]) {
        let descriptor = FetchDescriptor<Users>(
            predicate: #Predicate<Users> { user in
                userIDs.contains(user.user_id)
            }
        )
        
        if let users = try? modelContext.fetch(descriptor) {
            userMap = Dictionary(uniqueKeysWithValues: users.map { ($0.user_id, $0) })
        }
    }
}

