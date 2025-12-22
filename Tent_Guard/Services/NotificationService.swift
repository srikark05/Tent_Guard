//
//  NotificationService.swift
//  Tent_Guard
//
//  Created on 12/21/25.
//

import Foundation
import UserNotifications
import SwiftData

class NotificationService {
    
    static let shared = NotificationService()
    
    private init() {}
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    /// Notify all users in tent about schedule gaps
    func notifyAboutGaps(gapSchedule: Gap_Schedule, tent: Tent) {
        let gapCount = gapSchedule.totalGaps
        let uncoveredCount = gapSchedule.getUncoveredGaps().count
        let understaffedCount = gapSchedule.getUnderstaffedGaps().count
        
        let content = UNMutableNotificationContent()
        content.title = "Schedule Gaps Detected"
        
        if uncoveredCount > 0 && understaffedCount > 0 {
            content.body = "Your tent schedule has \(gapCount) gap\(gapCount == 1 ? "" : "s"): \(uncoveredCount) uncovered and \(understaffedCount) understaffed. Please update your availability."
        } else if uncoveredCount > 0 {
            content.body = "Your tent schedule has \(uncoveredCount) uncovered time slot\(uncoveredCount == 1 ? "" : "s"). Please update your availability."
        } else {
            content.body = "Your tent schedule has \(understaffedCount) understaffed time slot\(understaffedCount == 1 ? "" : "s"). Please update your availability."
        }
        
        content.sound = .default
        content.badge = NSNumber(value: gapCount)
        
        let request = UNNotificationRequest(
            identifier: "schedule-gaps-\(tent.id.uuidString)-\(gapSchedule.weekStartDate.timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    /// Notify specific user about a gap they could fill
    func notifyUserAboutGap(gap: GapInfo, user: Users, tent: Tent) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let gapStart = formatter.string(from: gap.timeRange.startTime)
        let gapEnd = formatter.string(from: gap.timeRange.endTime)
        
        let content = UNMutableNotificationContent()
        content.title = "Fill Schedule Gap"
        
        if gap.isUncovered {
            content.body = "There's an uncovered gap from \(gapStart) to \(gapEnd). Can you help fill it? (\(gap.requiredCount) people needed)"
        } else {
            content.body = "There's an understaffed gap from \(gapStart) to \(gapEnd). \(gap.missingCount) more person\(gap.missingCount == 1 ? "" : "s") needed."
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "fill-gap-\(user.user_id.uuidString)-\(gap.timeRange.startTime.timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling gap notification: \(error)")
            }
        }
    }
    
    /// Notify all users in tent about gaps
    func notifyAllUsersAboutGaps(
        gapSchedule: Gap_Schedule,
        tent: Tent,
        modelContext: ModelContext
    ) {
        // Notify about overall gaps
        notifyAboutGaps(gapSchedule: gapSchedule, tent: tent)
        
        // Notify individual users about specific gaps they could fill
        let gaps = gapSchedule.gaps
        guard !gaps.isEmpty else { return }
        
        // Fetch all users in the tent
        let userDescriptor = FetchDescriptor<Users>()
        guard let allUsers = try? modelContext.fetch(userDescriptor) else { return }
        
        let tentUsers = allUsers.filter { user in
            tent.tent_users.contains(where: { $0.user_id == user.user_id })
        }
        
        // Notify each user about gaps
        for user in tentUsers {
            // Pick a random gap to suggest (or could be smarter about matching availability)
            if let gap = gaps.randomElement() {
                notifyUserAboutGap(gap: gap, user: user, tent: tent)
            }
        }
    }
}

