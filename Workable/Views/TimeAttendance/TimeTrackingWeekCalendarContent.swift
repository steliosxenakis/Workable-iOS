import SwiftUI

/// Calendar / List toggle and weekly chart shared by personal and employee time-tracking flows.
/// Figma: 15616-17727 (Calendar), 15616-173383 (List).
/// Session FAB: 15775-245174 (idle) · 15775-245205 (working) · 15849-268875 (on break).
struct TimeTrackingWeekCalendarContent: View {
    @Binding var selectedSubTab: Int
    @Binding var showsAddTimeEntrySheet: Bool
    var weekHours: [DayHours] = TimeAttendanceMockData.defaultWeekHours
    /// Floating clock-in control (Figma play FAB / session pill on calendar drill-in).
    var showsClockInFAB: Bool = true
    /// Employee without time tracking (Figma 16634-38522) — scheduled hours only.
    var hidesTimeTracking: Bool = false

    @Environment(\.breakSupportEnabled) private var breakSupportEnabled
    @Environment(\.breakSupportUIVersion) private var breakSupportUIVersion
    @Environment(\.breaksNestedInTimeEntry) private var breaksNestedInTimeEntry
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("settings.approvalsEnabled") private var approvalsEnabled = false
    @AppStorage(ScheduleChangeRequestUIVersion.appStorageKey) private var scheduleChangeUIVersionRaw =
        ScheduleChangeRequestUIVersion.defaultVersion.rawValue
    @AppStorage(ScheduleChangeRequestPersona.appStorageKey) private var scheduleChangePersonaRaw =
        ScheduleChangeRequestPersona.defaultPersona.rawValue
    @ObservedObject private var session = ClockInSessionStore.shared
    @ObservedObject private var pendingStore = PendingScheduleChangeStore.shared
    @ObservedObject private var quickWorkplaceStore = QuickWorkplaceOverrideStore.shared

    private var canCreateScheduleRequest: Bool {
        ScheduleChangeRequestPersona.showsEmployeeRequestUI(
            approvalsEnabled: approvalsEnabled,
            versionRaw: scheduleChangeUIVersionRaw,
            personaRaw: scheduleChangePersonaRaw
        )
    }

    private var isManagerPersona: Bool {
        ScheduleChangeRequestPersona.showsManagerInboxRequest(
            approvalsEnabled: approvalsEnabled,
            versionRaw: scheduleChangeUIVersionRaw,
            personaRaw: scheduleChangePersonaRaw
        )
    }

    @Namespace private var sessionFABNamespace
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdCompleted = false
    @State private var holdGeneration = 0
    @State private var activeHoldAction: HoldAction?
    @State private var breakEmojiDraft = "☕"
    @State private var isEmojiKeyboardFocused = false
    @State private var showsWorkScheduleSheet = false
    @State private var showsRequestScheduleChangeSheet = false
    @State private var requestChangeDate = ScheduleChangeFormField.tomorrow
    @State private var showsWorkplaceChangeToast = false
    /// 0 = this week, 1 = next week, -1 = last week, etc. Any week other than "this week"
    /// falls back to a scheduled-only mock (nothing worked/logged yet for it).
    @State private var weekOffset = 0

    private enum HoldAction {
        case clockIn, clockOut
    }

    /// Sit the session widget above the glass tab menu (Figma 15775:245205).
    private static let fabGapAboveMenu: CGFloat = 8
    private static let fabBottomInset: CGFloat = TabBarView.menuTopFromBottom + fabGapAboveMenu
    private static let fabSize: CGFloat = 56
    private static let holdDuration: TimeInterval = 1.0
    private static let ringLineWidth: CGFloat = 3.5
    private static let holdingButtonSize: CGFloat = 90
    /// Clock in / out morph.
    private static let sessionTransition = Animation.spring(response: 0.52, dampingFraction: 0.88)
    /// Working ↔ break — timer slides linearly into the single-row break pill.
    private static let breakTransition = Animation.linear(duration: 0.28)

    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    // Matches the work schedule's 09:00–18:00 (Mon–Thu) / 09:00–16:30 (Fri) range, with a
    // 1-hour trailing buffer.
    private let chartStartHour: Double = 9
    private let chartEndHour: Double = 19
    private let pixelsPerHour: CGFloat = 33
    private let dayColumnWidth: CGFloat = 37
    private let workedBarWidth: CGFloat = 17
    private let timeGutterWidth: CGFloat = 52
    private let scheduledFill = AppColors.separator
    private let workedFill = AppColors.fontSecondary

    private var chartHeight: CGFloat {
        CGFloat(chartEndHour - chartStartHour) * pixelsPerHour
    }

    private var timeSlots: [Int] {
        Array(stride(from: Int(chartStartHour), through: Int(chartEndHour), by: 1))
    }

    /// This week uses the real (mock) data passed in; any other week hasn't happened (or
    /// hasn't been logged) yet, so it just shows what's scheduled. Worked entries after
    /// today are hidden — those days have not been logged yet. Employees without time
    /// tracking always see the scheduled week, never logged hours.
    private var displayedWeekHours: [DayHours] {
        let source: [DayHours]
        if hidesTimeTracking || weekOffset != 0 {
            source = TimeAttendanceMockData.scheduledOnlyWeekHours
        } else {
            source = weekHours
        }
        guard weekOffset == 0, !hidesTimeTracking else { return source }
        return source.enumerated().map { index, day in
            let weekdayNumber = ((index + 1) % 7) + 1
            guard isFutureDay(dateForWeekdayNumber(weekdayNumber)) else { return day }
            return DayHours(
                day: day.day,
                scheduled: day.scheduled,
                worked: nil,
                breaks: [],
                hasAnomaly: false,
                anomalyHour: nil,
                timeEntry: nil
            )
        }
    }

    private var nowMarkerHour: Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60
        return min(max(hour, chartStartHour), chartEndHour)
    }

    private var weekNavigationTitle: String {
        switch weekOffset {
        case 0: return "This week"
        case 1: return "Next week"
        case -1: return "Last week"
        case let offset where offset > 1: return "\(offset) weeks from now"
        default: return "\(-weekOffset) weeks ago"
        }
    }

    private var scheduledTotalText: String {
        totalText(for: displayedWeekHours.compactMap(\.scheduled))
    }

    private var workedTotalText: String {
        totalText(for: displayedWeekHours.compactMap(\.worked))
    }

    private func totalText(for ranges: [(Double, Double)]) -> String {
        let totalHours = ranges.reduce(0) { $0 + max(0, $1.1 - $1.0) }
        let hours = Int(totalHours)
        let minutes = Int((totalHours - Double(hours)) * 60)
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    private var buttonSize: CGFloat {
        isHolding ? Self.holdingButtonSize : Self.fabSize
    }

    private var scrollBottomInset: CGFloat {
        guard showsClockInFAB else { return 24 }
        let controlHeight: CGFloat = Self.fabSize
        return Self.fabBottomInset + controlHeight + 24
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    subTabToggle
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    if selectedSubTab == 0 {
                        calendarContent
                    } else {
                        listContent
                    }
                }
                .padding(.bottom, scrollBottomInset)
            }

            if showsClockInFAB {
                sessionFloatingControl
                    .padding(.bottom, Self.fabBottomInset)
                    // Always trailing + 24pt — avoids a center jump when clocking in.
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 24)
                    // Halo/shadow room above only — keep the 24pt gap to the menu.
                    .padding(.top, 18)
            }
        }
        .scheduleRequestSentToast(isPresented: $showsWorkplaceChangeToast)
        .sheet(isPresented: $showsAddTimeEntrySheet) {
            EditTimeEntryView.addToday()
                .environment(\.breakSupportEnabled, breakSupportEnabled)
                .environment(\.breakSupportUIVersion, breakSupportUIVersion)
                .environment(\.breaksNestedInTimeEntry, breaksNestedInTimeEntry)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showsWorkScheduleSheet) {
            WorkScheduleView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showsRequestScheduleChangeSheet) {
            ScheduleChangeRequestSheet(
                date: requestChangeDate,
                onSend: { triggerScheduleRequestSentToast($showsWorkplaceChangeToast) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            session.syncFromExternalSources(breaksEnabled: breakSupportEnabled)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                session.syncFromExternalSources(breaksEnabled: breakSupportEnabled)
            }
        }
        .animation(Self.sessionTransition, value: session.isClockedIn)
        .animation(Self.breakTransition, value: session.isOnBreak)
        .background {
            EmojiKeyboardField(
                emoji: $breakEmojiDraft,
                isFocused: $isEmojiKeyboardFocused,
                onEmojiPicked: { picked in
                    if session.isOnBreak, breakSupportUIVersion.usesEditableBreakEmojiLabel {
                        session.updateBreakEmoji(picked, breaksEnabled: breakSupportEnabled)
                    }
                }
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Calendar / List chips (Figma selectors)

    private var subTabToggle: some View {
        HStack(spacing: 8) {
            subTabChip(title: "Calendar", systemImage: "calendar", index: 0)
            subTabChip(title: "List", systemImage: "list.bullet", index: 1)
            Spacer(minLength: 0)
        }
    }

    private func subTabChip(title: String, systemImage: String, index: Int) -> some View {
        let isSelected = selectedSubTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedSubTab = index }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .regular))
                Text(title)
                    .font(AppFonts.subheadStrong())
            }
            .foregroundColor(AppColors.fontDefault)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(isSelected ? AppColors.fontDefault : AppColors.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        weekCard
            .padding(.horizontal, 16)
    }

    private var weekCard: some View {
        VStack(spacing: 24) {
            weekNavigation

            VStack(spacing: 16) {
                Rectangle()
                    .fill(AppColors.separator)
                    .frame(height: 1)

                scheduleSummary

                Rectangle()
                    .fill(AppColors.separator)
                    .frame(height: 1)

                weekChart
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 1)
        )
    }

    private var weekNavigation: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { weekOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                    .frame(width: 24, height: 24)
            }
            Spacer()
            HStack(spacing: 4) {
                Text(weekNavigationTitle)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { weekOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                    .frame(width: 24, height: 24)
            }
        }
    }

    private var scheduleSummary: some View {
        HStack(spacing: 8) {
            summaryItem(
                color: scheduledFill,
                label: "Scheduled",
                value: scheduledTotalText
            )
            if !hidesTimeTracking {
                summaryItem(
                    color: workedFill,
                    label: "Worked",
                    value: workedTotalText
                )
            }
            Spacer(minLength: 0)
        }
    }

    private func summaryItem(color: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(AppColors.fontSecondary, lineWidth: 1)
                )
                .frame(width: 10, height: 10)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                Text(value)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
            }
        }
        .padding(.horizontal, 8)
    }

    private var weekChart: some View {
        VStack(spacing: 0) {
            dayLabels
            chartCanvas
        }
    }

    private var dayLabels: some View {
        HStack(spacing: 3) {
            Color.clear.frame(width: timeGutterWidth)
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let weekdayNumber = ((index + 1) % 7) + 1
                VStack(spacing: 4) {
                    Text(day)
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(index < 5 ? AppColors.fontSecondary : AppColors.iconInactive)
                    // On-site vs remote (home/travel) for that scheduled day (Figma 16908-805551)
                    // — weekends have no entry in `workScheduleDays`, so no icon shows.
                    if let day = scheduleDay(forWeekdayNumber: weekdayNumber) {
                        workplaceQuickChangeMenu(for: day)
                    }
                }
                .frame(width: dayColumnWidth)
                .padding(.vertical, 12)
            }
            Spacer(minLength: 0)
        }
    }

    private enum QuickWorkplaceChoice: Hashable {
        case onSite, home, travel
    }

    /// Boxed icon (Figma 16908-805551) — tapping it opens a native menu to switch that day's
    /// workplace without opening the full "Request schedule change" form. `Toggle` rows (not a
    /// label-based `Picker`, which rendered its items inline instead of collapsing into the
    /// small boxed trigger) get the native checkmark on the selected row for free, and `Section`
    /// groups Home/Travel under "Remote".
    private func workplaceQuickChangeMenu(for day: WorkScheduleDay) -> some View {
        let choice = quickWorkplaceStore.choice(for: day)
        let selection = quickWorkplaceChoice(for: choice)
        return Menu {
            workplaceToggle(.onSite, title: "On-site", systemImage: "building.2.fill", selection: selection, day: day)
            Section("Remote") {
                workplaceToggle(.home, title: "Home", systemImage: "house.fill", selection: selection, day: day)
                workplaceToggle(.travel, title: "Travel", systemImage: "airplane", selection: selection, day: day)
            }
        } label: {
            Image(systemName: choice.systemImage)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
                .frame(width: 22, height: 20)
                .background(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppColors.separator, lineWidth: 1)
                )
        }
        .accessibilityLabel("Change workplace for \(day.weekday)")
    }

    private func quickWorkplaceChoice(for choice: QuickWorkplaceOverrideStore.Choice) -> QuickWorkplaceChoice {
        switch choice.workplace {
        case .onSite: return .onSite
        case .remote: return choice.remoteDetail == .travel ? .travel : .home
        }
    }

    private func workplaceToggle(
        _ value: QuickWorkplaceChoice,
        title: String,
        systemImage: String,
        selection: QuickWorkplaceChoice,
        day: WorkScheduleDay
    ) -> some View {
        Toggle(isOn: Binding(
            get: { selection == value },
            set: { isOn in
                guard isOn else { return }
                switch value {
                case .onSite:
                    applyQuickWorkplaceChange(day: day, workplace: .onSite, remoteDetail: nil)
                case .home:
                    applyQuickWorkplaceChange(day: day, workplace: .remote, remoteDetail: .home)
                case .travel:
                    applyQuickWorkplaceChange(day: day, workplace: .remote, remoteDetail: .travel)
                }
            }
        )) {
            Label(title, systemImage: systemImage)
        }
    }

    /// Updates the calendar's own icon (`QuickWorkplaceOverrideStore`) and, so the Work Schedule
    /// sheet shows the same crossed-out/pending treatment a full request produces, submits a
    /// one-off `PendingScheduleChangeRequest` for this week's occurrence of `day`.
    private func applyQuickWorkplaceChange(day: WorkScheduleDay, workplace: WorkplaceType, remoteDetail: RemoteWorkplaceDetail?) {
        quickWorkplaceStore.set(weekdayNumber: day.weekdayNumber, workplace: workplace, remoteDetail: remoteDetail)

        let date = day.date()
        let breakSuffix = day.breakText.map { " (Break: \($0))" } ?? ""
        pendingStore.submit(
            PendingScheduleChangeRequest(
                weekdayNumber: day.weekdayNumber,
                dateLabel: ScheduleChangeFormField.fullDateFormatter.string(from: date),
                oldRangesText: day.rangesText,
                oldTotalText: day.totalText,
                newRangesText: day.rangesText,
                newTotalText: "\(day.totalHoursText)\(breakSuffix) | \(workplace.rawValue)",
                dateSpans: [PendingScheduleDateSpan(start: date, end: date)]
            )
        )

        triggerScheduleRequestSentToast($showsWorkplaceChangeToast)
    }

    private func scheduleDay(forWeekdayNumber weekdayNumber: Int) -> WorkScheduleDay? {
        TimeAttendanceMockData.workScheduleDays.first { $0.weekdayNumber == weekdayNumber }
    }

    private var chartCanvas: some View {
        ZStack(alignment: .topLeading) {
            // Hour labels + grid lines (8:00 AM at top → 5:00 PM at bottom)
            ForEach(timeSlots, id: \.self) { hour in
                let y = CGFloat(Double(hour) - chartStartHour) * pixelsPerHour
                HStack(spacing: 0) {
                    Text(hourLabel(hour))
                        .font(.system(size: 10, weight: .regular))
                        .tracking(0.12)
                        .foregroundColor(AppColors.iconDefault)
                        .frame(width: timeGutterWidth, alignment: .leading)

                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                }
                .offset(y: y)
            }

            // Day columns with scheduled / worked bars
            HStack(alignment: .top, spacing: 3) {
                Color.clear.frame(width: timeGutterWidth, height: chartHeight)
                ForEach(Array(displayedWeekHours.enumerated()), id: \.offset) { index, dayData in
                    // M/T/W/T/F/S/S at index 0...6 → Calendar weekday numbers 2...7, 1.
                    dayColumn(dayData, weekdayNumber: ((index + 1) % 7) + 1)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: chartHeight + 12, alignment: .top)
    }

    private func dateForWeekdayNumber(_ weekdayNumber: Int) -> Date {
        let calendar = Calendar.current
        let reference = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: reference)?.start ?? reference
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)
        components.weekday = weekdayNumber
        return calendar.nextDate(
            after: weekStart.addingTimeInterval(-1),
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? reference
    }

    private func isPastDay(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }

    private func isFutureDay(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date())
    }

    @ViewBuilder
    private func dayColumn(_ dayData: DayHours, weekdayNumber: Int) -> some View {
        let columnDate = dateForWeekdayNumber(weekdayNumber)
        let pendingRequest = isPastDay(columnDate) ? nil : pendingStore.pending(for: columnDate)
        let isPending = pendingRequest != nil
        let column = ZStack(alignment: .top) {
            if isPending, let request = pendingRequest, request.newRangesText == "Day off" {
                // Requested day off — no scheduled block.
            } else if isPending, let ranges = pendingRequest?.newHourRanges, !ranges.isEmpty {
                ForEach(Array(ranges.enumerated()), id: \.offset) { _, range in
                    pendingBar(from: range.start, to: range.end, width: dayColumnWidth)
                }
            } else if let scheduled = dayData.scheduled {
                if isPending {
                    pendingBar(from: scheduled.0, to: scheduled.1, width: dayColumnWidth)
                } else {
                    bar(
                        from: scheduled.0,
                        to: scheduled.1,
                        width: dayColumnWidth,
                        color: scheduledFill,
                        cornerRadius: 0
                    )
                }
            }

            if !hidesTimeTracking, let worked = dayData.worked {
                bar(
                    from: worked.0,
                    to: worked.1,
                    width: workedBarWidth,
                    color: workedFill,
                    cornerRadius: 8
                )
            }

            // Pause/break segments — fill Informative/200 + dashed top/bottom stroke
            // (Figma 15786:77791 / 15786:77709).
            if !hidesTimeTracking, breakSupportEnabled {
                ForEach(Array(dayData.breaks.enumerated()), id: \.offset) { _, interval in
                    breakBar(from: interval.0, to: interval.1)
                }
            }

            if weekOffset == 0, Calendar.current.isDateInToday(columnDate) {
                nowMarker(at: nowMarkerHour)
            }
        }
        .frame(width: dayColumnWidth, height: chartHeight, alignment: .top)
        .contentShape(Rectangle())

        if isPending, let pendingRequest {
            NavigationLink {
                ScheduleChangeRequestDetailView(
                    item: pendingRequest.asInboxItem(),
                    mode: isManagerPersona ? .managerReview : .employeePending
                )
            } label: {
                column
            }
            .buttonStyle(.plain)
        } else if !hidesTimeTracking, let entry = resolvedEntry(from: dayData) {
            NavigationLink {
                TimeEntryDetailView(entry: entry)
            } label: {
                column
            }
            .buttonStyle(.plain)
        } else if canCreateScheduleRequest {
            Button {
                requestChangeDate = dateForWeekdayNumber(weekdayNumber)
                showsRequestScheduleChangeSheet = true
            } label: {
                column
            }
            .buttonStyle(.plain)
        } else if dayData.hasAnomaly {
            Button {
                showsAddTimeEntrySheet = true
            } label: {
                column
            }
            .buttonStyle(.plain)
        } else if dayData.scheduled != nil {
            Button {
                showsWorkScheduleSheet = true
            } label: {
                column
            }
            .buttonStyle(.plain)
        } else {
            column
        }
    }

    /// Strip breaks from the detail payload when the feature flag is off.
    private func resolvedEntry(from dayData: DayHours) -> TimeEntryDetail? {
        guard var entry = dayData.timeEntry else { return nil }
        if !breakSupportEnabled {
            entry.breaks = []
        }
        return entry
    }

    private func bar(
        from start: Double,
        to end: Double,
        width: CGFloat,
        color: Color,
        cornerRadius: CGFloat
    ) -> some View {
        let top = CGFloat(start - chartStartHour) * pixelsPerHour
        let height = CGFloat(max(0, end - start)) * pixelsPerHour
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(color)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.fontSecondary, lineWidth: 1)
            )
            .frame(width: width, height: height)
            .offset(y: top)
    }

    /// Scheduled block for a day with a pending change request — dashed outline instead
    /// of the solid scheduled fill.
    private func pendingBar(from start: Double, to end: Double, width: CGFloat) -> some View {
        let top = CGFloat(start - chartStartHour) * pixelsPerHour
        let height = CGFloat(max(0, end - start)) * pixelsPerHour
        return Rectangle()
            .fill(AppColors.background)
            .overlay(
                Rectangle()
                    .strokeBorder(AppColors.fontDefault, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
            .frame(width: width, height: height)
            .offset(y: top)
    }

    /// Break segment: Informative/200 fill + dashed top/bottom Informative background stroke.
    private func breakBar(from start: Double, to end: Double) -> some View {
        let top = CGFloat(start - chartStartHour) * pixelsPerHour
        let height = CGFloat(max(0, end - start)) * pixelsPerHour
        return Rectangle()
            .fill(AppColors.background)
            .frame(width: workedBarWidth, height: height)
            .overlay(alignment: .top) { breakDashedEdge }
            .overlay(alignment: .bottom) { breakDashedEdge }
            .offset(y: top)
    }

    private var breakDashedEdge: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0.5))
            path.addLine(to: CGPoint(x: size.width, y: 0.5))
            context.stroke(
                path,
                with: .color(AppColors.fontSecondary),
                style: StrokeStyle(lineWidth: 1, dash: [2, 2])
            )
        }
        .frame(height: 1)
        .allowsHitTesting(false)
    }

    private func nowMarker(at hour: Double) -> some View {
        let top = CGFloat(hour - chartStartHour) * pixelsPerHour
        return HStack(spacing: 0) {
            Circle()
                .fill(AppColors.fontDefault)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(AppColors.fontDefault)
                .frame(width: 34, height: 1.5)
        }
        .offset(x: 4, y: top - 4)
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%02d:00 %@", h, period)
    }

    // MARK: - Session floating control (Figma 15775:245174 / 245205 / 245237)

    @ViewBuilder
    private var sessionFloatingControl: some View {
        Group {
            if !session.isClockedIn {
                playFAB
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.88).combined(with: .opacity),
                            removal: .scale(scale: 0.92).combined(with: .opacity)
                        )
                    )
            } else {
                // One pill morphs working ↔ break so the timer can slide linearly.
                activeSessionPill
            }
        }
    }

    /// Idle — hold-to-clock-in play FAB (bottom trailing).
    private var playFAB: some View {
        ZStack {
            Color.clear
                .frame(width: Self.fabSize, height: Self.fabSize)

            ZStack {
                Circle()
                    .stroke(AppColors.activeBackground.opacity(0.55), lineWidth: Self.ringLineWidth)
                    .frame(width: buttonSize, height: buttonSize)
                    .opacity((isHolding || holdProgress > 0) && activeHoldAction == .clockIn ? 1 : 0)

                Circle()
                    .trim(from: 0, to: activeHoldAction == .clockIn ? holdProgress : 0)
                    .stroke(
                        AppColors.primaryDark,
                        style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round)
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .fill(AppColors.activeBackground)
                    .frame(
                        width: buttonSize - (isHolding && activeHoldAction == .clockIn ? 7 : 0),
                        height: buttonSize - (isHolding && activeHoldAction == .clockIn ? 7 : 0)
                    )

                Image(systemName: "play.fill")
                    .font(.system(size: isHolding ? 26 : 17, weight: .medium))
                    .foregroundColor(AppColors.primaryDark)
                    .offset(x: (isHolding ? 26 : 17) * 0.08)
            }
            .frame(width: buttonSize, height: buttonSize)
            .shadow(
                color: AppColors.primary.opacity(0.5),
                radius: isHolding && activeHoldAction == .clockIn ? 13.7 : 8.5,
                x: 0,
                y: 0
            )
            .contentShape(Circle())
            .gesture(holdGesture(for: .clockIn))
            .accessibilityLabel("Clock in")
            .accessibilityHint("Press and hold to clock in")
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isHolding)
        }
        .frame(width: Self.fabSize, height: Self.fabSize)
    }

    /// Working / on-break session pill — shared timer identity so it slides on state change.
    /// On break: emoji + `00m 01s` + End break (Figma 15849:268875).
    private var activeSessionPill: some View {
        let onBreak = session.isOnBreak && breakSupportEnabled
        return HStack(spacing: onBreak ? 8 : 16) {
            if onBreak {
                HStack(alignment: .center, spacing: 4) {
                    onBreakEmojiPill
                    sessionTimerLabels(
                        primarySize: 17,
                        secondarySize: 13,
                        omitHoursWhenZero: true
                    )
                    .matchedGeometryEffect(id: "fabSessionTimer", in: sessionFABNamespace)
                }
            } else {
                sessionTimerLabels(primarySize: 22, secondarySize: 16)
                    .matchedGeometryEffect(id: "fabSessionTimer", in: sessionFABNamespace)
            }

            // Instant control swap — no animation on buttons.
            Group {
                if onBreak {
                    Button {
                        endBreak()
                    } label: {
                        Text("End break")
                            .font(AppFonts.headline())
                            .tracking(-0.41)
                            .foregroundColor(AppColors.primaryDark)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(AppColors.activeBackground)
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("End break")
                    .padding(.trailing, 2)
                    .padding(.vertical, 2)
                } else {
                    HStack(spacing: 16) {
                        if breakSupportEnabled {
                            outlinedCircleControl(
                                systemName: "pause.fill",
                                iconSize: 15,
                                accessibilityLabel: "Pause"
                            ) {
                                startBreak()
                            }
                        }

                        holdOverflowSlot {
                            stopControl
                        }
                    }
                }
            }
            .transaction { $0.animation = nil }
        }
        .padding(.leading, 24)
        .padding(.trailing, onBreak ? 0 : 4)
        .padding(.vertical, onBreak ? 0 : 4)
        .frame(height: onBreak ? Self.fabSize : nil)
        // Capsule fill only — no clipShape, so stop/halo aren’t cut by the pill edge.
        .background {
            Capsule(style: .continuous)
                .fill(AppColors.surface)
                .matchedGeometryEffect(id: "sessionPillChrome", in: sessionFABNamespace)
                .sessionPillShadow()
        }
    }

    /// Emoji-only status chip (Figma Label/Pill on 15849:268875).
    @ViewBuilder
    private var onBreakEmojiPill: some View {
        let emoji = session.breakEmoji
            ?? (breakSupportUIVersion.usesEditableBreakEmojiLabel ? breakEmojiDraft : nil)
        if let emoji, !emoji.isEmpty {
            let pill = EmojiText(emoji: emoji, size: 16)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if breakSupportUIVersion.usesEditableBreakEmojiLabel {
                pill
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture {
                        if let current = session.breakEmoji, !current.isEmpty {
                            breakEmojiDraft = current
                        }
                        isEmojiKeyboardFocused = true
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Edit break emoji")
            } else {
                pill
            }
        }
    }

    private func sessionTimerLabels(
        primarySize: CGFloat,
        secondarySize: CGFloat,
        omitHoursWhenZero: Bool = false
    ) -> some View {
        let anchor: Date = {
            if session.isOnBreak, let breakStart = session.breakStartDate {
                return breakStart
            }
            return session.clockInDate ?? Date()
        }()

        return TimelineView(.periodic(from: anchor, by: 1)) { context in
            let elapsed = max(0, Int(context.date.timeIntervalSince(anchor)))
            let hours = elapsed / 3600
            let minutes = (elapsed % 3600) / 60
            let seconds = elapsed % 60
            let primaryText = omitHoursWhenZero && hours == 0
                ? String(format: "%02dm", minutes)
                : "\(hours)h \(String(format: "%02d", minutes))m"

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(primaryText)
                    .font(.system(size: primarySize, weight: .semibold))
                    .tracking(primarySize >= 20 ? 0.35 : -0.41)
                    .foregroundColor(AppColors.fontDefault)
                Text(String(format: "%02ds", seconds))
                    .font(.system(size: secondarySize, weight: .regular))
                    .tracking(secondarySize >= 16 ? -0.32 : -0.08)
                    .foregroundColor(AppColors.fontSecondary)
            }
            .contentTransition(.numericText())
        }
    }

    private var stopControl: some View {
        let isThisHold = isHolding && activeHoldAction == .clockOut
        return ZStack {
            Circle()
                .stroke(AppColors.iconInactive.opacity(0.7), lineWidth: Self.ringLineWidth)
                .frame(width: buttonSize, height: buttonSize)
                .opacity(isThisHold ? 1 : 0)

            Circle()
                .trim(from: 0, to: isThisHold ? holdProgress : 0)
                .stroke(
                    AppColors.iconDefault,
                    style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round)
                )
                .frame(width: buttonSize, height: buttonSize)
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(AppColors.fontDefault)
                .frame(
                    width: buttonSize - (isThisHold ? 7 : 0),
                    height: buttonSize - (isThisHold ? 7 : 0)
                )

            Image(systemName: "stop.fill")
                .font(.system(size: isHolding ? 22 : 15, weight: .medium))
                .foregroundColor(AppColors.surface)
        }
        .frame(width: buttonSize, height: buttonSize)
        .shadow(
            color: Color(hex: "333E49").opacity(0.48),
            radius: isThisHold ? 13.7 : 8.5,
            x: 0,
            y: 0
        )
        .contentShape(Circle())
        .gesture(holdGesture(for: .clockOut))
        .accessibilityLabel("Clock out")
        .accessibilityHint("Press and hold to clock out")
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isHolding)
    }

    private func holdOverflowSlot<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.clear
                .frame(width: Self.fabSize, height: Self.fabSize)
            content()
        }
        .frame(width: Self.fabSize, height: Self.fabSize)
    }

    private func outlinedCircleControl(
        systemName: String,
        iconSize: CGFloat,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                // strokeBorder keeps the ring inside the 56pt frame so the pill
                // clipShape doesn’t cut the top/bottom (unlike centered .stroke).
                Circle()
                    .strokeBorder(AppColors.fontDefault, lineWidth: 1.5)
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(AppColors.fontDefault)
            }
            .frame(width: Self.fabSize, height: Self.fabSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func holdGesture(for action: HoldAction) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isHolding else { return }
                beginHold(action)
            }
            .onEnded { _ in
                endHold()
            }
    }

    private func beginHold(_ action: HoldAction) {
        activeHoldAction = action
        isHolding = true
        holdProgress = 0
        holdCompleted = false
        holdGeneration += 1
        let generation = holdGeneration

        withAnimation(.linear(duration: Self.holdDuration)) {
            holdProgress = 1
        }

        Task { @MainActor in
            let nanos = UInt64(Self.holdDuration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard generation == holdGeneration, isHolding, holdProgress >= 0.99 else { return }
            finishHold()
        }
    }

    private func endHold() {
        guard !holdCompleted else { return }

        holdGeneration += 1
        if holdProgress >= 0.99 {
            finishHold()
        } else {
            withAnimation(.easeOut(duration: 0.22)) {
                isHolding = false
                holdProgress = 0
            }
        }
    }

    private func finishHold() {
        guard !holdCompleted else { return }
        holdCompleted = true
        holdGeneration += 1

        switch activeHoldAction {
        case .clockIn:
            withAnimation(Self.sessionTransition) {
                isHolding = false
                holdProgress = 0
                session.clockIn(breaksEnabled: breakSupportEnabled)
            }
        case .clockOut:
            withAnimation(Self.sessionTransition) {
                isHolding = false
                holdProgress = 0
                session.clockOut()
            }
        case .none:
            break
        }
    }

    private func startBreak() {
        withAnimation(Self.breakTransition) {
            isHolding = false
            holdProgress = 0
            if breakSupportUIVersion.usesEditableBreakEmojiLabel {
                let emoji = breakEmojiDraft.isEmpty ? "☕" : breakEmojiDraft
                session.startBreak(
                    breaksEnabled: breakSupportEnabled,
                    plannedMinutes: 30,
                    emoji: emoji
                )
            } else {
                session.startBreak(breaksEnabled: breakSupportEnabled, plannedMinutes: 30)
            }
        }
    }

    private func endBreak() {
        withAnimation(Self.breakTransition) {
            isHolding = false
            holdProgress = 0
            session.endBreak(breaksEnabled: breakSupportEnabled)
        }
    }

    // MARK: - List Content (Figma 15616-173383 + break support variants)

    private var listDays: [TimesheetListDay] {
        TimeAttendanceMockData.defaultTimesheetListDays
    }

    private var listContent: some View {
        VStack(spacing: 24) {
            workScheduleBanner

            if !hidesTimeTracking {
                ForEach(listDays) { day in
                    listDaySection(day)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    /// "Today's work schedule" banner above the List view (Figma 15849-268785).
    private var workScheduleBanner: some View {
        Button {
            showsWorkScheduleSheet = true
        } label: {
            HStack(spacing: 8) {
                Text(TimeAttendanceMockData.todaysScheduleBannerText)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "info.circle")
                    .foregroundColor(AppColors.iconDefault)
            }
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(AppColors.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func listDaySection(_ day: TimesheetListDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.title)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)

            VStack(spacing: 12) {
                ForEach(Array(day.entries.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                    }
                    NavigationLink {
                        TimeEntryDetailView(entry: listDetail(for: entry, day: day))
                    } label: {
                        listEntryBlock(entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            // Figma Dashboard 4050-88413 — Timesheet card shadow
            .shadow(color: .black.opacity(0.07), radius: 7, y: 4)
        }
    }

    private func listDetail(for entry: TimesheetListEntry, day: TimesheetListDay) -> TimeEntryDetail {
        var detail = entry.detail(dateLabel: day.detailDateLabel)
        if !breakSupportEnabled {
            detail.breaks = []
        }
        return detail
    }

    private func listEntryBlock(_ entry: TimesheetListEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                HStack(spacing: 2) {
                    Text(entry.start)
                        .foregroundColor(AppColors.fontDefault)
                    Text("-")
                        .foregroundColor(AppColors.iconDefault)
                    Text(entry.end)
                        .foregroundColor(AppColors.fontDefault)
                }
                .font(AppFonts.headline())

                Spacer(minLength: 8)

                Text(entry.duration)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Session pill shadow (Figma 15775:247833 / 247920)

private extension View {
    /// Dual drop shadow: `#6F7073` @ 18%, (0, 6) blur ~17 + (0, 3) blur ~10.
    func sessionPillShadow() -> some View {
        shadow(color: Color(hex: "6F7073").opacity(0.18), radius: 8.5, x: 0, y: 6)
            .shadow(color: Color(hex: "6F7073").opacity(0.18), radius: 5, x: 0, y: 3)
    }
}
