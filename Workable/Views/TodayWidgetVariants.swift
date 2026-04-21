import SwiftUI

// MARK: - Pill Style (self-contained)

enum TodayPillStyle: Equatable {
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
        case .danger:  return Color(light: "FFD2CF", dark: "5A1A0F")
        case .warning: return Color(light: "FFF0B8", dark: "5C3200")
        case .success: return AppColors.activeBackground
        case .neutral: return AppColors.separator
        }
    }

    var badgeTextColor: Color {
        switch self {
        case .danger:  return AppColors.dangerDefault
        case .warning: return AppColors.warningDefault
        case .success: return AppColors.successDefault
        case .neutral: return AppColors.fontSecondary
        }
    }
}

// MARK: - Shared Data Model

struct TodayEvent: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let subtitle: String
}

struct TodayAnomalyPill: Identifiable {
    var id: String { label }
    let label: String
    let count: Int
    let style: TodayPillStyle
    let filters: Set<AnomalyFilterCategory>
}

struct TodayCelebration: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let value: String
}

struct TodayWidgetData {
    let events: [TodayEvent]
    let anomalyPills: [TodayAnomalyPill]
    let onLeaveTitle: String
    let onLeaveAvatars: [String]
    let onLeaveOverflow: Int
    let celebrations: [TodayCelebration]

    var issueCount: Int {
        anomalyPills.filter { $0.style == .danger || $0.style == .warning }.reduce(0) { $0 + $1.count }
    }
    var onTrackCount: Int {
        anomalyPills.first(where: { $0.style == .success })?.count ?? 0
    }

    static let mock = TodayWidgetData(
        events: [
            TodayEvent(title: "Call with John Doe",             time: "10:30 - 11:00", subtitle: "Software Engineer"),
            TodayEvent(title: "Interview with Elissa McArthur", time: "9:30 - 10:00",  subtitle: "Product Designer"),
        ],
        anomalyPills: {
            let eligible = TimeAttendanceMockData.employees.filter { !$0.hasScheduleIcon }
            return [
                TodayAnomalyPill(label: "Missed clocks",            count: eligible.filter { $0.anomalyType == .noClockIn }.count,            style: .danger,  filters: [.noClockIn]),
                TodayAnomalyPill(label: "Missed clock-ins",         count: eligible.filter { $0.anomalyType == .noClockInNorOut }.count,      style: .danger,  filters: [.noClockInNorOut]),
                TodayAnomalyPill(label: "Missed clock-outs",        count: eligible.filter { $0.anomalyType == .exceededWorkSchedule }.count, style: .warning, filters: [.exceededWorkSchedule]),
                TodayAnomalyPill(label: "On track",                  count: eligible.filter { $0.anomalyType == .onTrack }.count,              style: .success, filters: [.onTrack]),
                TodayAnomalyPill(label: "Expected to work today",    count: eligible.count,                                                    style: .neutral, filters: []),
            ]
        }(),
        onLeaveTitle: "On leave",
        onLeaveAvatars: ["avatar-abdi", "avatar-emma", "avatar-tyler"],
        onLeaveOverflow: 150,
        celebrations: [
            TodayCelebration(icon: "icon-hat",  iconColor: AppColors.betaDefault,  iconBackground: AppColors.betaLightBackground, title: "Work anniversaries", value: "Smith, Johannes +3"),
            TodayCelebration(icon: "icon-gift", iconColor: Color(hex: "E9756D"),   iconBackground: AppColors.dangerBackground,    title: "Birthdays",          value: "Doe, John +2"),
            TodayCelebration(icon: "icon-pyro", iconColor: Color(hex: "37B086"),   iconBackground: AppColors.successBackground,   title: "Holidays",           value: "Christmas day"),
        ]
    )
}

// MARK: - Version Enum & Switcher

enum TodayWidgetVersion: String, CaseIterable, Identifiable {
    case figma     = "Figma"
    case classic   = "Classic"
    case compact   = "Compact"
    case cardGrid  = "Grid"
    case rich      = "Rich"
    case timeline  = "Timeline"
    case magazine  = "Magazine"
    case bento     = "Bento"
    case dashboard = "Stats"

    var id: String { rawValue }
}

struct TodayWidgetSwitcher: View {
    let data: TodayWidgetData
    @State private var selectedVersion: TodayWidgetVersion = .figma

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TodayWidgetVersion.allCases) { version in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedVersion = version }
                        } label: {
                            Text(version.rawValue)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(selectedVersion == version ? AppColors.surface : AppColors.fontSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(selectedVersion == version ? AppColors.fontDefault : AppColors.separator.opacity(0.6))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 10)
            .background(AppColors.lightBackground)
            .cornerRadius(16, corners: [.topLeft, .topRight])

            Group {
                switch selectedVersion {
                case .figma:     TodayWidgetFigma(data: data)
                case .classic:   TodayWidgetClassic(data: data)
                case .compact:   TodayWidgetCompact(data: data)
                case .cardGrid:  TodayWidgetCardGrid(data: data)
                case .rich:      TodayWidgetRich(data: data)
                case .timeline:  TodayWidgetTimeline(data: data)
                case .magazine:  TodayWidgetMagazine(data: data)
                case .bento:     TodayWidgetBento(data: data)
                case .dashboard: TodayWidgetDashboard(data: data)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: selectedVersion)
        }
    }
}

// MARK: - Selective Corner Radius

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Shared Sub-views

private struct TodayHeader: View {
    var body: some View {
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
    }
}

private struct EventRow: View {
    let event: TodayEvent
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
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
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle().size(width: 32, height: 32))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct CelebrationRow: View {
    let item: TodayCelebration
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(item.iconBackground)
                    .frame(width: 40, height: 40)
                Image(item.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(item.iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
                Text(item.value)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
            }
            Spacer()
        }
    }
}

private struct AvatarStack: View {
    let names: [String]
    let overflow: Int
    var size: CGFloat = 25

    var body: some View {
        HStack(spacing: 2) {
            ForEach(names.prefix(3), id: \.self) { name in
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            }
        }
        if overflow > 0 {
            Text("+\(overflow)")
                .font(AppFonts.caption1Strong())
                .foregroundColor(AppColors.fontSecondary)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .frame(height: size)
                .background(AppColors.separator)
                .clipShape(Capsule())
        }
    }
}

private struct AttendanceBadge: View {
    let count: Int
    let label: String
    let badgeColor: Color
    let textColor: Color
    let labelColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Text("\(count)")
                .font(AppFonts.caption1Strong())
                .foregroundColor(textColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(badgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(label)
                .font(AppFonts.caption1())
                .foregroundColor(labelColor)
        }
    }
}

// MARK: - Version F — Figma (faithful to design)

struct TodayWidgetFigma: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            ForEach(data.events.prefix(1)) { event in
                EventRow(event: event)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    CelebrationRow(item: item)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(data.onLeaveTitle)
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontDefault)
                    AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(AppColors.lightBackground)
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Attendance")
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontDefault)

                    VStack(alignment: .leading, spacing: 8) {
                        AttendanceBadge(
                            count: data.issueCount,
                            label: "Issues",
                            badgeColor: Color(light: "FFD2CF", dark: "5A1A0F"),
                            textColor: AppColors.dangerDefault,
                            labelColor: AppColors.dangerDefault
                        )
                        AttendanceBadge(
                            count: data.onTrackCount,
                            label: "On track",
                            badgeColor: AppColors.activeBackground,
                            textColor: AppColors.primaryDark,
                            labelColor: AppColors.fontDefault
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(AppColors.lightBackground)
                .cornerRadius(16)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }
}

// MARK: - Version A — Classic

struct TodayWidgetClassic: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            VStack(alignment: .leading, spacing: 24) {
                ForEach(data.events) { event in
                    EventRow(event: event)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.anomalyPills) { pill in
                        NavigationLink {
                            TimeAttendanceAnomaliesListView(initialFilters: pill.filters)
                        } label: {
                            pillView(label: pill.label, count: pill.count, style: pill.style)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Text(data.onLeaveTitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.24)
                Spacer()
                AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    CelebrationRow(item: item)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private func pillView(label: String, count: Int, style: TodayPillStyle) -> some View {
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

// MARK: - Version B — Compact

struct TodayWidgetCompact: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(0.35)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Text("\(data.events.count) events")
                    .font(AppFonts.caption1())
                    .foregroundColor(AppColors.fontSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(data.events) { event in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppColors.primaryDark)
                            .frame(width: 6, height: 6)
                        Text(event.title)
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontDefault)
                            .lineLimit(1)
                        Spacer()
                        Text(event.time)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
            }

            Rectangle().fill(AppColors.separator).frame(height: 1)

            HStack(spacing: 16) {
                ForEach(data.anomalyPills.filter { !$0.filters.isEmpty }) { pill in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(pill.style.badgeBackground)
                            .frame(width: 8, height: 8)
                        Text("\(pill.count)")
                            .font(AppFonts.caption1Strong())
                            .foregroundColor(AppColors.fontDefault)
                    }
                }
                Spacer()
                NavigationLink {
                    TimeAttendanceAnomaliesListView(initialFilters: [])
                } label: {
                    Text("View all")
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(AppColors.separator).frame(height: 1)

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.iconDefault)
                    Text(data.onLeaveTitle)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                        .lineLimit(1)
                }
                Spacer()
                ForEach(data.celebrations) { item in
                    HStack(spacing: 4) {
                        Image(item.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundColor(item.iconColor)
                        Text(item.value)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }
}

// MARK: - Version C — Card Grid

struct TodayWidgetCardGrid: View {
    let data: TodayWidgetData

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TodayHeader()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.events) { event in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.primaryDark)
                            .frame(width: 3, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)
                            Text(event.time)
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(AppColors.lightBackground)
                    .cornerRadius(12)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                gridCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.dangerDefault)
                            Text("Attendance")
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        let total = data.anomalyPills.first(where: { $0.filters.isEmpty })?.count ?? 0
                        Text("\(total)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.fontDefault)
                        HStack(spacing: 4) {
                            ForEach(data.anomalyPills.filter { !$0.filters.isEmpty }) { pill in
                                Circle()
                                    .fill(pill.style.badgeBackground)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }

                gridCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.informativeDefault)
                            Text("On Leave")
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        AvatarStack(names: data.onLeaveAvatars, overflow: 0, size: 24)
                        if data.onLeaveOverflow > 0 {
                            Text("+\(data.onLeaveOverflow) more")
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                }

                ForEach(data.celebrations) { item in
                    gridCard {
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(item.iconBackground)
                                    .frame(width: 32, height: 32)
                                Image(item.icon)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(item.iconColor)
                            }
                            Text(item.title)
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                            Text(item.value)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private func gridCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)
    }
}

// MARK: - Version D — Rich

struct TodayWidgetRich: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()
            progressSection

            VStack(alignment: .leading, spacing: 10) {
                ForEach(data.events) { event in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.primaryDark)
                            .frame(width: 4, height: 48)
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
                        Spacer()
                        Button {} label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.iconDefault)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            anomalyBarChart

            HStack(spacing: 12) {
                ForEach(data.celebrations) { item in
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(item.iconBackground)
                                .frame(width: 44, height: 44)
                            Image(item.icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundColor(item.iconColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                            Text(item.value)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(item.iconBackground.opacity(0.5))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private var progressSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(AppColors.separator, lineWidth: 5)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(AppColors.primaryDark, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                Text("6h")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontDefault)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("6h of 8h tracked")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.fontDefault)
                Text("8:00 – 16:00 schedule")
                    .font(AppFonts.caption1())
                    .foregroundColor(AppColors.fontSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(AppColors.lightBackground)
        .cornerRadius(12)
    }

    private var anomalyBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendance")
                .font(AppFonts.caption1Strong())
                .foregroundColor(AppColors.fontSecondary)

            let filtered = data.anomalyPills.filter { !$0.filters.isEmpty }
            let maxCount = filtered.map(\.count).max() ?? 1
            ForEach(filtered) { pill in
                HStack(spacing: 8) {
                    Text(pill.label)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                        .frame(width: 120, alignment: .trailing)
                        .lineLimit(1)
                    GeometryReader { geo in
                        let fraction = maxCount > 0 ? CGFloat(pill.count) / CGFloat(maxCount) : 0
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(pill.style.badgeBackground)
                            .frame(width: max(geo.size.width * fraction, 4))
                    }
                    .frame(height: 12)
                    Text("\(pill.count)")
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.fontDefault)
                        .frame(width: 24, alignment: .leading)
                }
            }
        }
        .padding(12)
        .background(AppColors.lightBackground)
        .cornerRadius(12)
    }
}

// MARK: - Version E — Timeline

struct TodayWidgetTimeline: View {
    let data: TodayWidgetData

    private var timelineNodes: [TimelineNode] {
        var nodes: [TimelineNode] = []
        nodes.append(TimelineNode(time: "8:00", title: "Shift starts", subtitle: "8:00 – 16:00", kind: .shift))
        for event in data.events {
            let startTime = String(event.time.prefix(5))
            nodes.append(TimelineNode(time: startTime, title: event.title, subtitle: "\(event.time) · \(event.subtitle)", kind: .event))
        }
        if data.issueCount > 0 {
            nodes.append(TimelineNode(time: "—", title: "\(data.issueCount) attendance issues", subtitle: "Missed clock-ins & clocks", kind: .anomaly))
        }
        nodes.append(TimelineNode(time: "16:00", title: "Shift ends", subtitle: nil, kind: .shift))
        for item in data.celebrations {
            nodes.append(TimelineNode(time: "✦", title: item.title, subtitle: item.value, kind: .milestone, celebration: item))
        }
        return nodes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TodayHeader()
                .padding(.bottom, 16)

            ForEach(Array(timelineNodes.enumerated()), id: \.offset) { index, node in
                let isLast = index == timelineNodes.count - 1
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        timelineDot(for: node.kind)
                        if !isLast {
                            Rectangle()
                                .fill(AppColors.separator)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 20)

                    Text(node.time)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                        .frame(width: 42, alignment: .leading)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        if let celebration = node.celebration {
                            HStack(spacing: 6) {
                                Image(celebration.icon)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(celebration.iconColor)
                                Text(node.title)
                                    .font(AppFonts.subheadStrong())
                                    .foregroundColor(AppColors.fontDefault)
                            }
                        } else {
                            Text(node.title)
                                .font(node.kind == .shift ? AppFonts.caption1Strong() : AppFonts.subheadline())
                                .foregroundColor(node.kind == .anomaly ? AppColors.dangerDefault : AppColors.fontDefault)
                                .tracking(-0.24)
                        }
                        if let subtitle = node.subtitle {
                            Text(subtitle)
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                    .padding(.bottom, isLast ? 0 : 16)
                    Spacer()
                }
            }

            if !data.onLeaveAvatars.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.iconDefault)
                    Text(data.onLeaveTitle)
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                    Spacer()
                    AvatarStack(names: data.onLeaveAvatars, overflow: 0, size: 20)
                }
                .padding(.top, 12)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private func timelineDot(for kind: TimelineNode.Kind) -> some View {
        Group {
            switch kind {
            case .event:
                Circle().fill(AppColors.primaryDark).frame(width: 10, height: 10).padding(5)
            case .shift:
                Circle().strokeBorder(AppColors.iconDefault, lineWidth: 2).frame(width: 10, height: 10).padding(5)
            case .anomaly:
                ZStack {
                    Circle().fill(AppColors.dangerBackground).frame(width: 20, height: 20)
                    Image(systemName: "exclamationmark").font(.system(size: 9, weight: .bold)).foregroundColor(AppColors.dangerDefault)
                }
            case .milestone:
                ZStack {
                    Circle().fill(AppColors.successBackground).frame(width: 20, height: 20)
                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(Color(hex: "37B086"))
                }
            }
        }
    }
}

private struct TimelineNode {
    enum Kind { case event, shift, anomaly, milestone }
    let time: String
    let title: String
    let subtitle: String?
    let kind: Kind
    var celebration: TodayCelebration? = nil
}

// MARK: - Version G — Magazine

struct TodayWidgetMagazine: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            if let event = data.events.first {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.fontDefault)
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.primaryDark)
                        Text(event.time)
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(AppColors.primaryDark)
                        Text("·")
                            .foregroundColor(AppColors.fontSecondary)
                        Text(event.subtitle)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.lightBackground)
                .cornerRadius(12)
            }

            if data.events.count > 1 {
                Text("+\(data.events.count - 1) more event\(data.events.count > 2 ? "s" : "")")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.primaryDark)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(data.celebrations) { item in
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(item.iconBackground)
                                    .frame(width: 32, height: 32)
                                Image(item.icon)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(item.iconColor)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title)
                                    .font(AppFonts.caption1())
                                    .foregroundColor(AppColors.fontSecondary)
                                Text(item.value)
                                    .font(AppFonts.subheadStrong())
                                    .foregroundColor(AppColors.fontDefault)
                                    .lineLimit(1)
                            }
                        }
                        .padding(8)
                        .background(AppColors.lightBackground)
                        .cornerRadius(10)
                    }
                }
            }

            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow, size: 22)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle().fill(AppColors.separator).frame(width: 1, height: 32)

                HStack(spacing: 12) {
                    AttendanceBadge(
                        count: data.issueCount,
                        label: "Issues",
                        badgeColor: Color(light: "FFD2CF", dark: "5A1A0F"),
                        textColor: AppColors.dangerDefault,
                        labelColor: AppColors.dangerDefault
                    )
                    AttendanceBadge(
                        count: data.onTrackCount,
                        label: "OK",
                        badgeColor: AppColors.activeBackground,
                        textColor: AppColors.primaryDark,
                        labelColor: AppColors.fontDefault
                    )
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }
}

// MARK: - Version H — Bento

struct TodayWidgetBento: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TodayHeader()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data.events) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)
                            Text(event.time)
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(AppColors.lightBackground)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Attendance")
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.fontSecondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(data.issueCount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.dangerDefault)
                        Text("issues")
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                    }

                    HStack(spacing: 4) {
                        Circle().fill(AppColors.activeBackground).frame(width: 8, height: 8)
                        Text("\(data.onTrackCount) on track")
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.lightBackground)
                .cornerRadius(12)
            }

            HStack(spacing: 12) {
                ForEach(data.celebrations) { item in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(item.iconBackground)
                                .frame(width: 36, height: 36)
                            Image(item.icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(item.iconColor)
                        }
                        Text(item.value)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontDefault)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.lightBackground)
                    .cornerRadius(10)
                }
            }

            HStack(spacing: 8) {
                Text(data.onLeaveTitle)
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow, size: 22)
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }
}

// MARK: - Version I — Dashboard

struct TodayWidgetDashboard: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TodayHeader()

            HStack(spacing: 12) {
                statCard(value: "\(data.events.count)", label: "Events", color: AppColors.primaryDark)
                statCard(value: "\(data.issueCount)", label: "Issues", color: AppColors.dangerDefault)
                statCard(value: "\(data.onTrackCount)", label: "On track", color: AppColors.successDefault)
                statCard(value: "\(data.onLeaveOverflow + data.onLeaveAvatars.count)", label: "On leave", color: AppColors.informativeDefault)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("EVENTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(0.5)
                ForEach(data.events) { event in
                    HStack(spacing: 10) {
                        Text(String(event.time.prefix(5)))
                            .font(AppFonts.caption1Strong())
                            .foregroundColor(AppColors.primaryDark)
                            .frame(width: 40, alignment: .leading)
                        Text(event.title)
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontDefault)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("CELEBRATIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(0.5)
                ForEach(data.celebrations) { item in
                    HStack(spacing: 8) {
                        Image(item.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(item.iconColor)
                        Text(item.title)
                            .font(AppFonts.caption1Strong())
                            .foregroundColor(AppColors.fontSecondary)
                        Spacer()
                        Text(item.value)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontDefault)
                    }
                }
            }
            .padding(12)
            .background(AppColors.lightBackground)
            .cornerRadius(12)

            HStack(spacing: 8) {
                AvatarStack(names: data.onLeaveAvatars, overflow: data.onLeaveOverflow, size: 22)
                Spacer()
                AttendanceBadge(
                    count: data.issueCount,
                    label: "Issues",
                    badgeColor: Color(light: "FFD2CF", dark: "5A1A0F"),
                    textColor: AppColors.dangerDefault,
                    labelColor: AppColors.dangerDefault
                )
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption1())
                .foregroundColor(AppColors.fontSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.lightBackground)
        .cornerRadius(10)
    }
}

// MARK: - Previews

#Preview("Today Widget Switcher") {
    NavigationStack {
        ScrollView {
            TodayWidgetSwitcher(data: .mock)
                .padding(16)
        }
        .background(AppColors.background)
    }
}
