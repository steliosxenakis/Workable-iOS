import SwiftUI

private enum HomeDashboardLayout {
    /// Total height of the blob header band below the status bar (pt)
    static let headerHeight: CGFloat = 64
    static let metricCardWidth: CGFloat = 160
    static let metricCardCornerRadius: CGFloat = 16
    static let transactionIconSize: CGFloat = 40
}

struct HomeView: View {

    private enum DashboardRoute: Hashable {
        case directReports
        case job(JobItem)
    }

    private let todayEvents: [TodayEvent] = [
        TodayEvent(title: "Call with John Doe",             time: "10:30 - 11:00", subtitle: "Software Engineer"),
        TodayEvent(title: "Interview with Elissa McArthur", time: "9:30 - 10:00",  subtitle: "Product Designer")
    ]

    private let jobs: [JobItem] = [
        JobItem(title: "Software Engineer",  details: "Engineering · Hybrid · Athens, Greece", candidateCount: 14),
        JobItem(title: "UX Writer",          details: "Design · Remote · London, UK",          candidateCount: 14),
        JobItem(title: "Product Manager",    details: "Product · On-site · New York, US",      candidateCount: 14)
    ]

    private var greetingTimePhrase: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning,"
        case 12 ..< 17: return "Good afternoon,"
        case 17 ..< 22: return "Good evening,"
        default: return "Good night,"
        }
    }

    private var openJobsCount: Int { jobs.count }
    private var newCandidatesThisWeek: Int { 12 }
    private var timeOffDaysRemaining: Int { 12 }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    greetingHeader
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    teamChips
                        .padding(.bottom, 16)

                    quickActionPills
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    metricCardsCarousel
                        .padding(.bottom, 20)

                    todosSection
                        .padding(.bottom, 12)

                    VStack(spacing: 12) {
                        todaySection
                        timeOffSection
                        jobsSection
                        candidatesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(AppColors.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                homeNavBarArea
            }
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .directReports:
                    DirectReportsView()
                case .job(let job):
                    CandidatesBrowserView(jobTitle: job.title, jobSubtitle: job.details)
                }
            }
        }
    }

    // MARK: - Nav bar area (blob header)

    private var headerBlobBackground: some View {
        ZStack {
            AppColors.background

            Ellipse()
                .fill(Color(hex: "C5C5F1").opacity(0.45))
                .frame(width: 300, height: 180)
                .rotationEffect(.degrees(-173.84))
                .offset(x: -140, y: -110)
                .blur(radius: 36)

            Ellipse()
                .fill(Color(hex: "C2EAD4").opacity(0.45))
                .frame(width: 115, height: 240)
                .rotationEffect(.degrees(-89.34))
                .offset(x: 140, y: -100)
                .blur(radius: 38)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var homeNavBarArea: some View {
        HStack {
            Image("avatar-emma")
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            Spacer(minLength: 0)

            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.fontSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: HomeDashboardLayout.headerHeight)
        .background {
            GeometryReader { proxy in
                let topInset = proxy.safeAreaInsets.top
                headerBlobBackground
                    .frame(width: proxy.size.width,
                           height: proxy.size.height + topInset)
                    .clipped()
                    .offset(y: -topInset)
            }
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingTimePhrase)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)

                Text("Emma")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {} label: {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                    .frame(width: 36, height: 36)
                    .background(AppColors.dashboardCardFill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Insights")
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Team Chips

    private var teamChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                NavigationLink(value: DashboardRoute.directReports) {
                    HStack(spacing: 8) {
                        Text("Direct reports")
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontSecondary)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.fontDefault)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(AppColors.iconInactive.opacity(0.35))
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.surface)
                    .clipShape(Capsule())
                }

                teamChip(title: "Your team", selected: false)
            }
            .padding(.horizontal, 16)
        }
    }

    private func teamChip(title: String, selected: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(AppFonts.subheadline())
                .tracking(selected ? -0.5 : -0.24)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
        }
        .foregroundColor(AppColors.fontSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .clipShape(Capsule())
    }

    // MARK: - Quick actions (Wise-style pills)

    private var quickActionPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                NavigationLink {
                    PersonalTimeTrackingView()
                } label: {
                    Text("Clock in")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(AppColors.activeBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {} label: {
                    Text("New request")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(AppColors.dashboardCardFill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {} label: {
                    Text("Search")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(AppColors.dashboardCardFill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search")
            }
        }
    }

    // MARK: - Metric cards (horizontal carousel)

    private var metricCardsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                metricCard(
                    assetIcon: "icon-list-bullet",
                    title: "Open jobs",
                    subtitle: "\(openJobsCount) active",
                    value: "\(openJobsCount)"
                )

                metricCard(
                    assetIcon: "icon-candidates-new",
                    title: "Candidates",
                    subtitle: "\(newCandidatesThisWeek) new this week",
                    value: "\(newCandidatesThisWeek)"
                )

                metricCard(
                    systemIcon: "calendar",
                    title: "Time off",
                    subtitle: "Next · 15 May",
                    value: "\(timeOffDaysRemaining)d"
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func metricCard(
        assetIcon: String? = nil,
        systemIcon: String? = nil,
        title: String,
        subtitle: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if let assetIcon {
                    Image(assetIcon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(AppColors.fontDefault)
                } else if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.fontDefault)
                }
                Text(title)
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontSecondary)
            }

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.fontDefault)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(subtitle)
                .font(AppFonts.caption1())
                .foregroundColor(AppColors.fontSecondary)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(width: HomeDashboardLayout.metricCardWidth, alignment: .leading)
        .frame(minHeight: 132, alignment: .leading)
        .background(AppColors.dashboardCardFill)
        .clipShape(RoundedRectangle(cornerRadius: HomeDashboardLayout.metricCardCornerRadius, style: .continuous))
    }

    // MARK: - Time tracking (compact, inside Today)

    private var compactTimeTrackingRow: some View {
        NavigationLink {
            PersonalTimeTrackingView()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                transactionIconCircle(systemName: "clock.fill", iconColor: AppColors.primaryDark, fill: AppColors.activeBackground)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Time today")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.24)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("8h 00m")
                            .font(AppFonts.body())
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.fontDefault)
                        Text("00s")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.iconDefault)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var attendanceStatusPills: [(label: String, count: Int, filters: Set<AnomalyFilterCategory>)] {
        let eligible = TimeAttendanceMockData.employees.filter { !$0.hasScheduleIcon }
        return [
            ("Missed clock-ins",  eligible.filter { $0.anomalyType == .noClockInNorOut }.count,      [.noClockInNorOut]),
            ("Exceeded work hours", eligible.filter { $0.anomalyType == .exceededWorkSchedule }.count, [.exceededWorkSchedule]),
            ("No attendance",     eligible.filter { $0.anomalyType == .noClockIn }.count,            [.noClockIn]),
        ]
    }

    private var timeAttendanceStatusCard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attendanceStatusPills, id: \.label) { pill in
                    NavigationLink {
                        AttendanceAnomaliesStandaloneView(initialFilters: pill.filters)
                    } label: {
                        Text("\(pill.label) (\(pill.count))")
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(AppColors.fontDefault)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(AppColors.dashboardCardFill)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.separator, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - To-dos

    private var todosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To-dos")
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
                .foregroundColor(AppColors.fontDefault)
                .padding(.horizontal, 16)

            Text("All done for now.")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.41)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Today

    private var todaySection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Today", actionTitle: "View all", action: {})

            compactTimeTrackingRow

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack {
                Text("Today · 8h in total")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.24)
                Spacer()
                Text("8:00–16:00")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
                .padding(.horizontal, 16)

            ForEach(todayEvents) { event in
                todayEventRow(event)
            }

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
                .padding(.horizontal, 16)

            todayInfoRow(
                icon: "gift.fill",
                iconColor: Color(hex: "E9756D"),
                iconBackground: Color(hex: "F8ECEB"),
                title: "Birthdays",
                value: "Doe, John +2"
            )

            todayInfoRow(
                icon: "sparkles",
                iconColor: Color(hex: "37B086"),
                iconBackground: Color(hex: "E8F4EF"),
                title: "Holidays",
                value: "Christmas day"
            )

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
                .padding(.horizontal, 16)

            onLeaveRow

            timeAttendanceStatusCard
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionHeader(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(AppColors.fontDefault)
            Spacer()
            Button(actionTitle, action: action)
                .font(AppFonts.subheadStrong())
                .foregroundColor(AppColors.primaryDark)
                .underline()
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func transactionIconCircle(systemName: String, iconColor: Color, fill: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: HomeDashboardLayout.transactionIconSize, height: HomeDashboardLayout.transactionIconSize)
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(iconColor)
        }
    }

    private func todayEventRow(_ event: TodayEvent) -> some View {
        HStack(alignment: .center, spacing: 12) {
            transactionIconCircle(systemName: "calendar", iconColor: AppColors.fontDefault, fill: AppColors.dashboardCardFill)

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
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.iconDefault)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func todayInfoRow(
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 12) {
            transactionIconCircle(systemName: icon, iconColor: iconColor, fill: iconBackground)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
                Text(value)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var onLeaveRow: some View {
        HStack(spacing: 12) {
            transactionIconCircle(systemName: "person.2.fill", iconColor: AppColors.fontDefault, fill: AppColors.dashboardCardFill)

            Text("No employees on leave")
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: -8) {
                ForEach(["avatar-lucy", "avatar-abdi", "avatar-michael"], id: \.self) { name in
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColors.surface, lineWidth: 1.5))
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.iconDefault)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Time off (Wise-style task row)

    private var timeOffSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Your time off")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(0.35)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Button("View all") {}
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
                    .underline()
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(AppColors.separator, lineWidth: 1))
                    Image(systemName: "beach.umbrella.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.primaryDark)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("15 May 2023 - 18 May 2023")
                        .font(AppFonts.body())
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryDark)
                        .tracking(-0.41)
                    Text("Upcoming · Paid time off")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {} label: {
                    Text("Review")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColors.activeBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Jobs

    private var jobsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Jobs", actionTitle: "View all", action: {})

            ForEach(Array(jobs.enumerated()), id: \.offset) { index, job in
                jobRow(job)
                if index < jobs.count - 1 {
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                        .padding(.leading, 16 + HomeDashboardLayout.transactionIconSize + 12)
                }
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func jobRow(_ job: JobItem) -> some View {
        NavigationLink(value: DashboardRoute.job(job)) {
            HStack(alignment: .center, spacing: 12) {
                transactionIconCircle(systemName: "briefcase.fill", iconColor: AppColors.fontDefault, fill: AppColors.dashboardCardFill)

                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.41)
                    Text(job.details)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.24)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(verbatim: "\(job.candidateCount)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                    .frame(minWidth: 28, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Candidates

    private var candidatesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Candidates")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Button("View all") {}
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
                    .underline()
                    .buttonStyle(.plain)
            }
            .padding(.bottom, 8)

            candidateRow(icon: "icon-candidates-new",    label: "New",             count: 12)
            Rectangle().fill(AppColors.separator).frame(height: 1)
            candidateRow(icon: "icon-candidates-unread",  label: "Unread",          count: 2)
            Rectangle().fill(AppColors.separator).frame(height: 1)
            candidateRow(icon: "icon-candidates-viewed",  label: "Recently viewed", count: 20)
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func candidateRow(icon: String, label: String, count: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(AppColors.iconDefault)

                Text(label)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
            }

            Spacer()

            Text(verbatim: "\(count)")
                .font(AppFonts.footnote())
                .foregroundColor(AppColors.iconDefault)
                .tracking(-0.08)
                .frame(width: 17, alignment: .trailing)
        }
        .padding(.vertical, 15)
    }
}

// MARK: - Local models

private extension HomeView {
    struct TodayEvent: Identifiable {
        let id = UUID()
        let title: String
        let time: String
        let subtitle: String
    }

    struct JobItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let details: String
        let candidateCount: Int
    }
}

#Preview {
    HomeView()
}
