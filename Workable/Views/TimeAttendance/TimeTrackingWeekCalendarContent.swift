import SwiftUI

/// Calendar / List toggle and weekly chart shared by personal and employee time-tracking flows.
/// Figma: 15616-17727 (Calendar), 15616-173383 (List).
struct TimeTrackingWeekCalendarContent: View {
    @Binding var selectedSubTab: Int
    var weekHours: [DayHours] = TimeAttendanceMockData.defaultWeekHours
    /// Floating clock-in control (Figma play FAB on calendar drill-in).
    var showsClockInFAB: Bool = true

    @Environment(\.breakSupportEnabled) private var breakSupportEnabled
    @State private var showsAddTimeEntrySheet = false

    /// Sit the play FAB above the floating tab bar (same inset pattern as attendance FABs).
    private static let fabBottomInset: CGFloat = TabBarView.barHeight + 16
    private static let fabSize: CGFloat = 56

    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    private let chartStartHour: Double = 8
    private let chartEndHour: Double = 17
    private let pixelsPerHour: CGFloat = 33
    private let dayColumnWidth: CGFloat = 37
    private let workedBarWidth: CGFloat = 17
    private let timeGutterWidth: CGFloat = 52
    private let scheduledFill = Color(hex: "C7E2FF").opacity(0.6)

    private var chartHeight: CGFloat {
        CGFloat(chartEndHour - chartStartHour) * pixelsPerHour
    }

    private var timeSlots: [Int] {
        Array(stride(from: Int(chartStartHour), through: Int(chartEndHour), by: 1))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                .padding(.bottom, showsClockInFAB ? Self.fabBottomInset + Self.fabSize + 16 : 24)
            }

            if showsClockInFAB {
                clockInFAB
                    .padding(.trailing, 24)
                    .padding(.bottom, Self.fabBottomInset)
            }
        }
        .sheet(isPresented: $showsAddTimeEntrySheet) {
            EditTimeEntryView.addToday()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
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
            .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AppColors.activeBackground : AppColors.surface)
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
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Figma Dashboard 4050-88397 — TT Overview card shadow
        .shadow(color: .black.opacity(0.07), radius: 7, y: 4)
    }

    private var weekNavigation: some View {
        HStack {
            Button {} label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                    .frame(width: 24, height: 24)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("This week")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.primaryDark)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.primaryDark)
            }
            Spacer()
            Button {} label: {
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
                color: Color(hex: "C7E2FF"),
                label: "Scheduled",
                value: "40h"
            )
            summaryItem(
                color: AppColors.informativeDefault,
                label: "Worked",
                value: "32h 30m"
            )
            Spacer(minLength: 0)
        }
    }

    private func summaryItem(color: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
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
                Text(day)
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(index < 5 ? AppColors.fontSecondary : AppColors.iconInactive)
                    .frame(width: dayColumnWidth)
                    .padding(.vertical, 12)
            }
            Spacer(minLength: 0)
        }
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
                ForEach(Array(weekHours.enumerated()), id: \.offset) { _, dayData in
                    dayColumn(dayData)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: chartHeight + 12, alignment: .top)
    }

    @ViewBuilder
    private func dayColumn(_ dayData: DayHours) -> some View {
        let column = ZStack(alignment: .top) {
            if let scheduled = dayData.scheduled {
                bar(
                    from: scheduled.0,
                    to: scheduled.1,
                    width: dayColumnWidth,
                    color: scheduledFill,
                    cornerRadius: 0
                )
            }

            if let worked = dayData.worked {
                bar(
                    from: worked.0,
                    to: worked.1,
                    width: workedBarWidth,
                    color: AppColors.informativeDefault,
                    cornerRadius: 8
                )
            }

            // Pause/break segments inside worked hours — lighter blue than worked fill.
            if breakSupportEnabled {
                ForEach(Array(dayData.breaks.enumerated()), id: \.offset) { _, interval in
                    bar(
                        from: interval.0,
                        to: interval.1,
                        width: workedBarWidth,
                        color: AppColors.iconInactive,
                        cornerRadius: 0
                    )
                }
            }

            if dayData.hasAnomaly {
                anomalyMarker(at: dayData.anomalyHour ?? chartStartHour)
            }
        }
        .frame(width: dayColumnWidth, height: chartHeight, alignment: .top)
        .contentShape(Rectangle())

        if let entry = resolvedEntry(from: dayData) {
            NavigationLink {
                TimeEntryDetailView(entry: entry)
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
            .frame(width: width, height: height)
            .offset(y: top)
    }

    private func anomalyMarker(at hour: Double) -> some View {
        let top = CGFloat(hour - chartStartHour) * pixelsPerHour
        return HStack(spacing: 0) {
            Circle()
                .fill(AppColors.dangerDefault)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(AppColors.dangerDefault)
                .frame(width: 34, height: 1.5)
        }
        .offset(x: 4, y: top - 4)
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%02d:00 %@", h, period)
    }

    // MARK: - Clock-in FAB

    private var clockInFAB: some View {
        Button {
            showsAddTimeEntrySheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.primaryDark)
                .frame(width: 56, height: 56)
                .background(AppColors.activeBackground)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.5), radius: 8.5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add time entry")
    }

    // MARK: - List Content (Figma 15616-173383 + break support variants)

    private var listDays: [TimesheetListDay] {
        TimeAttendanceMockData.defaultTimesheetListDays
    }

    private var listContent: some View {
        VStack(spacing: 24) {
            ForEach(listDays) { day in
                listDaySection(day)
            }
        }
        .padding(.horizontal, 16)
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

            if breakSupportEnabled, entry.hasBreaks {
                Text(entry.breakListSummary)
                    .font(AppFonts.caption1())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .contentShape(Rectangle())
    }
}
