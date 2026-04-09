import SwiftUI

/// Calendar / List toggle and weekly chart shared by personal and employee time-tracking flows.
struct TimeTrackingWeekCalendarContent: View {
    @Binding var selectedSubTab: Int
    var weekHours: [DayHours] = TimeAttendanceMockData.defaultWeekHours

    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    private let timeSlots = Array(stride(from: 8, through: 17, by: 1))

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                subTabToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                if selectedSubTab == 0 {
                    calendarContent
                } else {
                    listContent
                }
            }
        }
    }

    // MARK: - Calendar / List Toggle

    private var subTabToggle: some View {
        HStack(spacing: 0) {
            subTabButton(title: "Calendar", icon: "calendar", index: 0)
            subTabButton(title: "List", icon: "list.bullet", index: 1)
        }
        .background(AppColors.lightBackground)
        .cornerRadius(8)
    }

    private func subTabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedSubTab = index }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(AppFonts.subheadStrong())
            }
            .foregroundColor(selectedSubTab == index ? AppColors.primaryDark : AppColors.fontSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(selectedSubTab == index ? AppColors.surface : Color.clear)
                    .shadow(color: selectedSubTab == index ? .black.opacity(0.06) : .clear, radius: 2, y: 1)
            )
            .padding(2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        VStack(spacing: 0) {
            weekCard
                .padding(.horizontal, 16)
        }
    }

    private var weekCard: some View {
        VStack(spacing: 16) {
            weekNavigation
            scheduleSummary
            weekChart
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private var weekNavigation: some View {
        HStack {
            Button {} label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("This week")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
        }
    }

    private var scheduleSummary: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.iconInactive)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Scheduled")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                    Text("40h")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                }
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.informativeDefault)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Worked")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                    Text("32h 30m")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                }
            }
            Spacer()
        }
    }

    private var weekChart: some View {
        VStack(spacing: 0) {
            dayLabels
                .padding(.bottom, 8)
            chartArea
        }
    }

    private var dayLabels: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 40)
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                Text(day)
                    .font(AppFonts.caption1())
                    .foregroundColor(index < 5 ? AppColors.fontDefault : AppColors.fontSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var chartArea: some View {
        VStack(spacing: 0) {
            ForEach(timeSlots, id: \.self) { hour in
                HStack(spacing: 0) {
                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(AppColors.fontSecondary)
                        .frame(width: 40, alignment: .leading)

                    ForEach(Array(weekHours.enumerated()), id: \.offset) { _, dayData in
                        ZStack {
                            if let scheduled = dayData.scheduled,
                               Double(hour) >= scheduled.0, Double(hour) < scheduled.1 {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(AppColors.separator)
                                    .frame(width: 14)
                            }

                            if let worked = dayData.worked,
                               Double(hour) >= worked.0, Double(hour) < worked.1 {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(AppColors.informativeDefault)
                                    .frame(width: 14)
                            }

                            if dayData.hasAnomaly, let worked = dayData.worked,
                               abs(Double(hour) - worked.1) < 0.5 {
                                Circle()
                                    .fill(AppColors.dangerDefault)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 12)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                    }
                }
                if hour < timeSlots.last ?? 17 {
                    HStack(spacing: 0) {
                        Color.clear.frame(width: 40)
                        Rectangle()
                            .fill(AppColors.separator.opacity(0.5))
                            .frame(height: 0.5)
                    }
                }
            }
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                listRow(day: "Monday", date: "31 Mar", scheduled: "08:00 - 16:00", worked: "08:30 - 15:30", hours: "7h")
                listRow(day: "Tuesday", date: "1 Apr", scheduled: "08:00 - 16:00", worked: "08:00 - 15:00", hours: "7h")
                listRow(day: "Wednesday", date: "2 Apr", scheduled: "08:00 - 16:00", worked: "08:00 - 16:00", hours: "8h")
                listRow(day: "Thursday", date: "3 Apr", scheduled: "08:00 - 16:00", worked: "08:30 - 15:00", hours: "6h 30m")
                listRow(day: "Friday", date: "4 Apr", scheduled: "08:00 - 16:00", worked: "09:00 - 13:00", hours: "4h", hasAnomaly: true)
            }
            .background(AppColors.surface)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    private func listRow(day: String, date: String, scheduled: String, worked: String, hours: String, hasAnomaly: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(day), \(date)")
                        .font(AppFonts.subheadlineBold())
                        .foregroundColor(AppColors.fontDefault)
                    Text("Scheduled: \(scheduled)")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                    HStack(spacing: 4) {
                        Text("Worked: \(worked)")
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                        if hasAnomaly {
                            Circle()
                                .fill(AppColors.dangerDefault)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                Spacer()
                Text(hours)
                    .font(AppFonts.headline())
                    .foregroundColor(hasAnomaly ? AppColors.dangerDefault : AppColors.fontDefault)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
                .padding(.horizontal, 16)
        }
    }
}
