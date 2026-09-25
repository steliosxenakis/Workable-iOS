import SwiftUI

private enum HomeDashboardLayout {
    /// Total height of the blob header band below the status bar (pt)
    static let headerHeight: CGFloat = 64
    static let metricCardWidth: CGFloat = 160
    static let metricCardCornerRadius: CGFloat = 16
    static let transactionIconSize: CGFloat = 40
}

/// Two prototype variants for the Home "To-dos" section — switchable from Settings.
enum TodosSectionUIVersion: String, CaseIterable, Identifiable {
    /// One notification-style stack per category, each expands independently in place.
    case v1 = "V1"
    /// Figma Dashboard 5281-28001/28311: a single combined stack with a Show more/less
    /// toggle, plus category pills to filter the expanded list.
    case v2 = "V2"

    var id: String { rawValue }

    static let appStorageKey = "settings.todosSectionUIVersion"
    static let defaultVersion: TodosSectionUIVersion = .v1

    var caption: String {
        switch self {
        case .v1:
            return "Per-category stacks (Schedule requests, Time off, …) — tap one to expand it on its own."
        case .v2:
            return "One combined stack with a Show more/less toggle and category pills to filter it."
        }
    }
}

struct HomeView: View {

    @Environment(\.redesign) private var redesign
    @State private var showsTimeOffTypeSheet = false
    @AppStorage(WorkablePlan.appStorageKey) private var planRaw = WorkablePlan.defaultPlan.rawValue
    @AppStorage(WidgetGlanceUIVersion.appStorageKey) private var widgetGlanceUIVersion =
        WidgetGlanceUIVersion.defaultVersion.rawValue
    @AppStorage(TodosSectionUIVersion.appStorageKey) private var todosUIVersionRaw =
        TodosSectionUIVersion.defaultVersion.rawValue

    private enum DashboardRoute: Hashable {
        case directReports
        case job(JobItem)
        case surveyDetail(SurveyItem)
        case scheduleChangeRequest(ScheduleChangeRequestItem)
        case timeOffReview
    }

    /// To-dos category pills — lets approvals/time-off/etc. be filtered to and found together.
    private enum TodoCategory: String, CaseIterable, Identifiable {
        case scheduleRequests = "Schedule requests"
        case timeOffRequests = "Time off requests"
        case surveys = "Surveys"
        case profileUpdates = "Profile updates"

        var id: String { rawValue }
    }

    private let todayData = TodayWidgetData.mock

    private let todayEvents: [RedesignTodayEvent] = [
        RedesignTodayEvent(title: "Call with John Doe",             time: "10:30 - 11:00", subtitle: "Software Engineer"),
        RedesignTodayEvent(title: "Interview with Elissa McArthur", time: "9:30 - 10:00",  subtitle: "Product Designer")
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
                if redesign {
                    redesignScrollContent
                } else {
                    originalScrollContent
                }
            }
            .scrollClipDisabled()
            .background(AppColors.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                if redesign { redesignNavBarArea } else { homeNavBarArea }
            }
            .tint(AppColors.primaryDark)
            .buttonBorderShape(.circle)
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .directReports:
                    DirectReportsView()
                case .job(let job):
                    CandidatesBrowserView(jobTitle: job.title, jobSubtitle: job.details)
                case .surveyDetail(let survey):
                    SurveyDetailView(survey: survey)
                case .scheduleChangeRequest(let request):
                    ScheduleChangeRequestDetailView(item: request)
                case .timeOffReview:
                    TimeOffRequestDetailView(item: TimeOffInboxMockData.reviewRequest)
                }
            }
            .sheet(isPresented: $showsTimeOffTypeSheet) {
                TimeOffRequestSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            // Wiring point for the "Today" home-screen widget (`TodayGlanceWidget`):
            // push this screen's section counts into the app group so the widget
            // can mirror them.
            WidgetGlanceStore.save(
                WidgetGlanceData(
                    todosPendingCount: todoSurveyItems.count + todoScheduleChangeRequests.count,
                    oneOnOnesCount: todayData.events.filter { $0.title.contains("Call") }.count,
                    interviewEventsCount: todayData.events.filter { $0.title.contains("Interview") }.count,
                    attendanceIssueCount: todayData.issueCount,
                    onLeaveCount: todayData.onLeaveAvatars.count + todayData.onLeaveOverflow,
                    celebrationsCount: todayData.celebrations.count,
                    newCandidatesCount: 12
                )
            )
            if let plan = WorkablePlan(rawValue: planRaw) {
                WidgetPlanStore.save(plan)
            }
            WidgetGlanceUIVersionStore.save(
                WidgetGlanceUIVersion(rawValue: widgetGlanceUIVersion) ?? .defaultVersion
            )
        }
    }

    // MARK: - Original scroll content

    private var originalScrollContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            teamChips
                // Extra inset so Light card shadow isn’t clipped by the scroll/nav edge.
                .padding(.top, 14)
                .padding(.bottom, 16)

            timeTrackingCard
                .padding(.horizontal, 16)
                // Room below for the hold halo to overflow without colliding with To-dos.
                .padding(.bottom, 20)
                .zIndex(10)

            todosSection
                // Extra room below — the stack "peek" cue pokes out (+ shadow) under the
                // front card and needs space to actually read as a stack, not get clipped
                // against the next section.
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                if showsAttendanceIssuesUI {
                    TodayWidgetSwitcher(data: todayData)
                } else {
                    todaySimpleWidget
                }
                timeOffSection
                jobsSection
                candidatesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Redesign scroll content (Wise-style dashboard)

    private var redesignScrollContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            redesignGreetingHeader
                .padding(.top, 8)
                .padding(.bottom, 12)

            redesignTeamChips
                .padding(.bottom, 16)

            redesignQuickActionPills
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            redesignMetricCardsCarousel
                .padding(.bottom, 20)

            todosSection
                // Extra room below — the stack "peek" cue pokes out (+ shadow) under the
                // front card and needs space to actually read as a stack, not get clipped
                // against the next section.
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                redesignTodaySection
                redesignTimeOffSection
                redesignJobsSection
                candidatesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    private var redesignNavBarArea: some View {
        HStack {
            Image("avatar-emma")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .glassEffect(.regular.interactive())
                .clipShape(Circle())

            Spacer(minLength: 0)

            Image("logo-workable")
                .resizable()
                .scaledToFit()
                .frame(width: 43, height: 30)

            Spacer(minLength: 0)

            GlassSymbolButton(
                systemName: "magnifyingglass",
                accessibilityLabel: "Search",
                action: {}
            )
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: HomeDashboardLayout.headerHeight)
        .background {
            GeometryReader { proxy in
                let topInset = proxy.safeAreaInsets.top
                redesignHeaderBlobBackground
                    .frame(width: proxy.size.width,
                           height: proxy.size.height + topInset)
                    .clipped()
                    .offset(y: -topInset)
            }
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
        }
    }

    private var redesignHeaderBlobBackground: some View {
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

    private var redesignGreetingHeader: some View {
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

    private var redesignTeamChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                NavigationLink(value: DashboardRoute.directReports) {
                    HStack(spacing: 8) {
                        Text("Direct reports")
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontSecondary)

                        if showDirectReports {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.fontDefault)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(AppColors.iconInactive.opacity(0.35))
                                .clipShape(Capsule())
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: Self.teamChipHeight)
                    .background(AppColors.surface)
                    .clipShape(Capsule())
                    .appLightCardShadow()
                }

                teamChip(title: "Your team", selected: false)
            }
            // Vertical inset so horizontal ScrollView doesn’t clip card shadows.
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var hidesTimeTracking: Bool {
        ScheduleChangeRequestPersona.hidesTimeTracking(
            approvalsEnabled: approvalsEnabled,
            versionRaw: scheduleChangeUIVersionRaw,
            personaRaw: scheduleChangePersonaRaw
        )
    }

    private var redesignQuickActionPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                NavigationLink {
                    PersonalTimeTrackingView()
                } label: {
                    Text(hidesTimeTracking ? "Work schedule" : "Clock in")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(AppColors.activeBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button { showsTimeOffTypeSheet = true } label: {
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
            }
        }
    }

    private var redesignMetricCardsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                redesignMetricCard(title: "Open jobs", value: "\(openJobsCount)", icon: "briefcase.fill", iconColor: AppColors.primaryDark, iconBackground: AppColors.activeBackground)
                redesignMetricCard(title: "New candidates", value: "\(newCandidatesThisWeek)", icon: "person.fill.badge.plus", iconColor: Color(hex: "6E5DC6"), iconBackground: Color(hex: "EDE8FF"))
                redesignMetricCard(title: "Time off left", value: "\(timeOffDaysRemaining) days", icon: "beach.umbrella.fill", iconColor: AppColors.warningDefault, iconBackground: AppColors.warningBackground)
            }
            .padding(.horizontal, 16)
        }
    }

    private func redesignMetricCard(title: String, value: String, icon: String, iconColor: Color, iconBackground: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
        }
        .frame(width: HomeDashboardLayout.metricCardWidth, alignment: .leading)
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HomeDashboardLayout.metricCardCornerRadius, style: .continuous))
        .appLightCardShadow()
    }

    private func transactionIconCircle(systemName: String, iconColor: Color, fill: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: HomeDashboardLayout.transactionIconSize, height: HomeDashboardLayout.transactionIconSize)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
        }
    }

    private func sectionHeader(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
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

    private var redesignTodaySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Today", actionTitle: "View all", action: {})

            ForEach(Array(todayEvents.enumerated()), id: \.offset) { index, event in
                redesignTodayEventRow(event: event)
                if index < todayEvents.count - 1 {
                    Rectangle().fill(AppColors.separator).frame(height: 1)
                        .padding(.leading, 16 + HomeDashboardLayout.transactionIconSize + 12)
                }
            }

            Rectangle().fill(AppColors.separator).frame(height: 1)
                .padding(.leading, 16 + HomeDashboardLayout.transactionIconSize + 12)

            redesignTodayInfoRow(
                icon: "gift.fill", iconColor: Color(hex: "E9756D"), iconBackground: AppColors.dangerBackground,
                title: "Birthdays", value: "Doe, John +2"
            )
            Rectangle().fill(AppColors.separator).frame(height: 1)
                .padding(.leading, 16 + HomeDashboardLayout.transactionIconSize + 12)

            redesignTodayInfoRow(
                icon: "party.popper.fill", iconColor: Color(hex: "37B086"), iconBackground: AppColors.successBackground,
                title: "Holidays", value: "Christmas day"
            )
            Rectangle().fill(AppColors.separator).frame(height: 1)
                .padding(.leading, 16 + HomeDashboardLayout.transactionIconSize + 12)

            redesignOnLeaveRow
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .appLightCardShadow()
    }

    private func redesignTodayEventRow(event: RedesignTodayEvent) -> some View {
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

    private func redesignTodayInfoRow(icon: String, iconColor: Color, iconBackground: Color, title: String, value: String) -> some View {
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

    private var redesignOnLeaveRow: some View {
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

    private var redesignTimeOffSection: some View {
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
        .appLightCardShadow()
    }

    private var redesignJobsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Jobs", actionTitle: "View all", action: {})

            ForEach(Array(jobs.enumerated()), id: \.offset) { index, job in
                redesignJobRow(job)
                if index < jobs.count - 1 {
                    Rectangle().fill(AppColors.separator).frame(height: 1)
                        .padding(.leading, 16 + HomeDashboardLayout.transactionIconSize + 12)
                }
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .appLightCardShadow()
    }

    private func redesignJobRow(_ job: JobItem) -> some View {
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

    // MARK: - Nav bar area (blob header)

    /// Lavender + mint blobs on white; sized to the header band (see `headerHeight`).
    private var headerBlobBackground: some View {
        ZStack {
            AppColors.background

            Ellipse()
                .fill(Color(hex: "C5C5F1").opacity(0.8))
                .frame(width: 300, height: 180)
                .rotationEffect(.degrees(-173.84))
                .offset(x: -140, y: -110)
                .blur(radius: 36)

            Ellipse()
                .fill(Color(hex: "C2EAD4").opacity(0.8))
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
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .glassEffect(.regular.interactive())
                .clipShape(Circle())

            Spacer()

            Image("logo-workable")
                .resizable()
                .scaledToFit()
                .frame(width: 43, height: 30)

            Spacer()

            GlassSymbolButton(
                systemName: "magnifyingglass",
                accessibilityLabel: "Search",
                action: {}
            )
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

    // MARK: - Team Chips

    @AppStorage("settings.showAttendanceIssuesUI") private var showsAttendanceIssuesUI = true
    @AppStorage("settings.showDirectReports") private var showDirectReports = true
    @Environment(\.attendanceUIVersion) private var attendanceUIVersion
    @Environment(\.attendanceNoIssues) private var attendanceNoIssues

    private var directReportsIssueCount: Int {
        TimeAttendanceMockData.directReportsWithIssueCount
    }

    /// Shared so “Direct reports” (with/without badge) and “Your team” match.
    private static let teamChipHeight: CGFloat = 44

    private var teamChips: some View {
        HStack(spacing: 8) {
            NavigationLink(value: DashboardRoute.directReports) {
                HStack(spacing: 8) {
                    Text("Direct reports")
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)

                    if showsAttendanceIssuesUI && showDirectReports {
                        directReportsAttendanceIndicator
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppColors.fontSecondary)
                }
                .padding(.horizontal, 12)
                .frame(height: Self.teamChipHeight)
                .background(AppColors.surface)
                .cornerRadius(26)
                .appLightCardShadow()
            }

            teamChip(title: "Your team", selected: false)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        // Keep Light card shadow inside layout bounds (blur 14).
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var directReportsAttendanceIndicator: some View {
        switch attendanceUIVersion {
        case .v1:
            if !attendanceNoIssues {
                Circle()
                    .fill(AppColors.dangerBadge)
                    .frame(width: 16, height: 16)
            }
        case .v2, .v4, .v5, .v6, .v7, .v8:
            if !attendanceNoIssues && directReportsIssueCount > 0 {
                Text("\(directReportsIssueCount)")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.dangerDefault)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppColors.dangerBadge))
            }
        case .v3:
            if !attendanceNoIssues && directReportsIssueCount > 0 {
                Text("\(directReportsIssueCount)")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.dangerDefault)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(AppColors.dangerBadge)
                    .clipShape(Capsule())
            }
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
        .frame(height: Self.teamChipHeight)
        .background(AppColors.surface)
        .cornerRadius(26)
        .appLightCardShadow()
    }

    // MARK: - Time Tracking

    private var timeTrackingCard: some View {
        TimeTrackingHomeCard()
    }

    // MARK: - To-dos

    @AppStorage("settings.surveysEnabled") private var surveysEnabled = false
    @AppStorage("settings.approvalsEnabled") private var approvalsEnabled = false
    @AppStorage("settings.timeOffEnabled") private var timeOffEnabled = true
    @AppStorage(ScheduleChangeRequestUIVersion.appStorageKey) private var scheduleChangeUIVersionRaw =
        ScheduleChangeRequestUIVersion.defaultVersion.rawValue
    @AppStorage(ScheduleChangeRequestPersona.appStorageKey) private var scheduleChangePersonaRaw =
        ScheduleChangeRequestPersona.defaultPersona.rawValue
    @ObservedObject private var pendingStore = PendingScheduleChangeStore.shared
    /// Gates the whole pills/stacks redesign — off shows the original flat scrolling row.
    @AppStorage("settings.todosRevampEnabled") private var todosRevampEnabled = false
    /// V1: only one per-category stack is expanded at a time — matches how notification
    /// groups behave.
    @State private var expandedTodoCategory: TodoCategory?
    /// V2: the single combined stack is either collapsed or expanded (Show more/less).
    @State private var isTodosExpandedV2 = false
    /// V2: pill filter over the combined list — nil means every category.
    @State private var selectedTodoCategoryV2: TodoCategory?

    private var todosUIVersion: TodosSectionUIVersion {
        TodosSectionUIVersion(rawValue: todosUIVersionRaw) ?? .defaultVersion
    }

    /// One row inside an expanded stack — a normalized shape so every category (schedule
    /// requests, time off, surveys, profile) can render/expand the same way.
    private struct TodoCardModel: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let route: DashboardRoute?
    }

    private var todoSurveyItems: [SurveyItem] {
        surveysEnabled ? SurveyMockData.items : []
    }

    private var todoScheduleChangeRequests: [ScheduleChangeRequestItem] {
        guard ScheduleChangeRequestPersona.showsManagerInboxRequest(
            approvalsEnabled: approvalsEnabled,
            versionRaw: scheduleChangeUIVersionRaw,
            personaRaw: scheduleChangePersonaRaw
        ) else { return [] }
        return pendingStore.managerInboxItems
    }

    /// Only categories that currently have at least one item get a stack.
    private var availableTodoCategories: [TodoCategory] {
        var categories: [TodoCategory] = []
        if !todoScheduleChangeRequests.isEmpty { categories.append(.scheduleRequests) }
        if timeOffEnabled { categories.append(.timeOffRequests) }
        if !todoSurveyItems.isEmpty { categories.append(.surveys) }
        categories.append(.profileUpdates)
        return categories
    }

    private func todoCards(for category: TodoCategory) -> [TodoCardModel] {
        switch category {
        case .scheduleRequests:
            return todoScheduleChangeRequests.map { request in
                TodoCardModel(
                    id: request.id.uuidString,
                    title: "Review \(request.requesterName)'s schedule change request",
                    subtitle: request.dateRange,
                    route: .scheduleChangeRequest(request)
                )
            }
        case .timeOffRequests:
            guard timeOffEnabled else { return [] }
            let timeOff = TimeOffInboxMockData.reviewRequest
            return [
                TodoCardModel(
                    id: "timeOffReview",
                    title: "Review a time-off request for \(timeOff.requesterName)",
                    subtitle: timeOff.previewText,
                    route: .timeOffReview
                ),
            ]
        case .surveys:
            return todoSurveyItems.map { item in
                TodoCardModel(
                    id: item.id.uuidString,
                    title: item.isReminder ? "Reminder to complete \(item.surveyName)" : "Start \(item.surveyName)",
                    subtitle: item.deadline != nil ? "Share your feedback by \(item.deadline!)." : "Share your feedback.",
                    route: .surveyDetail(item)
                )
            }
        case .profileUpdates:
            return [
                TodoCardModel(id: "profileUpdate", title: "Review your profile", subtitle: "Review updated profile.", route: nil),
            ]
        }
    }

    @ViewBuilder
    private var todosSection: some View {
        if todosRevampEnabled {
            switch todosUIVersion {
            case .v1: todosSectionV1
            case .v2: todosSectionV2
            }
        } else {
            todosSectionClassic
        }
    }

    // MARK: - To-dos classic (original flat scrolling row, pre-revamp)

    /// Every available to-do, flattened across categories, in the same order the sections list.
    private var allTodoItems: [TodoCardModel] {
        availableTodoCategories.flatMap { todoCards(for: $0) }
    }

    private var todosSectionClassic: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To-dos")
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
                .foregroundColor(AppColors.fontDefault)
                .padding(.horizontal, 16)

            if allTodoItems.isEmpty {
                Text("All done for now.")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.41)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(AppColors.surface)
                    .cornerRadius(16)
                    .appLightCardShadow()
                    .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(allTodoItems) { item in
                            if let route = item.route {
                                NavigationLink(value: route) {
                                    classicTodoCard(title: item.title, subtitle: item.subtitle)
                                }
                                .buttonStyle(.plain)
                            } else {
                                classicTodoCard(title: item.title, subtitle: item.subtitle)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func classicTodoCard(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)
        }
        .padding(16)
        .frame(width: UIScreen.main.bounds.width * 0.75, alignment: .leading)
        .frame(height: 100)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }

    // MARK: - To-dos V1 (per-category stacks)

    private var todosSectionV1: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To-dos")
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
                .foregroundColor(AppColors.fontDefault)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(availableTodoCategories) { category in
                    todoCategoryStack(category)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// One category's notification-style stack. A single item skips the expand step
    /// entirely — nothing to reveal, so the row goes straight to its destination. Two or
    /// more show a peeking card pile that expands vertically in place on tap.
    @ViewBuilder
    private func todoCategoryStack(_ category: TodoCategory) -> some View {
        let items = todoCards(for: category)

        if items.count <= 1 {
            if let only = items.first {
                todoItemRow(only)
            }
        } else {
            expandableTodoCategoryStack(category, items: items)
        }
    }

    private func expandableTodoCategoryStack(_ category: TodoCategory, items: [TodoCardModel]) -> some View {
        let isExpanded = expandedTodoCategory == category

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                    expandedTodoCategory = isExpanded ? nil : category
                }
            } label: {
                ZStack(alignment: .bottom) {
                    if !isExpanded {
                        stackPeekLayer(inset: 14, yOffset: 10, opacity: 0.5)
                        stackPeekLayer(inset: 7, yOffset: 5, opacity: 0.8)
                    }
                    todoStackHeader(category: category, items: items, isExpanded: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        todoItemRow(item)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    /// A card edge peeking out from underneath the front card — the "stack" cue. A visible
    /// shadow (not just the opacity step) is what actually sells the depth against the page
    /// background, which is otherwise too close in tone to the card fill.
    private func stackPeekLayer(inset: CGFloat, yOffset: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppColors.surface)
            .opacity(opacity)
            .frame(height: 60)
            .padding(.horizontal, inset)
            .offset(y: yOffset)
            .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
    }

    private func todoStackHeader(category: TodoCategory, items: [TodoCardModel], isExpanded: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(category.rawValue)
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)

                    if items.count > 1 {
                        Text("\(items.count)")
                            .font(AppFonts.caption1Strong())
                            .foregroundColor(AppColors.fontSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule(style: .continuous).fill(AppColors.surfaceDarker))
                    }
                }

                Text(isExpanded ? "Tap to collapse" : (items.first?.title ?? "All done for now."))
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.iconDefault)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }

    private func todoRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }

    /// A to-do row wrapped in navigation when it has a destination — no arrows anywhere;
    /// the whole card is the tap target.
    @ViewBuilder
    private func todoItemRow(_ item: TodoCardModel) -> some View {
        if let route = item.route {
            NavigationLink(value: route) {
                todoRow(title: item.title, subtitle: item.subtitle)
            }
            .buttonStyle(.plain)
        } else {
            todoRow(title: item.title, subtitle: item.subtitle)
        }
    }

    // MARK: - To-dos V2 (Figma Dashboard 5281-28001/28311 — single combined stack + pills)

    /// The combined list, narrowed by the selected pill (nil = every category).
    private var filteredTodoItemsV2: [TodoCardModel] {
        guard let selected = selectedTodoCategoryV2 else { return allTodoItems }
        return todoCards(for: selected)
    }

    private var todosSectionV2: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To-dos")
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
                .foregroundColor(AppColors.fontDefault)
                .padding(.horizontal, 16)

            if availableTodoCategories.count > 1 {
                todoCategoryPillsV2
            }

            VStack(spacing: 8) {
                if filteredTodoItemsV2.count <= 1 {
                    // Nothing to expand — a single (or no) item skips straight to itself.
                    if let only = filteredTodoItemsV2.first {
                        todoItemRow(only)
                    } else {
                        todoRow(title: "All done for now.", subtitle: "Nothing pending right now.")
                    }
                } else if isTodosExpandedV2 {
                    showLessButtonV2

                    VStack(spacing: 8) {
                        ForEach(filteredTodoItemsV2) { item in
                            todoItemRow(item)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isTodosExpandedV2 = true }
                    } label: {
                        ZStack(alignment: .bottom) {
                            stackPeekLayer(inset: 14, yOffset: 10, opacity: 0.5)
                            stackPeekLayer(inset: 7, yOffset: 5, opacity: 0.8)
                            if let first = filteredTodoItemsV2.first {
                                todoRow(title: first.title, subtitle: first.subtitle)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// Tapping a pill again (or selecting a new one) toggles the filter — no standalone "All".
    private var todoCategoryPillsV2: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableTodoCategories) { category in
                    let isSelected = selectedTodoCategoryV2 == category
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if isSelected {
                                // Deselecting back to "everything" collapses again.
                                selectedTodoCategoryV2 = nil
                                isTodosExpandedV2 = false
                            } else {
                                // Picking a filter implies wanting to see its items right away.
                                selectedTodoCategoryV2 = category
                                isTodosExpandedV2 = true
                            }
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(isSelected ? AppColors.activeBackground : AppColors.surface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var showLessButtonV2: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isTodosExpandedV2 = false }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                Text("Show less")
                    .font(AppFonts.subheadStrong())
            }
            .foregroundColor(AppColors.primaryDark)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Today Simple Widget (no attendance)

    private var todaySimpleWidget: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(0.35)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Button("View all") {}
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
                    .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 0) {
                todayEventRow(
                    title: "Call with John Doe",
                    subtitle: "10:30 - 11:00 · Software Engineer"
                )
                Divider()
                todayEventRow(
                    title: "Interview with Elissa McArthur",
                    subtitle: "9:30 - 10:00 · Product Designer"
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(AppColors.dangerBackground)
                            .frame(width: 40, height: 40)
                        Image("icon-gift")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(hex: "E9756D"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Birthdays")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                            .tracking(-0.24)
                        Text("Doe, John +2")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.fontDefault)
                            .tracking(-0.41)
                    }
                }

                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(AppColors.successBackground)
                            .frame(width: 40, height: 40)
                        Image("icon-pyro")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(hex: "37B086"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Holidays")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                            .tracking(-0.24)
                        Text("Christmas day")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.fontDefault)
                            .tracking(-0.41)
                    }
                }
            }

            HStack {
                Text("No employees on leave")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.24)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.iconDefault)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.lightBackground)
            .cornerRadius(16)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }

    private func todayEventRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                Text(subtitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundColor(AppColors.iconDefault)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Time Off

    private var timeOffSection: some View {
        VStack(alignment: .leading, spacing: 12) {
           

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Your time off")
                        .font(.system(size: 22, weight: .semibold))
                        .tracking(0.35)
                        .foregroundColor(AppColors.fontDefault)
                    Spacer()
                    Button("View all") {}
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.primaryDark)
                        .buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("15 May 2023 - 18 May 2023")
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                    Text("Upcoming · Paid time off")
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                }

                HStack(spacing: 8) {
                    Button { showsTimeOffTypeSheet = true } label: {
                        HStack(spacing: 6) {
                            Image("icon-add-circle")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("New request")
                                .font(AppFonts.subheadStrong())
                        }
                        .foregroundColor(AppColors.primaryDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.activeBackground)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)

                    Button {} label: {
                        Image(systemName: "tablecells")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.primaryDark)
                            .frame(width: 36, height: 36)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AppColors.separator, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(16)
            .appLightCardShadow()
        }
    }

    // MARK: - Jobs

    private var jobsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Jobs")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Button("View all") {}
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
                    .buttonStyle(.plain)
            }
            .padding(.bottom, 12)

            ForEach(Array(jobs.enumerated()), id: \.offset) { index, job in
                jobRow(job)
                if index < jobs.count - 1 {
                    Rectangle().fill(AppColors.separator).frame(height: 1)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }

    private func jobRow(_ job: JobItem) -> some View {
        NavigationLink(value: DashboardRoute.job(job)) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.41)
                    Text(job.details)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.24)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.iconDefault)

                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.iconDefault)
                        Text(verbatim: "\(job.candidateCount)")
                            .font(AppFonts.footnote())
                            .foregroundColor(AppColors.iconDefault)
                            .tracking(-0.08)
                    }
                }
                .frame(height: 41, alignment: .bottom)
            }
            .padding(.vertical, 15)
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
                    .buttonStyle(.plain)
            }
            .padding(.bottom, 8)

            candidateRow(systemName: "person.badge.plus", label: "New", count: 12)
            Rectangle().fill(AppColors.separator).frame(height: 1)
            candidateRow(systemName: "list.bullet.below.rectangle", label: "Unread", count: 2)
            Rectangle().fill(AppColors.separator).frame(height: 1)
            candidateRow(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90", label: "Recently viewed", count: 20)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .appLightCardShadow()
    }

    private func candidateRow(systemName: String, label: String, count: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppColors.iconDefault)
                    .frame(width: 24, height: 24)

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
    struct JobItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let details: String
        let candidateCount: Int
    }

    struct RedesignTodayEvent: Identifiable {
        let id = UUID()
        let title: String
        let time: String
        let subtitle: String
    }
}

// MARK: - Todo Cards
//
// Superseded by `todoRow(title:subtitle:)` inside the To-dos notification-stack UI
// (see "MARK: - To-dos" above) — kept out of the build on purpose, nothing references
// these anymore.

#Preview {
    HomeView()
}
