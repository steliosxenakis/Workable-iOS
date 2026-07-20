import SwiftUI

// MARK: - Anomaly Type

enum AnomalyType: String, CaseIterable, Identifiable {
    // Actionable (danger)
    case noClockIn = "No attendance"
    case noClockInNorOut = "Missed clock-in"
    case missedClockOut = "Missed clock-out"
    case exceededWorkSchedule = "Exceeding work hours"
    case workedLess = "Worked less"
    // Non-actionable (warning)
    case late = "Late arrival"
    case exceededHours = "Exceeded work hours"
    case unplanned = "Unplanned attendance"
    /// Scheduled today; shift not started — not an anomaly.
    case scheduleNotStarted = "Schedule not started"
    case onTrack = "On track"

    var id: String { rawValue }

    var textColor: Color {
        switch self {
        case .noClockIn, .noClockInNorOut, .missedClockOut, .exceededWorkSchedule, .workedLess:
            return AppColors.dangerDefault
        case .late, .exceededHours, .unplanned:
            return AppColors.warningDefault
        case .scheduleNotStarted:
            return AppColors.informativeDefault
        case .onTrack:
            return AppColors.successDefault
        }
    }

    var badgeBackground: Color {
        switch self {
        case .noClockIn, .noClockInNorOut, .missedClockOut, .exceededWorkSchedule, .workedLess:
            return AppColors.dangerBackground
        case .late, .exceededHours, .unplanned:
            return AppColors.warningBackground
        case .scheduleNotStarted:
            return AppColors.informativeBackground
        case .onTrack:
            return AppColors.successBackground
        }
    }

    var isDangerLevel: Bool {
        switch self {
        case .noClockIn, .noClockInNorOut, .missedClockOut, .exceededWorkSchedule, .workedLess:
            return true
        default:
            return false
        }
    }

    var isWarningLevel: Bool {
        switch self {
        case .late, .exceededHours, .unplanned:
            return true
        default:
            return false
        }
    }
}

// MARK: - Filter Categories (drill-in list)

enum AnomalyFilterCategory: String, CaseIterable, Identifiable {
    case noClockInNorOut = "Missed clock-ins"
    case missedClockOut = "Missed clock-outs"
    case exceededWorkSchedule = "Exceeding work hours"
    case noClockIn = "No attendance"
    case late = "Late arrival"
    case exceededHours = "Exceeded work hours"
    case unplanned = "Unplanned attendance"
    case workedLess = "Worked less"
    case onTrack = "On track"

    var id: String { rawValue }

    /// Every category in the Attendance issues filter except On track.
    static var allIssues: Set<AnomalyFilterCategory> {
        Set(allCases.filter { $0 != .onTrack })
    }

    var matchingTypes: Set<AnomalyType> {
        switch self {
        case .noClockIn:              return [.noClockIn]
        case .noClockInNorOut:        return [.noClockInNorOut]
        case .missedClockOut:         return [.missedClockOut]
        case .exceededWorkSchedule:   return [.exceededWorkSchedule]
        case .workedLess:             return [.workedLess]
        case .late:                   return [.late]
        case .exceededHours:          return [.exceededHours]
        case .unplanned:              return [.unplanned]
        case .onTrack:                return [.onTrack]
        }
    }

    /// Today issue pill copy — singular when `count == 1`.
    func issuePillLabel(count: Int) -> String {
        switch self {
        case .noClockInNorOut:
            return count == 1 ? "Missed clock-in" : rawValue
        case .missedClockOut:
            return count == 1 ? "Missed clock-out" : rawValue
        case .exceededWorkSchedule:
            return count == 1 ? "Exceeding work hour" : rawValue
        case .noClockIn, .onTrack, .late, .exceededHours, .unplanned, .workedLess:
            return rawValue
        }
    }
}

// MARK: - Data Models

struct AnomalySummaryItem: Identifiable, Hashable {
    let label: String
    let count: Int
    let textColor: Color
    let matchingFilters: Set<AnomalyFilterCategory>
    var id: String { label }

    static func == (lhs: AnomalySummaryItem, rhs: AnomalySummaryItem) -> Bool {
        lhs.label == rhs.label
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(label)
    }

    init(type: AnomalyType, count: Int) {
        self.label = type.rawValue
        self.count = count
        self.textColor = type.textColor
        self.matchingFilters = Set(AnomalyFilterCategory.allCases.filter { $0.matchingTypes.contains(type) })
    }

    init(label: String, count: Int, textColor: Color, matchingFilters: Set<AnomalyFilterCategory>) {
        self.label = label
        self.count = count
        self.textColor = textColor
        self.matchingFilters = matchingFilters
    }
}

struct EmployeeAnomaly: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let avatarName: String?
    let anomalyType: AnomalyType
    let hasScheduleIcon: Bool
    let department: String
    let workplace: String
    let entity: String
    let scheduledHours: Double
    let workedHours: Double
    /// V6 — schedule time range displayed in banners (e.g. "09:30 - 17:00").
    var scheduleTimeRange: String?
    /// V7 — second inline issue pill (Figma 390-15756).
    var secondaryIssueLabel: String? = nil

    var hasMultipleIssuePills: Bool {
        secondaryIssueLabel != nil
    }

    var hasAttendanceIssue: Bool {
        switch anomalyType {
        case .noClockIn, .noClockInNorOut, .missedClockOut, .exceededWorkSchedule, .workedLess, .late, .exceededHours, .unplanned:
            return true
        case .onTrack, .scheduleNotStarted:
            return false
        }
    }

    /// Attendance issues that should surface in counts (excludes PTO / on-leave and non-actionable warnings).
    var countsTowardAttendanceIssues: Bool {
        !hasScheduleIcon && hasAttendanceIssue && !anomalyType.isWarningLevel
    }

    /// Currently clocked in — on track with an ongoing shift (Figma 413-16918).
    var isCurrentlyWorking: Bool {
        anomalyType == .onTrack && scheduleTimeRange?.contains("Ongoing") == true
    }

    /// V6 subtitle — exactly one of Scheduled / Working / Worked for `scheduleTimeRange`.
    var scheduleTimeLabel: String? {
        guard let range = scheduleTimeRange else { return nil }
        let prefix: String
        switch anomalyType {
        case .scheduleNotStarted:
            prefix = "Scheduled: "
        default:
            if range.contains("Ongoing") {
                prefix = "Working: "
            } else if workedHours == 0 {
                prefix = "Scheduled: "
            } else {
                prefix = "Worked: "
            }
        }
        return "\(prefix)\(range)"
    }
}

// MARK: - Week calendar (shared mock chart rows)

struct DayHours {
    let day: String
    let scheduled: (Double, Double)?
    let worked: (Double, Double)?
    var hasAnomaly: Bool = false
}

// MARK: - Mock Data

enum TimeAttendanceMockData {
    static var summaryItems: [AnomalySummaryItem] {
        let eligible = employees.filter { !$0.hasScheduleIcon }
        let missedClocks = eligible.filter { $0.anomalyType == .noClockIn || $0.anomalyType == .noClockInNorOut }.count
        let exceeded = eligible.filter { $0.anomalyType == .exceededWorkSchedule }.count
        let unplanned = eligible.filter { $0.anomalyType == .unplanned }.count
        let late = eligible.filter { $0.anomalyType == .late }.count
        let exceededHours = eligible.filter { $0.anomalyType == .exceededHours }.count
        let onTrack = eligible.filter { $0.anomalyType == .onTrack }.count
        return [
            .init(label: "No attendance", count: missedClocks, textColor: AppColors.dangerDefault, matchingFilters: [.noClockIn, .noClockInNorOut]),
            .init(type: .exceededWorkSchedule, count: exceeded),
            .init(type: .unplanned, count: unplanned),
            .init(type: .late, count: late),
            .init(type: .exceededHours, count: exceededHours),
            .init(type: .onTrack, count: onTrack),
        ]
    }

    static let departments = ["Engineering", "Marketing", "Sales", "Operations"]
    static let entities = ["Workable Inc.", "Workable EU", "Workable UK"]

    /// Shared week chart data for personal and employee time-tracking calendar views.
    static let defaultWeekHours: [DayHours] = [
        .init(day: "M", scheduled: (8, 16), worked: (8.5, 15.5)),
        .init(day: "T", scheduled: (8, 16), worked: (8, 15)),
        .init(day: "W", scheduled: (8, 16), worked: (8, 16)),
        .init(day: "T", scheduled: (8, 16), worked: (8.5, 15)),
        .init(day: "F", scheduled: (8, 16), worked: (9, 13), hasAnomaly: true),
        .init(day: "S", scheduled: nil, worked: nil),
        .init(day: "S", scheduled: nil, worked: nil),
    ]

    static let loggedInUser = EmployeeAnomaly(
        name: "Sung, Natalie",
        role: "People Partner",
        avatarName: "avatar-emma",
        anomalyType: .onTrack,
        hasScheduleIcon: false,
        department: "Operations",
        workplace: "Remote",
        entity: "Workable Inc.",
        scheduledHours: 8, workedHours: 7.5
    )

    static let employees: [EmployeeAnomaly] = [
        // On track — Worked: 09:00 - 17:00 (Figma: Issue=Worked)
        .init(name: "Gutmann, Elyssa",                 role: "Marketing Director",      avatarName: "avatar-michael", anomalyType: .onTrack,               hasScheduleIcon: false, department: "Marketing",   workplace: "Remote",    entity: "Workable EU",   scheduledHours: 8, workedHours: 8, scheduleTimeRange: "09:00 - 17:00"),
        // Working — Working: 09:00 - Ongoing... (Figma 413-16918)
        .init(name: "Milwaukee, Jordan",                role: "Software Engineer",       avatarName: "avatar-jamal",   anomalyType: .onTrack,               hasScheduleIcon: false, department: "Engineering", workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 4.5, scheduleTimeRange: "09:00 - Ongoing..."),
        // Schedule not started — Scheduled: 09:00 - 17:00 (Figma: Issue=Expected)
        .init(name: "Tomasevic, George",                role: "Operations Manager",      avatarName: "avatar-tyler",   anomalyType: .scheduleNotStarted,   hasScheduleIcon: false,  department: "Operations",  workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 0, scheduleTimeRange: "09:00 - 17:00"),
        // Missed clock-in — Scheduled: 09:00 - 17:00 (Figma: Issue=Missed clock-in)
        .init(name: "Okafor, Chidi",                   role: "DevOps Engineer",         avatarName: "avatar-zoe",     anomalyType: .noClockInNorOut,       hasScheduleIcon: false,  department: "Engineering", workplace: "Remote",    entity: "Workable UK",   scheduledHours: 8, workedHours: 0, scheduleTimeRange: "09:00 - 17:00"),
        // Exceeding by 2h — Working: 09:00 - Ongoing... (Figma: Issue=Exceeding work hours)
        .init(name: "Wilhelham, Minnie Laris Julie",   role: "Sales Consultant",        avatarName: nil,              anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Engineering", workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 10, scheduleTimeRange: "07:00 - Ongoing..."),
        // No attendance — Scheduled: 09:00 - 17:00 (Figma: Issue=No attendance)
        .init(name: "Carty, Jonathan-Augustus",         role: "Operations Engineer",     avatarName: "avatar-abdi",    anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Operations",  workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 0, scheduleTimeRange: "09:00 - 17:00"),
        // Late by 1h — Working: 10:30 - Ongoing... (Figma: Issue=Late arrival)
        .init(name: "Patelaranga, Priya",               role: "Recruiter",               avatarName: "avatar-priya",   anomalyType: .late,                 hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 3, scheduleTimeRange: "10:30 - Ongoing..."),
        // Exceeded by 1h 30m — Worked: 09:00 - 19:00 (Figma: Issue=Exceeded work hours)
        .init(name: "Alonso, Clara",                    role: "Support Engineer",        avatarName: "avatar-sophia",  anomalyType: .exceededHours,        hasScheduleIcon: false, department: "Operations",  workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 9.5, scheduleTimeRange: "09:00 - 18:30"),
        // Unplanned — Worked: 09:07 - 17:09 (Figma: Issue=Unplanned)
        .init(name: "Kovasevic-Szobolzoi, Katarina",    role: "Data Analyst",            avatarName: "avatar-jamal",   anomalyType: .unplanned,            hasScheduleIcon: false, department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 0, workedHours: 8, scheduleTimeRange: "09:07 - 17:07"),
        .init(name: "Torres, Diego",                    role: "Data Analyst",            avatarName: "avatar-jamal",   anomalyType: .unplanned,            hasScheduleIcon: false, department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 0, workedHours: 7.5, scheduleTimeRange: "09:30 - 17:00"),
        // Missed clock-out — Worked: 09:15 - Missing (Figma: Issue=Missed clock-out)
        .init(name: "Elordi, Xavier",                   role: "Account Executive",       avatarName: "avatar-michael", anomalyType: .missedClockOut,       hasScheduleIcon: false,  department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 5, scheduleTimeRange: "09:15 - Missing"),
        // Exceeded by 1h 30m + Late by 2m — Worked: 09:32 - 19:00 (Figma 390-15756)
        .init(name: "Doe, Joanne",                     role: "Account Manager",         avatarName: "avatar-lucy",    anomalyType: .exceededHours,         hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 9.5, scheduleTimeRange: "09:32 - 19:00", secondaryIssueLabel: "Late by 2m"),
        // Worked 15m less — Worked: 09:00 - 16:45 (Figma: Issue=Worked less)
        .init(name: "Alonso, Javier",                   role: "Solutions Architect",     avatarName: "avatar-jamal",   anomalyType: .workedLess,           hasScheduleIcon: false,  department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 7.75, scheduleTimeRange: "09:00 - 16:45"),
        // Exceeded by 2h (multiple ranges) — Worked: 09:00 - 13:00, 15:00 - 21:00 (Figma: Issue=Exceeded, Multiple worked)
        .init(name: "Alonso, Javier",                   role: "Solutions Architect",     avatarName: "avatar-jamal",   anomalyType: .exceededHours,        hasScheduleIcon: false,  department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 10, scheduleTimeRange: "09:00 - 13:00, 15:00 - 21:00"),
        // Missed clock-in (selectable) — Scheduled: 09:30 - 17:00 (Figma: Issue=Selectable)
        .init(name: "Novak, Elena",                     role: "HR Coordinator",          avatarName: "avatar-priya",   anomalyType: .noClockInNorOut,       hasScheduleIcon: false,  department: "Operations",  workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 0, scheduleTimeRange: "09:30 - 17:00"),
        // Additional employees for variety
        .init(name: "Kovarek, Tomas",                  role: "Territory Manager",       avatarName: "avatar-tyler",   anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Sales",       workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 0, scheduleTimeRange: "09:00 - 17:00"),
        .init(name: "Nguyen, Mai",                     role: "Software Engineer",       avatarName: "avatar-sophia",  anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Engineering", workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 0, scheduleTimeRange: "08:30 - 16:30"),
        .init(name: "Petrov, Andrei",                  role: "QA Lead",                 avatarName: "avatar-tyler",   anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false,  department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 11, scheduleTimeRange: "06:30 - Ongoing..."),
        .init(name: "Santos, Maria",                   role: "Customer Success Manager",avatarName: "avatar-lucy",    anomalyType: .onTrack,               hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 7.5, scheduleTimeRange: "09:00 - 16:30"),
        .init(name: "Müller, Hans",                    role: "Finance Analyst",         avatarName: "avatar-jamal",   anomalyType: .onTrack,               hasScheduleIcon: false, department: "Operations",  workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 6, scheduleTimeRange: "08:30 - 14:30"),
        .init(name: "Chen, Wei",                       role: "Product Designer",        avatarName: "avatar-abdi",    anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Engineering", workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 9, scheduleTimeRange: "08:00 - Ongoing..."),
        .init(name: "Johansson, Erik",                 role: "Sales Director",          avatarName: "avatar-michael", anomalyType: .onTrack,               hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 8, scheduleTimeRange: "08:00 - 16:00"),
        .init(name: "Patel, Priya",                    role: "HR Business Partner",     avatarName: "avatar-priya",   anomalyType: .onTrack,               hasScheduleIcon: false, department: "Operations",  workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 7, scheduleTimeRange: "09:30 - 16:30"),
        .init(name: "Kim, Soo-Jin",                    role: "Content Strategist",      avatarName: "avatar-lucy",    anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Marketing",   workplace: "Remote",    entity: "Workable EU",   scheduledHours: 8, workedHours: 10.5, scheduleTimeRange: "07:30 - Ongoing..."),
        .init(name: "Rossi, Luca",                     role: "Backend Developer",       avatarName: nil,              anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 0, scheduleTimeRange: "10:00 - 18:00"),
        .init(name: "Barnes, Alex",                    role: "Product Manager",         avatarName: "avatar-michael", anomalyType: .scheduleNotStarted,   hasScheduleIcon: false, department: "Engineering", workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 0, scheduleTimeRange: "09:00 - 17:00"),
        .init(name: "Lindqvist, Nora",                 role: "UX Researcher",           avatarName: "avatar-emma",    anomalyType: .scheduleNotStarted,   hasScheduleIcon: false, department: "Marketing",   workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 0, scheduleTimeRange: "08:00 - 16:00"),
        .init(name: "Larsson, Ingrid",                  role: "People Partner",          avatarName: "avatar-emma",    anomalyType: .onTrack,              hasScheduleIcon: true,   department: "Operations",  workplace: "London",    entity: "Workable UK",   scheduledHours: 0, workedHours: 0),
        .init(name: "Bergström, Nils",                  role: "Data Engineer",           avatarName: "avatar-jamal",   anomalyType: .unplanned,            hasScheduleIcon: true,   department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 0, workedHours: 3, scheduleTimeRange: "10:00 - 13:00"),
        .init(name: "Andersson, Karin",                 role: "Frontend Developer",      avatarName: "avatar-sophia",  anomalyType: .onTrack,              hasScheduleIcon: false,  department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 7, scheduleTimeRange: "08:30 - 15:30"),
        .init(name: "Fischer, Leon",                    role: "Security Engineer",       avatarName: "avatar-tyler",   anomalyType: .onTrack,              hasScheduleIcon: false,  department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 8, scheduleTimeRange: "07:45 - 15:45"),
        .init(name: "Moreau, Camille",                  role: "Marketing Manager",       avatarName: "avatar-lucy",    anomalyType: .onTrack,              hasScheduleIcon: false,  department: "Marketing",   workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 6.5, scheduleTimeRange: "09:00 - 15:30"),
        .init(name: "Suzuki, Yuki",                     role: "iOS Developer",           avatarName: "avatar-zoe",     anomalyType: .onTrack,              hasScheduleIcon: false,  department: "Engineering", workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 7.5, scheduleTimeRange: "10:00 - 17:30"),
    ]

    /// Order matches Figma Direct reports (15276-14308).
    static var directReportsInFigmaOrder: [EmployeeAnomaly] {
        let order = ["Doe, Joanne", "Gutmann, Elyssa", "Carty, Jonathan-Augustus", "Tomasevic, George", "Larsson, Ingrid"]
        return order.compactMap { name in employees.first { $0.name == name } }
    }

    static var directReportsWithIssueCount: Int {
        directReportsInFigmaOrder.filter(\.countsTowardAttendanceIssues).count
    }

    /// Date-seeded variant — same people, different anomaly assignments per day.
    static func employees(for date: Date) -> [EmployeeAnomaly] {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return employees }

        let isFuture = date > Date()

        if isFuture {
            let schedules = [
                "09:00 - 17:00", "09:30 - 17:30", "08:00 - 16:00",
                "08:30 - 16:30", "10:00 - 18:00", "07:30 - 15:30",
                "09:00 - 17:30", "08:00 - 16:30",
            ]
            return employees.filter { !$0.hasScheduleIcon }.enumerated().map { index, emp in
                EmployeeAnomaly(
                    name: emp.name,
                    role: emp.role,
                    avatarName: emp.avatarName,
                    anomalyType: .scheduleNotStarted,
                    hasScheduleIcon: false,
                    department: emp.department,
                    workplace: emp.workplace,
                    entity: emp.entity,
                    scheduledHours: 8,
                    workedHours: 0,
                    scheduleTimeRange: schedules[index % schedules.count]
                )
            }
        }

        let seed = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let pastAnomalies: [AnomalyType] = [
            .onTrack, .onTrack, .onTrack,
            .exceededHours, .late, .unplanned,
            .noClockIn, .noClockInNorOut,
        ]
        let pastHours: [(scheduled: Double, worked: Double, range: String?)] = [
            (8, 8, "09:00 - 17:00"), (8, 7.5, "09:30 - 17:00"), (8, 7, "08:00 - 16:00"),
            (8, 10, "08:00 - 18:00"), (8, 7.45, "09:33 - 15:50"), (0, 3, "09:30 - 14:00"),
            (8, 0, "09:00 - 17:00"), (8, 0, "09:30 - 17:30"),
        ]

        return employees.enumerated().map { index, emp in
            guard !emp.hasScheduleIcon else { return emp }
            let pick = (seed + index * 7) % pastAnomalies.count
            let anomaly = pastAnomalies[pick]
            let hours = pastHours[pick]
            return EmployeeAnomaly(
                name: emp.name,
                role: emp.role,
                avatarName: emp.avatarName,
                anomalyType: anomaly,
                hasScheduleIcon: emp.hasScheduleIcon,
                department: emp.department,
                workplace: emp.workplace,
                entity: emp.entity,
                scheduledHours: hours.scheduled,
                workedHours: hours.worked,
                scheduleTimeRange: hours.range
            )
        }
    }
}

// MARK: - Filtering helper

extension Array where Element == EmployeeAnomaly {
    func filtered(
        by categories: Set<AnomalyFilterCategory>,
        departments: Set<String> = [],
        entities: Set<String> = []
    ) -> [EmployeeAnomaly] {
        var result = self
        if !categories.isEmpty {
            let matching = categories.reduce(into: Set<AnomalyType>()) { $0.formUnion($1.matchingTypes) }
            result = result.filter { matching.contains($0.anomalyType) }
        }
        if !departments.isEmpty {
            result = result.filter { departments.contains($0.department) }
        }
        if !entities.isEmpty {
            result = result.filter { entities.contains($0.entity) }
        }
        return result
    }
}

// MARK: - Flow Layout (iOS 16+)

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        return arrange(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(in: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x,
                            y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }

    private struct ArrangeResult { var positions: [CGPoint]; var size: CGSize }

    private func arrange(in maxWidth: CGFloat, subviews: Subviews) -> ArrangeResult {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + horizontalSpacing
            maxX = max(maxX, x - horizontalSpacing)
        }
        return ArrangeResult(positions: positions, size: CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: - Anomaly Pill Style (Figma 15399-147313)

enum AnomalyPillStyle {
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
        case .danger:  return AppColors.dangerBadge
        case .warning: return AppColors.warningBadge
        case .success: return AppColors.activeBackground
        case .neutral: return AppColors.separator
        }
    }

    var badgeTextColor: Color {
        switch self {
        case .danger:  return AppColors.dangerDefault
        case .warning: return AppColors.warningDefault
        case .success: return AppColors.primaryDark
        case .neutral: return AppColors.fontDefault
        }
    }
}

extension AnomalyType {
    var pillStyle: AnomalyPillStyle {
        switch self {
        case .noClockIn, .noClockInNorOut, .missedClockOut, .workedLess: return .danger
        case .exceededWorkSchedule:        return .warning
        case .late, .exceededHours, .unplanned: return .warning
        case .scheduleNotStarted:          return .neutral
        case .onTrack:                     return .success
        }
    }
}

// MARK: - Anomaly Pill View (Figma 15399-147313)

struct AnomalyPillView: View {
    let label: String
    let count: Int
    let style: AnomalyPillStyle

    var body: some View {
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

// MARK: - On Leave Row (Figma 15399-147467)

struct OnLeaveRowView: View {
    let title: String
    var avatarNames: [String] = []
    var overflowCount: Int? = nil
    var showChevron: Bool = true

    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontDefault)
                .tracking(-0.24)

            Spacer()

            if !avatarNames.isEmpty {
                HStack(spacing: 2) {
                    ForEach(avatarNames, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                }
            }

            if let count = overflowCount {
                TodayNeutralStatusPill(label: "+\(count)")
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.iconDefault)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 47)
        .background(AppColors.lightBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Anomaly Summary Pills (wireframe style — outlined)

struct AnomalySummaryTagsView: View {
    let items: [AnomalySummaryItem]
    var pillBackground: Color = AppColors.lightBackground
    var onTap: ((AnomalySummaryItem) -> Void)? = nil

    var body: some View {
        ForEach(items) { item in
            let pill = VStack(spacing: 2) {
                Text(item.label)
                    .font(AppFonts.caption1())
                    .foregroundColor(AppColors.fontSecondary)
                Text("\(item.count)")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(pillBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.separator, lineWidth: 1)
            )
            .cornerRadius(12)
            .fixedSize()

            if onTap != nil {
                Button { onTap?(item) } label: { pill }
                    .buttonStyle(.plain)
            } else {
                pill
            }
        }
    }
}

// MARK: - Filter chip checkmark (SF Symbol)

private struct AnomalyFilterCheckmarkIcon: View {
    var size: CGFloat = 20

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: size, weight: .semibold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(Color.white, AppColors.primaryDark)
    }
}

// MARK: - Liquid glass symbol button (40×40)

struct GlassSymbolButton: View {
    static let size: CGFloat = 40
    static let symbolPointSize: CGFloat = 18

    let systemName: String
    var fontSize: CGFloat = symbolPointSize
    var fontWeight: Font.Weight = .medium
    var foregroundColor: Color = Color(hex: "1A1A1A")
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundStyle(foregroundColor)
                .frame(width: Self.size, height: Self.size)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - V2 toolbar search toggle

struct AttendanceV2SearchToolbarButton: View {
    @Binding var isSearchVisible: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearchVisible.toggle()
            }
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.primaryDark)
        }
        .buttonStyle(.plain)
        .padding(.leading, 10)
        .accessibilityLabel(isSearchVisible ? "Hide search" : "Show search")
    }
}

// MARK: - Anomaly Filter Bar (horizontal scrolling chips)

struct AnomalyFilterBar: View {
    @Binding var selectedFilters: Set<AnomalyFilterCategory>
    @Binding var selectedDepartments: Set<String>
    @Binding var selectedEntities: Set<String>
    @Binding var searchText: String
    /// V2: toggled from nav search icon. V1: pass `.constant(true)`.
    @Binding var isSearchRowVisible: Bool
    var filterCounts: [AnomalyFilterCategory: Int] = [:]
    var attendanceVersion: AttendanceUIVersion = .v1
    var filteredResultCount: Int = 0

    @FocusState private var isSearchFieldFocused: Bool
    @State private var showsFilterSheet = false

    private var isV2Layout: Bool { attendanceVersion.usesModernAttendanceChrome }

    private var sortedFilters: [AnomalyFilterCategory] {
        AnomalyFilterCategory.allCases.filter { $0 != .onTrack }
    }

    private var hasActiveContextFilters: Bool {
        !selectedDepartments.isEmpty || !selectedEntities.isEmpty
    }

    private var showsSearchRow: Bool {
        if attendanceVersion.usesV6IssueBannerStyle { return true }
        return isV2Layout ? isSearchRowVisible : true
    }

    var body: some View {
        VStack(spacing: 0) {
            if attendanceVersion.usesV6IssueBannerStyle {
                HStack(spacing: 8) {
                    searchFieldRow
                    Button { showsFilterSheet = true } label: {
                        filterIconLabel
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .sheet(isPresented: $showsFilterSheet) {
                    AttendanceFilterSheet(
                        selectedFilters: $selectedFilters,
                        selectedDepartments: $selectedDepartments,
                        selectedEntities: $selectedEntities,
                        searchText: $searchText,
                        resultCount: filteredResultCount
                    )
                    .presentationDragIndicator(.visible)
                }
            } else {
                filterChipsRow(contextFiltersLeading: isV2Layout)

                if showsSearchRow {
                    Group {
                        if isV2Layout {
                            searchFieldRow
                        } else {
                            HStack(spacing: 8) {
                                searchFieldRow
                                contextFiltersMenu
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
        .animation(.easeInOut(duration: 0.2), value: showsSearchRow)
        .onChange(of: isSearchRowVisible) { isVisible in
            guard isV2Layout else { return }
            if isVisible {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    isSearchFieldFocused = true
                }
            } else {
                isSearchFieldFocused = false
            }
        }
    }

    private func filterChipsRow(contextFiltersLeading: Bool) -> some View {
        HStack(spacing: 8) {
            if contextFiltersLeading {
                contextFiltersMenu
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sortedFilters, id: \.self) { filter in
                        let isSelected = selectedFilters.contains(filter)
                        let count = filterCounts[filter] ?? 0
                        Button {
                            if isSelected { selectedFilters.remove(filter) }
                            else { selectedFilters.insert(filter) }
                        } label: {
                            if attendanceVersion.usesV6IssueBannerStyle {
                                v6FilterChip(filter: filter, count: count, isSelected: isSelected)
                            } else {
                                v4FilterChip(filter: filter, count: count, isSelected: isSelected)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, contextFiltersLeading ? 16 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 16)
        .padding(.trailing, contextFiltersLeading ? 0 : 16)
        .padding(.top, 12)
        .padding(.bottom, contextFiltersLeading ? 16 : 0)
    }

    private func v4FilterChip(filter: AnomalyFilterCategory, count: Int, isSelected: Bool) -> some View {
        HStack(spacing: isSelected ? 8 : 4) {
            if isSelected {
                AnomalyFilterCheckmarkIcon()
            }
            Text("\(filter.rawValue) (\(count))")
                .font(AppFonts.subheadStrong())
                .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontSecondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(isSelected ? AppColors.activeBackground : AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func v6FilterChip(filter: AnomalyFilterCategory, count: Int, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(filter.rawValue)
                .font(AppFonts.subheadline())
                .tracking(-0.24)
                .foregroundColor(AppColors.fontDefault)

            if count > 0 {
                Text("\(count)")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.dangerDefault)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppColors.dangerBackground)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? AppColors.dangerBackground : AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 7, y: 4)
    }

    private var searchFieldRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            TextField("Search employees", text: $searchText)
                .font(AppFonts.subheadline())
                .focused($isSearchFieldFocused)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.lightBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var contextFiltersMenu: some View {
        Menu {
            if attendanceVersion.usesV6IssueBannerStyle {
                Menu("Issues") {
                    Button {
                        selectedFilters.removeAll()
                    } label: {
                        if selectedFilters.isEmpty {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(sortedFilters, id: \.self) { filter in
                        let isSelected = selectedFilters.contains(filter)
                        Button {
                            if isSelected { selectedFilters.remove(filter) }
                            else { selectedFilters.insert(filter) }
                        } label: {
                            if isSelected {
                                Label(filter.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filter.rawValue)
                            }
                        }
                    }
                }
            }

            if attendanceVersion.usesV6IssueBannerStyle {
                Menu("Department") {
                    Button {
                        selectedDepartments.removeAll()
                    } label: {
                        if selectedDepartments.isEmpty {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(TimeAttendanceMockData.departments, id: \.self) { dept in
                        let isSelected = selectedDepartments.contains(dept)
                        Button {
                            if isSelected { selectedDepartments.remove(dept) }
                            else { selectedDepartments.insert(dept) }
                        } label: {
                            if isSelected {
                                Label(dept, systemImage: "checkmark")
                            } else {
                                Text(dept)
                            }
                        }
                    }
                }
                Menu("Entities") {
                    Button {
                        selectedEntities.removeAll()
                    } label: {
                        if selectedEntities.isEmpty {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(TimeAttendanceMockData.entities, id: \.self) { entity in
                        let isSelected = selectedEntities.contains(entity)
                        Button {
                            if isSelected { selectedEntities.remove(entity) }
                            else { selectedEntities.insert(entity) }
                        } label: {
                            if isSelected {
                                Label(entity, systemImage: "checkmark")
                            } else {
                                Text(entity)
                            }
                        }
                    }
                }
            } else {
                Section("Department") {
                    Button("All") { selectedDepartments.removeAll() }
                    ForEach(TimeAttendanceMockData.departments, id: \.self) { dept in
                        let isSelected = selectedDepartments.contains(dept)
                        Button {
                            if isSelected { selectedDepartments.remove(dept) }
                            else { selectedDepartments.insert(dept) }
                        } label: {
                            if isSelected {
                                Label(dept, systemImage: "checkmark")
                            } else {
                                Text(dept)
                            }
                        }
                    }
                }
                Section("Entities") {
                    Button("All") { selectedEntities.removeAll() }
                    ForEach(TimeAttendanceMockData.entities, id: \.self) { entity in
                        let isSelected = selectedEntities.contains(entity)
                        Button {
                            if isSelected { selectedEntities.remove(entity) }
                            else { selectedEntities.insert(entity) }
                        } label: {
                            if isSelected {
                                Label(entity, systemImage: "checkmark")
                            } else {
                                Text(entity)
                            }
                        }
                    }
                }
            }
        } label: {
            filterIconLabel
        }
    }

    private var hasAnyActiveFilter: Bool {
        hasActiveContextFilters || !selectedFilters.isEmpty
    }

    private var filterIconLabel: some View {
        let isActive = attendanceVersion.usesV6IssueBannerStyle ? hasAnyActiveFilter : hasActiveContextFilters
        return Image(systemName: "slider.horizontal.3")
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(isActive ? AppColors.primaryDark : AppColors.fontSecondary)
            .frame(width: 40, height: 40)
            .background(isActive ? AppColors.activeBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
    }

}

// MARK: - Attendance Filter Sheet (Figma 384-15252)

private enum FilterPage: Hashable {
    case issues
    case department
    case entities
}

struct AttendanceFilterSheet: View {
    @Binding var selectedFilters: Set<AnomalyFilterCategory>
    @Binding var selectedDepartments: Set<String>
    @Binding var selectedEntities: Set<String>
    @Binding var searchText: String
    var resultCount: Int
    @Environment(\.dismiss) private var dismiss
    @State private var path: [FilterPage] = []
    @State private var subSearch: String = ""

    private var hasActiveFilters: Bool {
        !selectedFilters.isEmpty || !selectedDepartments.isEmpty || !selectedEntities.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            filterRoot
                .navigationBarHidden(true)
                .navigationDestination(for: FilterPage.self) { page in
                    switch page {
                    case .issues:     issuesPage
                    case .department: departmentPage
                    case .entities:   entitiesPage
                    }
                }
        }
    }

    // MARK: Root

    private var filterRoot: some View {
        VStack(spacing: 0) {
            filterHeader(
                leading: .close,
                title: "Filters",
                clearLabel: "Clear all",
                clearDisabled: !hasActiveFilters,
                showsSearch: true,
                searchBinding: $searchText
            ) {
                selectedFilters.removeAll()
                selectedDepartments.removeAll()
                selectedEntities.removeAll()
                searchText = ""
            }
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    drillInRow("Attendance issues", selection: attendanceIssuesSelection) {
                        subSearch = ""
                        path.append(.issues)
                    }
                    drillInRow("Department", selection: departmentSelection) {
                        subSearch = ""
                        path.append(.department)
                    }
                    drillInRow("Entities", selection: entitiesSelection) {
                        subSearch = ""
                        path.append(.entities)
                    }
                }
            }
            Spacer()
            showResultsCTA
        }
        .background(Color.white)
    }

    private var showResultsCTA: some View {
        primaryButton("Show \(resultCount) results") { dismiss() }
    }

    // MARK: Issues drill-in (Figma 384-15775)

    private var issuesPage: some View {
        let sortedFilters = AnomalyFilterCategory.allCases.filter { $0 != .onTrack }
        let filtered = subSearch.isEmpty ? sortedFilters : sortedFilters.filter {
            $0.rawValue.localizedCaseInsensitiveContains(subSearch)
        }
        return VStack(spacing: 0) {
            filterHeader(
                leading: .back,
                title: "Attendance issues",
                clearLabel: "Clear",
                clearDisabled: selectedFilters.isEmpty,
                showsSearch: true,
                searchBinding: $subSearch
            ) {
                selectedFilters.removeAll()
            }
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered, id: \.self) { category in
                        let isSelected = selectedFilters.contains(category)
                        selectableRow(category.rawValue, isSelected: isSelected) {
                            if isSelected { selectedFilters.remove(category) }
                            else { selectedFilters.insert(category) }
                        }
                    }
                }
            }
            Spacer()
            showResultsCTA
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: Department drill-in

    private var departmentPage: some View {
        let depts = TimeAttendanceMockData.departments
        let filtered = subSearch.isEmpty ? depts : depts.filter {
            $0.localizedCaseInsensitiveContains(subSearch)
        }
        return VStack(spacing: 0) {
            filterHeader(
                leading: .back,
                title: "Department",
                clearLabel: "Clear",
                clearDisabled: selectedDepartments.isEmpty,
                showsSearch: true,
                searchBinding: $subSearch
            ) {
                selectedDepartments.removeAll()
            }
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered, id: \.self) { dept in
                        let isSelected = selectedDepartments.contains(dept)
                        selectableRow(dept, isSelected: isSelected) {
                            if isSelected { selectedDepartments.remove(dept) }
                            else { selectedDepartments.insert(dept) }
                        }
                    }
                }
            }
            Spacer()
            showResultsCTA
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: Entities drill-in

    private var entitiesPage: some View {
        let entities = TimeAttendanceMockData.entities
        let filtered = subSearch.isEmpty ? entities : entities.filter {
            $0.localizedCaseInsensitiveContains(subSearch)
        }
        return VStack(spacing: 0) {
            filterHeader(
                leading: .back,
                title: "Entities",
                clearLabel: "Clear",
                clearDisabled: selectedEntities.isEmpty,
                showsSearch: true,
                searchBinding: $subSearch
            ) {
                selectedEntities.removeAll()
            }
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered, id: \.self) { entity in
                        let isSelected = selectedEntities.contains(entity)
                        selectableRow(entity, isSelected: isSelected) {
                            if isSelected { selectedEntities.remove(entity) }
                            else { selectedEntities.insert(entity) }
                        }
                    }
                }
            }
            Spacer()
            showResultsCTA
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: Shared components

    private enum LeadingAction { case close, back }

    private func filterHeader(
        leading: LeadingAction,
        title: String,
        clearLabel: String,
        clearDisabled: Bool,
        showsSearch: Bool,
        searchBinding: Binding<String>,
        clearAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                GlassSymbolButton(
                    systemName: leading == .close ? "xmark" : "chevron.left",
                    fontWeight: .medium,
                    accessibilityLabel: leading == .close ? "Close" : "Back"
                ) {
                    switch leading {
                    case .close: dismiss()
                    case .back:  path.removeLast()
                    }
                }
                .frame(width: 85, alignment: .leading)

                Spacer(minLength: 0)

                Button(action: clearAction) {
                    Text(clearLabel)
                        .font(.system(size: 17, weight: .medium))
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                        .frame(height: GlassSymbolButton.size)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .foregroundStyle(clearDisabled ? Color(hex: "BFBFBF") : AppColors.fontDefault)
                .disabled(clearDisabled)
                .fixedSize(horizontal: true, vertical: false)
            }
            .overlay {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if showsSearch {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.fontSecondary)
                    TextField("Search", text: searchBinding)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.fontDefault)
                }
                .padding(10)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(AppColors.surface)
    }

    private var attendanceIssuesSelection: DrillInSelectionState {
        if selectedFilters.isEmpty { return .none }
        if selectedFilters == AnomalyFilterCategory.allIssues { return .all }
        return .partial
    }

    private var departmentSelection: DrillInSelectionState {
        if selectedDepartments.isEmpty { return .none }
        if selectedDepartments == Set(TimeAttendanceMockData.departments) { return .all }
        return .partial
    }

    private var entitiesSelection: DrillInSelectionState {
        if selectedEntities.isEmpty { return .none }
        if selectedEntities == Set(TimeAttendanceMockData.entities) { return .all }
        return .partial
    }

    private enum DrillInSelectionState {
        case none, partial, all
    }

    private func drillInRow(_ title: String, selection: DrillInSelectionState, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    switch selection {
                    case .none:
                        EmptyView()
                    case .partial:
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.fontDefault)
                    case .all:
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.fontDefault)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.fontSecondary)
                        .padding(4)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                Divider()
            }
        }
        .buttonStyle(.plain)
    }

    private func selectableRow(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    Text(label)
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.fontDefault)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                Divider()
            }
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [.white, .white.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 120)
            .allowsHitTesting(false),
            alignment: .bottom
        )
    }
}

// MARK: - Employee row status (pills vs progress bars)

/// V3 — anomaly label + scheduled/worked progress bar (pre-pill list UI).
struct EmployeeAnomalyProgressStatus: View {
    let employee: EmployeeAnomaly

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showsAnomalyLabel {
                Text(employee.anomalyType.rawValue)
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(employee.anomalyType.pillStyle.badgeTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(employee.anomalyType.pillStyle.pillBackground)
                    .clipShape(Capsule())
            }

            AnomalyProgressBar(
                scheduledHours: employee.scheduledHours,
                workedHours: employee.workedHours,
                anomalyType: employee.anomalyType
            )
        }
    }

    private var showsAnomalyLabel: Bool {
        guard employee.anomalyType != .onTrack, employee.anomalyType != .scheduleNotStarted else {
            return false
        }
        if employee.anomalyType == .noClockIn, employee.hasScheduleIcon {
            return false
        }
        return true
    }
}

private struct AnomalyProgressBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var fillRatio: Double {
        guard scheduledHours > 0 else { return 0 }
        return workedHours / scheduledHours
    }

    private var hoursLabel: String {
        if workedHours == 0 { return "0h / \(formatted(scheduledHours))h" }
        return "\(formatted(workedHours))h / \(formatted(scheduledHours))h"
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private var maxRatio: Double {
        fillRatio > 1.0 ? min(fillRatio, 1.5) : 1.0
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(hoursLabel)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.07)
                .fixedSize()

            GeometryReader { geo in
                let trackWidth = geo.size.width
                let scheduledWidth = trackWidth / maxRatio
                let filledWidth = trackWidth * min(fillRatio, maxRatio) / maxRatio

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(AppColors.informativeBackground)
                        .frame(width: scheduledWidth, height: 4)

                    if filledWidth > 0 {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.informativeDefault)
                            .frame(width: min(filledWidth, scheduledWidth), height: 4)
                    }

                    if fillRatio > 1.0 {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.warningText)
                            .frame(width: filledWidth - scheduledWidth, height: 4)
                            .offset(x: scheduledWidth)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 4)
        }
    }
}

// MARK: - V4 employee issue banner (Figma 15509:62644)

/// V4 — full-width issue banner below name/role (replaces issue pills).
struct EmployeeAnomalyV4IssueBanner: View {
    let employee: EmployeeAnomaly

    private var hoursModel: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(
            scheduledHours: employee.scheduledHours,
            workedHours: employee.workedHours,
            anomalyType: employee.anomalyType
        )
    }

    private var bannerColor: Color {
        employee.anomalyType.isWarningLevel ? AppColors.warningDefault : AppColors.dangerDefault
    }

    static func showsBanner(for employee: EmployeeAnomaly) -> Bool {
        switch employee.anomalyType {
        case .onTrack, .scheduleNotStarted:
            return false
        case .noClockIn:
            return !employee.hasScheduleIcon
        case .noClockInNorOut, .missedClockOut, .exceededWorkSchedule, .workedLess, .late, .exceededHours, .unplanned:
            return true
        }
    }

    var body: some View {
        if Self.showsBanner(for: employee) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 4) {
                    Image(iconAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(bannerColor)

                    Text(employee.anomalyType.rawValue)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(bannerColor)
                        .tracking(-0.08)
                }

                Spacer(minLength: 8)

                Text(bannerHoursValue)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(bannerColor)
                    .tracking(-0.08)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surfaceDarker)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hoursModel.accessibilitySummary)
        }
    }

    private var iconAssetName: String {
        switch employee.anomalyType {
        case .exceededWorkSchedule, .workedLess:
            return "icon-attendance-exceeded"
        case .noClockIn:
            return "icon-close"
        case .noClockInNorOut, .missedClockOut:
            return "icon-attendance-missed-clock-in"
        case .late, .exceededHours, .unplanned:
            return "icon-attendance-exceeded"
        case .onTrack, .scheduleNotStarted:
            return "icon-close"
        }
    }

    private var bannerHoursValue: String {
        switch employee.anomalyType {
        case .noClockIn, .noClockInNorOut, .missedClockOut:
            return "0h"
        case .exceededWorkSchedule, .exceededHours, .workedLess:
            return hoursModel.gapDisplayText
        case .late, .unplanned, .onTrack, .scheduleNotStarted:
            return ""
        }
    }
}

/// V5 — colored pill banners: centered label, hours inline, type-tinted background.
struct EmployeeAnomalyV5IssueBanner: View {
    let employee: EmployeeAnomaly
    var isPastDate: Bool = false

    private var hoursModel: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(
            scheduledHours: employee.scheduledHours,
            workedHours: employee.workedHours,
            anomalyType: employee.anomalyType
        )
    }

    private var bannerColor: Color {
        employee.anomalyType.isWarningLevel ? AppColors.warningDefault : AppColors.dangerDefault
    }

    private var bannerBackground: Color {
        employee.anomalyType.isWarningLevel ? AppColors.warningBackground : AppColors.dangerBackground
    }

    static func showsBanner(for employee: EmployeeAnomaly) -> Bool {
        EmployeeAnomalyV4IssueBanner.showsBanner(for: employee)
    }

    private var bannerLabel: String {
        let base: String
        if isPastDate && employee.anomalyType == .exceededWorkSchedule {
            base = AnomalyType.exceededHours.rawValue
        } else {
            base = employee.anomalyType.rawValue
        }
        switch employee.anomalyType {
        case .exceededWorkSchedule, .exceededHours, .workedLess:
            let gap = hoursModel.gapDisplayText
            return gap.isEmpty ? base : "\(base) (\(gap))"
        default:
            return base
        }
    }

    var body: some View {
        if Self.showsBanner(for: employee) {
            Text(bannerLabel)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(bannerColor)
                .tracking(-0.08)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(bannerBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel(hoursModel.accessibilitySummary)
        }
    }
}

/// V6 — left-aligned issue label + right-aligned schedule/time, per-type backgrounds.
struct EmployeeAnomalyV6IssueBanner: View {
    let employee: EmployeeAnomaly
    var isPastDate: Bool = false

    private var hoursModel: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(
            scheduledHours: employee.scheduledHours,
            workedHours: employee.workedHours,
            anomalyType: employee.anomalyType
        )
    }

    private var bannerBackground: Color {
        AppColors.dangerBackground
    }

    private var showsBanner: Bool {
        switch employee.anomalyType {
        case .scheduleNotStarted, .onTrack:
            return false
        case .noClockIn:
            return !employee.hasScheduleIcon
        default:
            return true
        }
    }

    private var issueLabel: String? {
        switch employee.anomalyType {
        case .noClockIn:
            return "No attendance"
        case .noClockInNorOut:
            return "Missed clock-in"
        case .missedClockOut:
            return "Missed clock-out"
        case .exceededWorkSchedule, .exceededHours:
            let gap = hoursModel.gapDisplayText
            return gap.isEmpty ? employee.anomalyType.rawValue : "\(employee.anomalyType.rawValue) by \(gap.replacingOccurrences(of: "+", with: ""))"
        case .workedLess:
            let gap = hoursModel.gapMagnitudeDisplayText
            return gap.isEmpty || gap == "0h" ? "Worked less" : "Worked \(gap) less"
        case .late:
            let dev = hoursModel.lateDeviationText.replacingOccurrences(of: "+", with: "")
            return dev.isEmpty ? "Late arrival" : "Late by \(dev)"
        case .unplanned:
            return employee.anomalyType.rawValue
        case .onTrack, .scheduleNotStarted:
            return nil
        }
    }

    private var timeText: String {
        if let range = employee.scheduleTimeRange {
            switch employee.anomalyType {
            case .exceededWorkSchedule:
                return range
            case .exceededHours:
                let gap = hoursModel.gapDisplayText
                return gap.isEmpty ? range : "\(range) (\(gap))"
            case .late:
                return range
            default:
                return range
            }
        }
        return ""
    }

    var body: some View {
        if showsBanner, let label = issueLabel {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppColors.dangerDefault)
                .tracking(-0.08)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            .background(bannerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

/// V7/V8 — issue as an inline pill on the right side of the row.
struct EmployeeAnomalyV7IssuePill: View {
    let employee: EmployeeAnomaly
    var allDangerStyle: Bool = false

    private var hoursModel: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(
            scheduledHours: employee.scheduledHours,
            workedHours: employee.workedHours,
            anomalyType: employee.anomalyType
        )
    }

    static func showsPill(for employee: EmployeeAnomaly) -> Bool {
        switch employee.anomalyType {
        case .scheduleNotStarted, .onTrack:
            return false
        case .noClockIn:
            return !employee.hasScheduleIcon
        default:
            return true
        }
    }

    private var pillLabel: String {
        Self.pillLabel(for: employee, anomalyType: employee.anomalyType)
    }

    private var pillTextColor: Color {
        allDangerStyle ? AppColors.dangerDefault : (employee.anomalyType.isWarningLevel ? AppColors.warningDefault : AppColors.dangerDefault)
    }

    private var pillBackground: Color {
        allDangerStyle ? AppColors.dangerBackground : (employee.anomalyType.isWarningLevel ? AppColors.warningBackground : AppColors.dangerBackground)
    }

    var body: some View {
        if Self.showsPill(for: employee) {
            Text(pillLabel)
                .font(AppFonts.subheadStrong())
                .foregroundColor(pillTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(pillBackground)
                .clipShape(Capsule())
                .fixedSize()
                .accessibilityLabel(hoursModel.accessibilitySummary)
        }
    }

    static func pillLabel(for employee: EmployeeAnomaly, anomalyType: AnomalyType) -> String {
        let model = HoursBalanceCapsuleModel(
            scheduledHours: employee.scheduledHours,
            workedHours: employee.workedHours,
            anomalyType: anomalyType
        )
        switch anomalyType {
        case .noClockIn: return "No attendance"
        case .noClockInNorOut: return "Missed clock-in"
        case .missedClockOut: return "Missed clock-out"
        case .exceededWorkSchedule:
            let gap = model.gapDisplayText.replacingOccurrences(of: "+", with: "")
            return gap.isEmpty ? "Exceeding" : "Exceeding by \(gap)"
        case .exceededHours:
            let gap = model.gapDisplayText.replacingOccurrences(of: "+", with: "")
            return gap.isEmpty ? "Exceeded" : "Exceeded by \(gap)"
        case .late:
            let dev = model.lateDeviationText.replacingOccurrences(of: "+", with: "")
            return dev.isEmpty ? "Late arrival" : "Late by \(dev)"
        case .unplanned: return "Unplanned"
        case .workedLess:
            let gap = model.gapMagnitudeDisplayText
            return gap.isEmpty || gap == "0h" ? "Worked less" : "Worked \(gap) less"
        case .onTrack, .scheduleNotStarted: return ""
        }
    }
}

/// V7/V8 — stacked inline pills when an employee has multiple issues (Figma 390-15756).
struct EmployeeAnomalyV7MultipleIssuePills: View {
    let employee: EmployeeAnomaly
    var allDangerStyle: Bool = false

    private func pillStyle(for anomalyType: AnomalyType) -> (text: Color, background: Color) {
        if allDangerStyle {
            return (AppColors.dangerDefault, AppColors.dangerBackground)
        }
        if anomalyType.isWarningLevel {
            return (AppColors.warningDefault, AppColors.warningBackground)
        }
        return (AppColors.dangerDefault, AppColors.dangerBackground)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            let primary = EmployeeAnomalyV7IssuePill.pillLabel(for: employee, anomalyType: employee.anomalyType)
            let primaryStyle = pillStyle(for: employee.anomalyType)
            Text(primary)
                .font(AppFonts.subheadStrong())
                .foregroundColor(primaryStyle.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(primaryStyle.background)
                .clipShape(Capsule())
                .fixedSize()

            if let secondary = employee.secondaryIssueLabel {
                Text(secondary)
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.dangerDefault)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppColors.dangerBackground)
                    .clipShape(Capsule())
                    .fixedSize()
            }
        }
    }
}

/// V1/V2 — issue / hour capsules on employee rows.
struct EmployeeAnomalyStatusPills: View {
    let employee: EmployeeAnomaly

    private var hoursCapsuleModel: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(
            scheduledHours: employee.scheduledHours,
            workedHours: employee.workedHours,
            anomalyType: employee.anomalyType
        )
    }

    var body: some View {
        Group {
            switch employee.anomalyType {
            case .noClockIn:
                if employee.hasScheduleIcon {
                    EmptyView()
                } else {
                    Text(employee.anomalyType.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.dangerDefault)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(AppColors.dangerBackground)
                        .clipShape(Capsule())
                }

            case .noClockInNorOut, .missedClockOut, .exceededWorkSchedule, .workedLess:
                let model = hoursCapsuleModel
                HStack(alignment: .center, spacing: 8) {
                    if model.showsCapsule {
                        Text(model.gapDisplayText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(-0.2)
                            .foregroundColor(AppColors.dangerDefault)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(AppColors.dangerBackground)
                            .clipShape(Capsule())
                    }

                    Text(employee.anomalyType.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.fontSecondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(AppColors.lightBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(AppColors.separator.opacity(0.35), lineWidth: 0.5)
                        )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(model.showsCapsule ? model.accessibilitySummary : employee.anomalyType.rawValue)

            case .late, .exceededHours, .unplanned:
                Text(employee.anomalyType.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.warningDefault)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(AppColors.warningBackground)
                    .clipShape(Capsule())

            case .onTrack, .scheduleNotStarted:
                EmptyView()
            }
        }
    }
}

// MARK: - Employee Anomaly Row

struct EmployeeAnomalyRow: View {
    let employee: EmployeeAnomaly

    var onBellTapped: (() -> Void)? = nil
    @Binding var isNotified: Bool
    var isSelectionMode: Bool = false
    var isSelectedForNotification: Bool = false
    /// Past-date rows keep issue banners but hide all actionable controls (bell, selection).
    var isActionable: Bool = true
    /// FAB mode hides inline bell controls; notifications happen via swipe or bulk selection.
    var hidesBellForFab: Bool = false
    /// Replaces schedule subtitle with "Notified Xm ago" in FAB selection mode.
    var lastNotifiedText: String?

    /// Trailing slot (bell / checkmark) — fixed size so layout does not shift in selection mode.
    private static let bellSlotDiameter: CGFloat = 36
    private static let bellIconSize: CGFloat = 16
    private static let selectionIconSize: CGFloat = 22

    @Environment(\.attendanceUIVersion) private var attendanceUIVersion
    @State private var bellRingRotation: Double = 0
    @State private var bellRingScale: CGFloat = 1
    @State private var showsNotifiedLabel = false
    @State private var notifiedLabelHideTask: Task<Void, Never>?

    /// V2/V3 — checkmarks in the bell slot; V1 & FAB mode — checkmarks replace the avatar.
    private var usesBellSlotSelection: Bool {
        isActionable && isSelectionMode && attendanceUIVersion.usesModernAttendanceChrome && !hidesBellForFab
    }

    private var usesAvatarSlotSelection: Bool {
        isActionable && isSelectionMode && (!attendanceUIVersion.usesModernAttendanceChrome || hidesBellForFab)
    }

    private var hasNotifyBellSlot: Bool {
        isActionable
            && employee.anomalyType != .onTrack && employee.anomalyType != .scheduleNotStarted
            && !employee.anomalyType.isWarningLevel
    }

    private var showsNotifyBell: Bool {
        !isSelectionMode && hasNotifyBellSlot && !hidesBellForFab
    }

    var body: some View {
        Group {
            if attendanceUIVersion.usesV4EmployeeCardStatus {
                v4RowBody
            } else {
                legacyRowBody
            }
        }
        .onDisappear {
            notifiedLabelHideTask?.cancel()
        }
    }

    private var v4RowBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            if attendanceUIVersion.usesV7InlinePillStyle && employee.hasMultipleIssuePills {
                HStack(alignment: .top, spacing: 12) {
                    if usesAvatarSlotSelection {
                        selectionControl(diameter: avatarDiameter, iconSize: avatarDiameter * 0.5)
                    } else {
                        avatarView
                    }

                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(employee.name)
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)

                            if let label = employee.scheduleTimeLabel {
                                Text(label)
                                    .font(AppFonts.footnote())
                                    .foregroundColor(AppColors.fontSecondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 0)

                        EmployeeAnomalyV7MultipleIssuePills(
                            employee: employee,
                            allDangerStyle: attendanceUIVersion.usesCompactAvatar
                        )
                    }

                    if usesBellSlotSelection && hasNotifyBellSlot {
                        selectionControl(diameter: Self.bellSlotDiameter, iconSize: Self.selectionIconSize)
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    if usesAvatarSlotSelection {
                        selectionControl(diameter: avatarDiameter, iconSize: avatarDiameter * 0.5)
                    } else {
                        avatarView
                    }

                    Text(employee.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if attendanceUIVersion.usesV7InlinePillStyle {
                        EmployeeAnomalyV7IssuePill(employee: employee, allDangerStyle: attendanceUIVersion.usesCompactAvatar)
                    }

                    if usesBellSlotSelection && hasNotifyBellSlot {
                        selectionControl(diameter: Self.bellSlotDiameter, iconSize: Self.selectionIconSize)
                    }
                }

                Group {
                    if attendanceUIVersion.usesV6IssueBannerStyle {
                        if let label = employee.scheduleTimeLabel {
                            if let notified = lastNotifiedText {
                                Text("\(label) · \(Image(systemName: "bell.fill")) \(notified)")
                                    .font(AppFonts.footnote())
                                    .foregroundColor(AppColors.fontSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else {
                                Text(label)
                                    .font(AppFonts.footnote())
                                    .foregroundColor(AppColors.fontSecondary)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        Text(employee.role)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                .padding(.leading, avatarDiameter + 12)

                if !attendanceUIVersion.usesV7InlinePillStyle {
                    if attendanceUIVersion.usesV6IssueBannerStyle {
                        EmployeeAnomalyV6IssueBanner(employee: employee, isPastDate: !isActionable)
                    } else if attendanceUIVersion.usesV5IssueBannerStyle {
                        EmployeeAnomalyV5IssueBanner(employee: employee, isPastDate: !isActionable)
                    } else {
                        EmployeeAnomalyV4IssueBanner(employee: employee)
                    }
                }
            }

            if showsNotifyBell {
                HStack {
                    Spacer()
                    notifyBellControlV2
                }
                .padding(.top, -2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var legacyRowBody: some View {
        HStack(alignment: .top, spacing: 12) {
            if usesAvatarSlotSelection {
                selectionControl(diameter: avatarDiameter, iconSize: avatarDiameter * 0.5)
            } else {
                avatarView
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(employee.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)

                Text(employee.role)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)

                if attendanceUIVersion.usesProgressBarEmployeeStatus {
                    EmployeeAnomalyProgressStatus(employee: employee)
                } else {
                    EmployeeAnomalyStatusPills(employee: employee)
                }
            }

            Spacer(minLength: 0)

            if usesBellSlotSelection && hasNotifyBellSlot {
                selectionControl(diameter: Self.bellSlotDiameter, iconSize: Self.selectionIconSize)
            } else if showsNotifyBell {
                if attendanceUIVersion.usesModernAttendanceChrome {
                    Color.clear
                        .frame(width: Self.bellSlotDiameter, height: Self.bellSlotDiameter)
                        .overlay(alignment: .trailing) {
                            notifyBellControlV2
                        }
                        .zIndex(1)
                } else {
                    notifyBellControlV1
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var notifyBellControlV1: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isNotified.toggle()
            }
            onBellTapped?()
        } label: {
            Image(systemName: isNotified ? "bell.fill" : "bell")
                .font(.system(size: Self.bellIconSize, weight: .semibold))
                .foregroundColor(AppColors.primaryDark)
                .frame(width: Self.bellSlotDiameter, height: Self.bellSlotDiameter)
                .background(
                    Circle()
                        .fill(isNotified ? AppColors.successBackground : .white)
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 0.5)
                )
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: Self.bellSlotDiameter, height: Self.bellSlotDiameter)
                )
                .scaleEffect(bellRingScale)
                .rotationEffect(.degrees(bellRingRotation))
        }
        .buttonStyle(.plain)
        .onChange(of: isNotified) { newValue in
            if newValue {
                playBellNotifyMicroanimation()
            } else {
                withAnimation(.easeOut(duration: 0.18)) {
                    bellRingRotation = 0
                    bellRingScale = 1
                }
            }
        }
    }

    private static let notifyPillExpansionAnimation = Animation.linear(duration: 0.24)
    private static let notifyPillCollapseAnimation = Animation.linear(duration: 0.22)

    private var notifyBellControlV2: some View {
        Button {
            let willNotify = !isNotified
            isNotified.toggle()
            onBellTapped?()
            if willNotify {
                presentNotifiedLabel()
            } else {
                dismissNotifiedLabel(animated: true)
            }
        } label: {
            HStack(spacing: 6) {
                if showsNotifiedLabel {
                    Text("Notified")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.primaryDark)
                        .transition(.opacity)
                }

                Image(systemName: isNotified ? "bell.fill" : "bell")
                    .font(.system(size: Self.bellIconSize, weight: .semibold))
                    .foregroundColor(AppColors.primaryDark)
                    .frame(width: 20, height: 20)
                    .scaleEffect(bellRingScale)
                    .rotationEffect(.degrees(bellRingRotation))
            }
            .padding(.leading, showsNotifiedLabel ? 12 : 8)
            .padding(.trailing, 8)
            .frame(height: Self.bellSlotDiameter)
            .background(notifyBellBackground)
            .overlay(
                Capsule()
                    .stroke(AppColors.separator.opacity(0.6), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .onChange(of: isNotified) { newValue in
            if newValue {
                playBellNotifyMicroanimation()
            } else {
                dismissNotifiedLabel(animated: false)
                withAnimation(.easeOut(duration: 0.18)) {
                    bellRingRotation = 0
                    bellRingScale = 1
                }
            }
        }
    }

    private var notifyBellBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .background(
                Capsule()
                    .fill(
                        (isNotified || showsNotifiedLabel || attendanceUIVersion.usesV5IssueBannerStyle)
                            ? AppColors.successBackground
                            : AppColors.background
                    )
            )
    }

    private func presentNotifiedLabel() {
        notifiedLabelHideTask?.cancel()
        withAnimation(Self.notifyPillExpansionAnimation) {
            showsNotifiedLabel = true
        }

        notifiedLabelHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            dismissNotifiedLabel(animated: true)
        }
    }

    private func dismissNotifiedLabel(animated: Bool) {
        notifiedLabelHideTask?.cancel()
        notifiedLabelHideTask = nil
        guard showsNotifiedLabel else { return }

        if animated {
            withAnimation(Self.notifyPillCollapseAnimation) {
                showsNotifiedLabel = false
            }
        } else {
            showsNotifiedLabel = false
        }
    }

    private func playBellNotifyMicroanimation() {
        bellRingRotation = -14
        bellRingScale = 0.94
        withAnimation(.spring(response: 0.26, dampingFraction: 0.42)) {
            bellRingRotation = 11
            bellRingScale = 1.09
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
                bellRingRotation = -5
                bellRingScale = 1.02
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                bellRingRotation = 0
                bellRingScale = 1
            }
        }
    }

    private func selectionControl(diameter: CGFloat, iconSize: CGFloat) -> some View {
        Group {
            if isSelectedForNotification {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, AppColors.primaryDark)
            } else {
                Image(systemName: "circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(AppColors.separator)
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private var avatarDiameter: CGFloat {
        attendanceUIVersion.usesCompactAvatar ? 30 : 48
    }

    private var avatarView: some View {
        let size = avatarDiameter
        return ZStack(alignment: .bottomTrailing) {
            if let name = employee.avatarName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color(hex: "E8E8ED"))
                        .frame(width: size, height: size)
                    Image(systemName: "person.fill")
                        .font(.system(size: size == 30 ? 14 : 20))
                        .foregroundColor(AppColors.iconDefault)
                }
            }

            if employee.hasScheduleIcon {
                let badgeSize: CGFloat = size == 30 ? 16 : 21
                Image(systemName: "calendar")
                    .font(.system(size: size == 30 ? 7 : 9, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: badgeSize, height: badgeSize)
                    .background(AppColors.fontDefault)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 0.5))
                    .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - Shared Employee-List Content

struct TimeAttendanceAnomaliesListContent: View {
    let employees: [EmployeeAnomaly]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(employees.enumerated()), id: \.element.id) { index, employee in
                    NavigationLink(destination: EmployeeTimeTrackingDetailView(employee: employee)) {
                        EmployeeAnomalyRow(employee: employee, isNotified: .constant(false))
                    }
                    .buttonStyle(.plain)
                    if index < employees.count - 1 {
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(16)
            .padding(.top, 16)
        }
    }
}
