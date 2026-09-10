import Foundation
import WidgetKit

/// Shared persistence so Live Activity actions and the home card stay in sync.
enum ClockInSessionSync {
    static let defaultsSuiteName = "group.com.workable.ios"
    static let didChangeNotification = Notification.Name("com.workable.ios.clockInSessionDidChange")

    static let isClockedInKey = "clockIn.isClockedIn"
    static let isOnBreakKey = "clockIn.isOnBreak"
    static let clockInDateKey = "clockIn.clockInDate"
    static let breakStartDateKey = "clockIn.breakStartDate"
    static let breaksEnabledKey = "clockIn.breaksEnabled"
    /// V15 on-break emoji (e.g. "☕") — shown on the Today widget while on break.
    static let breakEmojiKey = "clockIn.breakEmoji"
    static let plannedBreakMinutesKey = "clockIn.plannedBreakMinutes"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: defaultsSuiteName) ?? .standard
    }

    static func persist(
        isClockedIn: Bool,
        isOnBreak: Bool,
        clockInDate: Date?,
        breakStartDate: Date?,
        breaksEnabled: Bool,
        plannedBreakMinutes: Int? = nil
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
        if isOnBreak, let plannedBreakMinutes, plannedBreakMinutes > 0 {
            defaults.set(plannedBreakMinutes, forKey: plannedBreakMinutesKey)
        } else {
            defaults.removeObject(forKey: plannedBreakMinutesKey)
        }
        defaults.synchronize()
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
        // Clock status is the widget's headline content — refresh it whenever
        // this changes, from either the app or a Live Activity intent.
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGlanceStore.widgetKind)
    }

    static func clear() {
        persist(
            isClockedIn: false,
            isOnBreak: false,
            clockInDate: nil,
            breakStartDate: nil,
            breaksEnabled: false
        )
        setBreakEmoji(nil)
    }

    /// Updates the shared on-break emoji independently of the rest of the
    /// session state (mirrors `ClockInSessionStore.updateBreakEmoji`).
    static func setBreakEmoji(_ emoji: String?) {
        let defaults = Self.defaults
        if let emoji, !emoji.isEmpty {
            defaults.set(emoji, forKey: breakEmojiKey)
        } else {
            defaults.removeObject(forKey: breakEmojiKey)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGlanceStore.widgetKind)
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
        guard let activity = Activity<ClockInActivityAttributes>.activities.first,
              activity.content.state.breaksEnabled else { return .result() }
        var state = activity.content.state
        if state.isOnBreak {
            ClockInSessionSync.setBreakEmoji(nil)
            ClockInSessionSync.persist(
                isClockedIn: true,
                isOnBreak: false,
                clockInDate: state.clockInDate,
                breakStartDate: nil,
                breaksEnabled: state.breaksEnabled
            )
            await dismissClockInLiveActivity(backAtWork: true)
        } else {
            state.isOnBreak = true
            state.breakStartDate = Date()
            state.breakEmoji = "☕"
            state.plannedBreakMinutes = nil
            state.isBreakOverLimit = false
            ClockInSessionSync.setBreakEmoji("☕")
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
            ClockInSessionSync.persist(
                isClockedIn: true,
                isOnBreak: true,
                clockInDate: state.clockInDate,
                breakStartDate: state.breakStartDate,
                breaksEnabled: state.breaksEnabled,
                plannedBreakMinutes: state.plannedBreakMinutes
            )
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct ClockOutLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Clock out"
    static var description = IntentDescription("End the current time-tracking session.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await clockOutFromWidgetOrLiveActivity()
        return .result()
    }
}

/// Home-screen widget play button — clocks in without opening the app.
@available(iOS 17.0, *)
struct ClockInWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Clock in"
    static var description = IntentDescription("Start a time-tracking session from the widget.")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        let defaults = ClockInSessionSync.defaults
        let breaksEnabled = defaults.bool(forKey: ClockInSessionSync.breaksEnabledKey)
        let now = Date()
        ClockInSessionSync.persist(
            isClockedIn: true,
            isOnBreak: false,
            clockInDate: now,
            breakStartDate: nil,
            breaksEnabled: breaksEnabled
        )
        ClockInSessionSync.setBreakEmoji(nil)
        return .result()
    }
}

/// Home-screen widget stop button — clocks out without opening the app.
@available(iOS 17.0, *)
struct ClockOutWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Clock out"
    static var description = IntentDescription("End the current time-tracking session from the widget.")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        await clockOutFromWidgetOrLiveActivity()
        return .result()
    }
}

@available(iOS 16.2, *)
private func clockOutFromWidgetOrLiveActivity() async {
    ClockInSessionSync.clear()
    await dismissClockInLiveActivity(backAtWork: false)
}

@available(iOS 16.2, *)
private func dismissClockInLiveActivity(backAtWork: Bool) async {
    let dismissalDate = Date().addingTimeInterval(3)
    for activity in Activity<ClockInActivityAttributes>.activities {
        if backAtWork {
            var state = activity.content.state
            state.isOnBreak = false
            state.breakStartDate = nil
            state.breakEmoji = nil
            state.plannedBreakMinutes = nil
            state.isBreakOverLimit = false
            state.isBackAtWork = true
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .after(dismissalDate)
            )
        } else {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

#endif
