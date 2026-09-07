import Foundation
import WidgetKit

/// Which Workable modules this (prototype) account has — gates which sections
/// the "Today" home-screen widget is allowed to show. A real build would read
/// this from the account/entitlements API; here it's a Settings toggle so the
/// widget can be exercised in every configuration.
enum WorkablePlan: String, Codable, CaseIterable, Identifiable {
    case atsOnly = "ATS only"
    case hrisOnly = "HRIS only"
    case both = "ATS + HRIS"

    var id: String { rawValue }

    var hasATS: Bool { self != .hrisOnly }
    var hasHRIS: Bool { self != .atsOnly }

    static let appStorageKey = "settings.workablePlan"
    static let defaultPlan: WorkablePlan = .both
}

/// Reads/writes the current plan in the shared app group so the widget
/// extension can gate its sections the same way the app does.
enum WidgetPlanStore {
    private static let key = "widget.plan"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: ClockInSessionSync.defaultsSuiteName) ?? .standard
    }

    static func save(_ plan: WorkablePlan) {
        defaults.set(plan.rawValue, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGlanceStore.widgetKind)
    }

    static func load() -> WorkablePlan {
        guard
            let raw = defaults.string(forKey: key),
            let plan = WorkablePlan(rawValue: raw)
        else {
            return .defaultPlan
        }
        return plan
    }
}

/// Home-screen “Today” widget visual treatments (Time tracking Figma).
enum WidgetGlanceUIVersion: String, CaseIterable, Identifiable {
    /// Forest-green card (Figma 15871:542987 / 542931 / 543037 / 543096).
    case v1 = "V1"
    /// Neutral/800 card with teal + purple glow (Figma 15871:545082 / 545026 / 545132 / 545191 / 545256 / 545319).
    case v2 = "V2"

    var id: String { rawValue }

    static let appStorageKey = "settings.widgetGlanceUIVersion"
    static let defaultVersion: WidgetGlanceUIVersion = .v1

    var caption: String {
        switch self {
        case .v1:
            return "Forest green card — Primary/700 with a warning chip for attendance issues"
        case .v2:
            return "Near-black card — mint and purple glow, same layout as V1"
        }
    }
}

/// Persists the widget UI version in the App Group so the extension can read it.
enum WidgetGlanceUIVersionStore {
    private static let key = WidgetGlanceUIVersion.appStorageKey

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: ClockInSessionSync.defaultsSuiteName) ?? .standard
    }

    static func save(_ version: WidgetGlanceUIVersion) {
        defaults.set(version.rawValue, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGlanceStore.widgetKind)
    }

    static func load() -> WidgetGlanceUIVersion {
        guard
            let raw = defaults.string(forKey: key),
            let version = WidgetGlanceUIVersion(rawValue: raw)
        else {
            return .defaultVersion
        }
        return version
    }
}

/// Data feeding the "Today at a glance" home-screen widget (`TodayGlanceWidget`).
/// Mirrors the sections on the in-app Home dashboard: time tracking, to-dos,
/// meetings (1:1s and/or interview events), attendance, new candidates,
/// on leave, and celebrations. Not wired to a live data layer in this
/// prototype yet (same pattern as `TodayWidgetData.mock`) — `WidgetGlanceStore`
/// persists whatever the app last computed so the widget extension can read it.
struct WidgetGlanceData: Codable, Equatable {
    /// To-dos section (survey/profile prompts) — general, not plan-gated.
    var todosPendingCount: Int
    /// 1:1s on today's calendar — HRIS.
    var oneOnOnesCount: Int
    /// Interview/candidate events on today's calendar — ATS.
    var interviewEventsCount: Int
    /// "Today" card attendance issues (missed clock-ins, exceeded hours, etc.) — HRIS.
    var attendanceIssueCount: Int
    /// "Today" card on-leave count — HRIS.
    var onLeaveCount: Int
    /// "Today" card celebrations (birthdays, anniversaries) — HRIS.
    var celebrationsCount: Int
    /// New candidates — ATS.
    var newCandidatesCount: Int

    /// Prototype placeholder — mirrors the constants already used by
    /// `TodayWidgetData.mock` and `HomeView`'s hardcoded sections.
    static let mock = WidgetGlanceData(
        todosPendingCount: 2,
        oneOnOnesCount: 1,
        interviewEventsCount: 1,
        attendanceIssueCount: 3,
        onLeaveCount: 3,
        celebrationsCount: 3,
        newCandidatesCount: 12
    )
}

/// Reads/writes `WidgetGlanceData` in the shared app group so both the app and
/// the widget extension see the same numbers. Mirrors `ClockInSessionSync`'s
/// approach for the clock-in state.
enum WidgetGlanceStore {
    private static let key = "widget.glanceData"

    /// Matches the `kind:` passed to `StaticConfiguration` in `TodayGlanceWidget`.
    static let widgetKind = "TodayGlanceWidget"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: ClockInSessionSync.defaultsSuiteName) ?? .standard
    }

    /// Call this whenever the app recomputes any of its dashboard sections
    /// (e.g. from `HomeView.onAppear`).
    static func save(_ data: WidgetGlanceData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    /// Falls back to `.mock` the first time the widget runs, before the app
    /// has ever written a snapshot.
    static func load() -> WidgetGlanceData {
        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(WidgetGlanceData.self, from: data)
        else {
            return .mock
        }
        return decoded
    }
}

// MARK: - Content planning (plan-aware section selection)

/// One glanceable metric — rendered as a chip (medium/large) or, when it's the
/// hero, as the widget's headline content.
struct WidgetSectionChip: Identifiable {
    let id: String
    let value: String
    let label: String
    let destination: WidgetDeepLink.Destination
    var systemImage: String = "circle"
    var isWarning: Bool = false

    /// Short labels used on the dark home-screen widget (Figma 15870:541009).
    var widgetLabel: String {
        switch id {
        case "todos": return "To-dos"
        case "meetings": return "Events"
        default: return label
        }
    }
}

/// Headline content for the widget. `.timeTracking` gets the special live-timer
/// treatment; `.metric` is just a bigger version of a chip.
enum WidgetHero {
    case timeTracking
    case metric(WidgetSectionChip)
}

/// Turns raw glance data + the account's plan into an ordered, plan-filtered
/// set of widget content. There is exactly **one** priority order — Time
/// Tracking → To-dos → Meetings → Attendance issues → New candidates → On
/// leave → Celebrations — and every plan is just that order with the
/// ineligible sections removed (relative order of the rest never changes):
///
/// - HRIS only:   Time Tracking → To-dos → Meetings(1:1s) → Attendance → On leave → Celebrations
/// - ATS only:    To-dos → Meetings(Events) → New candidates
/// - ATS + HRIS:  Time Tracking → To-dos → Meetings → Attendance → New candidates → On leave → Celebrations
///
/// The hero is whichever eligible section lands first. Time Tracking is only
/// ever eligible under HRIS and is always first in the master order, so it's
/// the hero any time HRIS is present. Without HRIS, To-dos moves up to fill
/// that slot and becomes the hero instead — nothing is specially promoted.
/// Family size (small/medium/large) only changes how many chips render after
/// the hero; it never reorders or re-selects them.
enum WidgetContentPlanner {
    static func plan(glance: WidgetGlanceData, plan: WorkablePlan) -> (hero: WidgetHero, chips: [WidgetSectionChip]) {
        // The master order, minus Time Tracking (which never appears as a
        // plain chip — see doc comment above).
        let masterOrder: [(eligible: Bool, chip: WidgetSectionChip)] = [
            (
                true,
                WidgetSectionChip(
                    id: "todos",
                    value: "\(glance.todosPendingCount)",
                    label: glance.todosPendingCount == 1 ? "To-do pending" : "To-dos pending",
                    destination: .home,
                    systemImage: "circle"
                )
            ),
            (
                true,
                meetingsChip(glance: glance, plan: plan)
            ),
            (
                plan.hasHRIS,
                WidgetSectionChip(
                    id: "attendance",
                    value: "\(glance.attendanceIssueCount)",
                    label: glance.attendanceIssueCount == 1 ? "Attendance issue" : "Attendance issues",
                    destination: .home,
                    systemImage: "exclamationmark.circle.fill",
                    isWarning: glance.attendanceIssueCount > 0
                )
            ),
            (
                plan.hasATS,
                WidgetSectionChip(
                    id: "candidates",
                    value: "\(glance.newCandidatesCount)",
                    label: glance.newCandidatesCount == 1 ? "New candidate" : "New candidates",
                    destination: .recruiting,
                    systemImage: "person.crop.rectangle.stack"
                )
            ),
            (
                plan.hasHRIS,
                WidgetSectionChip(
                    id: "onleave",
                    value: "\(glance.onLeaveCount)",
                    label: "On leave",
                    destination: .home,
                    systemImage: "beach.umbrella"
                )
            ),
            (
                plan.hasHRIS,
                WidgetSectionChip(
                    id: "celebrations",
                    value: "\(glance.celebrationsCount)",
                    label: "Celebrations",
                    destination: .home,
                    systemImage: "birthday.cake"
                )
            ),
        ]

        var eligible = masterOrder.filter(\.eligible).map(\.chip)

        if plan.hasHRIS {
            return (.timeTracking, eligible)
        }

        // No Time Tracking: the first eligible chip (always To-dos) becomes
        // the hero instead of being special-cased.
        guard let heroChip = eligible.first else {
            return (.timeTracking, [])  // unreachable: To-dos is always eligible
        }
        eligible.removeFirst()
        return (.metric(heroChip), eligible)
    }

    /// One "Meetings" slot covering both 1:1s (HRIS) and interview/candidate
    /// events (ATS). Label and value adapt to what's actually eligible.
    private static func meetingsChip(glance: WidgetGlanceData, plan: WorkablePlan) -> WidgetSectionChip {
        switch (plan.hasHRIS, plan.hasATS) {
        case (true, true):
            let total = glance.oneOnOnesCount + glance.interviewEventsCount
            return WidgetSectionChip(
                id: "meetings",
                value: "\(total)",
                label: total == 1 ? "Meeting today" : "Meetings today",
                destination: .home,
                systemImage: "calendar"
            )
        case (true, false):
            return WidgetSectionChip(
                id: "meetings",
                value: "\(glance.oneOnOnesCount)",
                label: glance.oneOnOnesCount == 1 ? "1:1 today" : "1:1s today",
                destination: .home,
                systemImage: "calendar"
            )
        case (false, true):
            return WidgetSectionChip(
                id: "meetings",
                value: "\(glance.interviewEventsCount)",
                label: glance.interviewEventsCount == 1 ? "Event today" : "Events today",
                destination: .home,
                systemImage: "calendar"
            )
        case (false, false):
            return WidgetSectionChip(
                id: "meetings",
                value: "0",
                label: "Meetings today",
                destination: .home,
                systemImage: "calendar"
            )
        }
    }
}
