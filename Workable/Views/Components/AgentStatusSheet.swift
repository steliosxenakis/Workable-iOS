import SwiftUI

/// Bottom sheet: agent outreach timeline (Figma — `Agent status`, spine `27574:189348`).
struct AgentStatusSheet: View {
    let candidate: Candidate
    var onViewMore: () -> Void

    /// Display order: top → bottom = future → past. Chrono index: `3 - displayIndex` (0 = sourced … 3 = review).
    /// `1` = email current (default). `0`…`4` = sourced current … all completed. Arrow right advances time, left goes back.
    @State private var chronoCurrent: Int = 1
    @FocusState private var keyboardFocused: Bool

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
    private func textTriple(for def: (id: String, title: String, subtitle: String?, date: String?), kind: TimelineStep.Kind) -> (title: String, subtitle: String?, date: String?) {
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
        VStack(spacing: 0) {
            Text("Agent status")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
                .padding(.top, 8)
                .padding(.bottom, 12)

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        timelineRow(step: step, index: index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 0)
            }
            .fixedSize(horizontal: false, vertical: true)

            Button {
                onViewMore()
            } label: {
                Text("View more")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.primaryDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .padding(.top, 36)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: AgentStatusSheetContentHeightKey.self, value: proxy.size.height)
            }
        )
        .focusable()
        .focused($keyboardFocused)
        .onAppear { keyboardFocused = true }
        .onKeyPress(.leftArrow) {
            stepChronoBackward()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            stepChronoForward()
            return .handled
        }
    }

    private func stepChronoForward() {
        chronoCurrent = min(4, chronoCurrent + 1)
    }

    private func stepChronoBackward() {
        chronoCurrent = max(0, chronoCurrent - 1)
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

    /// Figma `27574:189348` / `189361` (passed = material.check) / `189360` (solid `ai-default` rod, rounded).
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

    /// Figma `27574:189361` — 16×16 wrapper, purple check.
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

    /// Figma: 12×12 ring, 1.2pt `ai-default`, inner 4pt fill.
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

    /// Matches active “Interest email sent” row: `body` title, `subheadline` subtitle & date.
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

// MARK: - Sheet sizing (content height → `presentationDetents`)

enum AgentStatusSheetContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    Text("Sheet")
        .sheet(isPresented: .constant(true)) {
            AgentStatusSheet(candidate: Candidate(
                name: "Adeline Lawrence",
                role: "Software Engineer",
                source: "Workable Agent",
                matchScore: 50,
                stageInfo: "Sourced stage",
                avatarName: nil
            ), onViewMore: {})
            .presentationDetents([.height(520), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
            .presentationBackground(AppColors.surface)
        }
}
