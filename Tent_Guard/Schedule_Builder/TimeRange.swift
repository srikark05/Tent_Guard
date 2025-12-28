import Foundation

struct TimeRange: Codable, Equatable, Hashable { 

    var startTime: Date
    var endTime: Date 

    init(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
    }

    func duration() -> TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    func overlaps(with other: TimeRange) -> Bool { 
        startTime < other.endTime && endTime > other.startTime
    }
    func contains(time: Date) -> Bool {
        time >= startTime && time <= endTime
    }
}