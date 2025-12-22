import Foundation
import SwiftData

//Get all User Schedules for the Tent and merge them into a single schedule 
//Overlapping Schedules should be trimmed and there should be Int (tent_capacity) filled for each time slot 
//Everyone should have a similar amount of total time slots filled 
//The schedule should be saved to the database 
//The schedule should be returned to the user in a readable format 

@Model
final class Tent_Schedule {
    var tent_id: UUID
    var weekStartDate: Date
    // Store TimeRange array as Data for SwiftData compatibility
    var scheduleData: Data?
    
    // Computed property to work with TimeRange array
    var schedule: [TimeRange] {
        get {
            guard let data = scheduleData,
                  let decoded = try? JSONDecoder().decode([TimeRange].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            scheduleData = try? JSONEncoder().encode(newValue)
        }
    }

    init(tent_id: UUID, weekStartDate: Date, schedule: [TimeRange] = []) {
        self.tent_id = tent_id
        self.weekStartDate = weekStartDate
        self.scheduleData = nil
        self.schedule = schedule
    }

    func add_schedule(range: TimeRange) {
        var ranges = schedule
        ranges.append(range)
        schedule = ranges
    }
    
    func remove_schedule(range: TimeRange) {
        var ranges = schedule
        ranges.removeAll(where: { $0 == range })
        schedule = ranges
    }
}