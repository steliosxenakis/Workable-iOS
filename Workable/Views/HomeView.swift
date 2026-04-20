import SwiftUI

private enum HomeDashboardLayout {
    /// Total height of the blob header band below the status bar (pt)
    static let headerHeight: CGFloat = 64
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Team scope chips ──
                    teamChips
                        .padding(.top, 6)
                        .padding(.bottom, 12)

                    // ── Time tracking card (Figma 15353-17275) ──
                    timeTrackingCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    // ── To-dos (empty state per Figma) ──
                    todosSection
                        .padding(.bottom, 12)

                    // ── Remaining cards ──
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
            // Nav bar sits outside the scroll view so its background can
            // reliably bleed behind the status bar via ignoresSafeArea
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
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            Spacer()

            Image("logo-workable")
                .resizable()
                .scaledToFit()
                .frame(width: 43, height: 30)

            Spacer()

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

    // MARK: - Team Chips

    private var teamChips: some View {
        HStack(spacing: 8) {
            NavigationLink(value: DashboardRoute.directReports) {
                HStack(spacing: 8) {
                    Text("Direct reports")
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(AppColors.iconInactive)
                        .cornerRadius(10)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppColors.fontSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColors.surface)
                .cornerRadius(26)
            }

            teamChip(title: "Your team", selected: false)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
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
        .cornerRadius(26)
    }

    // MARK: - Time Tracking

    /// Figma 15353-17275: running timer, stop control, drill-in chevron; summary row below
    private var timeTrackingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 24) {
                NavigationLink {
                    PersonalTimeTrackingView()
                } label: {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("8h 00m")
                            .font(.system(size: 22, weight: .semibold))
                            .tracking(0.35)
                            .foregroundColor(AppColors.fontDefault)
                        Text("00s")
                            .font(.system(size: 16, weight: .regular))
                            .tracking(-0.32)
                            .foregroundColor(AppColors.fontSecondary)
                            .frame(height: 20)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Button {} label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "24272c"))
                            .frame(width: 56, height: 56)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.surface)
                            .frame(width: 12, height: 12)
                    }
                    .shadow(color: Color(hex: "333E49").opacity(0.48), radius: 8.5, x: 0, y: 0)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PersonalTimeTrackingView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.iconDefault)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.surface)
            .cornerRadius(16)

            HStack {
                Text("Today · 8h in total")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.24)

                Spacer()

                Text("8:00-16:00")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppColors.lightBackground)
        .cornerRadius(16)
        .shadow(color: Color(hex: "333E49").opacity(0.04), radius: 5, x: 0, y: 3)
    }

    private let attendanceStatusPills: [(label: String, count: Int, filters: Set<AnomalyFilterCategory>)] = [
        ("Missed clocks", 3, [.noClockIn]),
        ("Missed clock-ins", 2, [.noClockInNorOut]),
        ("Missed clock-outs", 3, [.exceededWorkSchedule]),
        ("On track", 18, [.onTrack]),
        ("All", 26, [])
    ]

    /// Figma 15353-17307 — opens full anomalies list
    private var timeAttendanceStatusCard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attendanceStatusPills, id: \.label) { pill in
                    NavigationLink {
                        TimeAttendanceAnomaliesListView(initialFilters: pill.filters)
                    } label: {
                        Text("\(pill.label) (\(pill.count))")
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(AppColors.fontDefault)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(AppColors.iconInactive)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(AppColors.separator, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - To-dos

    /// Figma 15353-17276: empty state
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
                .cornerRadius(16)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Today

    private var todaySection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Today")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)

                Spacer()

                Button("View all") {}
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ForEach(todayEvents) { event in
                todayEventRow(event)
            }
            Rectangle().fill(AppColors.separator).frame(height: 1)
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
            Rectangle().fill(AppColors.separator).frame(height: 1)
                .padding(.horizontal, 16)

            onLeaveRow

            Rectangle().fill(AppColors.separator).frame(height: 1)
                .padding(.horizontal, 16)

            timeAttendanceStatusCard
                .padding(16)
        }
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private func todayEventRow(_ event: TodayEvent) -> some View {
        HStack(alignment: .center) {
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
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontSecondary)
                Text(value)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var onLeaveRow: some View {
        HStack {
            Text("No employees on leave")
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

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
                .padding(.leading, 6)
        }
        .padding(.horizontal, 16)
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
                    Button {} label: {
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

            candidateRow(icon: "icon-candidates-new",    label: "New",             count: 12)
            Rectangle().fill(AppColors.separator).frame(height: 1)
            candidateRow(icon: "icon-candidates-unread",  label: "Unread",          count: 2)
            Rectangle().fill(AppColors.separator).frame(height: 1)
            candidateRow(icon: "icon-candidates-viewed",  label: "Recently viewed", count: 20)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
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
