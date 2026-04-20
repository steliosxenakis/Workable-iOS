import SwiftUI

// MARK: - Anomaly Type

enum AnomalyType: String, CaseIterable, Identifiable {
    case noClockIn = "No clock in"
    case noClockInNorOut = "No clock in nor out"
    case exceededWorkSchedule = "Exceeded work schedule"
    case onTrack = "On track"

    var id: String { rawValue }

    var textColor: Color {
        switch self {
        case .noClockIn, .noClockInNorOut:
            return AppColors.dangerDefault
        case .exceededWorkSchedule:
            return AppColors.warningDefault
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
        case .onTrack:
            return AppColors.successBackground
        }
    }
}

// MARK: - Filter Categories (drill-in list)

enum AnomalyFilterCategory: String, CaseIterable, Identifiable {
    case noClockIn = "No clock in"
    case noClockInNorOut = "No clock in nor out"
    case exceededWorkSchedule = "Exceeded work schedule"
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
    static let summaryItems: [AnomalySummaryItem] = [
        .init(label: "Missed clocks", count: 4, textColor: AppColors.dangerDefault, matchingFilters: [.noClockIn, .noClockInNorOut]),
        .init(type: .exceededWorkSchedule, count: 3),
        .init(type: .onTrack, count: 18),
    ]

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
        .init(name: "Wilhelham, Minnie Laris Julie",   role: "Sales Consultant",        avatarName: "avatar-grace",   anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Engineering", workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 10),
        .init(name: "Nguyen, Mai",                     role: "Software Engineer",       avatarName: "avatar-sophia",  anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Engineering", workplace: "Remote",    entity: "Workable Inc.", scheduledHours: 8, workedHours: 0),
        .init(name: "Petrov, Andrei",                  role: "QA Lead",                 avatarName: "avatar-tyler",   anomalyType: .exceededWorkSchedule,  hasScheduleIcon: true,  department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 11),
        .init(name: "Santos, Maria",                   role: "Customer Success Manager",avatarName: "avatar-lucy",    anomalyType: .onTrack,               hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 7.5),
        .init(name: "Müller, Hans",                    role: "Finance Analyst",         avatarName: "avatar-jamal",   anomalyType: .onTrack,               hasScheduleIcon: false, department: "Operations",  workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 6),
        .init(name: "Chen, Wei",                       role: "Product Designer",        avatarName: "avatar-abdi",    anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Engineering", workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 9),
        .init(name: "Okafor, Chidi",                   role: "DevOps Engineer",         avatarName: "avatar-zoe",     anomalyType: .noClockInNorOut,       hasScheduleIcon: true,  department: "Engineering", workplace: "Remote",    entity: "Workable UK",   scheduledHours: 8, workedHours: 0),
        .init(name: "Johansson, Erik",                 role: "Sales Director",          avatarName: "avatar-michael", anomalyType: .onTrack,               hasScheduleIcon: false, department: "Sales",       workplace: "London",    entity: "Workable UK",   scheduledHours: 8, workedHours: 8),
        .init(name: "Patel, Priya",                    role: "HR Business Partner",     avatarName: "avatar-priya",   anomalyType: .onTrack,               hasScheduleIcon: false, department: "Operations",  workplace: "New York",  entity: "Workable Inc.", scheduledHours: 8, workedHours: 7),
        .init(name: "Kim, Soo-Jin",                    role: "Content Strategist",      avatarName: "avatar-lucy",    anomalyType: .exceededWorkSchedule,  hasScheduleIcon: false, department: "Marketing",   workplace: "Remote",    entity: "Workable EU",   scheduledHours: 8, workedHours: 10.5),
        .init(name: "Rossi, Luca",                     role: "Backend Developer",       avatarName: "avatar-sarah",   anomalyType: .noClockIn,             hasScheduleIcon: false, department: "Engineering", workplace: "Berlin",    entity: "Workable EU",   scheduledHours: 8, workedHours: 0),
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
        case .noClockIn, .noClockInNorOut: return .danger
        case .exceededWorkSchedule:        return .warning
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
                Text("+\(count)")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .frame(height: 25)
                    .background(AppColors.separator)
                    .clipShape(RoundedRectangle(cornerRadius: 200, style: .continuous))
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

// MARK: - Anomaly Filter Bar (horizontal scrolling chips)

struct AnomalyFilterBar: View {
    @Binding var selectedFilters: Set<AnomalyFilterCategory>
    @Binding var selectedDepartment: String?
    @Binding var selectedEntity: String?
    @Binding var searchText: String
    var filterCounts: [AnomalyFilterCategory: Int] = [:]
    var isSearchRowVisible: Bool = true

    private var sortedFilters: [AnomalyFilterCategory] {
        AnomalyFilterCategory.allCases
    }

    private var hasActiveContextFilters: Bool {
        selectedDepartment != nil || selectedEntity != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sortedFilters, id: \.self) { filter in
                        let isSelected = selectedFilters.contains(filter)
                        let count = filterCounts[filter] ?? 0
                        Button {
                            if isSelected { selectedFilters.remove(filter) }
                            else { selectedFilters.insert(filter) }
                        } label: {
                            HStack(spacing: isSelected ? 8 : 4) {
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppColors.primaryDark)
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            if isSearchRowVisible {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.iconDefault)
                        TextField("Search", text: $searchText)
                            .font(AppFonts.subheadline())
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

                    Menu {
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
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(hasActiveContextFilters ? AppColors.primaryDark : AppColors.fontSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(hasActiveContextFilters ? AppColors.activeBackground : AppColors.lightBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(hasActiveContextFilters ? AppColors.primaryDark : AppColors.separator, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

}

// MARK: - Employee Anomaly Row

struct EmployeeAnomalyRow: View {
    let employee: EmployeeAnomaly

    private var progress: Double {
        guard employee.scheduledHours > 0 else { return 0 }
        return min(employee.workedHours / employee.scheduledHours, 1.5)
    }

    private var barColor: Color {
        employee.anomalyType.textColor
    }

    var onBellTapped: (() -> Void)? = nil
    @Binding var isNotified: Bool

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

                if employee.anomalyType != .onTrack {
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

            Spacer()

            if employee.anomalyType != .onTrack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isNotified.toggle()
                    }
                    onBellTapped?()
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isNotified ? AppColors.primaryDark : AppColors.primaryDark)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(isNotified ? AppColors.successBackground : .white)
                                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.6), lineWidth: 0.5)
                            )
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 38, height: 38)
                            )

                        if isNotified {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.primaryDark)
                                .background(Circle().fill(AppColors.successBackground).frame(width: 12, height: 12))
                                .offset(x: 4, y: 4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let name = employee.avatarName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color(hex: "E8E8ED"))
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.iconDefault)
                }
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
