import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Live Activity payload for an active clock-in session (Notification Center / Lock Screen / Dynamic Island).
struct ClockInActivityAttributes: ActivityAttributes {
    /// Fixed for the lifetime of the activity.
    var employeeName: String

    struct ContentState: Codable, Hashable {
        /// Session start — used by `Text(timerInterval:)` for a live elapsed timer.
        var clockInDate: Date
        var isOnBreak: Bool
        var breakStartDate: Date?
        /// When false, Pause/Resume is hidden on the Live Activity.
        var breaksEnabled: Bool
        /// Selected break emoji (e.g. "☕") — shown while on break.
        var breakEmoji: String? = nil
        /// Planned break length. Progress + over-limit warning only apply when set.
        var plannedBreakMinutes: Int? = nil
        /// True once elapsed break time has passed `plannedBreakMinutes`.
        /// Pushed as its own state so ActivityKit re-renders warning colors at the limit.
        var isBreakOverLimit: Bool = false
        /// Compact “You’re back at work” banner shown for ~3s after ending a break
        /// (Figma 15862:461663).
        var isBackAtWork: Bool = false

        init(
            clockInDate: Date,
            isOnBreak: Bool,
            breakStartDate: Date?,
            breaksEnabled: Bool,
            breakEmoji: String? = nil,
            plannedBreakMinutes: Int? = nil,
            isBreakOverLimit: Bool = false,
            isBackAtWork: Bool = false
        ) {
            self.clockInDate = clockInDate
            self.isOnBreak = isOnBreak
            self.breakStartDate = breakStartDate
            self.breaksEnabled = breaksEnabled
            self.breakEmoji = breakEmoji
            self.plannedBreakMinutes = plannedBreakMinutes
            self.isBreakOverLimit = isBreakOverLimit
            self.isBackAtWork = isBackAtWork
        }

        enum CodingKeys: String, CodingKey {
            case clockInDate, isOnBreak, breakStartDate, breaksEnabled
            case breakEmoji, plannedBreakMinutes, isBreakOverLimit, isBackAtWork
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            clockInDate = try container.decode(Date.self, forKey: .clockInDate)
            isOnBreak = try container.decode(Bool.self, forKey: .isOnBreak)
            breakStartDate = try container.decodeIfPresent(Date.self, forKey: .breakStartDate)
            breaksEnabled = try container.decode(Bool.self, forKey: .breaksEnabled)
            breakEmoji = try container.decodeIfPresent(String.self, forKey: .breakEmoji)
            plannedBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .plannedBreakMinutes)
            isBreakOverLimit = try container.decodeIfPresent(Bool.self, forKey: .isBreakOverLimit) ?? false
            isBackAtWork = try container.decodeIfPresent(Bool.self, forKey: .isBackAtWork) ?? false
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(clockInDate, forKey: .clockInDate)
            try container.encode(isOnBreak, forKey: .isOnBreak)
            try container.encodeIfPresent(breakStartDate, forKey: .breakStartDate)
            try container.encode(breaksEnabled, forKey: .breaksEnabled)
            try container.encodeIfPresent(breakEmoji, forKey: .breakEmoji)
            try container.encodeIfPresent(plannedBreakMinutes, forKey: .plannedBreakMinutes)
            try container.encode(isBreakOverLimit, forKey: .isBreakOverLimit)
            try container.encode(isBackAtWork, forKey: .isBackAtWork)
        }

        /// Session elapsed while working; break elapsed while paused.
        var activeTimerStart: Date {
            if isOnBreak, let breakStartDate { return breakStartDate }
            return clockInDate
        }

        var plannedBreakEndDate: Date? {
            guard isOnBreak,
                  let plannedBreakMinutes, plannedBreakMinutes > 0,
                  let breakStartDate else { return nil }
            return breakStartDate.addingTimeInterval(TimeInterval(plannedBreakMinutes * 60))
        }
    }
}
#endif
