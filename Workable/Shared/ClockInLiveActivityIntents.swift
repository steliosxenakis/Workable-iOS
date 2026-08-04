import Foundation

/// Shared persistence so Live Activity actions and the home card stay in sync.
enum ClockInSessionSync {
    static let defaultsSuiteName = "group.com.workable.ios"
    static let didChangeNotification = Notification.Name("com.workable.ios.clockInSessionDidChange")

    static let isClockedInKey = "clockIn.isClockedIn"
    static let isOnBreakKey = "clockIn.isOnBreak"
    static let clockInDateKey = "clockIn.clockInDate"
    static let breakStartDateKey = "clockIn.breakStartDate"
    static let breaksEnabledKey = "clockIn.breaksEnabled"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: defaultsSuiteName) ?? .standard
    }

    static func persist(
        isClockedIn: Bool,
        isOnBreak: Bool,
        clockInDate: Date?,
        breakStartDate: Date?,
        breaksEnabled: Bool
    ) {
        let defaults = Self.defaults
        defaults.set(isClockedIn, forKey: isClockedInKey)
        defaults.set(isOnBreak, forKey: isOnBreakKey)
        defaults.set(breaksEnabled, forKey: breaksEnabledKey)
        if let clockInDate {
            defaults.set(clockInDate.timeIntervalSince1970, forKey: clockInDateKey)
        } else {
            defaults.removeObject(forKey: clockInDateKey)
        }
        if let breakStartDate {
            defaults.set(breakStartDate.timeIntervalSince1970, forKey: breakStartDateKey)
        } else {
            defaults.removeObject(forKey: breakStartDateKey)
        }
        defaults.synchronize()
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func clear() {
        persist(
            isClockedIn: false,
            isOnBreak: false,
            clockInDate: nil,
            breakStartDate: nil,
            breaksEnabled: false
        )
    }
}

#if canImport(ActivityKit) && canImport(AppIntents)
import ActivityKit
import AppIntents

@available(iOS 17.0, *)
struct ToggleBreakLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle break"
    static var description = IntentDescription("Pause or resume the current time-tracking session.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        for activity in Activity<ClockInActivityAttributes>.activities {
            guard activity.content.state.breaksEnabled else { continue }
            var state = activity.content.state
            if state.isOnBreak {
                state.isOnBreak = false
                state.breakStartDate = nil
            } else {
                state.isOnBreak = true
                state.breakStartDate = Date()
            }
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
            ClockInSessionSync.persist(
                isClockedIn: true,
                isOnBreak: state.isOnBreak,
                clockInDate: state.clockInDate,
                breakStartDate: state.breakStartDate,
                breaksEnabled: state.breaksEnabled
            )
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct ClockOutLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Clock out…"
    static var description = IntentDescription(
        "Opens Workable so you can confirm clock-out in the app."
    )
    /// Opens the app instead of ending the session here — hold-to-clock-out stays in-app for error prevention.
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Intentionally does not clock out. The Live Activity button only deep-opens Workable.
        return .result()
    }
}
#endif
