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
    }
}
#endif
