import SwiftUI

struct TimeAttendanceAnomaliesListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.attendanceUIVersion) private var attendanceUIVersion
    @State private var selectedTab: Int
    @State private var selectedFilters: Set<AnomalyFilterCategory>

    init(initialFilters: Set<AnomalyFilterCategory> = [], initialTab: Int? = nil) {
        _selectedFilters = State(initialValue: initialFilters)
        let version = AttendanceUIVersion.resolved(
            from: UserDefaults.standard.string(forKey: AttendanceUIVersion.appStorageKey)
                ?? AttendanceUIVersion.defaultVersion.rawValue
        )
        let defaultTab = version.usesModernAttendanceChrome ? 3 : 1
        _selectedTab = State(initialValue: initialTab ?? defaultTab)
    }
    @State private var selectedDepartment: String?
    @State private var selectedEntity: String?
    @State private var searchText = ""
    @State private var selectedDate = Date()
    @State private var showSearchRow = false
    @State private var notifiedEmployees: Set<UUID> = []
    @State private var allNotified = false
    @State private var isSelecting = false
    @State private var selectedForNotification: Set<UUID> = []

    private var tabs: [String] {
        switch attendanceUIVersion {
        case .v1:
            return ["Events", "Time tracking", "On leave", "Celebrations"]
        case .v2, .v3, .v4:
            return ["Events", "On leave", "Celebrations", "Attendance"]
        }
    }

    private var attendanceTabIndex: Int {
        attendanceUIVersion.usesModernAttendanceChrome ? 3 : 1
    }

    /// Matches `TabBarView` height; FABs sit 16pt above the menu (V1).
    private static let mainTabBarHeight: CGFloat = 83
    private static let floatingBarGapAboveMenu: CGFloat = 16
    /// V2/V3 — shift floating actions 16pt lower (flush with tab bar top).
    private static let modernFloatingBarExtraLowerOffset: CGFloat = 16
    private static let floatingBarGradientHeight: CGFloat = 88

    private func floatingBarBottomInset(for version: AttendanceUIVersion) -> CGFloat {
        let standard = Self.mainTabBarHeight + Self.floatingBarGapAboveMenu
        if version.usesModernAttendanceChrome {
            return standard - Self.modernFloatingBarExtraLowerOffset
        }
        return standard
    }

    private var showsFloatingSelectionBar: Bool {
        selectedTab == attendanceTabIndex
            && (!attendanceUIVersion.usesModernAttendanceChrome || isSelecting)
    }

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

    /// IDs visible with current filters & search — used for select all / deselect all.
    private var selectableEmployeeIDs: Set<UUID> {
        Set(filteredEmployees.map(\.id))
    }

    private var allFilteredEmployeesSelected: Bool {
        let ids = selectableEmployeeIDs
        guard !ids.isEmpty else { return false }
        return ids.isSubset(of: selectedForNotification)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                tabBar

                Group {
                    tabContent
                }
            }
            .onChange(of: attendanceUIVersion) { version in
                selectedTab = attendanceTabIndex
                if version == .v1 {
                    showSearchRow = false
                }
            }

            if showsFloatingSelectionBar {
                floatingSelectionBar
            }
        }
        .background(AppColors.background)
        .navigationTitle("7 April 2025")
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
            if attendanceUIVersion.usesModernAttendanceChrome {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AttendanceV2SearchToolbarButton(isSearchVisible: $showSearchRow)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                attendanceCalendarPicker
            }
        }
    }

    private var attendanceCalendarPicker: some View {
        Image(systemName: "calendar")
            .font(.system(size: 18))
            .foregroundColor(AppColors.primaryDark)
            .frame(width: 44, height: 44)
            .overlay {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorMultiply(.clear)
                    .frame(width: 44, height: 44)
            }
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private var tabContent: some View {
        if attendanceUIVersion.usesModernAttendanceChrome {
            switch selectedTab {
            case 0:  placeholderTab("Events")
            case 1:  onLeaveContent
            case 2:  placeholderTab("Celebrations")
            case 3:  timeAttendanceContent
            default: Spacer()
            }
        } else {
            switch selectedTab {
            case 0:  placeholderTab("Events")
            case 1:  timeAttendanceContent
            case 2:  onLeaveContent
            case 3:  placeholderTab("Celebrations")
            default: Spacer()
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
        .padding(.top, 8)
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
                isSearchRowVisible: $showSearchRow,
                filterCounts: filterCounts,
                attendanceVersion: attendanceUIVersion
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !directReportEmployees.isEmpty {
                        employeeSection(
                            title: "Direct reports",
                            employees: directReportEmployees,
                            showsSelectionAction: attendanceUIVersion.usesModernAttendanceChrome
                        )
                    }
                    if !otherEmployees.isEmpty {
                        employeeSection(title: "Other employees", employees: otherEmployees)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, showsFloatingSelectionBar ? 140 : 16)
            }
        }
        .background(AppColors.background)
    }

    private var floatingSelectionBar: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0), location: 0),
                    .init(color: AppColors.background.opacity(0.92), location: 0.55),
                    .init(color: AppColors.background, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.floatingBarGradientHeight + 52)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)

            HStack(spacing: 12) {
                    if isSelecting {
                        floatingCapsuleButton(
                            "Cancel",
                            foreground: AppColors.fontSecondary,
                            style: attendanceUIVersion.usesModernAttendanceChrome ? .tertiary : .secondary
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedForNotification.removeAll()
                                isSelecting = false
                            }
                        }
                    }

                    if isSelecting && !filteredEmployees.isEmpty {
                        floatingCapsuleButton(
                            allFilteredEmployeesSelected ? "Deselect all" : "Select all",
                            style: .selectAll
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                let ids = selectableEmployeeIDs
                                if allFilteredEmployeesSelected {
                                    selectedForNotification.subtract(ids)
                                } else {
                                    selectedForNotification.formUnion(ids)
                                }
                            }
                        }
                        .accessibilityHint("Selects or clears everyone in the current list and filters.")
                    }

                    if isSelecting && !selectedForNotification.isEmpty {
                        floatingCapsuleButton(
                            "Notify \(selectedForNotification.count)",
                            icon: "bell",
                            style: .primary
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                for id in selectedForNotification {
                                    notifiedEmployees.insert(id)
                                }
                                selectedForNotification.removeAll()
                                isSelecting = false
                            }
                        }
                    }

                    if attendanceUIVersion == .v1 && !isSelecting {
                        floatingCapsuleButton("Select", icon: "checkmark.circle") {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSelecting = true
                            }
                        }
                    }

                }
                .padding(.horizontal, 16)
                .padding(.bottom, floatingBarBottomInset(for: attendanceUIVersion))
        }
        .frame(maxWidth: .infinity)
    }

    private enum FloatingCapsuleButtonStyle {
        case secondary
        case primary
        case tertiary
        case selectAll
    }

    private func floatingCapsuleButton(
        _ title: String,
        icon: String? = nil,
        foreground: Color = AppColors.primaryDark,
        style: FloatingCapsuleButtonStyle = .secondary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AppFonts.subheadStrong())
            }
            .foregroundColor(style == .primary ? .white : foreground)
            .padding(.horizontal, style == .tertiary ? 16 : 20)
            .padding(.vertical, 12)
            .background {
                switch style {
                case .primary:
                    Capsule().fill(AppColors.primaryDark)
                case .selectAll:
                    Capsule().fill(AppColors.activeBackground)
                case .secondary:
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .background(Capsule().fill(.white.opacity(0.7)))
                        .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 0.5))
                case .tertiary:
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .background(Capsule().fill(AppColors.surface.opacity(0.85)))
                }
            }
            .shadow(
                color: .black.opacity(style == .tertiary ? 0.06 : (style == .selectAll ? 0.08 : 0.1)),
                radius: style == .tertiary ? 8 : 16,
                y: style == .tertiary ? 3 : 6
            )
        }
        .buttonStyle(.plain)
    }

    private func employeeSection(
        title: String,
        employees: [EmployeeAnomaly],
        showsSelectionAction: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.08)

                Spacer(minLength: 8)

                if showsSelectionAction {
                    if !isSelecting {
                        tertiarySelectionButton(title: "Select", icon: nil, foreground: AppColors.primaryDark) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSelecting = true
                            }
                        }
                    }
                }
            }

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(employees.enumerated()), id: \.element.id) { index, employee in
                    if isSelecting {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selectedForNotification.contains(employee.id) {
                                    selectedForNotification.remove(employee.id)
                                } else {
                                    selectedForNotification.insert(employee.id)
                                }
                            }
                        } label: {
                            EmployeeAnomalyRow(
                                employee: employee,
                                isNotified: .constant(notifiedEmployees.contains(employee.id) || allNotified),
                                isSelectionMode: true,
                                isSelectedForNotification: selectedForNotification.contains(employee.id)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(destination: EmployeeTimeTrackingDetailView(employee: employee)) {
                            EmployeeAnomalyRow(
                                employee: employee,
                                isNotified: Binding(
                                    get: { notifiedEmployees.contains(employee.id) || allNotified },
                                    set: { newValue in
                                        if newValue { notifiedEmployees.insert(employee.id) }
                                        else { notifiedEmployees.remove(employee.id); allNotified = false }
                                    }
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    if index < employees.count - 1 {
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(16)
        }
    }

    private func tertiarySelectionButton(
        title: String,
        icon: String?,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AppFonts.subheadStrong())
            }
            .foregroundColor(foreground)
        }
        .buttonStyle(.plain)
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
                if let avatarName = card.avatarName {
                    Image(avatarName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "E8E8ED"))
                            .frame(width: 30, height: 30)
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.iconDefault)
                    }
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
    let avatarName: String?
    let entries: [LeaveEntry]
}

private struct OnLeaveSection: Identifiable {
    let id = UUID()
    let title: String
    let cards: [OnLeaveCard]
}

private enum OnLeaveMockData {
    static let sections: [OnLeaveSection] = [
        OnLeaveSection(title: "Direct reports", cards: [
            OnLeaveCard(name: "Gutmann, Elyssa", role: "Account Manager", avatarName: "avatar-michael", entries: [
                LeaveEntry(type: .paidTimeOff, dateRange: "6 Jan 2023 - 18 Jan 2023", isPending: false)
            ])
        ]),
        OnLeaveSection(title: "Manager", cards: [
            OnLeaveCard(name: "Carty, Joe", role: "Operations Engineer", avatarName: "avatar-abdi", entries: [
                LeaveEntry(type: .unpaidTimeOff, dateRange: "6 Jan 2023 (18:00) - 6 Jan 2023 (19:00)", isPending: true),
                LeaveEntry(type: .sickLeave, dateRange: "6 Jan 2023 (20:00) - 6 Jan 2023 (21:00)", isPending: true)
            ])
        ]),
        OnLeaveSection(title: "Teammates", cards: [
            OnLeaveCard(name: "Laren, John", role: "Operations Engineer", avatarName: "avatar-tyler", entries: [
                LeaveEntry(type: .sickLeave, dateRange: "6 Jan 2023 (first half)", isPending: false)
            ])
        ]),
        OnLeaveSection(title: "Other employees", cards: [
            OnLeaveCard(name: "Wilhelham, Minnie Laris Julie", role: "Operations Engineer", avatarName: "avatar-grace", entries: [
                LeaveEntry(type: .paidTimeOff, dateRange: "6 Jan 2023 (half day) - 21 Jan 2023 (half day)", isPending: false)
            ]),
            OnLeaveCard(name: "Kovarek, Tomas", role: "Operations Engineer", avatarName: "avatar-tyler", entries: [
                LeaveEntry(type: .paidTimeOff, dateRange: "6 Jan 2023 (first half)", isPending: false)
            ])
        ])
    ]
}
