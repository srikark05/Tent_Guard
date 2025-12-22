//
//  ScheduleManager.swift
//  Tent_Guard
//
//  Created on 12/21/25.
//

import Foundation
import SwiftData

class ScheduleManager {
    
    /// Build complete schedule for a tent including gap detection
    /// - Parameters:
    ///   - tent: The tent object
    ///   - weekStartDate: Start date of the week (Monday)
    ///   - modelContext: SwiftData model context
    /// - Returns: Tuple of (Tent_Schedule, Gap_Schedule)
    static func buildSchedule(
        tent: Tent,
        weekStartDate: Date,
        modelContext: ModelContext
    ) -> (tentSchedule: Tent_Schedule, gapSchedule: Gap_Schedule) {
        
        // Fetch all user schedules for this tent and week
        let tentID = tent.id
        let descriptor = FetchDescriptor<User_Schedule>(
            predicate: #Predicate<User_Schedule> { schedule in
                schedule.tent_id == tentID
            }
        )
        
        // Filter by weekStartDate in memory (SwiftData predicate limitation with Date comparison)
        var userSchedules: [User_Schedule] = []
        if let fetched = try? modelContext.fetch(descriptor) {
            let calendar = Calendar.current
            userSchedules = fetched.filter { schedule in
                calendar.isDate(schedule.weekStartDate, inSameDayAs: weekStartDate) ||
                abs(schedule.weekStartDate.timeIntervalSince(weekStartDate)) < 86400 // Within 1 day
            }
        }
        
        // If no schedules found, return empty
        guard !userSchedules.isEmpty else {
            let emptyTentSchedule = Tent_Schedule(tent_id: tent.id, weekStartDate: weekStartDate)
            let emptyGapSchedule = Gap_Schedule(tent_id: tent.id, weekStartDate: weekStartDate)
            return (emptyTentSchedule, emptyGapSchedule)
        }
        
        // Generate schedule slots
        let slots = ScheduleGenerator.generateSchedule(
            userSchedules: userSchedules,
            tentCapacity: tent.tent_capacity,
            weekStartDate: weekStartDate
        )
        
        // Detect gaps
        let gaps = ScheduleGenerator.detectGaps(
            slots: slots,
            weekStartDate: weekStartDate,
            tentCapacity: tent.tent_capacity
        )
        
        // Create Tent_Schedule
        let tentSchedule = ScheduleGenerator.createTentSchedule(
            tent_id: tent.id,
            weekStartDate: weekStartDate,
            slots: slots
        )
        
        // Create Gap_Schedule
        let gapSchedule = Gap_Schedule(tent_id: tent.id, weekStartDate: weekStartDate, gaps: gaps)
        
        // Save to database
        modelContext.insert(tentSchedule)
        modelContext.insert(gapSchedule)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving schedule: \(error)")
        }
        
        return (tentSchedule, gapSchedule)
    }
    
    /// Get user schedules for a tent and week
    static func getUserSchedules(
        tent: Tent,
        weekStartDate: Date,
        modelContext: ModelContext
    ) -> [User_Schedule] {
        let tentID = tent.id
        let descriptor = FetchDescriptor<User_Schedule>(
            predicate: #Predicate<User_Schedule> { schedule in
                schedule.tent_id == tentID
            }
        )
        
        guard let fetched = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        // Filter by weekStartDate in memory
        let calendar = Calendar.current
        return fetched.filter { schedule in
            calendar.isDate(schedule.weekStartDate, inSameDayAs: weekStartDate) ||
            abs(schedule.weekStartDate.timeIntervalSince(weekStartDate)) < 86400
        }
    }
}

