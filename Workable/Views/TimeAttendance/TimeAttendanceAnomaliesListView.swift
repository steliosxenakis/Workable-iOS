import SwiftUI

struct TimeAttendanceAnomaliesListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 3
    @State private var selectedFilters: Set<AnomalyFilterCategory>

    init(initialFilters: Set<AnomalyFilterCategory> = []) {
        _selectedFilters = State(initialValue: initialFilters)
    }
    @State private var selectedDepartment: String?
    @State private var selectedEntity: String?
    @State private var searchText = ""
    @State private var selectedDate = Date()
    @State private var showSearchRow = true

    private let tabs = ["Events", "Celebrations", "On leave", "Attendance"]
    private let employees = TimeAttendanceMockData.employees

    private let directReportNames = Set(["Doe, Joanne", "Gutmann, Elyssa", "Carty, Joe"])

    private var eligibleEmployees: [EmployeeAnomaly] {
        employees.filter { !$0.hasScheduleIcon }
    }

    private var filterCounts: [AnomalyFilterCategory: Int] {
        var counts: [AnomalyFilterCategory: Int] = [:]
        for category in AnomalyFilterCategory.allCases {
            counts[category] = eligibleEmployees.filter { category.matchingTypes.contains($0.anomalyType) }.count
        }
        return counts
    }

    private var filteredEmployees: [EmployeeAnomaly] {
        var result = eligibleEmployees.filtered(by: selectedFilters, department: selectedDepartment, entity: selectedEntity)
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.role.lowercased().contains(query)
            }
        }
        return result
    }

    private var directReportEmployees: [EmployeeAnomaly] {
        filteredEmployees.filter { directReportNames.contains($0.name) }
    }

    private var otherEmployees: [EmployeeAnomaly] {
        filteredEmployees.filter { !directReportNames.contains($0.name) }
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            Group {
                switch selectedTab {
                case 0:  placeholderTab("Events")
                case 1:  placeholderTab("Celebrations")
                case 2:  onLeaveContent
                case 3:  timeAttendanceContent
                default: Spacer()
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("7 May 2025")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(AppFonts.body())
                    }
                    .foregroundColor(AppColors.primaryDark)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedTab != 3 {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primaryDark)
                        .overlay {
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                                .colorMultiply(.clear)
                        }
                        .fixedSize()
                }
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
                    } label: {
                        VStack(spacing: 8) {
                            Text(title)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(selectedTab == index ? AppColors.primaryDark : AppColors.fontSecondary)
                                .padding(.horizontal, 16)

                            Rectangle()
                                .fill(selectedTab == index ? AppColors.primaryDark : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Time & Attendance Content

    private var timeAttendanceContent: some View {
        VStack(spacing: 0) {
            AnomalyFilterBar(
                selectedFilters: $selectedFilters,
                selectedDepartment: $selectedDepartment,
                selectedEntity: $selectedEntity,
                searchText: $searchText,
                filterCounts: filterCounts,
                isSearchRowVisible: showSearchRow
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("taScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    if !directReportEmployees.isEmpty {
                        employeeSection(title: "Direct reports", employees: directReportEmployees)
                    }
                    if !otherEmployees.isEmpty {
                        employeeSection(title: "Other employees", employees: otherEmployees)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .coordinateSpace(name: "taScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                let shouldShow = offset > -10
                if shouldShow != showSearchRow {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearchRow = shouldShow
                    }
                }
            }
        }
    }

    private func employeeSection(title: String, employees: [EmployeeAnomaly]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.08)

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
        }
    }

    // MARK: - On Leave Content

    private var onLeaveContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(OnLeaveMockData.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppColors.fontSecondary)
                            .tracking(-0.08)

                        VStack(spacing: 8) {
                            ForEach(section.cards) { card in
                                onLeaveCard(card)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private func onLeaveCard(_ card: OnLeaveCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "E8E8ED"))
                        .frame(width: 30, height: 30)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.iconDefault)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(card.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.41)
                    Text(card.role)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.08)
                }
            }

            ForEach(card.entries) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(entry.type.barColor)
                                .frame(width: 6)

                            Text(entry.type.rawValue)
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.fontDefault)
                                .tracking(-0.24)
                        }
                        .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        if entry.isPending {
                            Text("Pending")
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(AppColors.warningDefault)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(AppColors.warningBackground)
                                .cornerRadius(20)
                        }
                    }

                    Text(entry.dateRange)
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(8)
    }

    // MARK: - Placeholder Tabs

    private func placeholderTab(_ title: String) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - On Leave Models & Mock Data

private enum LeaveType: String {
    case paidTimeOff = "Paid time off"
    case unpaidTimeOff = "Unpaid time off"
    case sickLeave = "Sick leave"

    var barColor: Color {
        switch self {
        case .paidTimeOff:   return Color(hex: "F8D8AB")
        case .unpaidTimeOff: return Color(hex: "A7C3FA")
        case .sickLeave:     return Color(hex: "F6C8FB")
        }
    }
}

private struct LeaveEntry: Identifiable {
    let id = UUID()
    let type: LeaveType
    let dateRange: String
    let isPending: Bool
}

private struct OnLeaveCard: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let entries: [LeaveEntry]
}

private struct OnLeaveSection: Identifiable {
    let id = UUID()
    let title: String
    let cards: [OnLeaveCard]
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private enum OnLeaveMockData {
    static let sections: [OnLeaveSection] = [
        OnLeaveSection(title: "Direct reports", cards: [
            OnLeaveCard(name: "Gutmann, Elyssa", role: "Account Manager", entries: [
                LeaveEntry(type: .paidTimeOff, dateRange: "6 Jan 2023 - 18 Jan 2023", isPending: false)
            ])
        ]),
        OnLeaveSection(title: "Manager", cards: [
            OnLeaveCard(name: "Carty, Joe", role: "Operations Engineer", entries: [
                LeaveEntry(type: .unpaidTimeOff, dateRange: "6 Jan 2023 (18:00) - 6 Jan 2023 (19:00)", isPending: true),
                LeaveEntry(type: .sickLeave, dateRange: "6 Jan 2023 (20:00) - 6 Jan 2023 (21:00)", isPending: true)
            ])
        ]),
        OnLeaveSection(title: "Teammates", cards: [
            OnLeaveCard(name: "Laren, John", role: "Operations Engineer", entries: [
                LeaveEntry(type: .sickLeave, dateRange: "6 Jan 2023 (first half)", isPending: false)
            ])
        ]),
        OnLeaveSection(title: "Other employees", cards: [
            OnLeaveCard(name: "Wilhelham, Minnie Laris Julie", role: "Operations Engineer", entries: [
                LeaveEntry(type: .paidTimeOff, dateRange: "6 Jan 2023 (half day) - 21 Jan 2023 (half day)", isPending: false)
            ]),
            OnLeaveCard(name: "Kovarek, Tomas", role: "Operations Engineer", entries: [
                LeaveEntry(type: .paidTimeOff, dateRange: "6 Jan 2023 (first half)", isPending: false)
            ])
        ])
    ]
}
