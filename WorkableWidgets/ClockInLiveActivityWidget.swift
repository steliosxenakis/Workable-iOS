import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

/// Lock Screen / Notification Center Live Activity for an active clock-in session.
struct ClockInLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockInActivityAttributes.self) { context in
            if context.state.isBackAtWork {
                BackAtWorkLockScreenView()
            } else {
                ClockInLockScreenView(context: context)
            }
        } dynamicIsland: { context in
            if context.state.isBackAtWork {
                return DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        Text("You’re back at work")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.fontDefault)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        liveActivityWorkableLogo(width: 29, height: 16)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        EmptyView()
                    }
                } compactLeading: {
                    Text("Work")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.fontDefault)
                } compactTrailing: {
                    liveActivityWorkableLogo(width: 22, height: 12)
                } minimal: {
                    liveActivityWorkableLogo(width: 18, height: 10)
                }
            }
            let timerTint = context.state.isBreakOverLimit
                ? AppColors.liveActivityWarning
                : AppColors.fontDefault
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        if let emoji = context.state.breakEmoji, !emoji.isEmpty {
                            Text(emoji)
                                .font(.system(size: 16))
                        } else {
                            Image(systemName: "pause.fill")
                                .font(.caption.weight(.semibold))
                        }
                        Text("On break")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(AppColors.fontDefault)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveActivitySplitTimer(
                        start: context.state.activeTimerStart,
                        tint: timerTint,
                        style: .island
                    )
                    .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: ToggleBreakLiveActivityIntent()) {
                        liveActivityActionLabel(
                            title: "End break",
                            systemImage: "play.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .tint(AppColors.fontDefault)
                    .font(.subheadline.weight(.semibold))
                }
            } compactLeading: {
                if let emoji = context.state.breakEmoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 14))
                } else {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(AppColors.fontDefault)
                }
            } compactTrailing: {
                liveActivitySplitTimer(
                    start: context.state.activeTimerStart,
                    tint: timerTint,
                    style: .compact
                )
            } minimal: {
                if let emoji = context.state.breakEmoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 12))
                } else {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(AppColors.fontDefault)
                }
            }
        }
    }
}

private struct ClockInLockScreenView: View {
    let context: ActivityViewContext<ClockInActivityAttributes>

    private var timerStart: Date {
        context.state.activeTimerStart
    }

    private var isBreakOverLimit: Bool {
        context.state.isBreakOverLimit
    }

    private var timerTint: Color {
        isBreakOverLimit ? AppColors.liveActivityWarning : .white
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        if let emoji = context.state.breakEmoji, !emoji.isEmpty {
                            Text(emoji)
                                .font(.system(size: 15))
                        }
                        Text("On break")
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundStyle(.white)
                    }

                    liveActivitySplitTimer(
                        start: timerStart,
                        tint: timerTint,
                        style: .lockScreen
                    )
                }

                Spacer(minLength: 8)

                liveActivityWorkableLogo(width: 29, height: 16)
            }

            breakProgressBar

            Button(intent: ToggleBreakLiveActivityIntent()) {
                liveActivityFigmaButton(title: "End break")
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .activityBackgroundTint(AppColors.primary700)
    }

    @ViewBuilder
    private var breakProgressBar: some View {
        if isBreakOverLimit {
            Capsule()
                .fill(AppColors.liveActivityWarning)
                .frame(height: 6)
        } else if let start = context.state.breakStartDate,
                  let end = context.state.plannedBreakEndDate {
            ProgressView(timerInterval: start...end, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
                .progressViewStyle(.linear)
                .tint(AppColors.liveActivityProgressFill)
                .frame(height: 6)
                .background(AppColors.liveActivityProgressTrack, in: Capsule())
                .clipShape(Capsule())
        } else {
            Capsule()
                .fill(AppColors.liveActivityProgressTrack)
                .frame(height: 6)
        }
    }
}

/// Compact dismissal (Figma 15862:461663 / 15864:462092) — 3 seconds after End break.
private struct BackAtWorkLockScreenView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("You’re back at work")
                .font(AppFonts.title3Strong())
                .tracking(0.38)
                .foregroundStyle(.white)
            Spacer(minLength: 8)
            liveActivityWorkableLogo(width: 29, height: 16)
        }
        .padding(16)
        .activityBackgroundTint(AppColors.primary700)
    }
}

private func liveActivityWorkableLogo(width: CGFloat, height: CGFloat) -> some View {
    Image("logo-workable")
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(.white)
        .frame(width: width, height: height)
        .accessibilityHidden(true)
}

/// Live elapsed time. `Text(timerInterval:)` is the only ActivityKit-safe
/// stopwatch — custom `DiscreteFormatStyle` / `TimeDataSource` leave the
/// lock-screen activity on skeletons.
///
/// End the interval at 10 hours, not `distantFuture`. ActivityKit sizes the
/// compact island from the worst-case duration string; a far-future end
/// stretches the bar across the screen.
private func liveActivitySplitTimer(
    start: Date,
    tint: Color,
    style: LiveActivityTimerStyle
) -> some View {
    Text(
        timerInterval: start...start.addingTimeInterval(10 * 60 * 60),
        countsDown: false,
        showsHours: false
    )
        .font(style.minutesFont)
        .monospacedDigit()
        .foregroundStyle(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .multilineTextAlignment(style.textAlignment)
        .frame(width: style.fixedWidth, alignment: style.frameAlignment)
        .frame(maxWidth: style.expandsToFullWidth ? .infinity : nil, alignment: .leading)
        .accessibilityLabel("Elapsed time")
}

private enum LiveActivityTimerStyle {
    case lockScreen
    case island
    case compact

    var minutesFont: Font {
        switch self {
        case .lockScreen: return AppFonts.chunkyTitle()
        case .island: return .system(size: 20, weight: .semibold)
        case .compact: return .system(size: 13, weight: .semibold)
        }
    }

    /// Compact island sizes from this view. Keep it to `mm:ss`, not hours.
    var fixedWidth: CGFloat? {
        switch self {
        case .compact: return 42
        case .island, .lockScreen: return nil
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .lockScreen: return .leading
        case .island, .compact: return .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .lockScreen: return .leading
        case .island, .compact: return .trailing
        }
    }

    var expandsToFullWidth: Bool {
        self == .lockScreen
    }
}

/// Full-width white capsule — Figma End break (15862:458985).
private func liveActivityFigmaButton(title: String) -> some View {
    Text(title)
        .font(AppFonts.headline())
        .tracking(-0.41)
        .foregroundStyle(AppColors.liveActivityButtonInk)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white, in: Capsule())
}

private func liveActivityActionLabel(title: String, systemImage: String) -> some View {
    Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
}
