import Foundation
import SwiftData

@Model
final class User_Schedule {
    var user_id: UUID
    var tent_id: UUID
    var weekStartDate: Date
    // Store TimeRange array as Data for SwiftData compatibility
    var availableRangesData: Data?
    var schedule_status: String
    
    // Computed property to work with TimeRange array
    var availableRanges: [TimeRange] {
        get {
            guard let data = availableRangesData,
                  let decoded = try? JSONDecoder().decode([TimeRange].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            availableRangesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(user_id: UUID, tent_id: UUID, weekStartDate: Date, availableRanges: [TimeRange] = [], schedule_status: String = "draft") {
        self.user_id = user_id
        self.tent_id = tent_id
        self.weekStartDate = weekStartDate
        self.availableRangesData = nil
        self.schedule_status = schedule_status
        self.availableRanges = availableRanges
    }
    
    func add_available_range(range: TimeRange) {
        var ranges = availableRanges
        ranges.append(range)
        availableRanges = ranges
    }
    
    func remove_available_range(range: TimeRange) {
        var ranges = availableRanges
        ranges.removeAll(where: { $0 == range })
        availableRanges = ranges
    }
    
    func get_available_ranges() -> [TimeRange] {
        return availableRanges
    }
    
    // Check if user is available at a specific time
    func isAvailable(at time: Date) -> Bool {
        availableRanges.contains { $0.contains(time: time) }
    }
    
    // Get all available ranges for a specific day of the week (0 = Monday, 6 = Sunday)
    func getRangesForDay(_ dayOfWeek: Int) -> [TimeRange] {
        let calendar = Calendar.current
        guard let dayDate = calendar.date(byAdding: .day, value: dayOfWeek, to: weekStartDate) else {
            return []
        }
        
        return availableRanges.filter { range in
            calendar.isDate(range.startTime, inSameDayAs: dayDate)
        }
    }
}