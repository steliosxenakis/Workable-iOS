import SwiftUI

// MARK: - Style selection (persisted; toggle via segmented control on Time tracking tab)

enum ScheduleHoursBarStyle: String, CaseIterable, Identifiable {
    case classic
    case dualMetrics
    case shiftBand
    /// Capsule family — see `HoursBalanceCapsuleModel` (±hours vs schedule).
    case differenceChip
    case capsuleLeading
    case capsuleInline
    case capsuleStacked
    /// Single tinted line: scheduled vs worked + delta text (no capsule chrome).
    case compactLine

    var id: String { rawValue }

    var pickerTitle: String {
        switch self {
        case .classic:          return "Classic bar"
        case .dualMetrics:      return "Dual metrics"
        case .shiftBand:        return "Shift band"
        case .differenceChip:   return "Δ Capsule · trailing"
        case .capsuleLeading:   return "Δ Capsule · leading"
        case .capsuleInline:    return "Δ Capsule · inline"
        case .capsuleStacked:   return "Δ Capsule · stacked"
        case .compactLine:      return "One line"
        }
    }
}

/// Hours visualization on employee rows — switches UI via `@AppStorage("scheduleHoursBarStyle")`.
struct ScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    /// Override for previews only; production rows omit this.
    var forcedStyle: ScheduleHoursBarStyle?

    @AppStorage("scheduleHoursBarStyle") private var storedRaw = ScheduleHoursBarStyle.classic.rawValue

    private var style: ScheduleHoursBarStyle {
        if let forcedStyle { return forcedStyle }
        return ScheduleHoursBarStyle(rawValue: storedRaw) ?? .classic
    }

    init(scheduledHours: Double, workedHours: Double, anomalyType: AnomalyType, forcedStyle: ScheduleHoursBarStyle? = nil) {
        self.scheduledHours = scheduledHours
        self.workedHours = workedHours
        self.anomalyType = anomalyType
        self.forcedStyle = forcedStyle
    }

    var body: some View {
        Group {
            switch style {
            case .classic:
                ClassicScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            case .dualMetrics:
                DualScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            case .shiftBand:
                ShiftBandScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            case .differenceChip:
                DifferenceChipScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            case .capsuleLeading:
                CapsuleLeadingScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            case .capsuleInline:
                CapsuleInlineScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            case .capsuleStacked:
                CapsuleStackedScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            case .compactLine:
                CompactLineScheduleHoursBar(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
            }
        }
    }
}

// MARK: - Shared helpers

private enum HoursFormat {
    static func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

// MARK: - Hours balance capsule (single source of truth for ±Δ UI)

/// Computes visibility, colors, and labels for the worked-vs-scheduled **difference capsule**.
/// All capsule-based row layouts should use this — only composition changes between styles.
struct HoursBalanceCapsuleModel {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    var gapHours: Double {
        workedHours - scheduledHours
    }

    /// When `false`, capsule layouts render empty space (same rules everywhere).
    var showsCapsule: Bool {
        if anomalyType == .scheduleNotStarted { return false }
        if anomalyType == .unplanned || anomalyType == .late || anomalyType == .exceededHours { return false }
        if anomalyType == .onTrack, abs(gapHours) < 0.05 { return false }
        return true
    }

    private var isDangerIssue: Bool {
        anomalyType.isDangerLevel
    }

    private var isWarningIssue: Bool {
        anomalyType.isWarningLevel
    }

    var foregroundColor: Color {
        if isWarningIssue {
            return AppColors.warningDefault
        }
        if isDangerIssue {
            return AppColors.dangerDefault
        }
        if anomalyType == .onTrack {
            return AppColors.successDefault
        }
        return AppColors.fontSecondary
    }

    var chipBackground: Color {
        if isWarningIssue {
            return AppColors.warningBackground.opacity(0.65)
        }
        if isDangerIssue {
            return AppColors.dangerBackground.opacity(0.65)
        }
        if anomalyType == .onTrack {
            return AppColors.successBackground.opacity(0.55)
        }
        return AppColors.lightBackground
    }

    var gapDisplayText: String {
        if anomalyType == .noClockInNorOut {
            return "0h"
        }
        let g = gapHours
        if abs(g) < 0.05 {
            return "0h"
        }
        let mag = HoursFormat.format(abs(g))
        return g > 0 ? "+\(mag)h" : "−\(mag)h"
    }

    var lateDeviationText: String {
        guard anomalyType == .late else { return "" }
        let deficit = scheduledHours - workedHours
        if deficit <= 0 { return "" }
        let totalMinutes = Int(round(deficit * 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return "+\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "+\(hours)h"
        } else {
            return "+\(minutes)m"
        }
    }

    var accessibilitySummary: String {
        "\(anomalyType.rawValue). Hours balance \(gapDisplayText)."
    }

    /// Small “worked / scheduled” pair for inline & stacked compositions.
    var hoursRatioSubtitle: String {
        "\(HoursFormat.format(workedHours))h / \(HoursFormat.format(scheduledHours))h"
    }
}

struct HoursBalanceCapsuleBadge: View {
    let model: HoursBalanceCapsuleModel

    var body: some View {
        Text(model.gapDisplayText)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .tracking(-0.2)
            .foregroundStyle(model.foregroundColor)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(model.chipBackground)
            .clipShape(Capsule())
    }
}

// MARK: - 1) Classic — label + horizontal track (current product pattern)

private struct ClassicScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var fillRatio: Double {
        guard scheduledHours > 0 else { return 0 }
        return workedHours / scheduledHours
    }

    private var maxRatio: Double {
        fillRatio > 1.0 ? min(fillRatio, 1.5) : 1.0
    }

    private var hoursLabel: String {
        if workedHours == 0 { return "0h / \(HoursFormat.format(scheduledHours))h" }
        return "\(HoursFormat.format(workedHours))h / \(HoursFormat.format(scheduledHours))h"
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(hoursLabel)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.07)
                .fixedSize()

            GeometryReader { geo in
                let trackWidth = geo.size.width
                let scheduledWidth = trackWidth / maxRatio
                let filledWidth = trackWidth * min(fillRatio, maxRatio) / maxRatio

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(AppColors.informativeBackground)
                        .frame(width: scheduledWidth, height: 4)

                    if filledWidth > 0 {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.informativeDefault)
                            .frame(width: min(filledWidth, scheduledWidth), height: 4)
                    }

                    if fillRatio > 1.0 {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.warningText)
                            .frame(width: filledWidth - scheduledWidth, height: 4)
                            .offset(x: scheduledWidth)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 4)
        }
    }
}

// MARK: - 2) Dual — separate “Scheduled” / “Worked” rows with stacked micro-bars

private struct DualScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    /// Worked segment length vs scheduled (cap bar at scheduled length).
    private var workedFractionOfScheduled: Double {
        guard scheduledHours > 0 else { return 0 }
        return min(workedHours / scheduledHours, 1.0)
    }

    private var accent: Color { anomalyType.textColor }

    private var workedHoursLabel: String {
        let base = "\(HoursFormat.format(workedHours))h"
        guard scheduledHours > 0, workedHours > scheduledHours + 0.05 else { return base }
        return "\(base) (+\(HoursFormat.format(workedHours - scheduledHours))h)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            dualMetricRow(
                title: "Scheduled",
                trailing: "\(HoursFormat.format(scheduledHours))h",
                fillFraction: 1.0,
                fill: AppColors.separator.opacity(0.85)
            )
            dualMetricRow(
                title: "Worked",
                trailing: workedHoursLabel,
                fillFraction: workedFractionOfScheduled,
                fill: accent.opacity(0.92)
            )
        }
    }

    private func dualMetricRow(title: String, trailing: String, fillFraction: Double, fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.fontSecondary)
                Spacer(minLength: 8)
                Text(trailing)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.06)
                    .multilineTextAlignment(.trailing)
            }
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.lightBackground)
                        .overlay(Capsule().stroke(AppColors.separator.opacity(0.55), lineWidth: 0.5))
                        .frame(height: 6)

                    Capsule()
                        .fill(fill)
                        .frame(width: max(4, w * CGFloat(fillFraction)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - 3) Shift band — thick capsule reads as “shift window”; overtime extends past

private struct ShiftBandScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var fillRatio: Double {
        guard scheduledHours > 0 else { return 0 }
        return workedHours / scheduledHours
    }

    private var caption: String {
        if workedHours == 0 { return "Worked 0h · scheduled \(HoursFormat.format(scheduledHours))h" }
        let delta = workedHours - scheduledHours
        let base = "\(HoursFormat.format(workedHours))h worked · \(HoursFormat.format(scheduledHours))h scheduled"
        if delta > 0.05 {
            return base + " · +\(HoursFormat.format(delta))h"
        }
        return base
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let ratio = fillRatio
                let workedSegment = min(ratio, 1.0) * w
                let overtimeSegment = ratio > 1 ? min((ratio - 1.0) * w, max(0, w - workedSegment)) : 0.0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.informativeBackground)
                        .frame(height: 12)

                    HStack(spacing: 0) {
                        Capsule()
                            .fill(AppColors.informativeDefault.opacity(0.92))
                            .frame(width: max(6, workedSegment), height: 12)
                        if overtimeSegment > 1 {
                            Capsule()
                                .fill(AppColors.warningText)
                                .frame(width: overtimeSegment, height: 12)
                        }
                    }
                }
                .frame(width: w, height: 12, alignment: .leading)
                .clipped()
            }
            .frame(height: 12)

            Text(caption)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.06)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 4a) Difference chip — trailing capsule (baseline capsule layout)

private struct DifferenceChipScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var model: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
    }

    var body: some View {
        Group {
            if model.showsCapsule {
                HStack {
                    Spacer(minLength: 0)
                    HoursBalanceCapsuleBadge(model: model)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(model.accessibilitySummary)
            }
        }
    }
}

// MARK: - 4b) Capsule · leading

private struct CapsuleLeadingScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var model: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
    }

    var body: some View {
        Group {
            if model.showsCapsule {
                HStack {
                    HoursBalanceCapsuleBadge(model: model)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(model.accessibilitySummary)
            }
        }
    }
}

// MARK: - 4c) Capsule · inline (hours ratio + Δ on one line)

private struct CapsuleInlineScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var model: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
    }

    var body: some View {
        Group {
            if model.showsCapsule {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(model.hoursRatioSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.06)
                    Spacer(minLength: 8)
                    HoursBalanceCapsuleBadge(model: model)
                }
                .padding(.top, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(model.hoursRatioSubtitle). \(model.accessibilitySummary)")
            }
        }
    }
}

// MARK: - 4d) Capsule · stacked (ratio above, Δ capsule below — right aligned)

private struct CapsuleStackedScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var model: HoursBalanceCapsuleModel {
        HoursBalanceCapsuleModel(scheduledHours: scheduledHours, workedHours: workedHours, anomalyType: anomalyType)
    }

    var body: some View {
        Group {
            if model.showsCapsule {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(model.hoursRatioSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.06)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    HoursBalanceCapsuleBadge(model: model)
                }
                .padding(.top, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(model.hoursRatioSubtitle). \(model.accessibilitySummary)")
            }
        }
    }
}

// MARK: - 5) Compact line — numbers only, tinted by anomaly

private struct CompactLineScheduleHoursBar: View {
    let scheduledHours: Double
    let workedHours: Double
    let anomalyType: AnomalyType

    private var delta: Double {
        workedHours - scheduledHours
    }

    private var line: String {
        let s = HoursFormat.format(scheduledHours)
        let w = HoursFormat.format(workedHours)
        if anomalyType == .scheduleNotStarted {
            return "Scheduled \(s)h · shift not started"
        }
        if workedHours <= 0.001 && scheduledHours > 0 {
            return "Scheduled \(s)h · no time logged"
        }
        if abs(delta) < 0.05 {
            return "\(w)h worked · \(s)h scheduled · on schedule"
        }
        let sign = delta > 0 ? "+" : "−"
        let mag = HoursFormat.format(abs(delta))
        return "\(w)h worked · \(s)h scheduled · \(sign)\(mag)h"
    }

    var body: some View {
        Text(line)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(anomalyType.textColor)
            .tracking(-0.08)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("\(anomalyType.rawValue). \(line)")
    }
}

#if DEBUG
#Preview("Schedule hours — all styles") {
    let emp = TimeAttendanceMockData.employees.first(where: { $0.anomalyType == .exceededWorkSchedule }) ?? TimeAttendanceMockData.employees[0]
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(ScheduleHoursBarStyle.allCases) { style in
                VStack(alignment: .leading, spacing: 8) {
                    Text(style.pickerTitle)
                        .font(AppFonts.headline())
                    ScheduleHoursBar(
                        scheduledHours: emp.scheduledHours,
                        workedHours: emp.workedHours,
                        anomalyType: emp.anomalyType,
                        forcedStyle: style
                    )
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    .background(AppColors.background)
}
#endif
