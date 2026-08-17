import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

/// Lock Screen / Notification Center Live Activity for an active clock-in session.
struct ClockInLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockInActivityAttributes.self) { context in
            ClockInLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.isOnBreak ? "On break" : "Working")
                    } icon: {
                        Image(systemName: context.state.isOnBreak ? "play.fill" : "pause.fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.fontDefault)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveActivitySystemTimer(
                        start: Self.activeTimerStart(for: context.state),
                        fontSize: 20
                    )
                    .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        if context.state.breaksEnabled {
                            Button(intent: ToggleBreakLiveActivityIntent()) {
                                liveActivityActionLabel(
                                    title: context.state.isOnBreak ? "End break" : "Take a break",
                                    systemImage: context.state.isOnBreak ? "play.fill" : "pause.fill"
                                )
                            }
                            .buttonStyle(.plain)
                            .tint(AppColors.fontDefault)
                        }

                        // Match the home card: no clock-out while on break.
                        if !context.state.isOnBreak {
                            Button(intent: ClockOutLiveActivityIntent()) {
                                liveActivityActionLabel(
                                    title: "Clock out…",
                                    systemImage: "stop.fill"
                                )
                            }
                            .buttonStyle(.plain)
                            .tint(AppColors.fontDefault)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                }
            } compactLeading: {
                Image(systemName: context.state.isOnBreak ? "pause.fill" : "play.fill")
                    .foregroundStyle(AppColors.fontDefault)
            } compactTrailing: {
                liveActivitySystemTimer(
                    start: Self.activeTimerStart(for: context.state),
                    fontSize: 13
                )
                .frame(width: 64, alignment: .trailing)
                .multilineTextAlignment(.trailing)
            } minimal: {
                Image(systemName: context.state.isOnBreak ? "pause.fill" : "play.fill")
                    .foregroundStyle(AppColors.fontDefault)
            }
        }
    }

    /// Session elapsed while working; break elapsed while paused.
    private static func activeTimerStart(for state: ClockInActivityAttributes.ContentState) -> Date {
        if state.isOnBreak, let breakStart = state.breakStartDate {
            return breakStart
        }
        return state.clockInDate
    }
}

private struct ClockInLockScreenView: View {
    let context: ActivityViewContext<ClockInActivityAttributes>

    private var timerStart: Date {
        if context.state.isOnBreak, let breakStart = context.state.breakStartDate {
            return breakStart
        }
        return context.state.clockInDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.isOnBreak ? "On break" : "Time tracking")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.fontSecondary)

                    // System-driven timer — TimelineView / manual ticks don't update in Live Activities.
                    liveActivitySystemTimer(start: timerStart, fontSize: 28)
                }

                Spacer(minLength: 8)

                Image("logo-workable")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(light: "00756A", dark: "FFFFFF"))
                    .frame(width: 36, height: 25)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 10) {
                if context.state.breaksEnabled {
                    Button(intent: ToggleBreakLiveActivityIntent()) {
                        liveActivityChip(
                            title: context.state.isOnBreak ? "End break" : "Take a break",
                            systemImage: context.state.isOnBreak ? "play.fill" : "pause.fill",
                            fill: AppColors.background,
                            ink: AppColors.fontDefault
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Match the home card: no clock-out while on break.
                if !context.state.isOnBreak {
                    Button(intent: ClockOutLiveActivityIntent()) {
                        liveActivityChip(
                            title: "Clock out…",
                            systemImage: "stop.fill",
                            fill: AppColors.fontDefault,
                            ink: AppColors.surface
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(AppColors.surface.opacity(0.96))
    }
}

/// Live-updating stopwatch. Must use `Text(timerInterval:)` — Live Activities won't tick custom TimelineViews.
private func liveActivitySystemTimer(start: Date, fontSize: CGFloat) -> some View {
    Text(timerInterval: start...Date.distantFuture, countsDown: false)
        .font(.system(size: fontSize, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(AppColors.fontDefault)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
}

/// Soft filled chip — pause/resume use neutral fill; clock-out stays dark.
private func liveActivityChip(
    title: String,
    systemImage: String,
    fill: Color,
    ink: Color
) -> some View {
    Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(fill, in: Capsule())
}

private func liveActivityActionLabel(title: String, systemImage: String) -> some View {
    Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
}
