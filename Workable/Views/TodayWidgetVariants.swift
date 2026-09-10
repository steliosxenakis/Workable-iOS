import SwiftUI

// MARK: - Pill Style (self-contained)

enum TodayPillStyle: Equatable {
    case danger, warning, success, neutral

    var pillBackground: Color {
        switch self {
        case .danger:  return AppColors.dangerBackground
        case .warning: return AppColors.warningBackground
        case .success: return AppColors.successBackground
        case .neutral: return AppColors.background
        }
    }

    var badgeBackground: Color {
        switch self {
        case .danger:  return Color(light: "FFD2CF", dark: "5A1A0F")
        case .warning: return Color(light: "FFF0B8", dark: "5C3200")
        case .success: return AppColors.activeBackground
        case .neutral: return AppColors.separator
        }
    }

    var badgeTextColor: Color {
        switch self {
        case .danger:  return AppColors.dangerDefault
        case .warning: return AppColors.warningDefault
        case .success: return AppColors.successDefault
        case .neutral: return AppColors.fontSecondary
        }
    }
}

// MARK: - Shared Data Model

struct TodayEvent: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let subtitle: String
}

struct TodayAnomalyPill: Identifiable {
    var id: String { label }
    let label: String
    let count: Int
    let style: TodayPillStyle
    let filters: Set<AnomalyFilterCategory>
}

struct TodayIssueChip: Identifiable {
    let category: AnomalyFilterCategory
    let count: Int
    let style: TodayPillStyle

    var id: AnomalyFilterCategory { category }
    var filters: Set<AnomalyFilterCategory> { [category] }

    var pillTitle: String {
        "\(count) \(category.issuePillLabel(count: count))"
    }
}

struct TodayCelebration: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let value: String
}

struct TodayWidgetData {
    let events: [TodayEvent]
    let anomalyPills: [TodayAnomalyPill]
    let onLeaveTitle: String
    let onLeaveAvatars: [String]
    let onLeaveOverflow: Int
    let celebrations: [TodayCelebration]

    /// Issue total for the Issues chip — from employee mock data (not tied to visible anomaly pills).
    var issueCount: Int {
        let eligible = TimeAttendanceMockData.employees.filter { !$0.hasScheduleIcon }
        return eligible.filter {
            switch $0.anomalyType {
            case .noClockIn, .noClockInNorOut, .exceededWorkSchedule, .workedLess, .late, .exceededHours, .unplanned:
                return true
            default:
                return false
            }
        }.count
    }

    var onTrackCount: Int {
        let eligible = TimeAttendanceMockData.employees.filter { !$0.hasScheduleIcon }
        return eligible.filter { $0.anomalyType == .onTrack }.count
    }

    /// V1 Today attendance row — one chip per issue type (missed / no attendance / exceeded).
    var issueChips: [TodayIssueChip] {
        let eligible = TimeAttendanceMockData.employees.filter { !$0.hasScheduleIcon }
        return [
            TodayIssueChip(
                category: .noClockInNorOut,
                count: eligible.filter { $0.anomalyType == .noClockInNorOut }.count,
                style: .danger
            ),
            TodayIssueChip(
                category: .noClockIn,
                count: eligible.filter { $0.anomalyType == .noClockIn }.count,
                style: .danger
            ),
            TodayIssueChip(
                category: .exceededWorkSchedule,
                count: eligible.filter { $0.anomalyType == .exceededWorkSchedule }.count,
                style: .danger
            ),
            TodayIssueChip(
                category: .unplanned,
                count: eligible.filter { $0.anomalyType == .unplanned }.count,
                style: .warning
            ),
            TodayIssueChip(
                category: .late,
                count: eligible.filter { $0.anomalyType == .late }.count,
                style: .warning
            ),
            TodayIssueChip(
                category: .exceededHours,
                count: eligible.filter { $0.anomalyType == .exceededHours }.count,
                style: .warning
            ),
            TodayIssueChip(
                category: .workedLess,
                count: eligible.filter { $0.anomalyType == .workedLess }.count,
                style: .danger
            ),
        ]
        .filter { $0.count > 0 }
    }

    static let mock = TodayWidgetData(
        events: [
            TodayEvent(title: "Call with John Doe",             time: "10:30 - 11:00", subtitle: "Software Engineer"),
            TodayEvent(title: "Interview with Elissa McArthur", time: "9:30 - 10:00",  subtitle: "Product Designer"),
        ],
        anomalyPills: {
            let eligible = TimeAttendanceMockData.employees.filter { !$0.hasScheduleIcon }
            return [
                TodayAnomalyPill(label: "Not clocked in",         count: eligible.filter { $0.anomalyType == .noClockInNorOut }.count,      style: .danger,  filters: [.noClockInNorOut]),
                TodayAnomalyPill(label: "Clock-out overdue",      count: eligible.filter { $0.anomalyType == .exceededWorkSchedule }.count, style: .warning, filters: [.exceededWorkSchedule]),
                TodayAnomalyPill(label: "Worked less",              count: eligible.filter { $0.anomalyType == .workedLess }.count,            style: .danger,  filters: [.workedLess]),
                TodayAnomalyPill(label: "On track",                  count: eligible.filter { $0.anomalyType == .onTrack }.count,              style: .success, filters: [.onTrack]),
                TodayAnomalyPill(label: "Expected to work today",    count: eligible.count,                                                    style: .neutral, filters: []),
            ]
        }(),
        onLeaveTitle: "On leave",
        onLeaveAvatars: ["avatar-abdi", "avatar-emma", "avatar-tyler"],
        onLeaveOverflow: 150,
        celebrations: [
            TodayCelebration(icon: "icon-hat",  iconColor: AppColors.betaDefault,  iconBackground: AppColors.betaLightBackground, title: "Work anniversaries", value: "Smith, Johannes +3"),
            TodayCelebration(icon: "icon-gift", iconColor: Color(hex: "E9756D"),   iconBackground: AppColors.dangerBackground,    title: "Birthdays",          value: "Doe, John +2"),
            TodayCelebration(icon: "icon-pyro", iconColor: Color(hex: "37B086"),   iconBackground: AppColors.successBackground,   title: "Holidays",           value: "Christmas day"),
        ]
    )
}

// MARK: - Main attendance UI versions (V1 / V2 / V3 / V4 / V5)

enum AttendanceUIVersion: String, CaseIterable, Identifiable {
    case v1 = "V1"
    case v2 = "V2"
    case v3 = "V3"
    case v4 = "V4"
    case v5 = "V5"
    case v6 = "V6 Exec"
    case v7 = "V7"
    case v8 = "V8"

    var id: String { rawValue }

    static let appStorageKey = "settings.attendanceUIVersion"
    static let defaultVersion: AttendanceUIVersion = .v8

    static func resolved(from rawValue: String) -> AttendanceUIVersion {
        AttendanceUIVersion(rawValue: rawValue) ?? .v1
    }

    /// V2/V3/V4/V5/V6/V7/V8 — Attendance tab order, search, filters, notify bell, issues chip, etc.
    var usesModernAttendanceChrome: Bool {
        self == .v2 || self == .v3 || self == .v4 || self == .v5 || self == .v6 || self == .v7 || self == .v8
    }

    /// V3 — progress bars on employee rows instead of status pills.
    var usesProgressBarEmployeeStatus: Bool {
        self == .v3
    }

    /// V4/V5/V6/V7/V8 — Figma 15509 employee cards (per-anomaly layouts; fork from V2 list chrome).
    var usesV4EmployeeCardStatus: Bool {
        self == .v4 || self == .v5 || self == .v6 || self == .v7 || self == .v8
    }

    /// V5 — simplified issue banners (no icons, no "0h", warning color support).
    var usesV5IssueBannerStyle: Bool {
        self == .v5
    }

    /// V6/V7/V8 — left-aligned label + right-aligned schedule time, per-type backgrounds.
    var usesV6IssueBannerStyle: Bool {
        self == .v6 || self == .v7 || self == .v8
    }

    /// V7/V8 — single issue as right-aligned pill; multiple issues in banner below.
    var usesV7InlinePillStyle: Bool {
        self == .v7 || self == .v8
    }

    /// V8 — compact 30×30 avatars instead of the standard 48×48.
    var usesCompactAvatar: Bool {
        self == .v8
    }
}

private struct AttendanceUIVersionEnvironmentKey: EnvironmentKey {
    static let defaultValue: AttendanceUIVersion = .v8
}

private struct AttendanceMVPEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct RedesignEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

enum AttendanceNotifyStyle: String, CaseIterable, Identifiable {
    case inlineBells = "Inline bells"
    case fab = "FAB + swipe"
    /// Final — FAB opens filter-based notify; no per-employee select/deselect.
    case final = "Final"
    /// Sheet — FAB opens “Choose who to notify” bottom sheet (category toggles).
    case sheet = "Sheet"

    var id: String { rawValue }

    static let appStorageKey = "settings.attendanceNotifyStyle"

    /// Uses the floating bell FAB chrome (vs inline row bells).
    var usesFabChrome: Bool {
        switch self {
        case .fab, .final, .sheet: return true
        case .inlineBells: return false
        }
    }

    /// Notify targets come only from active filters — no employee checkmarks.
    var isFilterOnlyNotify: Bool {
        self == .final
    }

    /// FAB opens a category-toggle bottom sheet instead of in-list notify mode.
    var usesNotifySheet: Bool {
        self == .sheet
    }
}

/// Break support home-widget interaction alternatives (Epic PROD-82468).
enum BreakSupportUIVersion: String, CaseIterable, Identifiable {
    case v1 = "V1"
    case v2 = "V2"
    case v3 = "V3"
    case v4 = "V4"
    case v5 = "V5"
    case v6 = "V6"
    case v7 = "V7"
    case v8 = "V8"
    case v9 = "V9"
    case v10 = "V10"
    case v11 = "V11"
    case v12 = "V12 (Label simple)"
    /// Former V12.2 — pause/resume on the left of the timer.
    case v12_1 = "V12.1 (Label left buttons)"
    case v13 = "V13 (Emoji)"
    /// Former V12.2 / V12.3 — On break uses tonal green “Back to work” button.
    case v14 = "V14 (Label Back to work)"
    /// V14 controls + “On break” pill with an editable emoji inside the label.
    case v15 = "V15 (Label with emoji)"

    var id: String { rawValue }

    static let appStorageKey = "settings.breakSupportUIVersion"
    static let enabledAppStorageKey = "settings.breakSupportEnabled"
    /// Nested breaks between start/end on time-entry detail & edit (orthogonal to widget versions).
    static let nestedInTimeEntryAppStorageKey = "settings.breaksNestedInTimeEntry"
    static let defaultVersion: BreakSupportUIVersion = .v15

    static func resolved(from rawValue: String) -> BreakSupportUIVersion {
        if let match = BreakSupportUIVersion(rawValue: rawValue) { return match }
        // Migrate pre-rename storage keys.
        switch rawValue {
        case "V12": return .v12
        case "V12.2": return .v12_1 // old left-buttons layout
        case "V12.2 (Label Back to work)", "V12.3": return .v14 // old “Back to work” label
        case "V13": return .v13
        case "V14": return .v14
        case "V15": return .v15
        default: return .v15
        }
    }

    var caption: String {
        switch self {
        case .v1:
            return "Serial — Hold to clock in → Pause → Tap to clock out"
        case .v2:
            return "Parallel — Pause/Resume circle beside hold-to-Stop anytime"
        case .v3:
            return "Status — Set Working / On break / Done (presence-style)"
        case .v4:
            return "Bounded break — Hold to clock in; tap pause/presets & tap clock out"
        case .v5:
            return "Slack-style — Emoji + 5/10/15/30m presets under the card while clocked in"
        case .v6:
            return "Sentence — Take a [emoji] break for [5m] + Pause under the card"
        case .v7:
            return "Two pickers — Choose break type + duration, then confirm Start"
        case .v8:
            return "Quick presets — Pick a one-tap break card, then confirm Start"
        case .v9:
            return "Break for — Duration chips (5/10/15/30m), then Start break"
        case .v10:
            return "Take a [emoji] for — Emoji + 5/15/30m chips, then Start break"
        case .v11:
            return "Take a [emoji] for — Duration optional; session clock stays up, break timer below"
        case .v12:
            return "Label simple — On break pill + circular resume; hold play/stop with halo"
        case .v12_1:
            return "Label left buttons — Pause/resume sits left of the timer"
        case .v13:
            return "Emoji — On break shows emoji beside the timer + resume only"
        case .v14:
            return "Label Back to work — On break uses a green tonal “Back to work” button"
        case .v15:
            return "Label with emoji — On break pill includes an editable emoji + Back to work"
        }
    }

    /// Bounded-break versions show a planned countdown instead of the session timer.
    var usesBoundedBreakCountdown: Bool {
        switch self {
        case .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11: return true
        default: return false
        }
    }

    /// Home composers that pick an emoji — also show it on time-entry detail/edit.
    var showsBreakEmoji: Bool {
        switch self {
        case .v5, .v6, .v7, .v8, .v10, .v11, .v13, .v15: return true
        default: return false
        }
    }

    /// On-break status pill includes a tappable emoji (home dashboard + calendar FAB).
    var usesEditableBreakEmojiLabel: Bool {
        self == .v15
    }
}

/// Preset for V4 bounded breaks (type + planned duration).
enum BoundedBreakPreset: String, CaseIterable, Identifiable {
    case coffee15 = "Coffee"
    case lunch30 = "Lunch"
    case lunch60 = "Long lunch"
    case other15 = "Break"

    var id: String { rawValue }

    var minutes: Int {
        switch self {
        case .coffee15, .other15: return 15
        case .lunch30: return 30
        case .lunch60: return 60
        }
    }

    var subtitle: String { "\(minutes)m" }

    /// SF Symbol — emoji glyphs don’t render reliably in this app target.
    var systemImage: String {
        switch self {
        case .coffee15: return "cup.and.saucer.fill"
        case .lunch30, .lunch60: return "fork.knife"
        case .other15: return "pause.fill"
        }
    }

    var menuTitle: String { "\(rawValue) · \(subtitle)" }

    /// Icon for an active break label (including custom).
    static func systemImage(forLabel label: String?) -> String {
        switch label {
        case "Coffee": return "cup.and.saucer.fill"
        case "Lunch", "Long lunch": return "fork.knife"
        case "Break": return "pause.fill"
        default: return "timer"
        }
    }
}

/// V5 Slack-style break suggestion (emoji + label + default duration).
struct StatusBreakPreset: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String
    let minutes: Int

    var durationLabel: String { "\(minutes)m" }

    static let suggestions: [StatusBreakPreset] = [
        StatusBreakPreset(id: "coffee", emoji: "☕", title: "Coffee", minutes: 10),
        StatusBreakPreset(id: "lunch", emoji: "🍽️", title: "Lunch", minutes: 30),
        StatusBreakPreset(id: "walk", emoji: "🚶", title: "Walk", minutes: 15),
        StatusBreakPreset(id: "focus", emoji: "🎧", title: "Focus break", minutes: 5),
        StatusBreakPreset(id: "away", emoji: "🏠", title: "Away from desk", minutes: 15)
    ]

    /// V8 — short set of one-tap quick breaks.
    static let quickPresets: [StatusBreakPreset] = [
        StatusBreakPreset(id: "coffee", emoji: "☕", title: "Coffee", minutes: 5),
        StatusBreakPreset(id: "lunch", emoji: "🍔", title: "Lunch", minutes: 30),
        StatusBreakPreset(id: "walk", emoji: "🚶", title: "Walk", minutes: 15)
    ]

    static let durationOptions: [Int] = [5, 10, 15, 30]

    /// V9 — “Break for” duration row (Figma 15675-33015).
    static let v9DurationOptions: [Int] = [5, 10, 15, 30]

    /// V10 — “Take a [emoji] for” duration row (Figma 15683-14659).
    static let v10DurationOptions: [Int] = [5, 15, 30]

    static let emojiChoices: [String] = [
        "☕", "🍵", "🍝", "🍽️", "🥪", "🚶", "🏃", "🎧", "🧘", "📞", "💬", "🏠", "🚗", "😴", "🤒", "🌴"
    ]
}

/// V7 — break type is independent of duration (two-picker mental model).
struct BreakTypeOption: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String

    var menuTitle: String { "\(emoji) \(title)" }

    static let all: [BreakTypeOption] = [
        BreakTypeOption(id: "coffee", emoji: "☕", title: "Coffee"),
        BreakTypeOption(id: "lunch", emoji: "🍽️", title: "Lunch"),
        BreakTypeOption(id: "walk", emoji: "🚶", title: "Walk"),
        BreakTypeOption(id: "focus", emoji: "🎧", title: "Focus"),
        BreakTypeOption(id: "away", emoji: "🏠", title: "Away")
    ]
}

private struct AttendanceNotifyStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: AttendanceNotifyStyle = .sheet
}

private struct AttendanceNoIssuesEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct AttendanceWorkingCaseEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct AttendanceTwoIssuesCaseEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct BreakSupportEnabledEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

private struct BreakSupportUIVersionEnvironmentKey: EnvironmentKey {
    static let defaultValue: BreakSupportUIVersion = .v15
}

private struct BreaksNestedInTimeEntryEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var attendanceUIVersion: AttendanceUIVersion {
        get { self[AttendanceUIVersionEnvironmentKey.self] }
        set { self[AttendanceUIVersionEnvironmentKey.self] = newValue }
    }

    /// Feature flag for break (pause/resume) support on time tracking (PROD-82468).
    var breakSupportEnabled: Bool {
        get { self[BreakSupportEnabledEnvironmentKey.self] }
        set { self[BreakSupportEnabledEnvironmentKey.self] = newValue }
    }

    var breakSupportUIVersion: BreakSupportUIVersion {
        get { self[BreakSupportUIVersionEnvironmentKey.self] }
        set { self[BreakSupportUIVersionEnvironmentKey.self] = newValue }
    }

    /// When on, time-entry detail/edit show breaks nested between start and end
    /// (applies on top of any break-support UI version).
    var breaksNestedInTimeEntry: Bool {
        get { self[BreaksNestedInTimeEntryEnvironmentKey.self] }
        set { self[BreaksNestedInTimeEntryEnvironmentKey.self] = newValue }
    }

    /// MVP mode — hides notification bells and multi-select from attendance lists.
    var attendanceMVP: Bool {
        get { self[AttendanceMVPEnvironmentKey.self] }
        set { self[AttendanceMVPEnvironmentKey.self] = newValue }
    }

    /// Redesign mode — enables redesigned UI from the redesign branch.
    var redesign: Bool {
        get { self[RedesignEnvironmentKey.self] }
        set { self[RedesignEnvironmentKey.self] = newValue }
    }

    /// Notification style — inline bells on each row vs FAB + swipe-to-notify.
    var attendanceNotifyStyle: AttendanceNotifyStyle {
        get { self[AttendanceNotifyStyleEnvironmentKey.self] }
        set { self[AttendanceNotifyStyleEnvironmentKey.self] = newValue }
    }

    /// Preview mode — Today attendance shows "On track" and lists exclude issue rows.
    var attendanceNoIssues: Bool {
        get { self[AttendanceNoIssuesEnvironmentKey.self] }
        set { self[AttendanceNoIssuesEnvironmentKey.self] = newValue }
    }

    /// Preview mode — attendance list shows employees with issues (mutually exclusive with no-issues).
    var attendanceWorkingCase: Bool {
        get { self[AttendanceWorkingCaseEnvironmentKey.self] }
        set { self[AttendanceWorkingCaseEnvironmentKey.self] = newValue }
    }

    /// Preview mode — attendance list shows Doe, Joanne with two stacked issue pills (Figma 390-15756).
    var attendanceTwoIssuesCase: Bool {
        get { self[AttendanceTwoIssuesCaseEnvironmentKey.self] }
        set { self[AttendanceTwoIssuesCaseEnvironmentKey.self] = newValue }
    }
}

// MARK: - Today neutral status pill (Figma 354-7370 — On track, +N on leave)

/// Grey capsule — shared by attendance "On track" and on-leave overflow counts.
struct TodayNeutralStatusPill: View {
    let label: String
    var compact: Bool = true

    var body: some View {
        Text(label)
            .font(compact ? AppFonts.caption1Strong() : AppFonts.subheadStrong())
            .foregroundColor(AppColors.fontDefault)
            .padding(.horizontal, compact ? 6 : 12)
            .padding(.vertical, compact ? 0 : 4)
            .frame(height: compact ? 25 : nil)
            .background(AppColors.lightBackground)
            .clipShape(Capsule())
    }
}

// MARK: - Today attendance status (Figma 354-7370 / 352-7912)

/// Issues count pill or neutral "On track" when previewing the no-issues Today state.
struct TodayAttendanceStatusPill: View {
    let issueCount: Int
    var compact: Bool = false

    @Environment(\.attendanceNoIssues) private var attendanceNoIssues
    @Environment(\.attendanceWorkingCase) private var attendanceWithIssues

    private var showsOnTrack: Bool {
        !attendanceWithIssues && (attendanceNoIssues || issueCount == 0)
    }

    var body: some View {
        if showsOnTrack {
            TodayNeutralStatusPill(label: "On track", compact: compact)
        } else {
            Text("\(issueCount) Issues")
                .font(compact ? AppFonts.caption1Strong() : AppFonts.subheadStrong())
                .foregroundColor(AppColors.dangerDefault)
                .padding(.horizontal, compact ? 6 : 12)
                .padding(.vertical, compact ? 0 : 4)
                .frame(height: compact ? 25 : nil)
                .background(AppColors.dangerBackground)
                .clipShape(Capsule())
        }
    }
}

struct TodayWidgetSwitcher: View {
    let data: TodayWidgetData

    @AppStorage(AttendanceUIVersion.appStorageKey) private var storedVersion =
        AttendanceUIVersion.defaultVersion.rawValue

    private var version: AttendanceUIVersion {
        AttendanceUIVersion.resolved(from: storedVersion)
    }

    var body: some View {
        Group {
            switch version {
            case .v1:
                TodayWidgetV1(data: data)
            case .v2, .v3:
                TodayWidgetV2(data: data)
            case .v4, .v5:
                TodayWidgetV4(data: data)
            case .v6, .v7, .v8:
                TodayWidgetV6(data: data)
            }
        }
    }
}

/// Miniature attendance **list page** preview — highlights what differs per version.
private struct AttendanceUIVersionPageSnippet: View {
    let version: AttendanceUIVersion

    private var attendanceTabTitle: String {
        version.usesModernAttendanceChrome ? "Attendance" : "Time tracking"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            snippetNavBar
            snippetTabBar
            snippetFilterBar
            if version.usesModernAttendanceChrome && !version.usesProgressBarEmployeeStatus {
                snippetSearchRow(visible: false)
            } else if !version.usesModernAttendanceChrome {
                snippetSearchRow(visible: true)
            }
            snippetSectionHeader
            snippetEmployeeRow
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 0.5)
        )
    }

    private var snippetNavBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.left")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(AppColors.primaryDark)
            Spacer()
            if version.usesModernAttendanceChrome {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AppColors.primaryDark)
            }
            Image(systemName: "calendar")
                .font(.system(size: 9))
                .foregroundColor(AppColors.primaryDark)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppColors.surface)
    }

    private var snippetTabBar: some View {
        HStack(spacing: 0) {
            snippetTab("Events", selected: false)
            if version.usesModernAttendanceChrome {
                snippetTab("On leave", selected: false)
                snippetTab(attendanceTabTitle, selected: true)
            } else {
                snippetTab(attendanceTabTitle, selected: true)
                snippetTab("On leave", selected: false)
            }
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 0.5), alignment: .bottom)
    }

    private func snippetTab(_ title: String, selected: Bool) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 7, weight: selected ? .semibold : .regular))
                .foregroundColor(selected ? AppColors.primaryDark : AppColors.fontSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Rectangle()
                .fill(selected ? AppColors.primaryDark : Color.clear)
                .frame(height: 1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)
    }

    private var snippetFilterBar: some View {
        HStack(spacing: 4) {
            if version.usesModernAttendanceChrome {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(AppColors.lightBackground)
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(AppColors.fontSecondary)
                    }
            }

            HStack(spacing: 3) {
                snippetFilterChip("Not clocked in (1)", selected: true)
                snippetFilterChip("Worked more (2)", selected: false)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppColors.surface)
    }

    private func snippetFilterChip(_ title: String, selected: Bool) -> some View {
        HStack(spacing: 2) {
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, AppColors.primaryDark)
            }
            Text(title)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(selected ? AppColors.primaryDark : AppColors.fontSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(selected ? AppColors.activeBackground : AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func snippetSearchRow(visible: Bool) -> some View {
        Group {
            if visible {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 8))
                        .foregroundColor(AppColors.iconDefault)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.separator.opacity(0.5))
                        .frame(height: 6)
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.lightBackground)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.fontSecondary)
                        }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(AppColors.lightBackground)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
        }
    }

    private var snippetSectionHeader: some View {
        HStack {
            Text("Direct reports")
                .font(.system(size: 7))
                .foregroundColor(AppColors.fontSecondary)
            Spacer()
            if version.usesModernAttendanceChrome {
                Text("Select")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(AppColors.primaryDark)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private var snippetEmployeeRow: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(Color(hex: "E8E8ED"))
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.fontDefault.opacity(0.85))
                    .frame(width: 52, height: 5)
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.fontSecondary.opacity(0.5))
                    .frame(width: 36, height: 4)

                if version.usesProgressBarEmployeeStatus {
                    snippetProgressStatus
                } else if version.usesV4EmployeeCardStatus {
                    snippetV4IssueBanner
                } else {
                    snippetPillStatus
                }
            }

            Spacer(minLength: 0)

            if version.usesModernAttendanceChrome {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: 18, height: 18)
                    .overlay {
                        Image(systemName: "bell")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(AppColors.primaryDark)
                    }
                    .overlay(Circle().stroke(AppColors.separator.opacity(0.6), lineWidth: 0.5))
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .overlay {
                        Image(systemName: "bell")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(AppColors.primaryDark)
                    }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .padding(.horizontal, 8)
    }

    private var snippetPillStatus: some View {
        HStack(spacing: 3) {
            Text("-8h")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(AppColors.dangerDefault)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(AppColors.dangerBackground)
                .clipShape(Capsule())
            Text("Not clocked in")
                .font(.system(size: 6, weight: .medium))
                .foregroundColor(AppColors.fontSecondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(AppColors.lightBackground)
                .clipShape(Capsule())
        }
    }

    private var snippetV4IssueBanner: some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(AppColors.dangerDefault.opacity(0.85))
                .frame(width: 5, height: 5)
            Text("Not clocked in")
                .font(.system(size: 5, weight: .regular))
                .foregroundColor(AppColors.dangerDefault)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("0h")
                .font(.system(size: 5, weight: .regular))
                .foregroundColor(AppColors.dangerDefault)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceDarker)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }

    private var snippetProgressStatus: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Not clocked in")
                .font(.system(size: 6, weight: .semibold))
                .foregroundColor(AppColors.dangerDefault)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(AppColors.dangerBackground)
                .clipShape(Capsule())

            HStack(spacing: 4) {
                Text("0h / 8h")
                    .font(.system(size: 6))
                    .foregroundColor(AppColors.fontSecondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(AppColors.informativeBackground)
                            .frame(width: geo.size.width)
                    }
                }
                .frame(height: 3)
            }
        }
    }
}

/// Compact selectable previews for V1 / V2 / V3 / V4 / V5 in Settings.
struct AttendanceUIVersionSnippets: View {
    @Binding var selectedVersion: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(AttendanceUIVersion.allCases) { version in
                    snippet(for: version)
                }
            }
        }
    }

    private func snippet(for version: AttendanceUIVersion) -> some View {
        let isSelected = AttendanceUIVersion.resolved(from: selectedVersion) == version

        return Button {
            selectedVersion = version.rawValue
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(version.rawValue)
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontSecondary)

                AttendanceUIVersionPageSnippet(version: version)
                    .frame(width: 148, height: 132)
                    .allowsHitTesting(false)

                Text(version.snippetCaption)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(width: 168, alignment: .leading)
            .background(isSelected ? AppColors.activeBackground : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppColors.primaryDark : AppColors.separator, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(version.rawValue) UI version")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension AttendanceUIVersion {
    var snippetCaption: String {
        switch self {
        case .v1:
            return "Time tracking tab · pills · always-visible search"
        case .v2:
            return "Attendance tab · pills · search icon · Select"
        case .v3:
            return "Like V2 · progress bars on rows"
        case .v4:
            return "Side-by-side On leave & Attendance · red banners"
        case .v5:
            return "Fork of V4 — red banners · independent iteration"
        case .v6:
            return "Fork of V5 — independent iteration"
        case .v7:
            return "Fork of V6 — inline issue pills on the right"
        case .v8:
            return "Fork of V7 — compact 30×30 avatars"
        }
    }
}

enum TodayWidgetVersion: String, CaseIterable, Identifiable {
    case figma     = "Figma"
    case classic   = "Classic"
    case compact   = "Compact"
    case cardGrid  = "Grid"
    case rich      = "Rich"
    case timeline  = "Timeline"
    case magazine  = "Magazine"
    case bento     = "Bento"
    case dashboard = "Stats"

    var id: String { rawValue }
}

// MARK: - Selective Corner Radius

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Shared Sub-views

private struct TodayHeader: View {
    var body: some View {
        HStack {
            Text("Today")
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
                .foregroundColor(AppColors.fontDefault)
            Spacer()
            Button("View all") {}
                .font(AppFonts.subheadStrong())
                .foregroundColor(AppColors.primaryDark)
                .buttonStyle(.plain)
        }
    }
}

private struct EventRow: View {
    let event: TodayEvent
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Text("\(event.time) · \(event.subtitle)")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.iconDefault)
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle().size(width: 32, height: 32))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct CelebrationRow: View {
    let item: TodayCelebration
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(item.iconBackground)
                    .frame(width: 40, height: 40)
                Image(item.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(item.iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
                Text(item.value)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
            }
            Spacer()
        }
    }
}

private struct AvatarStack: View {
    let names: [String]
    let overflow: Int
    var size: CGFloat = 25

    var body: some View {
        HStack(spacing: 2) {
            ForEach(names.prefix(3), id: \.self) { name in
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            }
        }
        if overflow > 0 {
            TodayNeutralStatusPill(label: "+\(overflow)")
        }
    }
}

private func todayCompactIssuePill(_ title: String, style: TodayPillStyle) -> some View {
    Text(title)
        .font(AppFonts.caption1Strong())
        .foregroundColor(style.badgeTextColor)
        .lineLimit(1)
        .padding(.horizontal, 6)
        .frame(height: 25)
        .background(style.badgeBackground)
        .clipShape(Capsule())
}

private struct AttendanceTitleWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// V1 Today row — pills start fully visible; scroll under the title fade overlay.
private struct TodayV1AttendanceIssueScroll: View {
    let issueChips: [TodayIssueChip]
    private let fadeWidth: CGFloat = 36
    private let pillHeight: CGFloat = 25
    /// Gap between fade tail and first pill at rest.
    private let pillStartGap: CGFloat = 12
    @State private var titleAreaWidth: CGFloat = 96

    private var scrollLeadingInset: CGFloat {
        titleAreaWidth + fadeWidth + pillStartGap
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Color.clear
                        .frame(width: scrollLeadingInset)

                    ForEach(issueChips) { chip in
                        NavigationLink {
                            TimeAttendanceAnomaliesListView(initialFilters: chip.filters)
                        } label: {
                            todayCompactIssuePill(chip.pillTitle, style: chip.style)
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        TimeAttendanceAnomaliesListView(initialFilters: [])
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.fontSecondary)
                            .padding(.horizontal, 6)
                            .frame(height: pillHeight)
                            .background(AppColors.separator)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: pillHeight)
            }

            attendanceTitleOverlay
        }
        .frame(minHeight: pillHeight)
        .onPreferenceChange(AttendanceTitleWidthKey.self) { titleAreaWidth = $0 }
    }

    private var attendanceTitleOverlay: some View {
        ZStack(alignment: .leading) {
            ZStack(alignment: .trailing) {
                Rectangle()
                    .fill(AppColors.lightBackground)
                LinearGradient(
                    colors: [
                        AppColors.lightBackground,
                        AppColors.lightBackground.opacity(0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: fadeWidth)
                .offset(x: fadeWidth)
            }
            .frame(width: titleAreaWidth + fadeWidth, alignment: .leading)
            .frame(maxHeight: .infinity)

            Text("Attendance")
                .font(AppFonts.subheadline())
                .tracking(-0.24)
                .foregroundColor(AppColors.fontDefault)
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: AttendanceTitleWidthKey.self, value: geo.size.width)
                    }
                }
        }
        .frame(maxHeight: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }
}

private struct AttendanceBadge: View {
    let count: Int
    let label: String
    let badgeColor: Color
    let textColor: Color
    let labelColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Text("\(count)")
                .font(AppFonts.caption1Strong())
                .foregroundColor(textColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(badgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(label)
                .font(AppFonts.caption1())
                .foregroundColor(labelColor)
        }
    }
}

// MARK: - V1 — main attendance Today UI

struct TodayWidgetV1: View {
    let data: TodayWidgetData
    @AppStorage("settings.showAttendanceIssuesUI") private var showsAttendanceIssuesUI = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            ForEach(data.events.prefix(1)) { event in
                EventRow(event: event)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    CelebrationRow(item: item)
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Text(data.onLeaveTitle)
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                    Spacer()
                    AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.lightBackground)
                .cornerRadius(16)

                if showsAttendanceIssuesUI {
                    TodayV1AttendanceIssueScroll(issueChips: data.issueChips)
                        .padding(.vertical, 12)
                        .background(AppColors.lightBackground)
                        .cornerRadius(16)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }
}

// MARK: - V2/V4/V5 Today attendance row (whole row tappable)

private struct TodayModernAttendanceSectionRow: View {
    let issueCount: Int

    var body: some View {
        NavigationLink {
            TimeAttendanceAnomaliesListView(initialFilters: [])
        } label: {
            HStack {
                Text("Attendance")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                HStack(spacing: 8) {
                    TodayAttendanceStatusPill(issueCount: issueCount, compact: true)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.fontSecondary)
                        .frame(height: 25)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.lightBackground)
            .cornerRadius(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - V2 — main attendance Today UI (fork for redesign)

struct TodayWidgetV2: View {
    let data: TodayWidgetData
    @AppStorage("settings.showAttendanceIssuesUI") private var showsAttendanceIssuesUI = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            ForEach(data.events.prefix(1)) { event in
                EventRow(event: event)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    CelebrationRow(item: item)
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Text(data.onLeaveTitle)
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                    Spacer()
                    AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.lightBackground)
                .cornerRadius(16)

                if showsAttendanceIssuesUI {
                    TodayModernAttendanceSectionRow(issueCount: data.issueCount)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }
}

// MARK: - V4 Today metric cards (Figma 15515:999262)

private struct TodayV4MetricCardsRow: View {
    let data: TodayWidgetData
    var showsAttendanceIssuesUI: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            TodayV4OnLeaveCard(
                title: data.onLeaveTitle,
                avatars: data.onLeaveAvatars,
                overflow: data.onLeaveOverflow
            )
            .frame(maxWidth: .infinity)

            if showsAttendanceIssuesUI {
                TodayV4AttendanceCard(issueCount: data.issueCount)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct TodayV4OnLeaveCard: View {
    let title: String
    let avatars: [String]
    let overflow: Int

    var body: some View {
        NavigationLink {
            TimeAttendanceAnomaliesListView(initialFilters: [], initialTab: 1)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)

                HStack(spacing: 2) {
                    AvatarStack(names: avatars, overflow: overflow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surfaceDarker)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct TodayV4AttendanceCard: View {
    let issueCount: Int

    var body: some View {
        NavigationLink {
            TimeAttendanceAnomaliesListView(initialFilters: [], initialTab: 3)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text("Attendance")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)

                TodayAttendanceStatusPill(issueCount: issueCount, compact: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surfaceDarker)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - V4 — fork of V2 (change here without affecting V2)

struct TodayWidgetV4: View {
    let data: TodayWidgetData
    @AppStorage("settings.showAttendanceIssuesUI") private var showsAttendanceIssuesUI = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            ForEach(data.events.prefix(1)) { event in
                EventRow(event: event)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    CelebrationRow(item: item)
                }
            }

            TodayV4MetricCardsRow(
                data: data,
                showsAttendanceIssuesUI: showsAttendanceIssuesUI
            )
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }
}

// MARK: - V6 — fork of V4 (Figma 48-57115)

struct TodayWidgetV6: View {
    let data: TodayWidgetData
    @AppStorage("settings.showAttendanceIssuesUI") private var showsAttendanceIssuesUI = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            ForEach(data.events.prefix(1)) { event in
                EventRow(event: event)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    CelebrationRow(item: item)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                TodayV6AttendanceChip(label: "Attendance", issueCount: data.issueCount)

                TodayV6OnLeaveChip(
                    label: "On leave",
                    avatars: data.onLeaveAvatars,
                    overflow: data.onLeaveOverflow
                )
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }
}

private struct TodayV6AttendanceChip: View {
    let label: String
    let issueCount: Int

    var body: some View {
        NavigationLink {
            TimeAttendanceAnomaliesListView(initialFilters: [], initialTab: 1)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)

                TodayAttendanceStatusPill(issueCount: issueCount)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .appLightCardShadow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct TodayV6OnLeaveChip: View {
    let label: String
    let avatars: [String]
    let overflow: Int

    var body: some View {
        NavigationLink {
            TimeAttendanceAnomaliesListView(initialFilters: [], initialTab: 2)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)

                HStack(spacing: 2) {
                    AvatarStack(names: avatars, overflow: overflow)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .appLightCardShadow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Version A — Classic

struct TodayWidgetClassic: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            VStack(alignment: .leading, spacing: 24) {
                ForEach(data.events) { event in
                    EventRow(event: event)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.anomalyPills) { pill in
                        NavigationLink {
                            TimeAttendanceAnomaliesListView(initialFilters: pill.filters)
                        } label: {
                            pillView(label: pill.label, count: pill.count, style: pill.style)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Text(data.onLeaveTitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
                Spacer()
                AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    CelebrationRow(item: item)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private func pillView(label: String, count: Int, style: TodayPillStyle) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontDefault)
                .tracking(-0.24)
            Text("\(count)")
                .font(AppFonts.caption1Strong())
                .foregroundColor(style.badgeTextColor)
                .frame(minWidth: 14)
                .padding(8)
                .background(style.badgeBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(style.pillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Version B — Compact

struct TodayWidgetCompact: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(0.35)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Text("\(data.events.count) events")
                    .font(AppFonts.caption1())
                    .foregroundColor(AppColors.fontSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(data.events) { event in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppColors.primaryDark)
                            .frame(width: 6, height: 6)
                        Text(event.title)
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontDefault)
                            .lineLimit(1)
                        Spacer()
                        Text(event.time)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
            }

            Rectangle().fill(AppColors.separator).frame(height: 1)

            HStack(spacing: 16) {
                ForEach(data.anomalyPills.filter { !$0.filters.isEmpty }) { pill in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(pill.style.badgeBackground)
                            .frame(width: 8, height: 8)
                        Text("\(pill.count)")
                            .font(AppFonts.caption1Strong())
                            .foregroundColor(AppColors.fontDefault)
                    }
                }
                Spacer()
                NavigationLink {
                    TimeAttendanceAnomaliesListView(initialFilters: [])
                } label: {
                    Text("View all")
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(AppColors.separator).frame(height: 1)

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.iconDefault)
                    Text(data.onLeaveTitle)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                        .lineLimit(1)
                }
                Spacer()
                ForEach(data.celebrations) { item in
                    HStack(spacing: 4) {
                        Image(item.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundColor(item.iconColor)
                        Text(item.value)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
}

// MARK: - Version C — Card Grid

struct TodayWidgetCardGrid: View {
    let data: TodayWidgetData

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TodayHeader()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.events) { event in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.primaryDark)
                            .frame(width: 3, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)
                            Text(event.time)
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(AppColors.lightBackground)
                    .cornerRadius(12)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                gridCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.dangerDefault)
                            Text("Attendance")
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        let total = data.anomalyPills.first(where: { $0.filters.isEmpty })?.count ?? 0
                        Text("\(total)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.fontDefault)
                        HStack(spacing: 4) {
                            ForEach(data.anomalyPills.filter { !$0.filters.isEmpty }) { pill in
                                Circle()
                                    .fill(pill.style.badgeBackground)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }

                gridCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.informativeDefault)
                            Text("On Leave")
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        AvatarStack(names: data.onLeaveAvatars, overflow: 0, size: 24)
                        if data.onLeaveOverflow > 0 {
                            Text("+\(data.onLeaveOverflow) more")
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                }

                ForEach(data.celebrations) { item in
                    gridCard {
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(item.iconBackground)
                                    .frame(width: 32, height: 32)
                                Image(item.icon)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(item.iconColor)
                            }
                            Text(item.title)
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                            Text(item.value)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private func gridCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)
    }
}

// MARK: - Version D — Rich

struct TodayWidgetRich: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()
            progressSection

            VStack(alignment: .leading, spacing: 10) {
                ForEach(data.events) { event in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.primaryDark)
                            .frame(width: 4, height: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(AppFonts.body())
                                .tracking(-0.41)
                                .foregroundColor(AppColors.fontDefault)
                            Text("\(event.time) · \(event.subtitle)")
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        Spacer()
                        Button {} label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.iconDefault)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            anomalyBarChart

            HStack(spacing: 12) {
                ForEach(data.celebrations) { item in
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(item.iconBackground)
                                .frame(width: 44, height: 44)
                            Image(item.icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundColor(item.iconColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                            Text(item.value)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(item.iconBackground.opacity(0.5))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private var progressSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(AppColors.separator, lineWidth: 5)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(AppColors.primaryDark, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                Text("6h")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontDefault)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("6h of 8h tracked")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.fontDefault)
                Text("8:00 – 16:00 schedule")
                    .font(AppFonts.caption1())
                    .foregroundColor(AppColors.fontSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(AppColors.lightBackground)
        .cornerRadius(12)
    }

    private var anomalyBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendance")
                .font(AppFonts.caption1Strong())
                .foregroundColor(AppColors.fontSecondary)

            let filtered = data.anomalyPills.filter { !$0.filters.isEmpty }
            let maxCount = filtered.map(\.count).max() ?? 1
            ForEach(filtered) { pill in
                HStack(spacing: 8) {
                    Text(pill.label)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                        .frame(width: 120, alignment: .trailing)
                        .lineLimit(1)
                    GeometryReader { geo in
                        let fraction = maxCount > 0 ? CGFloat(pill.count) / CGFloat(maxCount) : 0
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(pill.style.badgeBackground)
                            .frame(width: max(geo.size.width * fraction, 4))
                    }
                    .frame(height: 12)
                    Text("\(pill.count)")
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.fontDefault)
                        .frame(width: 24, alignment: .leading)
                }
            }
        }
        .padding(12)
        .background(AppColors.lightBackground)
        .cornerRadius(12)
    }
}

// MARK: - Version E — Timeline

struct TodayWidgetTimeline: View {
    let data: TodayWidgetData

    private var timelineNodes: [TimelineNode] {
        var nodes: [TimelineNode] = []
        nodes.append(TimelineNode(time: "8:00", title: "Shift starts", subtitle: "8:00 – 16:00", kind: .shift))
        for event in data.events {
            let startTime = String(event.time.prefix(5))
            nodes.append(TimelineNode(time: startTime, title: event.title, subtitle: "\(event.time) · \(event.subtitle)", kind: .event))
        }
        if data.issueCount > 0 {
            nodes.append(TimelineNode(time: "—", title: "\(data.issueCount) attendance issues", subtitle: "Not clocked in & absent", kind: .anomaly))
        }
        nodes.append(TimelineNode(time: "16:00", title: "Shift ends", subtitle: nil, kind: .shift))
        for item in data.celebrations {
            nodes.append(TimelineNode(time: "✦", title: item.title, subtitle: item.value, kind: .milestone, celebration: item))
        }
        return nodes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TodayHeader()
                .padding(.bottom, 16)

            ForEach(Array(timelineNodes.enumerated()), id: \.offset) { index, node in
                let isLast = index == timelineNodes.count - 1
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        timelineDot(for: node.kind)
                        if !isLast {
                            Rectangle()
                                .fill(AppColors.separator)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 20)

                    Text(node.time)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                        .frame(width: 42, alignment: .leading)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        if let celebration = node.celebration {
                            HStack(spacing: 6) {
                                Image(celebration.icon)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(celebration.iconColor)
                                Text(node.title)
                                    .font(AppFonts.subheadStrong())
                                    .foregroundColor(AppColors.fontDefault)
                            }
                        } else {
                            Text(node.title)
                                .font(node.kind == .shift ? AppFonts.caption1Strong() : AppFonts.subheadline())
                                .foregroundColor(node.kind == .anomaly ? AppColors.dangerDefault : AppColors.fontDefault)
                                .tracking(-0.24)
                        }
                        if let subtitle = node.subtitle {
                            Text(subtitle)
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                    .padding(.bottom, isLast ? 0 : 16)
                    Spacer()
                }
            }

            if !data.onLeaveAvatars.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.iconDefault)
                    Text(data.onLeaveTitle)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                    Spacer()
                    AvatarStack(names: data.onLeaveAvatars, overflow: 0, size: 20)
                }
                .padding(.top, 12)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private func timelineDot(for kind: TimelineNode.Kind) -> some View {
        Group {
            switch kind {
            case .event:
                Circle().fill(AppColors.primaryDark).frame(width: 10, height: 10).padding(5)
            case .shift:
                Circle().strokeBorder(AppColors.iconDefault, lineWidth: 2).frame(width: 10, height: 10).padding(5)
            case .anomaly:
                ZStack {
                    Circle().fill(AppColors.dangerBackground).frame(width: 20, height: 20)
                    Image(systemName: "exclamationmark").font(.system(size: 9, weight: .bold)).foregroundColor(AppColors.dangerDefault)
                }
            case .milestone:
                ZStack {
                    Circle().fill(AppColors.successBackground).frame(width: 20, height: 20)
                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(Color(hex: "37B086"))
                }
            }
        }
    }
}

private struct TimelineNode {
    enum Kind { case event, shift, anomaly, milestone }
    let time: String
    let title: String
    let subtitle: String?
    let kind: Kind
    var celebration: TodayCelebration? = nil
}

// MARK: - Version G — Magazine

struct TodayWidgetMagazine: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            if let event = data.events.first {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.fontDefault)
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.primaryDark)
                        Text(event.time)
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(AppColors.primaryDark)
                        Text("·")
                            .foregroundColor(AppColors.fontSecondary)
                        Text(event.subtitle)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.lightBackground)
                .cornerRadius(12)
            }

            if data.events.count > 1 {
                Text("+\(data.events.count - 1) more event\(data.events.count > 2 ? "s" : "")")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.primaryDark)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(data.celebrations) { item in
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(item.iconBackground)
                                    .frame(width: 32, height: 32)
                                Image(item.icon)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(item.iconColor)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title)
                                    .font(AppFonts.caption1())
                                    .foregroundColor(AppColors.fontSecondary)
                                Text(item.value)
                                    .font(AppFonts.subheadStrong())
                                    .foregroundColor(AppColors.fontDefault)
                                    .lineLimit(1)
                            }
                        }
                        .padding(8)
                        .background(AppColors.lightBackground)
                        .cornerRadius(10)
                    }
                }
            }

            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow, size: 22)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle().fill(AppColors.separator).frame(width: 1, height: 32)

                HStack(spacing: 12) {
                    AttendanceBadge(
                        count: data.issueCount,
                        label: "Issues",
                        badgeColor: Color(light: "FFD2CF", dark: "5A1A0F"),
                        textColor: AppColors.dangerDefault,
                        labelColor: AppColors.dangerDefault
                    )
                    AttendanceBadge(
                        count: data.onTrackCount,
                        label: "OK",
                        badgeColor: AppColors.activeBackground,
                        textColor: AppColors.primaryDark,
                        labelColor: AppColors.fontDefault
                    )
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
}

// MARK: - Version H — Bento

struct TodayWidgetBento: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TodayHeader()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data.events) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)
                            Text(event.time)
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(AppColors.lightBackground)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Attendance")
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.fontSecondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(data.issueCount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.dangerDefault)
                        Text("issues")
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                    }

                    HStack(spacing: 4) {
                        Circle().fill(AppColors.activeBackground).frame(width: 8, height: 8)
                        Text("\(data.onTrackCount) on track")
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.lightBackground)
                .cornerRadius(12)
            }

            HStack(spacing: 12) {
                ForEach(data.celebrations) { item in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(item.iconBackground)
                                .frame(width: 36, height: 36)
                            Image(item.icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(item.iconColor)
                        }
                        Text(item.value)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontDefault)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.lightBackground)
                    .cornerRadius(10)
                }
            }

            HStack(spacing: 8) {
                Text(data.onLeaveTitle)
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow, size: 22)
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
}

// MARK: - Version I — Dashboard

struct TodayWidgetDashboard: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            HStack(spacing: 12) {
                statCard(value: "\(data.events.count)", label: "Events", color: AppColors.primaryDark)
                statCard(value: "\(data.issueCount)", label: "Issues", color: AppColors.dangerDefault)
                statCard(value: "\(data.onTrackCount)", label: "On track", color: AppColors.successDefault)
                statCard(value: "\(data.onLeaveOverflow + data.onLeaveAvatars.count)", label: "On leave", color: AppColors.informativeDefault)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("EVENTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(0.5)
                ForEach(data.events) { event in
                    HStack(spacing: 10) {
                        Text(String(event.time.prefix(5)))
                            .font(AppFonts.caption1Strong())
                            .foregroundColor(AppColors.primaryDark)
                            .frame(width: 40, alignment: .leading)
                        Text(event.title)
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontDefault)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("CELEBRATIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(0.5)
                ForEach(data.celebrations) { item in
                    HStack(spacing: 8) {
                        Image(item.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(item.iconColor)
                        Text(item.title)
                            .font(AppFonts.caption1Strong())
                            .foregroundColor(AppColors.fontSecondary)
                        Spacer()
                        Text(item.value)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontDefault)
                    }
                }
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)

            HStack(spacing: 8) {
                AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow, size: 22)
                Spacer()
                AttendanceBadge(
                    count: data.issueCount,
                    label: "Issues",
                    badgeColor: Color(light: "FFD2CF", dark: "5A1A0F"),
                    textColor: AppColors.dangerDefault,
                    labelColor: AppColors.dangerDefault
                )
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption1())
                .foregroundColor(AppColors.fontSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.lightBackground)
        .cornerRadius(10)
    }
}

// MARK: - Previews

#Preview("Today Widget Switcher") {
    NavigationStack {
        ScrollView {
            TodayWidgetSwitcher(data: .mock)
                .padding(16)
        }
        .background(AppColors.background)
    }
}
