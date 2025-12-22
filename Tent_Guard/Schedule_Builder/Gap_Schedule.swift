import Foundation
import SwiftData

struct GapInfo: Codable, Equatable {
    var timeRange: TimeRange
    var date: Date
    var requiredCount: Int
    var currentCount: Int
    
    init(timeRange: TimeRange, date: Date, requiredCount: Int, currentCount: Int) {
        self.timeRange = timeRange
        self.date = date
        self.requiredCount = requiredCount
        self.currentCount = currentCount
    }
    
    var isUncovered: Bool {
        currentCount == 0
    }
    
    var isUnderstaffed: Bool {
        currentCount > 0 && currentCount < requiredCount
    }
    
    var missingCount: Int {
        max(0, requiredCount - currentCount)
    }
}

@Model
final class Gap_Schedule {
    var tent_id: UUID
    var weekStartDate: Date
    // Store GapInfo array as Data for SwiftData compatibility
    var gapsData: Data?
    
    // Computed property to work with GapInfo array
    var gaps: [GapInfo] {
        get {
            guard let data = gapsData,
                  let decoded = try? JSONDecoder().decode([GapInfo].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            gapsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(tent_id: UUID, weekStartDate: Date, gaps: [GapInfo] = []) {
        self.tent_id = tent_id
        self.weekStartDate = weekStartDate
        self.gapsData = nil
        self.gaps = gaps
    }
    
    func addGap(_ gap: GapInfo) {
        var currentGaps = gaps
        currentGaps.append(gap)
        gaps = currentGaps
    }
    
    func removeGap(_ gap: GapInfo) {
        var currentGaps = gaps
        currentGaps.removeAll(where: { $0 == gap })
        gaps = currentGaps
    }
    
    func getUncoveredGaps() -> [GapInfo] {
        gaps.filter { $0.isUncovered }
    }
    
    func getUnderstaffedGaps() -> [GapInfo] {
        gaps.filter { $0.isUnderstaffed }
    }
    
    var totalGaps: Int {
        gaps.count
    }
}