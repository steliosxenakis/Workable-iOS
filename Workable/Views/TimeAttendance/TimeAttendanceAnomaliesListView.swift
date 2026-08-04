import SwiftUI

struct TimeAttendanceAnomaliesListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.attendanceUIVersion) private var attendanceUIVersion
    @Environment(\.attendanceMVP) private var attendanceMVP
    @Environment(\.attendanceNoIssues) private var attendanceNoIssues
    @Environment(\.attendanceWorkingCase) private var attendanceWorkingCase
    @Environment(\.attendanceNotifyStyle) private var notifyStyle
    @AppStorage("settings.showDirectReports") private var showDirectReports = true
    @State private var selectedTab: Int
    @State private var selectedFilters: Set<AnomalyFilterCategory>

    init(initialFilters: Set<AnomalyFilterCategory> = [], initialTab: Int? = nil) {
        _selectedFilters = State(initialValue: initialFilters)
        let version = AttendanceUIVersion.resolved(
            from: UserDefaults.standard.string(forKey: AttendanceUIVersion.appStorageKey)
                ?? AttendanceUIVersion.defaultVersion.rawValue
        )
        let defaultTab = (version == .v6 || version == .v7 || version == .v8) ? 1 : version.usesModernAttendanceChrome ? 3 : 1
        _selectedTab = State(initialValue: initialTab ?? defaultTab)
    }
    @State private var selectedDepartments: Set<String> = []
    @State private var selectedEntities: Set<String> = []
    @State private var searchText = ""
    @State private var selectedDate = Date()
    @State private var showSearchRow = false

    /// V5 — past-date attendance is read-only (no bells, no selection).
    private var isViewingNonTodayDate: Bool {
        (attendanceUIVersion == .v5 || attendanceUIVersion == .v6 || attendanceUIVersion == .v7 || attendanceUIVersion == .v8) && !Calendar.current.isDateInToday(selectedDate)
    }

    private var isViewingFutureDate: Bool {
        (attendanceUIVersion == .v5 || attendanceUIVersion == .v6 || attendanceUIVersion == .v7 || attendanceUIVersion == .v8) && selectedDate > Date()
    }

    private var isViewingPastDate: Bool {
        isViewingNonTodayDate && !isViewingFutureDate
    }

    private var navigationDateTitle: String {
        guard attendanceUIVersion == .v5 || attendanceUIVersion == .v6 || attendanceUIVersion == .v7 || attendanceUIVersion == .v8 else { return "7 April 2025" }
        if attendanceUIVersion == .v5 && Calendar.current.isDateInToday(selectedDate) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    @State private var notifiedEmployees: Set<UUID> = []
    @State private var notifiedTimestamps: [UUID: Date] = [:]
    @State private var allNotified = false
    @State private var isSelecting = false
    @State private var selectedForNotification: Set<UUID> = []
    @State private var filtersBeforeFab: Set<AnomalyFilterCategory>?
    @State private var showsReminderToast = false
    @State private var lastReminderSentCount = 0
    @State private var showsResendReminderAlert = false
    @State private var pendingReminderTargets: Set<UUID> = []
    @State private var showsNotifySheet = false

    private static let actionableFilterCategories: Set<AnomalyFilterCategory> = [
        .noClockInNorOut, .missedClockOut, .exceededWorkSchedule, .noClockIn, .workedLess
    ]

    /// Grabber + header + 3 toggle rows + bottom padding — hugs content (not a full/medium page).
    private static let notifySheetDetentHeight: CGFloat = 268

    private var tabs: [String] {
        switch attendanceUIVersion {
        case .v1:
            return ["Events", "Time tracking", "On leave", "Celebrations"]
        case .v6, .v7, .v8:
            return ["Events", "Attendance", "On leave", "Celebrations"]
        case .v2, .v3, .v4, .v5:
            return ["Events", "On leave", "Celebrations", "Attendance"]
        }
    }

    private var attendanceTabIndex: Int {
        if attendanceUIVersion == .v6 || attendanceUIVersion == .v7 || attendanceUIVersion == .v8 { return 1 }
        return attendanceUIVersion.usesModernAttendanceChrome ? 3 : 1
    }

    /// Matches `TabBarView` height; FABs sit 16pt above the menu (V1).
    private static let mainTabBarHeight: CGFloat = TabBarView.barHeight
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
        !attendanceMVP
            && !isViewingNonTodayDate
            && selectedTab == attendanceTabIndex
            && (!attendanceUIVersion.usesModernAttendanceChrome || isSelecting)
    }

    private var usesFabNotifyStyle: Bool {
        notifyStyle.usesFabChrome && !attendanceMVP
    }

    private var usesFilterOnlyNotify: Bool {
        notifyStyle.isFilterOnlyNotify && !attendanceMVP
    }

    private var usesNotifySheet: Bool {
        notifyStyle.usesNotifySheet && !attendanceMVP
    }

    private func enterFabSelection() {
        if usesNotifySheet {
            openNotifySheet()
            return
        }
        filtersBeforeFab = selectedFilters
        selectedFilters = Self.actionableFilterCategories
        isSelecting = true
        if usesFilterOnlyNotify {
            selectedForNotification.removeAll()
        } else {
            selectedForNotification = selectableEmployeeIDs
        }
    }

    private func openNotifySheet() {
        showsNotifySheet = true
    }

    private func notifyTargets(for categories: Set<AnomalyFilterCategory>) -> Set<UUID> {
        Set(
            departmentEntityScopedEmployees
                .filter { employee in
                    categories.contains {
                        $0.matchingTypes.contains(employee.anomalyType)
                    }
                }
                .map(\.id)
        )
    }

    private func exitFabSelection(restoreFilters: Bool = true) {
        selectedForNotification.removeAll()
        isSelecting = false
        if restoreFilters, let saved = filtersBeforeFab {
            selectedFilters = saved
        }
        filtersBeforeFab = nil
    }

    private func attemptSendFilterReminders() {
        attemptSendReminders(to: selectableEmployeeIDs)
    }

    private func attemptSendReminders(to targets: Set<UUID>) {
        guard !targets.isEmpty else { return }
        if !targets.isDisjoint(with: notifiedEmployees) {
            pendingReminderTargets = targets
            withAnimation(.easeInOut(duration: 0.2)) {
                showsResendReminderAlert = true
            }
        } else {
            sendFilterReminders(to: targets)
        }
    }

    private func sendFilterReminders(to targets: Set<UUID>) {
        guard !targets.isEmpty else { return }
        let now = Date()
        for id in targets {
            _ = notifiedEmployees.insert(id)
            notifiedTimestamps[id] = now
        }
        pendingReminderTargets = []
        showsResendReminderAlert = false
        showsNotifySheet = false
        selectedForNotification.removeAll()
        isSelecting = false
        if usesFilterOnlyNotify {
            selectedFilters.removeAll()
            filtersBeforeFab = nil
        }
        lastReminderSentCount = targets.count
        withAnimation(.easeInOut(duration: 0.2)) {
            showsReminderToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showsReminderToast = false
            }
        }
    }

    private var employees: [EmployeeAnomaly] {
        if attendanceUIVersion == .v5 || attendanceUIVersion == .v6 || attendanceUIVersion == .v7 || attendanceUIVersion == .v8 {
            return TimeAttendanceMockData.employees(for: selectedDate)
        }
        return TimeAttendanceMockData.employees
    }

    private let directReportNames = Set(["Doe, Joanne", "Gutmann, Elyssa", "Carty, Jonathan-Augustus", "Tomasevic, George"])

    private var eligibleEmployees: [EmployeeAnomaly] {
        let base: [EmployeeAnomaly]
        if attendanceUIVersion.usesV6IssueBannerStyle {
            base = employees
        } else {
            base = employees.filter { !$0.hasScheduleIcon }
        }
        if attendanceWorkingCase {
            return base.filter(\.countsTowardAttendanceIssues)
        }
        if attendanceNoIssues {
            return base.filter {
                $0.anomalyType == .onTrack || $0.anomalyType == .scheduleNotStarted
            }
        }
        return base
    }

    private var isNotifiableCategory: (AnomalyFilterCategory) -> Bool {{ category in
        let types = category.matchingTypes
        return !types.isSubset(of: [.onTrack, .scheduleNotStarted, .late, .exceededHours, .unplanned])
    }}

    private var departmentEntityScopedEmployees: [EmployeeAnomaly] {
        eligibleEmployees.filtered(by: [], departments: selectedDepartments, entities: selectedEntities)
    }

    private var filterCounts: [AnomalyFilterCategory: Int] {
        let base = departmentEntityScopedEmployees
        var counts: [AnomalyFilterCategory: Int] = [:]
        for category in AnomalyFilterCategory.allCases {
            counts[category] = base.filter { category.matchingTypes.contains($0.anomalyType) }.count
        }
        return counts
    }

    private var filteredEmployees: [EmployeeAnomaly] {
        var result = eligibleEmployees.filtered(by: selectedFilters, departments: selectedDepartments, entities: selectedEntities)
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
        filteredEmployees.filter {
            directReportNames.contains($0.name) && !$0.hasMultipleIssuePills
        }
    }

    private var otherEmployees: [EmployeeAnomaly] {
        var result = filteredEmployees.filter {
            !directReportNames.contains($0.name) &&
            !(attendanceUIVersion.usesV6IssueBannerStyle && $0.hasScheduleIcon && $0.anomalyType == .onTrack) &&
            !$0.hasMultipleIssuePills
        }
        result.append(contentsOf: filteredEmployees.filter(\.hasMultipleIssuePills))
        return result
    }

    private var fabSelecting: Bool {
        usesFabNotifyStyle && isSelecting
    }

    private var v6StatsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(AnomalyFilterCategory.allCases.filter { $0 != .onTrack && $0 != .missedClockOut }.prefix(3)), id: \.self) { filter in
                    let count = filterCounts[filter] ?? 0
                    let isSelected = selectedFilters.contains(filter)
                    let isActionable = isNotifiableCategory(filter)
                    let dimmed = fabSelecting && !isActionable
                    Button {
                        if !dimmed {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isSelected { selectedFilters.remove(filter) }
                                else { selectedFilters.insert(filter) }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(filter.rawValue)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(
                                    dimmed
                                        ? AppColors.fontSecondary.opacity(0.4)
                                        : (isSelected ? AppColors.primaryDark : AppColors.fontSecondary)
                                )

                            Text("\(count)")
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(
                                    dimmed
                                        ? AppColors.fontSecondary.opacity(0.4)
                                        : (isSelected || count > 0 ? AppColors.fontDefault : AppColors.fontSecondary)
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    dimmed
                                        ? AppColors.lightBackground.opacity(0.5)
                                        : (isSelected
                                           ? AppColors.successBackground
                                           : (count > 0 ? AppColors.background : AppColors.lightBackground))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            dimmed
                                ? AppColors.surface.opacity(0.5)
                                : (isSelected ? AppColors.activeBackground : AppColors.surface)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(dimmed ? 0.02 : 0.07), radius: 14, y: 4)
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(!dimmed)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -16)
        .padding(.vertical, -18)
    }

    /// IDs visible with current filters & search — used for select all / deselect all.
    private var selectableEmployeeIDs: Set<UUID> {
        Set(filteredEmployees.map(\.id))
    }

    /// Everyone in scope who can receive a reminder (actionable issue types).
    private var allNotifiableEmployeeIDs: Set<UUID> {
        Set(
            departmentEntityScopedEmployees
                .filter { employee in
                    Self.actionableFilterCategories.contains {
                        $0.matchingTypes.contains(employee.anomalyType)
                    }
                }
                .map(\.id)
        )
    }

    private var allFilteredEmployeesSelected: Bool {
        let ids = selectableEmployeeIDs
        guard !ids.isEmpty else { return false }
        return ids.isSubset(of: selectedForNotification)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if attendanceUIVersion.usesV6IssueBannerStyle {
                    v6NavBar
                } else {
                    tabBar
                }

                Group {
                    tabContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: attendanceUIVersion) { version in
                selectedTab = attendanceTabIndex
                if version == .v1 {
                    showSearchRow = false
                }
            }
            .onChange(of: selectedDate) { _ in
                if isViewingNonTodayDate {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSelecting = false
                        selectedForNotification.removeAll()
                    }
                }
            }

            if showsFloatingSelectionBar && !usesFabNotifyStyle {
                floatingSelectionBar
            }

            if usesFabNotifyStyle && !isViewingNonTodayDate && selectedTab == attendanceTabIndex {
                fabOverlay
            }

            if showsReminderToast {
                reminderSentToast
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(10)
            }

            if showsResendReminderAlert {
                resendReminderAlert
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(11)
            }
        }
        .sheet(isPresented: $showsNotifySheet) {
            NotifyEmployeesSheet(
                filterCounts: filterCounts,
                targets: { notifyTargets(for: $0) },
                onCancel: { showsNotifySheet = false },
                onConfirm: { targets in
                    showsNotifySheet = false
                    attemptSendReminders(to: targets)
                }
            )
            .presentationDetents([.height(Self.notifySheetDetentHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(34)
            .presentationBackground {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.regularMaterial)
            }
        }
        .background(AppColors.background)
        .navigationTitle(attendanceUIVersion.usesV6IssueBannerStyle ? "" : navigationDateTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(attendanceUIVersion.usesV6IssueBannerStyle)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if !attendanceUIVersion.usesV6IssueBannerStyle {
                ToolbarItem(placement: .navigationBarLeading) {
                    attendanceBackButton
                        .fixedSize()
                }
                if attendanceUIVersion.usesModernAttendanceChrome {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        AttendanceV2SearchToolbarButton(isSearchVisible: $showSearchRow)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    attendanceCalendarButton
                        .fixedSize()
                }
            }
        }
    }

    // MARK: - V6 Nav Bar (Figma 390-15733)

    private var v6NavBar: some View {
        VStack(spacing: 0) {
            HStack {
                attendanceBackButton
                    .frame(width: 96, alignment: .leading)

                Spacer(minLength: 0)

                attendanceCalendarButton
                    .frame(minWidth: 96, alignment: .trailing)
            }
            .overlay {
                Text(navigationDateTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            attendanceTabItems(horizontalPadding: 26)
                .padding(.top, 8)
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

    private var attendanceBackButton: some View {
        GlassSymbolButton(
            systemName: "chevron.left",
            fontWeight: .semibold,
            accessibilityLabel: "Back",
            action: { dismiss() }
        )
    }

    private var attendanceCalendarButton: some View {
        ZStack {
            GlassSymbolButton(
                systemName: "calendar",
                accessibilityLabel: "Select date",
                action: {}
            )
            .allowsHitTesting(false)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .colorMultiply(.clear)
                .frame(width: GlassSymbolButton.size, height: GlassSymbolButton.size)
        }
        .frame(width: GlassSymbolButton.size, height: GlassSymbolButton.size)
    }

    @ViewBuilder
    private var tabContent: some View {
        if attendanceUIVersion.usesV6IssueBannerStyle {
            switch selectedTab {
            case 0:  placeholderTab("Events")
            case 1:  timeAttendanceContent
            case 2:  onLeaveContent
            case 3:  placeholderTab("Celebrations")
            default: Spacer()
            }
        } else if attendanceUIVersion.usesModernAttendanceChrome {
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
        attendanceTabItems(horizontalPadding: 0)
            .padding(.top, 8)
            .background(AppColors.surface)
            .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

    private func attendanceTabItems(horizontalPadding: CGFloat) -> some View {
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
            .padding(.horizontal, horizontalPadding)
        }
    }

    // MARK: - Time & Attendance Content

    private var timeAttendanceContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if attendanceUIVersion.usesV6IssueBannerStyle {
                    v6StatsRow
                }

                if filteredEmployees.isEmpty && attendanceUIVersion.usesV6IssueBannerStyle {
                    VStack(spacing: 12) {
                        Image("illustration-empty-list")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                        Text("No employees to show")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.fontDefault)
                        Text(!selectedFilters.isEmpty || !selectedDepartments.isEmpty || !selectedEntities.isEmpty ? "Try modifying your filters." : "Try modifying your search.")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    if !directReportEmployees.isEmpty {
                        employeeSection(
                            title: "Direct reports",
                            employees: directReportEmployees,
                            showsSelectionAction: !attendanceMVP && !isViewingNonTodayDate && attendanceUIVersion.usesModernAttendanceChrome
                        )
                    }
                    if !otherEmployees.isEmpty {
                        employeeSection(title: "Other employees", employees: otherEmployees)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, showsFloatingSelectionBar ? 140 : 80)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if !fabSelecting {
                AnomalyFilterBar(
                    selectedFilters: $selectedFilters,
                    selectedDepartments: $selectedDepartments,
                    selectedEntities: $selectedEntities,
                    searchText: $searchText,
                    isSearchRowVisible: $showSearchRow,
                    filterCounts: filterCounts,
                    attendanceVersion: attendanceUIVersion,
                    filteredResultCount: filteredEmployees.count
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        let allSel = allFilteredEmployeesSelected
                        let cnt = selectedForNotification.count
                        floatingCapsuleButton(
                            allSel ? "Notify all (\(cnt))" : "Notify (\(cnt))",
                            icon: "bell",
                            style: .primary
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                let now = Date()
                                for id in selectedForNotification {
                                    notifiedEmployees.insert(id)
                                    notifiedTimestamps[id] = now
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

    private var fabOverlay: some View {
        ZStack(alignment: .bottom) {
            // Sheet style never enters in-list selection — FAB only opens the bottom sheet.
            if isSelecting && !usesNotifySheet {
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
                    .frame(height: Self.floatingBarGradientHeight + 72)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)

                    if usesFilterOnlyNotify {
                        finalNotifyFloatingBar
                    } else {
                        fabSelectionFloatingBar
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            } else if !isSelecting {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            if usesNotifySheet {
                                openNotifySheet()
                            } else {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    enterFabSelection()
                                }
                            }
                        } label: {
                            Image("icon-notification-add")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(AppColors.primaryDark)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.07), radius: 9.8, y: 5.6)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .accessibilityLabel("Remind employees")
                    }
                    .padding(.bottom, floatingBarBottomInset(for: attendanceUIVersion))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    /// Sit Final notify actions closer to the tab bar than the legacy floating bar.
    private var finalNotifyBottomInset: CGFloat {
        max(Self.mainTabBarHeight - 8, 72)
    }

    /// Final notify — glass close + Notify all / Notify (N); filters drive the target list.
    private var finalNotifyFloatingBar: some View {
        let targets = selectableEmployeeIDs
        let count = targets.count
        let isNotifyingAll = !targets.isEmpty && targets == allNotifiableEmployeeIDs
        let notifyTitle = isNotifyingAll ? "Notify all (\(count))" : "Notify (\(count))"
        return HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    exitFabSelection(restoreFilters: true)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .frame(width: 54, height: 54)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                    }
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel")

            Button {
                guard count > 0 else { return }
                attemptSendFilterReminders()
            } label: {
                Text(notifyTitle)
                    .font(AppFonts.subheadlineBold())
                    .tracking(-0.41)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(count > 0 ? AppColors.primaryDark : AppColors.primaryDark.opacity(0.4))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.22), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
            .accessibilityLabel(notifyTitle)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, finalNotifyBottomInset)
    }

    /// Legacy FAB + swipe — Cancel / Select all / Notify with per-employee selection.
    private var fabSelectionFloatingBar: some View {
        HStack(spacing: 12) {
            floatingCapsuleButton(
                "Cancel",
                foreground: AppColors.fontSecondary,
                style: .tertiary
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    exitFabSelection()
                }
            }

            if !filteredEmployees.isEmpty {
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
            }

            if !selectedForNotification.isEmpty {
                let allSelected = allFilteredEmployeesSelected
                let count = selectedForNotification.count
                floatingCapsuleButton(
                    allSelected ? "Notify all (\(count))" : "Notify (\(count))",
                    icon: "bell",
                    style: .primary
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        let now = Date()
                        for id in selectedForNotification {
                            _ = notifiedEmployees.insert(id)
                            notifiedTimestamps[id] = now
                        }
                        exitFabSelection()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, floatingBarBottomInset(for: attendanceUIVersion))
    }

    private var reminderSentToast: some View {
        Text(reminderSentToastCopy)
            .font(AppFonts.subheadline())
            .tracking(-0.24)
            .foregroundColor(AppColors.surface)
            .padding(16)
            .background(AppColors.fontDefault)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .allowsHitTesting(false)
    }

    private var reminderSentToastCopy: String {
        let count = lastReminderSentCount
        let noun = count == 1 ? "employee" : "employees"
        return "Notifications sent to \(count) \(noun)"
    }

    /// Figma 1392-36602 — shown when Notify all includes already-notified employees.
    private var resendReminderAlert: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsResendReminderAlert = false
                        pendingReminderTargets = []
                    }
                }

            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    Text("Notification already sent to some employees")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.43)
                        .foregroundColor(AppColors.fontDefault)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text("Do you want to send another notification?")
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.43)
                        .foregroundColor(AppColors.fontDefault)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 24)

                VStack(spacing: 10) {
                    Button {
                        sendFilterReminders(to: pendingReminderTargets)
                    } label: {
                        Text("Send again to all")
                            .font(.system(size: 17, weight: .medium))
                            .tracking(-0.43)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppColors.primaryDark)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        let onlyNew = pendingReminderTargets.subtracting(notifiedEmployees)
                        sendFilterReminders(to: onlyNew)
                    } label: {
                        Text("Send only to new")
                            .font(.system(size: 17, weight: .medium))
                            .tracking(-0.43)
                            .foregroundColor(AppColors.fontDefault)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(hex: "787880").opacity(0.16))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsResendReminderAlert = false
                            pendingReminderTargets = []
                        }
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .tracking(-0.43)
                            .foregroundColor(AppColors.fontDefault)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(hex: "787880").opacity(0.16))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .frame(width: 300)
            .background {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(Color.white.opacity(0.72))
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                if showsSelectionAction && !usesFabNotifyStyle {
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
                    if isSelecting && !attendanceMVP && !isViewingNonTodayDate && !usesFilterOnlyNotify {
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
                                isSelectedForNotification: selectedForNotification.contains(employee.id),
                                isActionable: true,
                                hidesBellForFab: usesFabNotifyStyle
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        let rowView = NavigationLink(destination: EmployeeTimeTrackingDetailView(employee: employee)) {
                            EmployeeAnomalyRow(
                                employee: employee,
                                isNotified: Binding(
                                    get: { notifiedEmployees.contains(employee.id) || allNotified },
                                    set: { newValue in
                                        if newValue {
                                            notifiedEmployees.insert(employee.id)
                                            notifiedTimestamps[employee.id] = Date()
                                        } else {
                                            notifiedEmployees.remove(employee.id)
                                            notifiedTimestamps.removeValue(forKey: employee.id)
                                            allNotified = false
                                        }
                                    }
                                ),
                                isActionable: usesFabNotifyStyle ? !isViewingNonTodayDate : (!attendanceMVP && !isViewingNonTodayDate),
                                hidesBellForFab: usesFabNotifyStyle
                            )
                        }
                        .buttonStyle(.plain)

                        let canSwipeNotify = !attendanceMVP
                            && !isViewingNonTodayDate
                            && !usesFilterOnlyNotify
                            && employee.anomalyType != .onTrack
                            && employee.anomalyType != .scheduleNotStarted
                            && !employee.anomalyType.isWarningLevel

                        if canSwipeNotify {
                            let alreadyNotified = notifiedEmployees.contains(employee.id) || allNotified
                            rowView
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            _ = notifiedEmployees.insert(employee.id)
                                            notifiedTimestamps[employee.id] = Date()
                                        }
                                    } label: {
                                        Label(alreadyNotified ? "Notify\nagain" : "Notify", systemImage: "bell")
                                    }
                                    .tint(AppColors.primaryDark)
                                }
                        } else {
                            rowView
                        }
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

// MARK: - Notify employees sheet (Figma 1705:148411)

/// Owns toggle state so the confirm checkmark is enabled on first presentation.
private struct NotifyEmployeesSheet: View {
    private static let categoryOrder: [AnomalyFilterCategory] = [
        .noClockInNorOut, .exceededWorkSchedule, .noClockIn
    ]

    let filterCounts: [AnomalyFilterCategory: Int]
    let targets: (Set<AnomalyFilterCategory>) -> Set<UUID>
    let onCancel: () -> Void
    let onConfirm: (Set<UUID>) -> Void

    /// Seeded on init — avoids empty parent `@State` being captured when the sheet first opens.
    @State private var enabledCategories: Set<AnomalyFilterCategory> = Set(categoryOrder)

    private var canConfirm: Bool { !enabledCategories.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                GlassSymbolButton(
                    systemName: "xmark",
                    foregroundColor: Color(hex: "727272"),
                    accessibilityLabel: "Cancel",
                    action: onCancel
                )

                Spacer(minLength: 8)

                Text("Notify employees with...")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.43)
                    .foregroundColor(AppColors.fontDefault)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                Button {
                    guard canConfirm else { return }
                    let selected = targets(enabledCategories)
                    guard !selected.isEmpty else { return }
                    onConfirm(selected)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: GlassSymbolButton.size, height: GlassSymbolButton.size)
                        .background(canConfirm ? AppColors.primaryDark : AppColors.primaryDark.opacity(0.35))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canConfirm)
                .accessibilityLabel("Send notifications")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            VStack(spacing: 8) {
                ForEach(Self.categoryOrder, id: \.self) { category in
                    let count = filterCounts[category] ?? 0
                    HStack {
                        Text("\(category.rawValue) (\(count))")
                            .font(.system(size: 17, weight: .regular))
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontDefault)

                        Spacer(minLength: 12)

                        Toggle(
                            "",
                            isOn: Binding(
                                get: { enabledCategories.contains(category) },
                                set: { enabled in
                                    if enabled {
                                        enabledCategories.insert(category)
                                    } else {
                                        enabledCategories.remove(category)
                                    }
                                }
                            )
                        )
                        .labelsHidden()
                        .tint(AppColors.successDefault)
                    }
                    .padding(10)
                }
            }
            .padding(.horizontal, 11)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            // Sheet content can be built before `@State` settles; re-seed so confirm is enabled on first open.
            enabledCategories = Set(Self.categoryOrder)
        }
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
