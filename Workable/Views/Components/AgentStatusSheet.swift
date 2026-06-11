import SwiftUI

/// Bottom sheet: agent outreach timeline (Figma — `Agent status`, spine `27574:189348`).
struct AgentStatusSheet: View {
    let candidate: Candidate
    var onViewMore: () -> Void

    /// Display order: top → bottom = future → past. Chrono index: `3 - displayIndex` (0 = sourced … 3 = review).
    /// `1` = email current (default). `0`…`4` = sourced current … all completed. Arrow right advances time, left goes back.
    @State private var chronoCurrent: Int = 1
    @FocusState private var keyboardFocused: Bool

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
                AgentStatusTimelineView(chronoCurrent: $chronoCurrent, presentation: .interactive)
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
