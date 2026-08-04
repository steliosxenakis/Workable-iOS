import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

/// Starts / updates / ends the clock-in Live Activity (Lock Screen + Dynamic Island).
@MainActor
final class ClockInLiveActivityManager {
    static let shared = ClockInLiveActivityManager()

    private init() {}

    func start(clockInDate: Date, breaksEnabled: Bool, isOnBreak: Bool = false, breakStartDate: Date? = nil) {
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

        let attributes = ClockInActivityAttributes(employeeName: "You")
        let state = ClockInActivityAttributes.ContentState(
            clockInDate: clockInDate,
            isOnBreak: isOnBreak,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled
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
        breaksEnabled: Bool
    ) {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        let state = ClockInActivityAttributes.ContentState(
            clockInDate: clockInDate,
            isOnBreak: isOnBreak,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled
        )
        Task {
            let activities = Activity<ClockInActivityAttributes>.activities
            if activities.isEmpty {
                // Session is live in-app but the system activity was lost — recreate.
                start(
                    clockInDate: clockInDate,
                    breaksEnabled: breaksEnabled,
                    isOnBreak: isOnBreak,
                    breakStartDate: breakStartDate
                )
                return
            }
            for activity in activities {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
        #endif
    }

    func end() {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        Task {
            await endAllActivities()
        }
        #endif
    }

    /// If the user is clocked in but no Live Activity is running, start one.
    func ensureRunning(for store: ClockInSessionStore, breaksEnabled: Bool) {
        #if canImport(ActivityKit) && os(iOS)
        guard #available(iOS 16.2, *) else { return }
        guard store.isClockedIn, let clockInDate = store.clockInDate else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if Activity<ClockInActivityAttributes>.activities.isEmpty {
            start(
                clockInDate: clockInDate,
                breaksEnabled: breaksEnabled,
                isOnBreak: store.isOnBreak,
                breakStartDate: store.breakStartDate
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
            store.applyExternalState(
                isClockedIn: true,
                isOnBreak: state.isOnBreak,
                clockInDate: state.clockInDate,
                breakStartDate: state.breakStartDate
            )
            ClockInSessionSync.persist(
                isClockedIn: true,
                isOnBreak: state.isOnBreak,
                clockInDate: state.clockInDate,
                breakStartDate: state.breakStartDate,
                breaksEnabled: breaksEnabled
            )
        } else {
            ensureRunning(for: store, breaksEnabled: breaksEnabled)
        }
        #endif
    }

    #if canImport(ActivityKit) && os(iOS)
    @available(iOS 16.2, *)
    private func endAllActivities() async {
        for activity in Activity<ClockInActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif
}
