import SwiftUI

/// How agent step titles/dates are shown (e.g. move-to-job modal vs interactive status sheet).
enum AgentStatusTimelinePresentation {
    case interactive
    case moveToJobConfirmation
}

/// Shared agent outreach spine + rows (`27574:189348`). Used by `AgentStatusSheet` and move-to-job confirmation.
struct AgentStatusTimelineView: View {
    @Binding private var chronoCurrent: Int
    private let presentation: AgentStatusTimelinePresentation

    init(
        chronoCurrent: Binding<Int>,
        presentation: AgentStatusTimelinePresentation = .interactive
    ) {
        _chronoCurrent = chronoCurrent
        self.presentation = presentation
    }

    init(
        fixedChronoCurrent: Int,
        presentation: AgentStatusTimelinePresentation = .interactive
    ) {
        _chronoCurrent = .constant(fixedChronoCurrent)
        self.presentation = presentation
    }

    private struct TimelineStep: Identifiable {
        enum Kind {
            case completed
            case current
            case upcoming
        }

        let id: String
        let kind: Kind
        let title: String
        let subtitle: String?
        let date: String?
    }

    private static let agentStepDefs: [(id: String, title: String, subtitle: String?, date: String?)] = [
        ("review", "Complete review", nil, nil),
        ("chat", "Chat with candidate", nil, nil),
        ("email", "Interest email sent", "Expires in 6 days, 2 days until follow up", "17 May 2025"),
        ("sourced", "Sourced via Search with AI", nil, "17 May 2025")
    ]

    private var steps: [TimelineStep] {
        Self.agentStepDefs.enumerated().map { displayIndex, def in
            let kind = kindForRow(displayIndex: displayIndex)
            let triple = textTriple(for: def, kind: kind)
            return TimelineStep(
                id: def.id,
                kind: kind,
                title: triple.title,
                subtitle: triple.subtitle,
                date: triple.date
            )
        }
    }

    /// Figma `52646:83312` (chat active), `52646:83362` (review active).
    private func textTriple(
        for def: (id: String, title: String, subtitle: String?, date: String?),
        kind: TimelineStep.Kind
    ) -> (title: String, subtitle: String?, date: String?) {
        switch def.id {
        case "review":
            switch kind {
            case .current:
                return ("Review completed", "Candidate not qualified to move", "23 May 2025")
            case .completed:
                return ("Complete review", nil, nil)
            case .upcoming:
                return ("Complete review", nil, nil)
            }
        case "chat":
            switch kind {
            case .current:
                return ("Chat in progress", "Expires in 6 days", "23 May 2025")
            case .completed:
                return ("Chat with candidate", nil, "23 May 2025")
            case .upcoming:
                return ("Chat with candidate", nil, nil)
            }
        case "email":
            if presentation == .moveToJobConfirmation, kind == .current {
                return ("Follow-up email sent", "Expires in 4 days, 2 days until follow up", "19 May")
            }
            let subtitle = kind == .current ? def.subtitle : nil
            let date: String? = {
                guard let d = def.date, kind != .upcoming else { return nil }
                return d
            }()
            return (def.title, subtitle, date)
        default:
            let date: String? = {
                guard let d = def.date, kind != .upcoming else { return nil }
                return d
            }()
            return (def.title, nil, date)
        }
    }

    private func kindForRow(displayIndex: Int) -> TimelineStep.Kind {
        let rowChrono = 3 - displayIndex
        let k = chronoCurrent
        if k >= 4 { return .completed }
        if rowChrono < k { return .completed }
        if rowChrono == k { return .current }
        return .upcoming
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                timelineRow(step: step, index: index)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 0)
    }

    private func timelineRow(step: TimelineStep, index: Int) -> some View {
        let hasConnectorBelow = index < steps.count - 1
        let nextKind = hasConnectorBelow ? steps[index + 1].kind : nil

        return HStack(alignment: .top, spacing: 12) {
            spineLeading(
                kind: step.kind,
                connectorBelow: connectorStyle(current: step.kind, next: nextKind),
                hasConnectorBelow: hasConnectorBelow
            )
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(agentTimelineTitleFont)
                    .foregroundColor(titleColor(for: step.kind))
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = step.subtitle {
                    Text(subtitle)
                        .font(agentTimelineSubtitleFont)
                        .foregroundColor(AppColors.fontSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let date = step.date {
                Text(date)
                    .font(agentTimelineDateFont)
                    .foregroundColor(dateColor(for: step.kind))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.bottom, index == steps.count - 1 ? 0 : 10)
    }

    private func connectorStyle(current: TimelineStep.Kind, next: TimelineStep.Kind?) -> ConnectorKind {
        guard let next else { return .none }
        if current == .current, next == .completed { return .solidAI }
        if current == .completed, next == .completed { return .solidAI }
        if current == .completed, next == .current { return .solidAI }
        return .dashedNeutral
    }

    private enum ConnectorKind {
        case none
        case dashedNeutral
        case solidAI
    }

    @ViewBuilder
    private func spineLeading(
        kind: TimelineStep.Kind,
        connectorBelow: ConnectorKind,
        hasConnectorBelow: Bool
    ) -> some View {
        switch kind {
        case .upcoming:
            VStack(spacing: 4) {
                upcomingDot
                if hasConnectorBelow {
                    connectorLine(kind: connectorBelow, height: 27)
                }
            }
            .frame(maxWidth: .infinity)

        case .current:
            VStack(spacing: 4) {
                currentStepIndicator
                if hasConnectorBelow {
                    connectorLine(kind: connectorBelow, height: 27)
                }
            }
            .frame(maxWidth: .infinity)

        case .completed:
            VStack(spacing: 4) {
                completedStepMark
                if hasConnectorBelow {
                    connectorLine(kind: connectorBelow, height: 27)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var completedStepMark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(AppColors.aiDefault)
            .frame(width: 16, height: 16)
    }

    private var upcomingDot: some View {
        Circle()
            .fill(AppColors.surface)
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .stroke(AppColors.iconDefault, lineWidth: 1)
            )
    }

    private var currentStepIndicator: some View {
        ZStack {
            Circle()
                .strokeBorder(AppColors.aiDefault, lineWidth: 1.2)
                .frame(width: 12, height: 12)
            Circle()
                .fill(AppColors.aiDefault)
                .frame(width: 4, height: 4)
        }
        .padding(.top, 2)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func connectorLine(kind: ConnectorKind, height: CGFloat) -> some View {
        switch kind {
        case .none:
            EmptyView()
        case .dashedNeutral:
            Path { path in
                path.move(to: CGPoint(x: 1, y: 0))
                path.addLine(to: CGPoint(x: 1, y: height))
            }
            .stroke(
                AppColors.iconDefault.opacity(0.55),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 4])
            )
            .frame(width: 2, height: height)
        case .solidAI:
            Capsule()
                .fill(AppColors.aiDefault)
                .frame(width: 2, height: height)
        }
    }

    private var agentTimelineTitleFont: Font { AppFonts.body() }
    private var agentTimelineSubtitleFont: Font { AppFonts.subheadline() }
    private var agentTimelineDateFont: Font { AppFonts.subheadline() }

    private func titleColor(for kind: TimelineStep.Kind) -> Color {
        switch kind {
        case .completed: return AppColors.fontSecondary
        case .current: return AppColors.fontDefault
        case .upcoming: return AppColors.iconInactive
        }
    }

    private func dateColor(for kind: TimelineStep.Kind) -> Color {
        switch kind {
        case .completed: return AppColors.fontSecondary
        case .current: return AppColors.fontDefault
        case .upcoming: return AppColors.iconInactive
        }
    }
}
