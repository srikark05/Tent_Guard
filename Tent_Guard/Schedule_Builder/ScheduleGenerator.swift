//
//  ScheduleGenerator.swift
//  Tent_Guard
//
//  Created on 12/21/25.
//

import Foundation
import SwiftData

// Represents a time slot with assigned users
struct ScheduleSlot {
    var timeRange: TimeRange
    var assignedUsers: [UUID]  // User IDs
    var requiredCount: Int
    
    var isFilled: Bool {
        assignedUsers.count >= requiredCount
    }
    
    var isUnderstaffed: Bool {
        assignedUsers.count > 0 && assignedUsers.count < requiredCount
    }
}

class ScheduleGenerator {
    
    /// Generate schedule from user availabilities for a tent
    /// - Parameters:
    ///   - userSchedules: Array of User_Schedule objects
    ///   - tentCapacity: Required number of users at tent at any time
    ///   - weekStartDate: Start date of the week (Monday)
    /// - Returns: Array of ScheduleSlot objects
    static func generateSchedule(
        userSchedules: [User_Schedule],
        tentCapacity: Int,
        weekStartDate: Date
    ) -> [ScheduleSlot] {
        var allTimeRanges: [TimeRange] = []
        
        // Collect all time ranges from all users
        for userSchedule in userSchedules {
            allTimeRanges.append(contentsOf: userSchedule.availableRanges)
        }
        
        // Sort by start time
        allTimeRanges.sort { $0.startTime < $1.startTime }
        
        // Merge overlapping ranges
        var mergedRanges: [TimeRange] = []
        var currentRange: TimeRange?
        
        for range in allTimeRanges {
            if let existing = currentRange {
                if range.overlaps(with: existing) {
                    // Merge overlapping ranges
                    let mergedStart = min(existing.startTime, range.startTime)
                    let mergedEnd = max(existing.endTime, range.endTime)
                    currentRange = TimeRange(startTime: mergedStart, endTime: mergedEnd)
                } else {
                    // Save previous range and start new one
                    mergedRanges.append(existing)
                    currentRange = range
                }
            } else {
                currentRange = range
            }
        }
        
        // Add final range
        if let final = currentRange {
            mergedRanges.append(final)
        }
        
        // Create schedule slots and assign users
        var slots: [ScheduleSlot] = []
        
        for range in mergedRanges {
            var slot = ScheduleSlot(timeRange: range, assignedUsers: [], requiredCount: tentCapacity)
            
            // Find available users for this time range
            var availableUsers: [UUID] = []
            for userSchedule in userSchedules {
                if userSchedule.availableRanges.contains(where: { $0.overlaps(with: range) }) {
                    availableUsers.append(userSchedule.user_id)
                }
            }
            
            // Shuffle for fair distribution
            availableUsers.shuffle()
            
            // Assign users up to required count
            let usersToAssign = min(tentCapacity, availableUsers.count)
            slot.assignedUsers = Array(availableUsers.prefix(usersToAssign))
            
            slots.append(slot)
        }
        
        return slots
    }
    
    /// Detect gaps in schedule coverage
    /// - Parameters:
    ///   - slots: Array of ScheduleSlot objects
    ///   - weekStartDate: Start date of the week
    ///   - tentCapacity: Required number of users
    /// - Returns: Array of GapInfo objects
    static func detectGaps(
        slots: [ScheduleSlot],
        weekStartDate: Date,
        tentCapacity: Int
    ) -> [GapInfo] {
        var gaps: [GapInfo] = []
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStartDate)!
        
        // Get all covered time ranges (only fully filled slots)
        var coveredRanges: [TimeRange] = []
        var understaffedSlots: [ScheduleSlot] = []
        
        for slot in slots {
            if slot.isFilled {
                coveredRanges.append(slot.timeRange)
            } else if slot.isUnderstaffed {
                understaffedSlots.append(slot)
            }
        }
        
        // Add gaps for understaffed slots
        for slot in understaffedSlots {
            let gapDate = calendar.startOfDay(for: slot.timeRange.startTime)
            gaps.append(GapInfo(
                timeRange: slot.timeRange,
                date: gapDate,
                requiredCount: slot.requiredCount,
                currentCount: slot.assignedUsers.count
            ))
        }
        
        // Sort covered ranges by start time
        coveredRanges.sort { $0.startTime < $1.startTime }
        
        // Find gaps between covered ranges
        var currentTime = weekStartDate
        
        for range in coveredRanges {
            if currentTime < range.startTime {
                // Gap before this range
                let gapRange = TimeRange(startTime: currentTime, endTime: range.startTime)
                let gapDate = calendar.startOfDay(for: gapRange.startTime)
                gaps.append(GapInfo(
                    timeRange: gapRange,
                    date: gapDate,
                    requiredCount: tentCapacity,
                    currentCount: 0
                ))
            }
            if range.endTime > currentTime {
                currentTime = range.endTime
            }
        }
        
        // Check for gap at end of week
        if currentTime < weekEnd {
            let gapRange = TimeRange(startTime: currentTime, endTime: weekEnd)
            let gapDate = calendar.startOfDay(for: gapRange.startTime)
            gaps.append(GapInfo(
                timeRange: gapRange,
                date: gapDate,
                requiredCount: tentCapacity,
                currentCount: 0
            ))
        }
        
        return gaps
    }
    
    /// Create Tent_Schedule from slots
    static func createTentSchedule(
        tent_id: UUID,
        weekStartDate: Date,
        slots: [ScheduleSlot]
    ) -> Tent_Schedule {
        let timeRanges = slots.map { $0.timeRange }
        return Tent_Schedule(tent_id: tent_id, weekStartDate: weekStartDate, schedule: timeRanges)
    }
}

