import SwiftUI

// MARK: - Pill Style (self-contained for cross-branch compat)

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

    static let mock = TodayWidgetData(
        events: [
            TodayEvent(title: "Call with John Doe",             time: "10:30 - 11:00", subtitle: "Software Engineer"),
            TodayEvent(title: "Interview with Elissa McArthur", time: "9:30 - 10:00",  subtitle: "Product Designer"),
        ],
        anomalyPills: {
            let eligible = TimeAttendanceMockData.employees.filter { !$0.hasScheduleIcon }
            return [
                TodayAnomalyPill(label: "Missed clock-ins",         count: eligible.filter { $0.anomalyType == .noClockInNorOut }.count,      style: .danger,  filters: [.noClockInNorOut]),
                TodayAnomalyPill(label: "Exceeded work hours",        count: eligible.filter { $0.anomalyType == .exceededWorkSchedule }.count, style: .warning, filters: [.exceededWorkSchedule]),
                TodayAnomalyPill(label: "No attendance",            count: eligible.filter { $0.anomalyType == .noClockIn }.count,            style: .danger,  filters: [.noClockIn]),
                TodayAnomalyPill(label: "On track",                  count: eligible.filter { $0.anomalyType == .onTrack }.count,              style: .success, filters: [.onTrack]),
                TodayAnomalyPill(label: "Expected to work today",    count: eligible.count,                                                    style: .neutral, filters: []),
            ]
        }(),
        onLeaveTitle: "No employees on leave",
        onLeaveAvatars: ["avatar-abdi", "avatar-emma", "avatar-tyler"],
        onLeaveOverflow: 2,
        celebrations: [
            TodayCelebration(icon: "icon-gift", iconColor: Color(hex: "E9756D"), iconBackground: AppColors.dangerBackground, title: "Birthdays", value: "Doe, John +2"),
            TodayCelebration(icon: "icon-pyro", iconColor: Color(hex: "37B086"), iconBackground: AppColors.successBackground, title: "Holidays", value: "Christmas day"),
        ]
    )
}

// MARK: - Version Enum & Switcher

enum TodayWidgetVersion: String, CaseIterable, Identifiable {
    case classic  = "Classic"
    case compact  = "Compact"
    case cardGrid = "Grid"
    case rich     = "Rich"
    case timeline = "Timeline"

    var id: String { rawValue }
}

struct TodayWidgetSwitcher: View {
    let data: TodayWidgetData
    @State private var selectedVersion: TodayWidgetVersion = .classic

    var body: some View {
        VStack(spacing: 0) {
            Picker("Version", selection: $selectedVersion) {
                ForEach(TodayWidgetVersion.allCases) { version in
                    Text(version.rawValue).tag(version)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.lightBackground)
            .cornerRadius(16, corners: [.topLeft, .topRight])

            Group {
                switch selectedVersion {
                case .classic:  TodayWidgetClassic(data: data)
                case .compact:  TodayWidgetCompact(data: data)
                case .cardGrid: TodayWidgetCardGrid(data: data)
                case .rich:     TodayWidgetRich(data: data)
                case .timeline: TodayWidgetTimeline(data: data)
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

// MARK: - Version A — Classic

struct TodayWidgetClassic: View {
    let data: TodayWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 24) {
                ForEach(data.events) { event in
                    eventRow(event)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.anomalyPills) { pill in
                        NavigationLink {
                            AttendanceAnomaliesStandaloneView(initialFilters: pill.filters)
                        } label: {
                            todayPillView(label: pill.label, count: pill.count, style: pill.style)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            onLeaveRow

            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.celebrations) { item in
                    celebrationRow(icon: item.icon, iconColor: item.iconColor, iconBackground: item.iconBackground, title: item.title, value: item.value)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private var header: some View {
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

    private func eventRow(_ event: TodayEvent) -> some View {
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

    private func todayPillView(label: String, count: Int, style: TodayPillStyle) -> some View {
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

    private var onLeaveRow: some View {
        HStack {
            Text(data.onLeaveTitle)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontDefault)
                .tracking(-0.24)
            Spacer()
            if !data.onLeaveAvatars.isEmpty {
                HStack(spacing: 2) {
                    ForEach(data.onLeaveAvatars, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                }
            }
            if data.onLeaveOverflow > 0 {
                Text("+\(data.onLeaveOverflow)")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .frame(height: 25)
                    .background(AppColors.separator)
                    .clipShape(RoundedRectangle(cornerRadius: 200, style: .continuous))
            }
        }
    }

    private func celebrationRow(icon: String, iconColor: Color, iconBackground: Color, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(iconColor)
            }
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
                    AttendanceAnomaliesStandaloneView(initialFilters: [])
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
                        HStack(spacing: -6) {
                            ForEach(data.onLeaveAvatars.prefix(3), id: \.self) { name in
                                Image(name)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppColors.surface, lineWidth: 1.5))
                            }
                        }
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
                ForEach(data.onLeaveAvatars, id: \.self) { name in
                    VStack(spacing: 4) {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        Text(name.replacingOccurrences(of: "avatar-", with: "").capitalized)
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                            .lineLimit(1)
                    }
                }
                if data.onLeaveOverflow > 0 {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(AppColors.separator)
                                .frame(width: 36, height: 36)
                            Text("+\(data.onLeaveOverflow)")
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        Text("more")
                            .font(AppFonts.caption1())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                Spacer()
            }

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

            let maxCount = data.anomalyPills.filter { !$0.filters.isEmpty }.map(\.count).max() ?? 1
            ForEach(data.anomalyPills.filter { !$0.filters.isEmpty }) { pill in
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
        let dangerCount = data.anomalyPills.filter { $0.style == .danger }.reduce(0) { $0 + $1.count }
        if dangerCount > 0 {
            nodes.append(TimelineNode(time: "—", title: "\(dangerCount) attendance issues", subtitle: "Missed clock-ins & no attendance", kind: .anomaly))
        }
        nodes.append(TimelineNode(time: "16:00", title: "Shift ends", subtitle: nil, kind: .shift))

        for item in data.celebrations {
            nodes.append(TimelineNode(time: "✦", title: item.title, subtitle: item.value, kind: .milestone, celebration: item))
        }
        return nodes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    HStack(spacing: -4) {
                        ForEach(data.onLeaveAvatars.prefix(3), id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.surface, lineWidth: 1))
                        }
                    }
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
                Circle()
                    .fill(AppColors.primaryDark)
                    .frame(width: 10, height: 10)
                    .padding(5)
            case .shift:
                Circle()
                    .strokeBorder(AppColors.iconDefault, lineWidth: 2)
                    .frame(width: 10, height: 10)
                    .padding(5)
            case .anomaly:
                ZStack {
                    Circle()
                        .fill(AppColors.dangerBackground)
                        .frame(width: 20, height: 20)
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppColors.dangerDefault)
                }
            case .milestone:
                ZStack {
                    Circle()
                        .fill(AppColors.successBackground)
                        .frame(width: 20, height: 20)
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "37B086"))
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
