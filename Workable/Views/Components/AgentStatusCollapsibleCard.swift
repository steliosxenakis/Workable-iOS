import SwiftUI

/// Chrome variants for **Agent status** collapse → expand (`AgentStatusTimelineView` when expanded).
enum AgentStatusCardStyle: String, CaseIterable {
    /// Figma `27655:127393` — split header on `background`, body on `surfaceDarker`, **Show timeline** link.
    case stackedShowTimeline = "Figma · stacked + link"
    case insetSummary = "Inset · summary"
    case borderedEmphasis = "Border · emphasis"
    case elevatedBadge = "Raised · badge"
}

struct AgentStatusCollapsibleCard: View {
    let style: AgentStatusCardStyle
    let fixedChronoCurrent: Int
    let presentation: AgentStatusTimelinePresentation

    @State private var isExpanded = false

    var body: some View {
        Group {
            if style == .stackedShowTimeline {
                stackedFigmaCard
            } else {
                standardChromeCard
            }
        }
    }

    // MARK: - Figma `27655:127393`

    private var stackedFigmaCard: some View {
        VStack(spacing: 0) {
            Text("Agent status")
                .font(AppFonts.subheadline())
                .tracking(-0.24)
                .foregroundColor(AppColors.fontSecondary)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(AppColors.background)

            VStack(spacing: 16) {
                Group {
                    if isExpanded {
                        AgentStatusTimelineView(
                            fixedChronoCurrent: fixedChronoCurrent,
                            presentation: presentation
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        figmaCollapsedCurrentRow
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.spring(response: 0.34, dampingFraction: 0.88), value: isExpanded)

                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Hide timeline" : "Show timeline")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontSecondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(isExpanded ? "Collapses to summary" : "Shows full agent timeline")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surfaceDarker)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var figmaCollapsedCurrentRow: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .strokeBorder(AppColors.aiDefault, lineWidth: 1.2)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(AppColors.aiDefault)
                        .frame(width: 4, height: 4)
                }
                .frame(height: 18)

                Capsule()
                    .fill(AppColors.aiDefault)
                    .frame(width: 2, height: 40)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.collapsedTitle(chrono: fixedChronoCurrent, presentation: presentation))
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                    .fixedSize(horizontal: false, vertical: true)

                if let sub = Self.collapsedSubtitle(chrono: fixedChronoCurrent, presentation: presentation) {
                    Text(sub)
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let date = Self.collapsedDate(chrono: fixedChronoCurrent, presentation: presentation) {
                Text(date)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontDefault)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Legacy chevron styles

    private var standardChromeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
                .padding(.top, style == .elevatedBadge ? 10 : 0)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(style == .elevatedBadge ? AppColors.lightBackground : Color.clear)

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)

            Group {
                if isExpanded {
                    AgentStatusTimelineView(
                        fixedChronoCurrent: fixedChronoCurrent,
                        presentation: presentation
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    collapsedBody
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.88), value: isExpanded)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(cardBackground)
        .overlay(cardOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: style == .elevatedBadge ? Color.black.opacity(0.07) : .clear, radius: 14, x: 0, y: 4)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Agent status")
                .font(AppFonts.subheadStrong())
                .foregroundColor(AppColors.fontDefault)

            Spacer(minLength: 8)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.iconDefault)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse agent status" : "Expand agent status")
        }
    }

    @ViewBuilder
    private var collapsedBody: some View {
        switch style {
        case .stackedShowTimeline:
            EmptyView()

        case .insetSummary:
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.collapsedTitle(chrono: fixedChronoCurrent, presentation: presentation))
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontDefault)
                if let sub = Self.collapsedSubtitle(chrono: fixedChronoCurrent, presentation: presentation) {
                    Text(sub)
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

        case .borderedEmphasis:
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(AppColors.aiDefault, lineWidth: 1.2)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(AppColors.aiDefault)
                        .frame(width: 4, height: 4)
                }
                Text(Self.collapsedTitle(chrono: fixedChronoCurrent, presentation: presentation))
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }

        case .elevatedBadge:
            VStack(alignment: .leading, spacing: 8) {
                Text("In progress")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.aiFitPillText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.aiFitPillFill)
                    .clipShape(Capsule())

                Text(Self.collapsedTitle(chrono: fixedChronoCurrent, presentation: presentation))
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var cardBackground: Color {
        switch style {
        case .stackedShowTimeline:
            return AppColors.surface
        case .insetSummary:
            return AppColors.surfaceDarker
        case .borderedEmphasis, .elevatedBadge:
            return AppColors.surface
        }
    }

    @ViewBuilder
    private var cardOverlay: some View {
        if style == .borderedEmphasis {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 1)
        } else {
            EmptyView()
        }
    }

    private static func collapsedTitle(chrono: Int, presentation: AgentStatusTimelinePresentation) -> String {
        guard chrono == 1 else { return "Agent activity" }
        switch presentation {
        case .moveToJobConfirmation:
            return "Follow-up email sent"
        case .interactive:
            return "Interest email sent"
        }
    }

    private static func collapsedSubtitle(chrono: Int, presentation: AgentStatusTimelinePresentation) -> String? {
        guard chrono == 1 else { return nil }
        switch presentation {
        case .moveToJobConfirmation:
            return "Expires in 4 days, 2 days until follow up"
        case .interactive:
            return "Expires in 6 days, 2 days until follow up"
        }
    }

    private static func collapsedDate(chrono: Int, presentation: AgentStatusTimelinePresentation) -> String? {
        guard chrono == 1 else { return nil }
        switch presentation {
        case .moveToJobConfirmation:
            return "19 May"
        case .interactive:
            return "17 May 2025"
        }
    }
}

#Preview("Agent status — styles") {
    ScrollView {
        VStack(alignment: .leading, spacing: 28) {
            Text("Agent status — UI variants")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(AgentStatusCardStyle.allCases), id: \.self) { style in
                VStack(alignment: .leading, spacing: 8) {
                    Text(style.rawValue)
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.fontSecondary)
                    AgentStatusCollapsibleCard(
                        style: style,
                        fixedChronoCurrent: 1,
                        presentation: .interactive
                    )
                }
            }
        }
        .padding(20)
    }
    .background(AppColors.background)
}
