import SwiftUI

// MARK: - Anomaly Type

enum AnomalyType: String, CaseIterable, Identifiable {
    case noClockIn = "No attendance"
    case noClockInNorOut = "Missed clock-in"
    case exceededWorkSchedule = "Exceeded work hours"
    /// Scheduled to work today; shift has not started — not an anomaly.
    case scheduleNotStarted = "Schedule not started"
    case onTrack = "On track"

    var id: String { rawValue }

    var textColor: Color {
        switch self {
        case .noClockIn, .noClockInNorOut:
            return AppColors.dangerDefault
        case .exceededWorkSchedule:
            return AppColors.warningDefault
        case .scheduleNotStarted:
            return AppColors.informativeDefault
        case .onTrack:
            return AppColors.successDefault
        }
    }

    var badgeBackground: Color {
        switch self {
        case .noClockIn, .noClockInNorOut:
            return AppColors.dangerBackground
        case .exceededWorkSchedule:
            return AppColors.warningBackground
        case .scheduleNotStarted:
            return AppColors.informativeBackground
        case .onTrack:
            return AppColors.successBackground
        }
    }
}

// MARK: - Filter Categories (drill-in list)

enum AnomalyFilterCategory: String, CaseIterable, Identifiable {
    case noClockInNorOut = "Missed clock-ins"
    case exceededWorkSchedule = "Exceeded work hours"
    case noClockIn = "No attendance"
    case onTrack = "On track"

    var id: String { rawValue }

    var matchingTypes: Set<AnomalyType> {
        switch self {
        case .noClockIn:              return [.noClockIn]
        case .noClockInNorOut:        return [.noClockInNorOut]
        case .exceededWorkSchedule:   return [.exceededWorkSchedule]
        case .onTrack:                return [.onTrack]
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
        let onTrack = eligible.filter { $0.anomalyType == .onTrack }.count
        return [
            .init(label: "No attendance", count: missedClocks, textColor: AppColors.dangerDefault, matchingFilters: [.noClockIn, .noClockInNorOut]),
            .init(type: .exceededWorkSchedule, count: exceeded),
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
        .init(name: "Kovarek, Tomas",                  role: "Territory Manager",       avatarName: "avatar-tyler",   anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Sales",       workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 0),
        .init(name: "Doe, Joanne",                     role: "Account Manager",         avatarName: "avatar-lucy",    anomalyType: .noClockInNorOut,       hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 0),
        .init(name: "Carty, Joe",                      role: "Operations Engineer",     avatarName: "avatar-abdi",    anomalyType: .noClockIn,             hasScheduleIcon: true,  department: "Operations",  workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 0),
        .init(name: "Gutmann, Elyssa",                 role: "Marketing Director",      avatarName: "avatar-michael", anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Marketing",   workplace: "Remote",    entity: "Workable EU",   scheduledHours: 8, workedHours: 9.5),
        .init(name: "Wilhelham, Minnie Laris Julie",   role: "Sales Consultant",        avatarName: nil,              anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Engineering", workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 10),
        .init(name: "Nguyen, Mai",                     role: "Software Engineer",       avatarName: nil,              anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Engineering", workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 0),
        .init(name: "Petrov, Andrei",                  role: "QA Lead",                 avatarName: "avatar-tyler",   anomalyType: .exceededWorkSchedule,  hasScheduleIcon: true,  department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 11),
        .init(name: "Santos, Maria",                   role: "Customer Success Manager",avatarName: "avatar-lucy",    anomalyType: .onTrack,               hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 7.5),
        .init(name: "Müller, Hans",                    role: "Finance Analyst",         avatarName: nil,              anomalyType: .onTrack,               hasScheduleIcon: false, department: "Operations",  workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 6),
        .init(name: "Chen, Wei",                       role: "Product Designer",        avatarName: "avatar-abdi",    anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Engineering", workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 9),
        .init(name: "Okafor, Chidi",                   role: "DevOps Engineer",         avatarName: nil,              anomalyType: .noClockInNorOut,       hasScheduleIcon: true,  department: "Engineering", workplace: "Remote",    entity: "Workable UK",   scheduledHours: 8, workedHours: 0),
        .init(name: "Johansson, Erik",                 role: "Sales Director",          avatarName: "avatar-michael", anomalyType: .onTrack,               hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 8),
        .init(name: "Patel, Priya",                    role: "HR Business Partner",     avatarName: nil,              anomalyType: .onTrack,               hasScheduleIcon: false, department: "Operations",  workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 7),
        .init(name: "Kim, Soo-Jin",                    role: "Content Strategist",      avatarName: "avatar-lucy",    anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Marketing",   workplace: "Remote",    entity: "Workable EU",   scheduledHours: 8, workedHours: 10.5),
        .init(name: "Rossi, Luca",                     role: "Backend Developer",       avatarName: nil,              anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 0),
        .init(name: "Barnes, Alex",                    role: "Product Manager",         avatarName: "avatar-michael", anomalyType: .scheduleNotStarted,   hasScheduleIcon: false, department: "Engineering", workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 0),
        .init(name: "Lindqvist, Nora",                 role: "UX Researcher",           avatarName: "avatar-emma",    anomalyType: .scheduleNotStarted,   hasScheduleIcon: false, department: "Marketing",   workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 0),
    ]

    /// Order matches Figma Direct reports (15276-14308).
    static var directReportsInFigmaOrder: [EmployeeAnomaly] {
        let order = ["Doe, Joanne", "Gutmann, Elyssa", "Carty, Joe"]
        return order.compactMap { name in employees.first { $0.name == name } }
    }
}

// MARK: - Filtering helper

extension Array where Element == EmployeeAnomaly {
    func filtered(
        by categories: Set<AnomalyFilterCategory>,
        department: String? = nil,
        entity: String? = nil
    ) -> [EmployeeAnomaly] {
        var result = self
        if !categories.isEmpty {
            let matching = categories.reduce(into: Set<AnomalyType>()) { $0.formUnion($1.matchingTypes) }
            result = result.filter { matching.contains($0.anomalyType) }
        }
        if let department, !department.isEmpty {
            result = result.filter { $0.department == department }
        }
        if let entity, !entity.isEmpty {
            result = result.filter { $0.entity == entity }
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

// MARK: - Department / Entity filters (shared menu content)

struct DepartmentEntityFilterMenuContent: View {
    @Binding var selectedDepartment: String?
    @Binding var selectedEntity: String?

    var body: some View {
        Section("Department") {
            Button("All") { selectedDepartment = nil }
            ForEach(TimeAttendanceMockData.departments, id: \.self) { dept in
                Button {
                    selectedDepartment = dept
                } label: {
                    if selectedDepartment == dept {
                        Label(dept, systemImage: "checkmark")
                    } else {
                        Text(dept)
                    }
                }
            }
        }
        Section("Entities") {
            Button("All") { selectedEntity = nil }
            ForEach(TimeAttendanceMockData.entities, id: \.self) { entity in
                Button {
                    selectedEntity = entity
                } label: {
                    if selectedEntity == entity {
                        Label(entity, systemImage: "checkmark")
                    } else {
                        Text(entity)
                    }
                }
            }
        }
    }
}

// MARK: - Anomaly Filter Bar (horizontal scrolling chips)

struct AnomalyFilterBar: View {
    @Binding var selectedFilters: Set<AnomalyFilterCategory>
    @Binding var searchText: String
    @FocusState.Binding var searchFieldFocused: Bool
    var filterCounts: [AnomalyFilterCategory: Int] = [:]
    var isSearchRowVisible: Bool = true

    private var sortedFilters: [AnomalyFilterCategory] {
        AnomalyFilterCategory.allCases
    }

    var body: some View {
        VStack(spacing: 0) {
            if isSearchRowVisible {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.iconDefault)
                    TextField("Search", text: $searchText)
                        .font(AppFonts.subheadline())
                        .focused($searchFieldFocused)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.iconDefault)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(AppColors.lightBackground)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
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
                            Text("\(filter.rawValue) (\(count))")
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(isSelected ? AppColors.fontDefault : AppColors.fontSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(isSelected ? AppColors.lightBackground : AppColors.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(isSelected ? AppColors.fontSecondary : AppColors.separator, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, isSearchRowVisible ? 4 : 12)
                .padding(.bottom, 12)
            }
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

}

// MARK: - Employee Anomaly Row

struct EmployeeAnomalyRow: View {
    let employee: EmployeeAnomaly

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            avatarView

            VStack(alignment: .leading, spacing: 6) {
                Text(employee.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)

                Text(employee.role)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)

                if employee.anomalyType != .onTrack && employee.anomalyType != .scheduleNotStarted {
                    Text(employee.anomalyType.rawValue)
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.fontSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.lightBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(AppColors.separator, lineWidth: 1)
                        )
                        .cornerRadius(4)
                }

                if employee.anomalyType != .scheduleNotStarted {
                    AnomalyProgressBar(
                        scheduledHours: employee.scheduledHours,
                        workedHours: employee.workedHours,
                        anomalyType: employee.anomalyType
                    )
                    .padding(.trailing, 16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(Color(hex: "E8E8ED"))
                    .frame(width: 48, height: 48)
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.iconDefault)
            }

            if employee.hasScheduleIcon {
                Image(systemName: "calendar")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(AppColors.fontSecondary)
                    .clipShape(Circle())
                    .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - Anomaly Progress Bar

private struct AnomalyProgressBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var fillRatio: Double {
        guard scheduledHours > 0 else { return 0 }
        return workedHours / scheduledHours
    }

    private var barColor: Color {
        anomalyType.textColor
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
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let scheduledWidth = trackWidth / maxRatio
                let filledWidth = trackWidth * min(fillRatio, maxRatio) / maxRatio

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(AppColors.separator)
                        .frame(width: scheduledWidth, height: 4)

                    if filledWidth > 0 {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.fontSecondary)
                            .frame(width: min(filledWidth, scheduledWidth), height: 4)
                    }

                    if fillRatio > 1.0 {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.fontSecondary.opacity(0.4))
                            .frame(width: filledWidth - scheduledWidth, height: 4)
                            .offset(x: scheduledWidth)
                    }
                }
            }
            .frame(height: 4)

            Text(hoursLabel)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.07)
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
                        EmployeeAnomalyRow(employee: employee)
                    }
                    .buttonStyle(.plain)
                    if index < employees.count - 1 {
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(16)
            .padding(.top, 16)
        }
    }
}
