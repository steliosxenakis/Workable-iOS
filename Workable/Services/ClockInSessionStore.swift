import Foundation
import Combine
import SwiftUI

/// Shared clock-in session for the home card and Live Activity actions.
@MainActor
final class ClockInSessionStore: ObservableObject {
    static let shared = ClockInSessionStore()

    @Published private(set) var isClockedIn = false
    @Published private(set) var isOnBreak = false
    @Published private(set) var clockInDate: Date?
    @Published private(set) var breakStartDate: Date?
    /// V4/V5 bounded-break label (e.g. "Lunch").
    @Published private(set) var breakLabel: String?
    /// V5 Slack-style break emoji (e.g. "☕").
    @Published private(set) var breakEmoji: String?
    /// V4/V5 planned break length in minutes.
    @Published private(set) var plannedBreakMinutes: Int?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        NotificationCenter.default.publisher(for: ClockInSessionSync.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)

        reloadFromDefaults()
    }

    func clockIn(breaksEnabled: Bool) {
        let now = Date()
        isClockedIn = true
        isOnBreak = false
        clockInDate = now
        breakStartDate = nil
        breakLabel = nil
        breakEmoji = nil
        plannedBreakMinutes = nil
        persist(breaksEnabled: breaksEnabled)
        ClockInLiveActivityManager.shared.start(
            clockInDate: now,
            breaksEnabled: breaksEnabled
        )
    }

    func clockOut() {
        if let clockInDate {
            TodayTimeEntriesStore.shared.addEntry(start: clockInDate, end: Date())
        }
        isClockedIn = false
        isOnBreak = false
        clockInDate = nil
        breakStartDate = nil
        breakLabel = nil
        breakEmoji = nil
        plannedBreakMinutes = nil
        ClockInSessionSync.clear()
        ClockInLiveActivityManager.shared.end()
    }

    func startBreak(
        breaksEnabled: Bool,
        label: String? = nil,
        plannedMinutes: Int? = nil,
        emoji: String? = nil
    ) {
        guard isClockedIn else { return }
        isOnBreak = true
        breakStartDate = Date()
        breakLabel = label
        breakEmoji = emoji
        plannedBreakMinutes = plannedMinutes
        persist(breaksEnabled: breaksEnabled)
        ClockInLiveActivityManager.shared.update(
            clockInDate: clockInDate ?? Date(),
            isOnBreak: true,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled
        )
    }

    func endBreak(breaksEnabled: Bool) {
        guard isClockedIn else { return }
        isOnBreak = false
        breakStartDate = nil
        breakLabel = nil
        breakEmoji = nil
        plannedBreakMinutes = nil
        persist(breaksEnabled: breaksEnabled)
        ClockInLiveActivityManager.shared.update(
            clockInDate: clockInDate ?? Date(),
            isOnBreak: false,
            breakStartDate: nil,
            breaksEnabled: breaksEnabled
        )
    }

    /// Update the on-break emoji without restarting the break timer (V15 label editing).
    func updateBreakEmoji(_ emoji: String, breaksEnabled: Bool) {
        guard isClockedIn, isOnBreak else { return }
        let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        breakEmoji = trimmed
        persist(breaksEnabled: breaksEnabled)
        ClockInLiveActivityManager.shared.update(
            clockInDate: clockInDate ?? Date(),
            isOnBreak: true,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled
        )
    }

    func toggleBreak(breaksEnabled: Bool) {
        if isOnBreak {
            endBreak(breaksEnabled: breaksEnabled)
        } else {
            startBreak(breaksEnabled: breaksEnabled)
        }
    }

    /// Pull latest state from App Group / Live Activities (e.g. after Notification Center actions).
    func syncFromExternalSources(breaksEnabled: Bool) {
        reloadFromDefaults()
        if #available(iOS 16.2, *) {
            ClockInLiveActivityManager.shared.syncStore(fromActivitiesInto: self, breaksEnabled: breaksEnabled)
            // Recreate the Live Activity if the session is active but the system dropped it.
            ClockInLiveActivityManager.shared.ensureRunning(for: self, breaksEnabled: breaksEnabled)
        }
    }

    private func persist(breaksEnabled: Bool) {
        ClockInSessionSync.persist(
            isClockedIn: isClockedIn,
            isOnBreak: isOnBreak,
            clockInDate: clockInDate,
            breakStartDate: breakStartDate,
            breaksEnabled: breaksEnabled
        )
    }

    private func reloadFromDefaults() {
        let defaults = ClockInSessionSync.defaults
        let clockedIn = defaults.bool(forKey: ClockInSessionSync.isClockedInKey)
        isClockedIn = clockedIn
        isOnBreak = defaults.bool(forKey: ClockInSessionSync.isOnBreakKey)
        if clockedIn, defaults.object(forKey: ClockInSessionSync.clockInDateKey) != nil {
            clockInDate = Date(timeIntervalSince1970: defaults.double(forKey: ClockInSessionSync.clockInDateKey))
        } else {
            clockInDate = nil
        }
        if defaults.object(forKey: ClockInSessionSync.breakStartDateKey) != nil {
            breakStartDate = Date(timeIntervalSince1970: defaults.double(forKey: ClockInSessionSync.breakStartDateKey))
        } else {
            breakStartDate = nil
        }
    }

    /// Used by Live Activity manager when applying Activity state into the store.
    func applyExternalState(
        isClockedIn: Bool,
        isOnBreak: Bool,
        clockInDate: Date?,
        breakStartDate: Date?
    ) {
        self.isClockedIn = isClockedIn
        self.isOnBreak = isOnBreak
        self.clockInDate = clockInDate
        self.breakStartDate = breakStartDate
    }
}

// MARK: - Today's completed entries (home card footer — Figma 15616-169058)

/// Prototype store for time entries logged on the current calendar day.
@MainActor
final class TodayTimeEntriesStore: ObservableObject {
    static let shared = TodayTimeEntriesStore()

    struct Entry: Identifiable, Equatable {
        let id: UUID
        var start: Date
        var end: Date

        init(id: UUID = UUID(), start: Date, end: Date) {
            self.id = id
            self.start = start
            self.end = end
        }

        var durationMinutes: Int {
            max(0, Int(end.timeIntervalSince(start) / 60))
        }
    }

    @Published private(set) var entries: [Entry] = []

    private init() {}

    var hasEntries: Bool { !entries.isEmpty }

    var totalMinutes: Int {
        entries.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalDurationText: String {
        Self.formatDuration(minutes: totalMinutes)
    }

    /// Earliest start – latest end across today's entries, e.g. `08:00-16:00`.
    var rangeText: String {
        guard let first = entries.map(\.start).min(),
              let last = entries.map(\.end).max() else { return "" }
        return "\(Self.timeString(first))-\(Self.timeString(last))"
    }

    /// First (earliest) entry’s own range for the home footer — Figma 2816:264111.
    var firstEntryRangeText: String {
        guard let first = entries.first else { return "" }
        return "\(Self.timeString(first.start))-\(Self.timeString(first.end))"
    }

    var summaryLeadingText: String {
        "Today · \(totalDurationText) in total"
    }

    /// Adds an entry when it falls on today (after live clock-out).
    func addEntry(start: Date, end: Date) {
        let calendar = Calendar.current
        guard calendar.isDateInToday(start) || calendar.isDateInToday(end) else { return }
        let clampedEnd = max(end, start)
        entries.append(Entry(start: start, end: clampedEnd))
        entries.sort { $0.start < $1.start }
    }

    private static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0, mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(mins)m"
    }
}
