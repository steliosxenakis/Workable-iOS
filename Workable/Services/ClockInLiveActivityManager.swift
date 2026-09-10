import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

/// Starts / updates / ends the clock-in Live Activity (Lock Screen + Dynamic Island).
@MainActor
final class ClockInLiveActivityManager {
    static let shared = ClockInLiveActivityManager()

    /// Pushes a ContentState update when a planned break crosses its limit so
    /// warning colors refresh (Live Activities do not re-evaluate `Date()` on their own).
    private var breakLimitTask: Task<Void, Never>?

    private init() {}

    func start(
        clockInDate: Date,
        breaksEnabled: Bool,
        isOnBreak: Bool = false,
        breakStartDate: Date? = nil,
        breakEmoji: String? = nil,
        plannedBreakMinutes: Int? = nil
    ) {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else {
            print("Clock-in Live Activity: requires iOS 16.2+")
            return
        }

        let auth = ActivityAuthorizationInfo()
        guard auth.areActivitiesEnabled else {
            print("Clock-in Live Activity: disabled in system Settings (or for this app)")
            return
        }

        // Lock Screen Live Activity is on-break only (Figma 15862:459001).
        guard isOnBreak else { return }

        let attributes = ClockInActivityAttributes(employeeName: "You")
        let state = contentState(
            clockInDate: clockInDate,
            isOnBreak: isOnBreak,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled,
            breakEmoji: breakEmoji,
            plannedBreakMinutes: plannedBreakMinutes
        )

        // End any existing activities *before* requesting a new one (must await —
        // a fire-and-forget end can dismiss the activity we just created).
        Task {
            await endAllActivities()
            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                print("Clock-in Live Activity: started")
                scheduleBreakLimitUpdate(
                    clockInDate: clockInDate,
                    isOnBreak: isOnBreak,
                    breakStartDate: breakStartDate,
                    breaksEnabled: breaksEnabled,
                    breakEmoji: breakEmoji,
                    plannedBreakMinutes: plannedBreakMinutes
                )
            } catch {
                print("Clock-in Live Activity failed to start: \(error.localizedDescription)")
            }
        }
        #else
        print("Clock-in Live Activity: unavailable on this platform (use an iPhone simulator or device)")
        #endif
    }

    func update(
        clockInDate: Date,
        isOnBreak: Bool,
        breakStartDate: Date?,
        breaksEnabled: Bool,
        breakEmoji: String? = nil,
        plannedBreakMinutes: Int? = nil
    ) {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        guard isOnBreak else {
            end()
            return
        }
        let state = contentState(
            clockInDate: clockInDate,
            isOnBreak: isOnBreak,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled,
            breakEmoji: breakEmoji,
            plannedBreakMinutes: plannedBreakMinutes
        )
        Task {
            let activities = Activity<ClockInActivityAttributes>.activities
            if activities.isEmpty {
                // Session is live in-app but the system activity was lost — recreate.
                start(
                    clockInDate: clockInDate,
                    breaksEnabled: breaksEnabled,
                    isOnBreak: isOnBreak,
                    breakStartDate: breakStartDate,
                    breakEmoji: breakEmoji,
                    plannedBreakMinutes: plannedBreakMinutes
                )
                return
            }
            for activity in activities {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
            scheduleBreakLimitUpdate(
                clockInDate: clockInDate,
                isOnBreak: isOnBreak,
                breakStartDate: breakStartDate,
                breaksEnabled: breaksEnabled,
                breakEmoji: breakEmoji,
                plannedBreakMinutes: plannedBreakMinutes
            )
        }
        #endif
    }

    func end() {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        breakLimitTask?.cancel()
        breakLimitTask = nil
        Task {
            await endAllActivities(backAtWork: false)
        }
        #endif
    }

    /// Compact “You’re back at work” banner for 3 seconds, then dismiss
    /// (Figma 15862:461663).
    func endAfterReturningToWork() {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        breakLimitTask?.cancel()
        breakLimitTask = nil
        Task {
            await endAllActivities(backAtWork: true)
        }
        #endif
    }

    /// If the user is clocked in but no Live Activity is running, start one.
    func ensureRunning(for store: ClockInSessionStore, breaksEnabled: Bool) {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        guard store.isClockedIn, let clockInDate = store.clockInDate else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if !store.isOnBreak {
            // Working has no Live Activity. Don't cancel a 3s “You’re back at work” dismissal.
            return
        }
        let planned = store.isOnBreak ? store.plannedBreakMinutes : nil
        let emoji = store.isOnBreak ? store.breakEmoji : nil
        if Activity<ClockInActivityAttributes>.activities.isEmpty {
            start(
                clockInDate: clockInDate,
                breaksEnabled: breaksEnabled,
                isOnBreak: store.isOnBreak,
                breakStartDate: store.breakStartDate,
                breakEmoji: emoji,
                plannedBreakMinutes: planned
            )
        } else {
            // Refresh over-limit warning if the scheduled flip was lost (app killed).
            update(
                clockInDate: clockInDate,
                isOnBreak: store.isOnBreak,
                breakStartDate: store.breakStartDate,
                breaksEnabled: breaksEnabled,
                breakEmoji: emoji,
                plannedBreakMinutes: planned
            )
        }
        #endif
    }

    /// Apply Live Activity → store only when an activity exists.
    /// Clock-out from the activity clears the App Group; do **not** treat a
    /// missing activity as clock-out (request can fail or race).
    func syncStore(fromActivitiesInto store: ClockInSessionStore, breaksEnabled: Bool) {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        if let activity = Activity<ClockInActivityAttributes>.activities.first {
            let state = activity.content.state
            let fallbackPlanned = store.plannedBreakMinutes
            let planned = state.isOnBreak ? (state.plannedBreakMinutes ?? fallbackPlanned) : nil
            store.applyExternalState(
                isClockedIn: true,
                isOnBreak: state.isOnBreak,
                clockInDate: state.clockInDate,
                breakStartDate: state.breakStartDate,
                breakEmoji: state.isOnBreak ? state.breakEmoji : nil,
                plannedBreakMinutes: planned
            )
            ClockInSessionSync.persist(
                isClockedIn: true,
                isOnBreak: state.isOnBreak,
                clockInDate: state.clockInDate,
                breakStartDate: state.breakStartDate,
                breaksEnabled: breaksEnabled,
                plannedBreakMinutes: planned
            )
            ClockInSessionSync.setBreakEmoji(state.isOnBreak ? state.breakEmoji : nil)
        } else if store.isOnBreak {
            ensureRunning(for: store, breaksEnabled: breaksEnabled)
        }
        #endif
    }

    #if canImport(ActivityKit) && os(iOS)
    @available(iOS 16.2, *)
    private func contentState(
        clockInDate: Date,
        isOnBreak: Bool,
        breakStartDate: Date?,
        breaksEnabled: Bool,
        breakEmoji: String?,
        plannedBreakMinutes: Int?
    ) -> ClockInActivityAttributes.ContentState {
        let planned = isOnBreak ? plannedBreakMinutes : nil
        let isOverLimit: Bool = {
            guard isOnBreak,
                  let planned, planned > 0,
                  let breakStartDate else { return false }
            return Date() > breakStartDate.addingTimeInterval(TimeInterval(planned * 60))
        }()
        return ClockInActivityAttributes.ContentState(
            clockInDate: clockInDate,
            isOnBreak: isOnBreak,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled,
            breakEmoji: isOnBreak ? breakEmoji : nil,
            plannedBreakMinutes: planned,
            isBreakOverLimit: isOverLimit
        )
    }

    @available(iOS 16.2, *)
    private func scheduleBreakLimitUpdate(
        clockInDate: Date,
        isOnBreak: Bool,
        breakStartDate: Date?,
        breaksEnabled: Bool,
        breakEmoji: String?,
        plannedBreakMinutes: Int?
    ) {
        breakLimitTask?.cancel()
        breakLimitTask = nil
        guard isOnBreak,
              let breakStartDate,
              let plannedBreakMinutes, plannedBreakMinutes > 0 else { return }
        let delay = breakStartDate
            .addingTimeInterval(TimeInterval(plannedBreakMinutes * 60))
            .timeIntervalSinceNow
        // Already past the limit — `contentState` has `isBreakOverLimit` for this push.
        guard delay > 0.05 else { return }
        breakLimitTask = Task { @MainActor in
            let nanoseconds = UInt64(delay * 1_000_000_000)
            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            update(
                clockInDate: clockInDate,
                isOnBreak: true,
                breakStartDate: breakStartDate,
                breaksEnabled: breaksEnabled,
                breakEmoji: breakEmoji,
                plannedBreakMinutes: plannedBreakMinutes
            )
        }
    }

    @available(iOS 16.2, *)
    private func endAllActivities(backAtWork: Bool = false) async {
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
}
