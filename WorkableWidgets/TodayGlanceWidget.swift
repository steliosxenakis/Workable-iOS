import WidgetKit
import SwiftUI
import AppIntents

/// Home-screen "Today at a glance" widget.
///
/// Mirrors the sections on the in-app Home dashboard — time tracking, to-dos,
/// the attendance-driven "Today" card (events/attendance/on leave/
/// celebrations), new candidates, and time off — and gates each one by the
/// account's plan (ATS only / HRIS only / both), since not every customer has
/// every module. `WidgetContentPlanner` (Shared/WidgetGlanceData.swift) owns
/// that filtering so small/medium/large just render more or less of the same
/// prioritized list.
///
/// Visuals: V1 forest-green (Figma 15871:542987 / 542931 / 543037 / 543096 /
/// 543161 / 544895) and V2 Neutral/800 with mint + purple glow (15871:545082 /
/// 545026 / 545132 / 545191 / 545256 / 545319). Pick either in Settings.
struct TodayGlanceWidget: Widget {
    let kind: String = WidgetGlanceStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayGlanceProvider()) { entry in
            TodayGlanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Time tracking, to-dos, attendance, candidates, and time off — scoped to your plan.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Timeline

struct TodayGlanceEntry: TimelineEntry {
    let date: Date
    let isClockedIn: Bool
    let isOnBreak: Bool
    let clockInDate: Date?
    let breakStartDate: Date?
    /// Emoji picked for the current break (V15 in-app UI), e.g. "☕". Falls back
    /// to a generic pause glyph when nil.
    let breakEmoji: String?
    let glance: WidgetGlanceData
    let plan: WorkablePlan
    let uiVersion: WidgetGlanceUIVersion

    var timerStart: Date? {
        if isOnBreak, let breakStartDate { return breakStartDate }
        if isClockedIn { return clockInDate }
        return nil
    }

    static let placeholder = TodayGlanceEntry(
        date: .now,
        isClockedIn: true,
        isOnBreak: false,
        clockInDate: Calendar.current.date(byAdding: .hour, value: -2, to: .now),
        breakStartDate: nil,
        breakEmoji: nil,
        glance: .mock,
        plan: .both,
        uiVersion: .v1
    )

    static let onBreakPlaceholder = TodayGlanceEntry(
        date: .now,
        isClockedIn: true,
        isOnBreak: true,
        clockInDate: Calendar.current.date(byAdding: .hour, value: -2, to: .now),
        breakStartDate: Calendar.current.date(byAdding: .minute, value: -15, to: .now),
        breakEmoji: "☕",
        glance: .mock,
        plan: .both,
        uiVersion: .v1
    )

    static let clockedOutPlaceholder = TodayGlanceEntry(
        date: .now,
        isClockedIn: false,
        isOnBreak: false,
        clockInDate: nil,
        breakStartDate: nil,
        breakEmoji: nil,
        glance: .mock,
        plan: .both,
        uiVersion: .v1
    )

    static let atsOnlyPlaceholder = TodayGlanceEntry(
        date: .now,
        isClockedIn: false,
        isOnBreak: false,
        clockInDate: nil,
        breakStartDate: nil,
        breakEmoji: nil,
        glance: .mock,
        plan: .atsOnly,
        uiVersion: .v1
    )

    func with(uiVersion: WidgetGlanceUIVersion) -> TodayGlanceEntry {
        TodayGlanceEntry(
            date: date,
            isClockedIn: isClockedIn,
            isOnBreak: isOnBreak,
            clockInDate: clockInDate,
            breakStartDate: breakStartDate,
            breakEmoji: breakEmoji,
            glance: glance,
            plan: plan,
            uiVersion: uiVersion
        )
    }
}

struct TodayGlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayGlanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayGlanceEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayGlanceEntry>) -> Void) {
        let entry = currentEntry()
        // The clock timer itself live-updates via `Text(timerInterval:)` with no
        // new entries needed. The app/Live Activity call `reloadTimelines` on any
        // state change, so this periodic refresh is just a safety net.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> TodayGlanceEntry {
        let defaults = ClockInSessionSync.defaults
        let isClockedIn = defaults.bool(forKey: ClockInSessionSync.isClockedInKey)
        let isOnBreak = defaults.bool(forKey: ClockInSessionSync.isOnBreakKey)
        let clockInDate: Date? = {
            guard isClockedIn, defaults.object(forKey: ClockInSessionSync.clockInDateKey) != nil else { return nil }
            return Date(timeIntervalSince1970: defaults.double(forKey: ClockInSessionSync.clockInDateKey))
        }()
        let breakStartDate: Date? = {
            guard isOnBreak, defaults.object(forKey: ClockInSessionSync.breakStartDateKey) != nil else { return nil }
            return Date(timeIntervalSince1970: defaults.double(forKey: ClockInSessionSync.breakStartDateKey))
        }()
        let breakEmoji = isOnBreak ? defaults.string(forKey: ClockInSessionSync.breakEmojiKey) : nil

        return TodayGlanceEntry(
            date: .now,
            isClockedIn: isClockedIn,
            isOnBreak: isOnBreak,
            clockInDate: clockInDate,
            breakStartDate: breakStartDate,
            breakEmoji: breakEmoji,
            glance: WidgetGlanceStore.load(),
            plan: WidgetPlanStore.load(),
            uiVersion: WidgetGlanceUIVersionStore.load()
        )
    }
}

// MARK: - Views

struct TodayGlanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayGlanceEntry

    private var content: (hero: WidgetHero, chips: [WidgetSectionChip]) {
        WidgetContentPlanner.plan(glance: entry.glance, plan: entry.plan)
    }

    var body: some View {
        switch family {
        case .systemLarge:
            TodayGlanceLargeView(entry: entry, content: content)
        case .systemMedium:
            TodayGlanceMediumView(entry: entry, content: content)
        default:
            TodayGlanceSmallView(entry: entry, content: content)
        }
    }
}

/// Small widget — Figma 15870:540892 (clocked out) / 15870:540837 (clocked in).
private struct TodayGlanceSmallView: View {
    let entry: TodayGlanceEntry
    let content: (hero: WidgetHero, chips: [WidgetSectionChip])

    var body: some View {
        Group {
            switch content.hero {
            case .timeTracking:
                smallTimeTracking
            case .metric(let chip):
                smallMetric(chip)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetGlanceChrome(version: entry.uiVersion, v1Background: AppColors.primary600)
        .widgetURL(smallWidgetURL)
    }

    private var smallTimeTracking: some View {
        VStack(alignment: .leading, spacing: 12) {
            if entry.isClockedIn {
                Link(destination: WidgetDeepLink.url(for: .home)) {
                    VStack(alignment: .leading, spacing: 12) {
                        WidgetWorkableLogo(width: 29, height: 16)
                        WidgetLiveTimer(start: entry.timerStart, style: .compact)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 8)
                HStack {
                    Spacer(minLength: 0)
                    WidgetClockControl(isClockedIn: true, showsStop: !entry.isOnBreak)
                    Spacer(minLength: 0)
                }
            } else {
                Spacer(minLength: 0)
                Link(destination: WidgetDeepLink.url(for: .home)) {
                    WidgetWorkableLogo(width: 58, height: 31)
                }
                .frame(maxWidth: .infinity)
                WidgetClockControl(isClockedIn: false, showsStop: false)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
        }
    }

    private func smallMetric(_ chip: WidgetSectionChip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetWorkableLogo(width: 29, height: 16)
            Spacer(minLength: 4)
            Text(chip.value)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(chip.widgetLabel)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.iconInactive)
                .lineLimit(1)
        }
    }

    private var smallWidgetURL: URL? {
        if case .metric(let chip) = content.hero {
            return WidgetDeepLink.url(for: chip.destination)
        }
        return nil
    }
}

/// Medium widget — Figma 15870:540943.
private struct TodayGlanceMediumView: View {
    let entry: TodayGlanceEntry
    let content: (hero: WidgetHero, chips: [WidgetSectionChip])

    private var mediumChips: [WidgetSectionChip] {
        chips(from: content.chips, ids: ["todos", "meetings", "attendance"], fallbackCount: 3)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            leadingColumn
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(entry.uiVersion == .v1 ? AppColors.primary600 : Color.clear)

            VStack(spacing: 8) {
                ForEach(mediumChips) { chip in
                    GlanceChipView(chip: chip, compact: true, version: entry.uiVersion)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetGlanceChrome(version: entry.uiVersion, v1Background: AppColors.primary700)
    }

    @ViewBuilder
    private var leadingColumn: some View {
        switch content.hero {
        case .timeTracking:
            if entry.isClockedIn {
                VStack(alignment: .leading, spacing: 12) {
                    Link(destination: WidgetDeepLink.url(for: .home)) {
                        VStack(alignment: .leading, spacing: 12) {
                            WidgetWorkableLogo(width: 29, height: 16)
                            WidgetLiveTimer(start: entry.timerStart, style: .compact)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer(minLength: 8)
                    HStack {
                        Spacer(minLength: 0)
                        WidgetClockControl(isClockedIn: true, showsStop: !entry.isOnBreak)
                        Spacer(minLength: 0)
                    }
                }
            } else {
                // Figma 15870:540943 — large mark + play, no timer.
                VStack(spacing: 17) {
                    Link(destination: WidgetDeepLink.url(for: .home)) {
                        WidgetWorkableLogo(width: 58, height: 31)
                    }
                    WidgetClockControl(isClockedIn: false, showsStop: false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case .metric(let chip):
            VStack(alignment: .leading, spacing: 8) {
                WidgetWorkableLogo(width: 29, height: 16)
                Spacer(minLength: 0)
                Text(chip.value)
                    .font(AppFonts.chunkyTitle())
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(chip.widgetLabel)
                    .font(AppFonts.caption1())
                    .foregroundStyle(AppColors.iconInactive)
                    .lineLimit(2)
            }
        }
    }
}

/// Large widget — Figma 15870:541004.
private struct TodayGlanceLargeView: View {
    let entry: TodayGlanceEntry
    let content: (hero: WidgetHero, chips: [WidgetSectionChip])

    private var largeChips: [WidgetSectionChip] {
        chips(from: content.chips, ids: ["todos", "meetings", "attendance", "onleave", "celebrations"], fallbackCount: 5)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .center)
                .background(entry.uiVersion == .v1 ? AppColors.primary600 : Color.clear)

            chipBlock
                .padding(.horizontal, 18)
                .padding(.top, 19)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .widgetGlanceChrome(version: entry.uiVersion, v1Background: AppColors.primary700)
    }

    @ViewBuilder
    private var header: some View {
        switch content.hero {
        case .timeTracking:
            if entry.isClockedIn {
                VStack(alignment: .leading, spacing: 21) {
                    WidgetWorkableLogo(width: 29, height: 16)
                    HStack(spacing: 16) {
                        Link(destination: WidgetDeepLink.url(for: .home)) {
                            WidgetLiveTimer(start: entry.timerStart, style: .large)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        WidgetClockControl(
                            isClockedIn: true,
                            showsStop: !entry.isOnBreak
                        )
                    }
                }
                .padding(.vertical, 18)
            } else {
                // Figma 15870:541004 — large mark on the left, play on the right.
                HStack {
                    Link(destination: WidgetDeepLink.url(for: .home)) {
                        WidgetWorkableLogo(width: 58, height: 31)
                    }
                    Spacer(minLength: 8)
                    WidgetClockControl(isClockedIn: false, showsStop: false)
                }
            }
        case .metric(let chip):
            VStack(alignment: .leading, spacing: 12) {
                WidgetWorkableLogo(width: 29, height: 16)
                Text(chip.value)
                    .font(AppFonts.chunkyTitle())
                    .foregroundStyle(.white)
                Text(chip.widgetLabel)
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.iconInactive)
            }
        }
    }

    private var chipBlock: some View {
        let chips = largeChips
        let rest = Array(chips.dropFirst())
        let rows = stride(from: 0, to: rest.count, by: 2).map {
            Array(rest[$0..<min($0 + 2, rest.count)])
        }
        return VStack(spacing: 10) {
            if let first = chips.first {
                GlanceChipView(chip: first, compact: false, version: entry.uiVersion)
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: 10) {
                    ForEach(pair) { chip in
                        GlanceChipView(chip: chip, compact: false, version: entry.uiVersion)
                            .frame(maxHeight: .infinity)
                    }
                    if pair.count == 1 {
                        Spacer(minLength: 0).frame(maxWidth: .infinity)
                    }
                }
                .frame(minHeight: GlanceChipView.largeHeight)
            }
        }
    }
}

// MARK: - Shared building blocks

private func chips(from all: [WidgetSectionChip], ids: [String], fallbackCount: Int) -> [WidgetSectionChip] {
    let byId = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    let picked = ids.compactMap { byId[$0] }
    if picked.isEmpty {
        return Array(all.prefix(fallbackCount))
    }
    return picked
}

private extension View {
    func widgetGlanceChrome(version: WidgetGlanceUIVersion, v1Background: Color) -> some View {
        self
            .clipShape(ContainerRelativeShape())
            .containerBackground(for: .widget) {
                if version == .v2 {
                    WidgetV2GlowBackground()
                } else {
                    v1Background
                }
            }
    }
}

/// Neutral/800 canvas with mint + purple ellipse washes.
/// Large (Figma 15871:545261): mint off the right edge, purple off the left,
/// header stays black. Small/medium (15871:545196): mint above, purple below-right.
private struct WidgetV2GlowBackground: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let isLarge = height > 250
            ZStack {
                AppColors.widgetV2Background
                if isLarge {
                    glow(
                        color: AppColors.widgetV2PurpleGlow.opacity(0.6),
                        size: CGSize(width: width * 0.88, height: height * 0.76),
                        blur: 25,
                        center: CGPoint(x: width * 0.28, y: height * 0.81)
                    )
                    glow(
                        color: AppColors.widgetV2MintGlow.opacity(0.84),
                        size: CGSize(width: width * 1.05, height: height * 0.90),
                        blur: 35,
                        center: CGPoint(x: width * 1.14, y: height * 0.84)
                    )
                } else {
                    glow(
                        color: AppColors.widgetV2MintGlow.opacity(0.84),
                        size: CGSize(width: width * 0.97, height: height * 1.65),
                        blur: 35,
                        center: CGPoint(x: width * 0.67, y: height * -0.05)
                    )
                    glow(
                        color: AppColors.widgetV2PurpleGlow.opacity(0.6),
                        size: CGSize(width: width * 1.04, height: height * 1.59),
                        blur: 25,
                        center: CGPoint(x: width * 0.78, y: height * 1.34)
                    )
                }
            }
            .clipped()
        }
        .allowsHitTesting(false)
    }

    private func glow(color: Color, size: CGSize, blur: CGFloat, center: CGPoint) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: size.width, height: size.height)
            .blur(radius: blur)
            .position(center)
    }
}

private struct WidgetWorkableLogo: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        Image("logo-workable")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

private enum WidgetTimerStyle {
    case compact
    case large
}

/// Elapsed time as `0h 00m` + `01s` (Figma 15871:545196 / 545063–545064).
/// Compact: Title2 strong 22 + Body 17 icon-inactive. Large keeps Chunky Title minutes.
private struct WidgetLiveTimer: View {
    let start: Date?
    var style: WidgetTimerStyle

    var body: some View {
        Group {
            if let start {
                TimelineView(.periodic(from: start, by: 1)) { context in
                    labels(elapsed: max(0, Int(context.date.timeIntervalSince(start))))
                }
            } else {
                labels(elapsed: 0)
            }
        }
        .accessibilityLabel("Elapsed time")
    }

    private func labels(elapsed: Int) -> some View {
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        let isLarge = style == .large
        return HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text("\(hours)h \(String(format: "%02d", minutes))m")
                .font(isLarge ? AppFonts.chunkyTitle() : AppFonts.title2Strong())
                .tracking(isLarge ? 0.41 : 0.35)
                .foregroundStyle(.white)
            Text(String(format: "%02ds", seconds))
                .font(isLarge ? AppFonts.title3() : AppFonts.body())
                .tracking(isLarge ? 0.38 : -0.41)
                .foregroundStyle(AppColors.widgetTimerSeconds)
        }
        .monospacedDigit()
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .contentTransition(.numericText())
    }
}

/// Play clocks in from the widget. Stop clocks out from the widget.
/// Neither action opens the app (`openAppWhenRun` is false on both intents).
///
/// Artwork lives *outside* the `Button` label. WidgetKit restyles intent
/// buttons and was dropping the circle fill, leaving a tiny glyph on the dark
/// card. A parent `.widgetURL` also suppressed interactive controls.
private struct WidgetClockControl: View {
    let isClockedIn: Bool
    let showsStop: Bool

    var body: some View {
        if isClockedIn, showsStop {
            widgetIntentButton(
                intent: ClockOutWidgetIntent(),
                accessibilityLabel: "Clock out",
                systemImage: "stop.fill",
                fontSize: 14,
                fill: Color.white,
                ink: AppColors.liveActivityButtonInk
            )
        } else if !isClockedIn {
            widgetIntentButton(
                intent: ClockInWidgetIntent(),
                accessibilityLabel: "Clock in",
                systemImage: "play.fill",
                fontSize: 18,
                fill: AppColors.liveActivityProgressTrack,
                ink: AppColors.liveActivityProgressFill,
                playNudge: true
            )
        }
    }

    private func widgetIntentButton<I: AppIntent>(
        intent: I,
        accessibilityLabel: String,
        systemImage: String,
        fontSize: CGFloat,
        fill: Color,
        ink: Color,
        playNudge: Bool = false
    ) -> some View {
        ZStack {
            clockButtonArtwork(
                systemImage: systemImage,
                fontSize: fontSize,
                fill: fill,
                ink: ink,
                playNudge: playNudge
            )
            Button(intent: intent) {
                Color.clear
                    .frame(width: 52, height: 52)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 52, height: 52)
        .accessibilityLabel(accessibilityLabel)
    }

    private func clockButtonArtwork(
        systemImage: String,
        fontSize: CGFloat,
        fill: Color,
        ink: Color,
        playNudge: Bool = false
    ) -> some View {
        ZStack {
            Circle()
                .fill(fill)
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(ink)
                .offset(x: playNudge ? 1 : 0)
        }
        .frame(width: 52, height: 52)
        .shadow(
            color: playNudge ? AppColors.primary.opacity(0.5) : .clear,
            radius: playNudge ? 8.5 : 0
        )
        .widgetAccentable(false)
    }
}

private struct GlanceChipView: View {
    /// Large-widget chip height (Figma 15871:545276) — matches two-line
    /// “Attendance issues” so every cell in the 2×2 grid is even.
    static let largeHeight: CGFloat = 60

    let chip: WidgetSectionChip
    var compact: Bool
    var version: WidgetGlanceUIVersion = .v1

    /// V2 attendance chip (Figma 15871:546824): outlined warning symbol +
    /// warning-text `#FFB420`. V1 keeps the filled symbol and brown chip fill.
    private var usesWarningAccent: Bool { chip.isWarning }

    private var accent: Color {
        usesWarningAccent ? AppColors.liveActivityWarning : AppColors.widgetChipAccent
    }

    private var symbolName: String {
        if version == .v2 {
            switch chip.id {
            case "attendance":
                return "exclamationmark.circle"
            case "onleave":
                return "calendar.badge.clock"
            default:
                break
            }
        }
        return chip.systemImage
    }

    private var chipFill: Color {
        switch version {
        case .v1:
            return usesWarningAccent ? AppColors.warning700 : AppColors.primary600
        case .v2:
            return AppColors.widgetV2Background
        }
    }

    var body: some View {
        Link(destination: WidgetDeepLink.url(for: chip.destination)) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 16, alignment: .center)

                Text(chip.widgetLabel)
                    .font(compact ? AppFonts.caption1() : AppFonts.subheadline())
                    .foregroundStyle(.white)
                    .lineLimit(compact ? 1 : 2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(chip.value)
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundStyle(accent)
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, compact ? 9 : 12)
            .frame(
                maxWidth: .infinity,
                minHeight: compact ? 38 : Self.largeHeight,
                maxHeight: compact ? nil : Self.largeHeight
            )
            .background(
                chipFill,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(
                color: version == .v2 ? Color.black.opacity(0.07) : .clear,
                radius: version == .v2 ? 14 : 0,
                y: version == .v2 ? 4 : 0
            )
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    TodayGlanceWidget()
} timeline: {
    TodayGlanceEntry.placeholder
    TodayGlanceEntry.clockedOutPlaceholder
    TodayGlanceEntry.onBreakPlaceholder
    TodayGlanceEntry.atsOnlyPlaceholder
    TodayGlanceEntry.placeholder.with(uiVersion: .v2)
    TodayGlanceEntry.clockedOutPlaceholder.with(uiVersion: .v2)
}

#Preview(as: .systemMedium) {
    TodayGlanceWidget()
} timeline: {
    TodayGlanceEntry.clockedOutPlaceholder
    TodayGlanceEntry.placeholder
    TodayGlanceEntry.atsOnlyPlaceholder
    TodayGlanceEntry.clockedOutPlaceholder.with(uiVersion: .v2)
    TodayGlanceEntry.placeholder.with(uiVersion: .v2)
}

#Preview(as: .systemLarge) {
    TodayGlanceWidget()
} timeline: {
    TodayGlanceEntry.clockedOutPlaceholder
    TodayGlanceEntry.placeholder
    TodayGlanceEntry.atsOnlyPlaceholder
    TodayGlanceEntry.clockedOutPlaceholder.with(uiVersion: .v2)
    TodayGlanceEntry.placeholder.with(uiVersion: .v2)
}
