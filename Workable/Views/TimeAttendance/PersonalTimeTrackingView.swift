import SwiftUI

/// Personal time-tracking drill-in (Figma nav 15616-620397).
struct PersonalTimeTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 2
    @State private var selectedSubTab = 0
    @State private var showsAddTimeEntrySheet = false

    private var personName: String {
        TimeAttendanceMockData.loggedInUser.name
    }

    var body: some View {
        VStack(spacing: 0) {
            TimeTrackingDrillInHeader(
                title: personName,
                tabs: ["Information", "Time off", "Time tracking"],
                selectedTab: $selectedTab,
                onBack: { dismiss() }
            ) {
                if selectedTab == 2 {
                    timeTrackingAddEntryButton { showsAddTimeEntrySheet = true }
                } else {
                    Color.clear
                        .frame(width: GlassSymbolButton.size, height: GlassSymbolButton.size)
                }
            }

            Group {
                switch selectedTab {
                case 0: TimeTrackingDrillInPlaceholder(title: "Information")
                case 1: TimeTrackingDrillInPlaceholder(title: "Time off")
                case 2:
                    TimeTrackingWeekCalendarContent(
                        selectedSubTab: $selectedSubTab,
                        showsAddTimeEntrySheet: $showsAddTimeEntrySheet
                    )
                default: Spacer()
                }
            }
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

/// Figma nav “Add entry” — surface capsule matching glass back button height.
func timeTrackingAddEntryButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text("Add entry")
            .font(AppFonts.subheadStrong())
            .foregroundColor(AppColors.fontDefault)
            .padding(.horizontal, 12)
            .frame(height: GlassSymbolButton.size)
            .background(AppColors.surface)
            .clipShape(Capsule(style: .continuous))
            .shadow(color: Color(hex: "333E49").opacity(0.1), radius: 2.5, x: 0, y: 2)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Add entry")
}

// MARK: - Shared drill-in chrome (matches Attendance V6 nav actions)

/// Same glass back / side framing as `TimeAttendanceAnomaliesListView.v6NavBar`.
struct TimeTrackingDrillInHeader<Trailing: View>: View {
    let title: String
    var tabs: [String]
    var selectedTab: Binding<Int>?
    let onBack: () -> Void
    let trailing: Trailing

    init(
        title: String,
        tabs: [String] = [],
        selectedTab: Binding<Int>? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.tabs = tabs
        self.selectedTab = selectedTab
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                GlassSymbolButton(
                    systemName: "chevron.left",
                    fontWeight: .semibold,
                    accessibilityLabel: "Back",
                    action: onBack
                )
                .frame(width: 96, alignment: .leading)

                Spacer(minLength: 0)

                trailing
                    .frame(minWidth: 96, alignment: .trailing)
            }
            .overlay {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            if !tabs.isEmpty, let selectedTab {
                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tabTitle in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab.wrappedValue = index }
                        } label: {
                            VStack(spacing: 8) {
                                Text(tabTitle)
                                    .font(AppFonts.subheadStrong())
                                    .foregroundColor(
                                        selectedTab.wrappedValue == index
                                            ? AppColors.primaryDark
                                            : AppColors.fontSecondary
                                    )
                                    .padding(.horizontal, 16)
                                Rectangle()
                                    .fill(
                                        selectedTab.wrappedValue == index
                                            ? AppColors.primaryDark
                                            : Color.clear
                                    )
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 26)
                .padding(.top, 8)
            }
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }
}

struct TimeTrackingDrillInPlaceholder: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Home clock-in widget (Figma 15616-620621 / 15616-169041 / 15616-169020)
// Break support models (PROD-82468):
// V1 serial · V2 parallel · V3 status · V4 bounded break

/// Idle play → clocked in (+ optional pause/resume) → stop → clocked out.
struct TimeTrackingHomeCard: View {
    private enum HoldAction {
        case clockIn, clockOut
    }

    private static let idleButtonSize: CGFloat = 56
    private static let holdingButtonSize: CGFloat = 90
    private static let holdDuration: TimeInterval = 1.0
    private static let ringLineWidth: CGFloat = 3.5
    /// Working ↔ break layout (timer shift, On break pill) — linear, no spring bounce.
    private static let breakTransition = Animation.linear(duration: 0.28)

    @Environment(\.breakSupportEnabled) private var breakSupportEnabled
    @Environment(\.breakSupportUIVersion) private var breakSupportUIVersion
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var session = ClockInSessionStore.shared
    @ObservedObject private var todayEntries = TodayTimeEntriesStore.shared

    @Namespace private var sessionTitleNamespace
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdGeneration = 0
    @State private var holdCompleted = false
    @State private var activeHoldAction: HoldAction = .clockIn
    @State private var showsBoundedBreakPicker = false
    @State private var showsCustomBreakSheet = false
    @State private var customBreakMinutes = 45
    @State private var v5SelectedEmoji = "☕"
    @State private var v5SelectedMinutes = 10
    /// Opens the system emoji keyboard via a hidden text field (no picker sheet).
    @State private var isEmojiKeyboardFocused = false
    /// V7 — type picker (duration reused from `v5SelectedMinutes`).
    @State private var v7SelectedTypeId = BreakTypeOption.all[0].id
    /// V8 — selected quick-preset card.
    @State private var v8SelectedPresetId = StatusBreakPreset.quickPresets[0].id
    /// V9/V10 — duration chip selection; `nil` hides the Start break CTA (Figma idle).
    @State private var v9SelectedMinutes: Int? = nil

    private var isClockedIn: Bool { session.isClockedIn }
    private var isOnBreak: Bool { session.isOnBreak }
    private var clockInDate: Date? { session.clockInDate }

    /// Today entries strip — shown whenever a completed entry exists, in any clock state.
    /// Figma 2816:264084 (one) / 2816:264111 (multiple).
    private var showsTodaySummaryFooter: Bool {
        todayEntries.hasEntries
    }

    /// Bottom corner radius for break composers — 0 when the entries footer sits below.
    private var breakComposerBottomRadius: CGFloat {
        showsTodaySummaryFooter ? 0 : 16
    }

    /// V5: Slack-style emoji + duration presets sit under the timer while working.
    private var showsV5BreakComposer: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v5 && isClockedIn && !isOnBreak
    }

    /// V6: compact “Take a [emoji] break for [5m] Pause” sentence under the timer.
    private var showsV6BreakSentence: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v6 && isClockedIn && !isOnBreak
    }

    /// V7: type + duration pickers, then confirm Start.
    private var showsV7BreakComposer: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v7 && isClockedIn && !isOnBreak
    }

    /// V8: quick preset cards, then confirm Start.
    private var showsV8BreakComposer: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v8 && isClockedIn && !isOnBreak
    }

    /// V9: “Break for” + duration chips, then Start break (Figma 15675-33015).
    private var showsV9BreakComposer: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v9 && isClockedIn && !isOnBreak
    }

    /// V10: “Take a [emoji] for” + duration chips, then Start break (Figma 15683-14659).
    private var showsV10BreakComposer: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v10 && isClockedIn && !isOnBreak
    }

    /// V11: V10-style emoji + duration chips; Start always available (no chip → counts up).
    private var showsV11BreakComposer: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v11 && isClockedIn && !isOnBreak
    }

    /// V11: while on break, session clock stays up top; break timer lives in the strip below.
    private var showsV11ActiveBreakStrip: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v11 && isClockedIn && isOnBreak
    }

    /// Versions that keep the main session timer unchanged and track break time under the card.
    private var tracksBreakInBottomSection: Bool {
        breakSupportUIVersion == .v11
    }

    private var cardHasBottomExtension: Bool {
        showsTodaySummaryFooter
            || showsV5BreakComposer
            || showsV6BreakSentence
            || showsV7BreakComposer
            || showsV8BreakComposer
            || showsV9BreakComposer
            || showsV10BreakComposer
            || showsV11BreakComposer
            || showsV11ActiveBreakStrip
    }

    private var v7SelectedType: BreakTypeOption {
        BreakTypeOption.all.first(where: { $0.id == v7SelectedTypeId }) ?? BreakTypeOption.all[0]
    }

    private var v8SelectedPreset: StatusBreakPreset {
        StatusBreakPreset.quickPresets.first(where: { $0.id == v8SelectedPresetId })
            ?? StatusBreakPreset.quickPresets[0]
    }

    private var buttonSize: CGFloat {
        isHolding ? Self.holdingButtonSize : Self.idleButtonSize
    }

    private var playIconSize: CGFloat {
        isHolding ? 26 : 17
    }

    private var stopIconSize: CGFloat {
        isHolding ? 22 : 15
    }

    /// V3 needs a stacked layout so the Working/Break control stays horizontal and readable.
    private var usesV3StatusLayout: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v3 && isClockedIn
    }

    /// V12.1: pause/resume on the left of the timer; hold-stop stays on the right while working.
    private var usesV12_1Layout: Bool {
        breakSupportEnabled && breakSupportUIVersion == .v12_1 && isClockedIn
    }

    /// V12 / V12.1 / V14 / V15 share the “On break” pill + open-ended break timer styling.
    private var usesV12BreakTitleStyle: Bool {
        switch breakSupportUIVersion {
        case .v12, .v12_1, .v14, .v15: return true
        default: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if usesV3StatusLayout {
                    v3CardContent
                } else if usesV12_1Layout {
                    v12_1CardContent
                } else {
                    defaultCardContent
                }
            }
            .frame(maxWidth: .infinity, minHeight: Self.idleButtonSize, alignment: .center)
            // Cap single-row cards so working ↔ break doesn’t resize (V3 stacks below).
            .frame(maxHeight: usesV3StatusLayout ? nil : Self.idleButtonSize)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: cardHasBottomExtension ? 0 : 16,
                    bottomTrailingRadius: cardHasBottomExtension ? 0 : 16,
                    topTrailingRadius: 16,
                    style: .continuous
                )
                .fill(AppColors.surface)
            }
            // Hold halo must paint above the Today footer (VStack draws later
            // siblings on top by default, which was clipping the 90pt button).
            .zIndex(1)

            if showsV5BreakComposer {
                v5BreakComposer
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsV6BreakSentence {
                v6BreakSentence
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsV7BreakComposer {
                v7BreakComposer
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsV8BreakComposer {
                v8BreakComposer
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsV9BreakComposer {
                v9BreakComposer
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsV10BreakComposer {
                v10BreakComposer
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsV11BreakComposer {
                v11BreakComposer
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsV11ActiveBreakStrip {
                v11ActiveBreakStrip
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: breakComposerBottomRadius,
                            bottomTrailingRadius: breakComposerBottomRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.surface)
                    }
                    .zIndex(0)
            }

            if showsTodaySummaryFooter {
                todaySummaryFooter
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 16,
                            bottomTrailingRadius: 16,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .fill(AppColors.lightBackground)
                    }
                    .zIndex(0)
                    .allowsHitTesting(!isHolding)
            }
        }
        // Opaque fill so the Figma card shadow actually paints (clear fills don't cast).
        // Never clipShape the card, or the hold-to-confirm halo (56→90) gets cut.
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(showsTodaySummaryFooter ? AppColors.lightBackground : AppColors.surface)
                .appTimeTrackingCardShadow()
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: isClockedIn)
        .animation(Self.breakTransition, value: isOnBreak)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: breakSupportUIVersion)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: todayEntries.hasEntries)
        .onChange(of: breakSupportUIVersion) { _, _ in
            v9SelectedMinutes = nil
        }
        .onAppear {
            session.syncFromExternalSources(breaksEnabled: breakSupportEnabled)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                session.syncFromExternalSources(breaksEnabled: breakSupportEnabled)
            }
        }
        .onChange(of: breakSupportEnabled) { _, enabled in
            // Keep an already-running Live Activity's action set in sync with Settings.
            guard isClockedIn, let clockInDate else { return }
            ClockInLiveActivityManager.shared.update(
                clockInDate: clockInDate,
                isOnBreak: isOnBreak,
                breakStartDate: session.breakStartDate,
                breaksEnabled: enabled
            )
        }
        .sheet(isPresented: $showsCustomBreakSheet) {
            customBreakSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .background {
            // Hidden field — tapping emoji controls only brings up the system keyboard.
            EmojiKeyboardField(
                emoji: $v5SelectedEmoji,
                isFocused: $isEmojiKeyboardFocused,
                onEmojiPicked: { picked in
                    // Dashboard / home card — keep session emoji in sync while on break.
                    if isOnBreak, breakSupportUIVersion.showsBreakEmoji {
                        session.updateBreakEmoji(picked, breaksEnabled: breakSupportEnabled)
                    }
                }
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
        }
    }

    /// Bottom strip: `Today · 8h in total` + first entry range (+N when multiple).
    private var todaySummaryFooter: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(todayEntries.summaryLeadingText)
                .font(.system(size: 15))
                .tracking(-0.24)
                .foregroundColor(AppColors.fontDefault)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Text(todayEntries.firstEntryRangeText)
                    .font(.system(size: 15))
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(1)

                if todayEntries.entries.count > 1 {
                    Text("+\(todayEntries.entries.count - 1)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.primaryDark)
                        .frame(width: 25, height: 25)
                        .background(AppColors.separator)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private var customBreakSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("How long is your break?")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Duration", selection: $customBreakMinutes) {
                    ForEach(Self.customBreakMinuteOptions, id: \.self) { minutes in
                        Text(minutes >= 60 ? "\(minutes / 60)h\(minutes % 60 == 0 ? "" : " \(minutes % 60)m")" : "\(minutes)m")
                            .tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 160)

                Button {
                    startCustomBoundedBreak(
                        minutes: customBreakMinutes,
                        label: {
                            switch breakSupportUIVersion {
                            case .v7: return v7SelectedType.title
                            case .v8: return v8SelectedPreset.title
                            default: return "Break"
                            }
                        }(),
                        emoji: {
                            switch breakSupportUIVersion {
                            case .v5, .v6, .v10, .v11: return v5SelectedEmoji
                            case .v7: return v7SelectedType.emoji
                            case .v8: return v8SelectedPreset.emoji
                            default: return nil
                            }
                        }()
                    )
                    showsCustomBreakSheet = false
                } label: {
                    Text("Start break")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.surface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(AppColors.surface)
            .navigationTitle("Custom time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showsCustomBreakSheet = false }
                }
            }
        }
    }

    /// Editable On-break emoji must sit outside `NavigationLink` or taps drill in instead.
    private var showsDashboardEditableBreakEmoji: Bool {
        isClockedIn && isOnBreak && (
            breakSupportUIVersion.usesEditableBreakEmojiLabel
                || breakSupportUIVersion == .v13
        )
    }

    private var defaultCardContent: some View {
        HStack(alignment: .center, spacing: 24) {
            dashboardTitleColumn

            Spacer(minLength: 0)

            controls
                .zIndex(10)

            drillInChevron
        }
    }

    /// Title + editable break emoji outside `NavigationLink` so taps don’t drill in.
    @ViewBuilder
    private var dashboardTitleColumn: some View {
        if isOnBreak, breakSupportUIVersion == .v13 {
            HStack(alignment: .bottom, spacing: 8) {
                editableBreakEmojiButton(size: 24)
                NavigationLink {
                    PersonalTimeTrackingView()
                } label: {
                    titleContent
                }
                .buttonStyle(.plain)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                if showsDashboardEditableBreakEmoji, breakSupportUIVersion.usesEditableBreakEmojiLabel {
                    onBreakTitlePill
                        .zIndex(2)
                        .transition(.opacity)
                }

                NavigationLink {
                    PersonalTimeTrackingView()
                } label: {
                    titleContent
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Figma 15754:231376 — `[pause|resume] · timer · [hold stop?] · chevron`.
    private var v12_1CardContent: some View {
        HStack(alignment: .center, spacing: 16) {
            outlinedCircleControl(
                systemName: isOnBreak ? "play.fill" : "pause.fill",
                iconSize: isOnBreak ? 17 : 15,
                accessibilityLabel: isOnBreak ? "Resume" : "Pause"
            ) {
                if isOnBreak {
                    endBreak()
                } else {
                    startBreak()
                }
            }
            .zIndex(10)

            dashboardTitleColumn
                .frame(maxWidth: .infinity, alignment: .leading)

            if !isOnBreak {
                holdOverflowSlot {
                    stopControl(holdAction: .clockOut)
                }
                .zIndex(10)
            }

            drillInChevron
        }
    }

    /// Timer + Done on the top row; full-width Working | Break status control underneath.
    private var v3CardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                NavigationLink {
                    PersonalTimeTrackingView()
                } label: {
                    titleContent
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                holdOverflowSlot {
                    stopControl(holdAction: .clockOut)
                }
                .zIndex(10)

                drillInChevron
            }

            statusModePicker
        }
    }

    /// Layout stays 56×56 so the white card height never grows; the magnified
    /// hold control (→90) draws outside the surface (Figma hold state).
    private func holdOverflowSlot<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.clear
                .frame(width: Self.idleButtonSize, height: Self.idleButtonSize)
            content()
        }
        .frame(width: Self.idleButtonSize, height: Self.idleButtonSize)
    }

    private var drillInChevron: some View {
        NavigationLink {
            PersonalTimeTrackingView()
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.iconDefault)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var controls: some View {
        if !isClockedIn {
            holdOverflowSlot { playControl }
        } else if !breakSupportEnabled {
            holdOverflowSlot { stopControl(holdAction: .clockOut) }
        } else {
            switch breakSupportUIVersion {
            case .v1: breakControlsV1Serial
            case .v2: breakControlsV2
            case .v3: breakControlsV3Status
            case .v4: breakControlsV4Bounded
            case .v5, .v6, .v7, .v8, .v9, .v10, .v11:
                // Top row: stop (+ emoji resume on break). Composers sit under the card.
                breakControlsV5Status
            case .v12: breakControlsV12
            case .v12_1:
                // Clocked-in UI is `v12_1CardContent`; idle still uses playControl above.
                EmptyView()
            case .v13: breakControlsV13
            case .v14, .v15: breakControlsV14
            }
        }
    }

    // MARK: - Title

    @ViewBuilder
    private var titleContent: some View {
        if isClockedIn, let clockInDate {
            // V4–V10 planned break: countdown replaces the session timer in the title.
            // V11 keeps the session clock and tracks break time in the strip below.
            let showsBoundedBreakCountdown =
                isOnBreak
                && !tracksBreakInBottomSection
                && breakSupportUIVersion.usesBoundedBreakCountdown
                && session.plannedBreakMinutes != nil
                && session.breakStartDate != nil
            // Other versions: on break, the main timer counts break elapsed.
            let timerAnchor =
                (!tracksBreakInBottomSection && !showsBoundedBreakCountdown && isOnBreak
                    ? session.breakStartDate : nil)
                ?? clockInDate

            if showsBoundedBreakCountdown,
               let planned = session.plannedBreakMinutes,
               let breakStart = session.breakStartDate {
                TimelineView(.periodic(from: breakStart, by: 1)) { context in
                    let elapsed = max(0, Int(context.date.timeIntervalSince(breakStart)))
                    let remaining = max(0, planned * 60 - elapsed)
                    let label = session.breakLabel ?? "Break"
                    let suffix = remaining > 0
                        ? "\(label) · \(Self.formatClock(remaining)) left"
                        : "\(label) · overtime"
                    HStack(spacing: 6) {
                        if let emoji = session.breakEmoji, !emoji.isEmpty {
                            EmojiText(emoji: emoji, size: 22)
                        }
                        Text(suffix)
                            .font(.system(size: 22, weight: .semibold))
                            .tracking(0.35)
                            .foregroundColor(AppColors.warningText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            } else if isOnBreak, breakSupportUIVersion == .v13 {
                // Emoji is rendered beside this column outside NavigationLink on the dashboard.
                TimelineView(.periodic(from: timerAnchor, by: 1)) { context in
                    let elapsed = max(0, Int(context.date.timeIntervalSince(timerAnchor)))
                    timerLabels(elapsed: elapsed, omitHoursWhenZero: true)
                        .matchedGeometryEffect(id: "homeSessionTimer", in: sessionTitleNamespace)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    // Editable emoji pill is rendered outside NavigationLink (dashboard tap target).
                    if isOnBreak, usesV12BreakTitleStyle, !breakSupportUIVersion.usesEditableBreakEmojiLabel {
                        onBreakTitlePill
                            .transition(.opacity)
                    } else if isOnBreak, breakSupportUIVersion != .v3, !tracksBreakInBottomSection,
                              !breakSupportUIVersion.usesEditableBreakEmojiLabel {
                        HStack(spacing: 6) {
                            if let emoji = session.breakEmoji, !emoji.isEmpty {
                                EmojiText(emoji: emoji, size: 14)
                            }
                            Text("On break")
                                .font(AppFonts.caption1Strong())
                                .foregroundColor(AppColors.warningText)
                        }
                        .transition(.opacity)
                    }

                    TimelineView(.periodic(from: timerAnchor, by: 1)) { context in
                        let elapsed = max(0, Int(context.date.timeIntervalSince(timerAnchor)))
                        timerLabels(
                            elapsed: elapsed,
                            omitHoursWhenZero: usesV12BreakTitleStyle && isOnBreak
                        )
                        .matchedGeometryEffect(id: "homeSessionTimer", in: sessionTitleNamespace)
                        .contentTransition(.numericText())
                    }
                }
            }
        } else {
            Text("Time tracking")
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
                .foregroundColor(AppColors.fontDefault)
        }
    }

    private func timerLabels(elapsed: Int, omitHoursWhenZero: Bool = false) -> some View {
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        let primaryText = omitHoursWhenZero && hours == 0
            ? String(format: "%02dm", minutes)
            : "\(hours)h \(String(format: "%02d", minutes))m"
        return HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(primaryText)
                .font(.system(size: 22, weight: .semibold))
                .tracking(0.35)
                .foregroundColor(AppColors.fontDefault)
            Text(String(format: "%02ds", seconds))
                .font(.system(size: 16, weight: .regular))
                .tracking(-0.32)
                .foregroundColor(AppColors.fontSecondary)
                .frame(height: 20, alignment: .bottom)
        }
    }

    @ViewBuilder
    private var onBreakTitlePill: some View {
        if breakSupportUIVersion.usesEditableBreakEmojiLabel {
            HStack(spacing: 4) {
                EmojiText(emoji: session.breakEmoji ?? v5SelectedEmoji, size: 14)
                Text("On break")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture { beginEditingBreakEmoji() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("On break, edit emoji")
        } else {
            Text("On break")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.fontDefault)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func editableBreakEmojiButton(size: CGFloat) -> some View {
        EmojiText(emoji: session.breakEmoji ?? v5SelectedEmoji, size: size)
            .contentShape(Rectangle())
            .onTapGesture { beginEditingBreakEmoji() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Edit break emoji")
    }

    private func beginEditingBreakEmoji() {
        if let emoji = session.breakEmoji, !emoji.isEmpty {
            v5SelectedEmoji = emoji
        } else if v5SelectedEmoji.isEmpty {
            v5SelectedEmoji = "☕"
        }
        isEmojiKeyboardFocused = true
    }

    // MARK: - Break UI V1 — serial (hold clock in → pause → tap clock out)

    @ViewBuilder
    private var breakControlsV1Serial: some View {
        if isOnBreak {
            HStack(spacing: 10) {
                serialActionButton(
                    systemName: "play.fill",
                    fill: AppColors.activeBackground,
                    ink: AppColors.primaryDark,
                    accessibilityLabel: "Resume"
                ) {
                    endBreak()
                }
                tapStopControl(showsShadow: true)
            }
        } else {
            serialActionButton(
                systemName: "pause.fill",
                fill: AppColors.warningBackground,
                ink: AppColors.warningText,
                accessibilityLabel: "Pause"
            ) {
                startBreak()
            }
        }
    }

    /// Single-tap clock-out (no hold halo). Optional shadow for V1; V4 stays flat.
    private func tapStopControl(showsShadow: Bool) -> some View {
        Button {
            completeClockOut()
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.fontDefault)
                Image(systemName: "stop.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.surface)
            }
            .frame(width: Self.idleButtonSize, height: Self.idleButtonSize)
            .shadow(
                color: showsShadow ? Color(hex: "333E49").opacity(0.48) : .clear,
                radius: showsShadow ? 8.5 : 0
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clock out")
        .accessibilityHint("Tap to clock out")
    }

    private func serialActionButton(
        systemName: String,
        fill: Color,
        ink: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fill)
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(ink)
                    .offset(x: systemName == "play.fill" ? 1.5 : 0)
            }
            .frame(width: Self.idleButtonSize, height: Self.idleButtonSize)
            .shadow(color: ink.opacity(0.35), radius: 8.5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Break UI V2 — parallel icon pause/resume + hold stop

    private var breakControlsV2: some View {
        HStack(spacing: 10) {
            serialActionButton(
                systemName: isOnBreak ? "play.fill" : "pause.fill",
                fill: isOnBreak ? AppColors.activeBackground : AppColors.warningBackground,
                ink: isOnBreak ? AppColors.primaryDark : AppColors.warningText,
                accessibilityLabel: isOnBreak ? "Resume" : "Pause"
            ) {
                toggleBreak()
            }

            holdOverflowSlot {
                stopControl(holdAction: .clockOut)
            }
        }
    }

    // MARK: - Break UI V12 — tap pause/resume + hold-to-stop (Figma 15751:224241 / 224329)

    @ViewBuilder
    private var breakControlsV12: some View {
        if isOnBreak {
            outlinedCircleControl(
                systemName: "play.fill",
                iconSize: 17,
                accessibilityLabel: "Resume"
            ) {
                endBreak()
            }
        } else {
            HStack(spacing: 8) {
                outlinedCircleControl(
                    systemName: "pause.fill",
                    iconSize: 15,
                    accessibilityLabel: "Pause"
                ) {
                    startBreak()
                }

                holdOverflowSlot {
                    stopControl(holdAction: .clockOut)
                }
            }
        }
    }

    // MARK: - Break UI V14 — V12 working; On break tonal “Back to work” (Figma 15761:244828)

    /// Instant swap (no animation) — timer/title still animate via `breakTransition`.
    @ViewBuilder
    private var breakControlsV14: some View {
        if isOnBreak {
            // Figma 15761:244828 — tonal Normal: 48pt tall, 16×8 padding, 14 semibold.
            ZStack {
                Button {
                    endBreak()
                } label: {
                    Text("End break")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primaryDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(height: 48)
                        .background(AppColors.activeBackground)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("End break")
            }
            .frame(height: Self.idleButtonSize)
            .transaction { $0.animation = nil }
        } else {
            HStack(spacing: 8) {
                outlinedCircleControl(
                    systemName: "pause.fill",
                    iconSize: 15,
                    accessibilityLabel: "Pause"
                ) {
                    startBreak()
                }

                holdOverflowSlot {
                    stopControl(holdAction: .clockOut)
                }
            }
            .transaction { $0.animation = nil }
        }
    }

    // MARK: - Break UI V13 — V12 gestures + emoji title; resume only while on break

    @ViewBuilder
    private var breakControlsV13: some View {
        if isOnBreak {
            outlinedCircleControl(
                systemName: "play.fill",
                iconSize: 17,
                accessibilityLabel: "Resume"
            ) {
                endBreak()
            }
        } else {
            HStack(spacing: 8) {
                outlinedCircleControl(
                    systemName: "pause.fill",
                    iconSize: 15,
                    accessibilityLabel: "Pause"
                ) {
                    startOpenEndedBreak(label: "Break", emoji: "☕")
                }

                holdOverflowSlot {
                    stopControl(holdAction: .clockOut)
                }
            }
        }
    }

    private func outlinedCircleControl(
        systemName: String,
        iconSize: CGFloat,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(AppColors.fontDefault, lineWidth: 1)
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(AppColors.fontDefault)
                    .offset(x: systemName == "play.fill" ? 1.5 : 0)
            }
            .frame(width: Self.idleButtonSize, height: Self.idleButtonSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Break UI V3 — status / presence (Working · On break · Done)

    /// Kept for the controls switch; V3 clocked-in UI uses `v3CardContent` instead.
    private var breakControlsV3Status: some View {
        statusModePicker
    }

    private var statusModePicker: some View {
        HStack(spacing: 4) {
            statusSegment(
                title: "Working",
                selected: !isOnBreak,
                selectedFill: AppColors.activeBackground,
                selectedInk: AppColors.primaryDark
            ) {
                if isOnBreak { endBreak() }
            }

            statusSegment(
                title: "On break",
                selected: isOnBreak,
                selectedFill: AppColors.warningBackground,
                selectedInk: AppColors.warningText
            ) {
                if !isOnBreak { startBreak() }
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        .clipShape(Capsule())
    }

    private func statusSegment(
        title: String,
        selected: Bool,
        selectedFill: Color,
        selectedInk: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadStrong())
                .foregroundColor(selected ? selectedInk : AppColors.fontSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? selectedFill : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Break UI V4 — bounded break (type + duration + countdown)

    private var breakControlsV4Bounded: some View {
        HStack(spacing: 10) {
            if isOnBreak {
                // On break: dark orange fill + light icon (inverse of idle cream + amber).
                Button {
                    endBreak()
                } label: {
                    symbolBreakButton(
                        systemName: BoundedBreakPreset.systemImage(forLabel: session.breakLabel),
                        fill: AppColors.warningDefault,
                        ink: AppColors.warningBackground
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Resume")
            } else {
                Button {
                    showsBoundedBreakPicker = true
                } label: {
                    symbolBreakButton(
                        systemName: "cup.and.saucer.fill",
                        fill: AppColors.warningBackground,
                        ink: AppColors.warningText
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start a break")
                .sheet(isPresented: $showsBoundedBreakPicker) {
                    boundedBreakPickerSheet
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }

            // Single-tap clock out — no hold halo / shadow (unlike clock-in).
            tapStopControl(showsShadow: false)
        }
    }

    // MARK: - Break UI V7 — two pickers (type + duration) → Start

    private var v7BreakComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Take a break")
                .font(AppFonts.caption1Strong())
                .foregroundColor(AppColors.fontSecondary)

            HStack(spacing: 10) {
                Menu {
                    ForEach(BreakTypeOption.all) { option in
                        Button {
                            v7SelectedTypeId = option.id
                        } label: {
                            Text(option.menuTitle)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        EmojiText(emoji: v7SelectedType.emoji, size: 20)
                        Text(v7SelectedType.title)
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(AppColors.fontDefault)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Menu {
                    ForEach(StatusBreakPreset.durationOptions, id: \.self) { minutes in
                        Button("\(minutes)m") { v5SelectedMinutes = minutes }
                    }
                    Divider()
                    Button("Custom…") {
                        customBreakMinutes = max(v5SelectedMinutes, 5)
                        showsCustomBreakSheet = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("\(v5SelectedMinutes)m")
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(AppColors.fontDefault)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            Button {
                startCustomBoundedBreak(
                    minutes: v5SelectedMinutes,
                    label: v7SelectedType.title,
                    emoji: v7SelectedType.emoji
                )
            } label: {
                HStack(spacing: 8) {
                    EmojiText(emoji: v7SelectedType.emoji, size: 18)
                    Text("Start \(v5SelectedMinutes)m \(v7SelectedType.title.lowercased()) break")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.surface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.fontDefault)
                .clipShape(Capsule())
            }
            .buttonStyle(UntintedPlainButtonStyle())
            .accessibilityLabel("Start break")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    // MARK: - Break UI V8 — quick presets → Start

    private var v8BreakComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick breaks")
                .font(AppFonts.caption1Strong())
                .foregroundColor(AppColors.fontSecondary)

            HStack(spacing: 8) {
                ForEach(StatusBreakPreset.quickPresets) { preset in
                    let selected = preset.id == v8SelectedPresetId
                    Button {
                        v8SelectedPresetId = preset.id
                    } label: {
                        VStack(spacing: 6) {
                            EmojiText(emoji: preset.emoji, size: 22)
                            Text(preset.title)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(AppColors.fontDefault)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(preset.durationLabel)
                                .font(AppFonts.caption1())
                                .foregroundColor(AppColors.fontSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 6)
                        .background(selected ? AppColors.activeBackground : AppColors.background)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    selected ? AppColors.primaryDark : Color.clear,
                                    lineWidth: 1.5
                                )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(UntintedPlainButtonStyle())
                    .accessibilityLabel("\(preset.title), \(preset.durationLabel)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }

            Button {
                let preset = v8SelectedPreset
                startCustomBoundedBreak(
                    minutes: preset.minutes,
                    label: preset.title,
                    emoji: preset.emoji
                )
            } label: {
                HStack(spacing: 8) {
                    EmojiText(emoji: v8SelectedPreset.emoji, size: 18)
                    Text("Start \(v8SelectedPreset.title.lowercased()) break")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.surface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.fontDefault)
                .clipShape(Capsule())
            }
            .buttonStyle(UntintedPlainButtonStyle())
            .accessibilityLabel("Start break")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    // MARK: - Break UI V9 — “Break for” + duration chips → Start break (Figma 15675-33015)

    private var v9BreakComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                v9DurationRow(compact: false)
                ScrollView(.horizontal, showsIndicators: false) {
                    v9DurationRow(compact: true)
                }
            }

            if let minutes = v9SelectedMinutes {
                Button {
                    startCustomBoundedBreak(minutes: minutes, label: "Break")
                    v9SelectedMinutes = nil
                } label: {
                    Text("Start break")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.surface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryDark)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start break")
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: v9SelectedMinutes)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private func v9DurationRow(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            Text("Break for")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .fixedSize()

            ForEach(StatusBreakPreset.v9DurationOptions, id: \.self) { minutes in
                figDurationChip(
                    title: "\(minutes)m",
                    selected: v9SelectedMinutes == minutes
                ) {
                    toggleV9Duration(minutes)
                }
            }

            figCustomDurationMenu(presetOptions: StatusBreakPreset.v9DurationOptions)
        }
    }

    // MARK: - Break UI V10 — “Take a [emoji] for” + chips → Start break (Figma 15683-14659)

    private var v10BreakComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                v10DurationRow(compact: false)
                ScrollView(.horizontal, showsIndicators: false) {
                    v10DurationRow(compact: true)
                }
            }

            if let minutes = v9SelectedMinutes {
                Button {
                    startCustomBoundedBreak(
                        minutes: minutes,
                        label: "Break",
                        emoji: v5SelectedEmoji
                    )
                    v9SelectedMinutes = nil
                } label: {
                    Text("Start break")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.surface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryDark)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start break")
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: v9SelectedMinutes)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private func v10DurationRow(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            Text("Take a")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .fixedSize()

            EmojiText(emoji: v5SelectedEmoji, size: compact ? 18 : 20)
                .frame(width: compact ? 32 : 36, height: compact ? 32 : 36)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onTapGesture { isEmojiKeyboardFocused = true }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Choose emoji")

            Text("for")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .fixedSize()

            ForEach(StatusBreakPreset.v10DurationOptions, id: \.self) { minutes in
                figDurationChip(
                    title: "\(minutes)m",
                    selected: v9SelectedMinutes == minutes
                ) {
                    toggleV9Duration(minutes)
                }
            }

            figCustomDurationMenu(presetOptions: StatusBreakPreset.v10DurationOptions)
        }
    }

    // MARK: - Break UI V11 — V10 chips + optional duration (nil → open-ended count-up)

    private var v11BreakComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                v10DurationRow(compact: false)
                ScrollView(.horizontal, showsIndicators: false) {
                    v10DurationRow(compact: true)
                }
            }

            Button {
                if let minutes = v9SelectedMinutes {
                    startCustomBoundedBreak(
                        minutes: minutes,
                        label: "Break",
                        emoji: v5SelectedEmoji
                    )
                    v9SelectedMinutes = nil
                } else {
                    startOpenEndedBreak(label: "Break", emoji: v5SelectedEmoji)
                }
            } label: {
                Text("Start break")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.surface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.primaryDark)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start break")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: v9SelectedMinutes)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    /// Active break strip under the card — session clock stays in the title above.
    private var v11ActiveBreakStrip: some View {
        HStack(spacing: 12) {
            if let emoji = session.breakEmoji, !emoji.isEmpty {
                EmojiText(emoji: emoji, size: 22)
                    .frame(width: 40, height: 40)
                    .background(AppColors.warningBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.breakLabel ?? "On break")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.warningText)

                if let breakStart = session.breakStartDate {
                    TimelineView(.periodic(from: breakStart, by: 1)) { context in
                        let elapsed = max(0, Int(context.date.timeIntervalSince(breakStart)))
                        if let planned = session.plannedBreakMinutes {
                            let remaining = max(0, planned * 60 - elapsed)
                            Text(remaining > 0
                                 ? "\(Self.formatClock(remaining)) left"
                                 : "Overtime · \(Self.formatClock(elapsed))")
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(AppColors.fontDefault)
                                .monospacedDigit()
                        } else {
                            Text(Self.formatClock(elapsed))
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(AppColors.fontDefault)
                                .monospacedDigit()
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            Button {
                endBreak()
            } label: {
                Text("End break")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.activeBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("End break")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private func toggleV9Duration(_ minutes: Int) {
        if v9SelectedMinutes == minutes {
            v9SelectedMinutes = nil
        } else {
            v9SelectedMinutes = minutes
        }
    }

    /// `+` opens a contextual minute menu (selects duration; does not start the break).
    private func figCustomDurationMenu(presetOptions: [Int]) -> some View {
        let customSelected = v9SelectedMinutes.map { !presetOptions.contains($0) } ?? false
        let title: String = {
            if customSelected, let minutes = v9SelectedMinutes {
                return Self.formatBreakMinutesLabel(minutes)
            }
            return "+"
        }()

        return Menu {
            ForEach(Self.customBreakMinuteOptions, id: \.self) { minutes in
                Button {
                    // Tapping the already-selected custom value deselects.
                    if v9SelectedMinutes == minutes {
                        v9SelectedMinutes = nil
                    } else {
                        v9SelectedMinutes = minutes
                    }
                } label: {
                    if v9SelectedMinutes == minutes {
                        Label(Self.formatBreakMinutesLabel(minutes), systemImage: "checkmark")
                    } else {
                        Text(Self.formatBreakMinutesLabel(minutes))
                    }
                }
            }
        } label: {
            Text(title)
                .font(AppFonts.subheadStrong())
                .foregroundColor(customSelected ? AppColors.primaryDark : AppColors.fontDefault)
                .frame(minWidth: 36)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(customSelected ? AppColors.activeBackground : AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .accessibilityLabel("Custom duration")
        .accessibilityAddTraits(customSelected ? .isSelected : [])
    }

    private static func formatBreakMinutesLabel(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }

    /// Figma duration chip — rounded rect (not capsule), mint when selected.
    private func figDurationChip(
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadStrong())
                .foregroundColor(selected ? AppColors.primaryDark : AppColors.fontDefault)
                .frame(minWidth: 36)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(selected ? AppColors.activeBackground : AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Break UI V6 — sentence: Take a [emoji] break for [5m] [Pause]

    private var v6BreakSentence: some View {
        ViewThatFits(in: .horizontal) {
            v6BreakSentenceRow(compact: false)
            v6BreakSentenceRow(compact: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private func v6BreakSentenceRow(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            Text("Take a")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .fixedSize()

            HStack(spacing: 4) {
                EmojiText(emoji: v5SelectedEmoji, size: compact ? 18 : 20)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.fontSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppColors.background)
            .clipShape(Capsule())
            .contentShape(Capsule())
            .onTapGesture { isEmojiKeyboardFocused = true }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Choose emoji")

            Text("break for")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .fixedSize()
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Menu {
                ForEach(StatusBreakPreset.durationOptions, id: \.self) { minutes in
                    Button("\(minutes)m") { v5SelectedMinutes = minutes }
                }
                Divider()
                Button("Custom…") {
                    customBreakMinutes = max(v5SelectedMinutes, 5)
                    showsCustomBreakSheet = true
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(v5SelectedMinutes)m")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.fontDefault)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.fontSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppColors.background)
                .clipShape(Capsule())
            }

            Spacer(minLength: 4)

            Button {
                startCustomBoundedBreak(
                    minutes: v5SelectedMinutes,
                    label: "Break",
                    emoji: v5SelectedEmoji
                )
            } label: {
                HStack(spacing: 6) {
                    Text("Pause")
                        .font(AppFonts.subheadStrong())
                    Image(systemName: "pause.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(AppColors.primaryDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.activeBackground)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start break")
        }
    }

    // MARK: - Break UI V5 — Slack-style emoji + duration under the card

    /// Top-row controls: resume (emoji) while on break; otherwise only clock out
    /// (presets live in `v5BreakComposer` / `v6BreakSentence` under the timer).
    /// V11 resumes from the break strip below so the top row stays clock-out only.
    private var breakControlsV5Status: some View {
        HStack(spacing: 10) {
            if isOnBreak, !tracksBreakInBottomSection {
                Button {
                    endBreak()
                } label: {
                    emojiBreakButton(
                        emoji: session.breakEmoji ?? "☕",
                        fill: AppColors.warningDefault
                    )
                }
                .buttonStyle(UntintedPlainButtonStyle())
                .accessibilityLabel("Resume")
            }

            tapStopControl(showsShadow: false)
        }
    }

    /// Inline composer under the time-tracking row (clocked in, not on break).
    private var v5BreakComposer: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Emoji + duration chips (Slack “status” + “Clear after…” vibe).
            HStack(spacing: 12) {
                EmojiText(emoji: v5SelectedEmoji, size: 28)
                    .frame(width: 44, height: 44)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onTapGesture { isEmojiKeyboardFocused = true }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Choose emoji")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Break for…")
                        .font(AppFonts.caption1Strong())
                        .foregroundColor(AppColors.fontSecondary)

                    HStack(spacing: 6) {
                        ForEach(StatusBreakPreset.durationOptions, id: \.self) { minutes in
                            v5DurationChip(
                                title: "\(minutes)m",
                                selected: v5SelectedMinutes == minutes
                            ) {
                                v5SelectedMinutes = minutes
                            }
                        }
                        v5DurationChip(title: "Custom", selected: false) {
                            customBreakMinutes = max(v5SelectedMinutes, 5)
                            showsCustomBreakSheet = true
                        }
                    }
                }
            }

            Button {
                startCustomBoundedBreak(
                    minutes: v5SelectedMinutes,
                    label: "Break",
                    emoji: v5SelectedEmoji
                )
            } label: {
                Text("Start break")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.surface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.warningDefault)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("Suggestions")
                .font(AppFonts.caption1Strong())
                .foregroundColor(AppColors.fontSecondary)
                .padding(.top, 2)

            VStack(spacing: 0) {
                ForEach(StatusBreakPreset.suggestions) { preset in
                    Button {
                        v5SelectedEmoji = preset.emoji
                        v5SelectedMinutes = preset.minutes
                        startCustomBoundedBreak(
                            minutes: preset.minutes,
                            label: preset.title,
                            emoji: preset.emoji
                        )
                    } label: {
                        HStack(spacing: 12) {
                            EmojiText(emoji: preset.emoji, size: 22)
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                    .font(AppFonts.subheadStrong())
                                    .foregroundColor(AppColors.fontDefault)
                                Text(preset.durationLabel)
                                    .font(AppFonts.caption1())
                                    .foregroundColor(AppColors.fontSecondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.iconInactive)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(UntintedPlainButtonStyle())

                    if preset.id != StatusBreakPreset.suggestions.last?.id {
                        Divider()
                            .background(AppColors.separator)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 14)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private func v5DurationChip(
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.caption1Strong())
                .foregroundColor(selected ? AppColors.primaryDark : AppColors.fontSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? AppColors.activeBackground : AppColors.background)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func emojiBreakButton(emoji: String, fill: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
            // Untinted text so Apple Color Emoji renders (no tofu).
            EmojiText(emoji: emoji, size: 24)
        }
        .frame(width: Self.idleButtonSize, height: Self.idleButtonSize)
    }

    private var boundedBreakPickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a break type and length. We’ll show a countdown while you’re away.")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)

                VStack(spacing: 8) {
                    ForEach(BoundedBreakPreset.allCases) { preset in
                        Button {
                            startBoundedBreak(preset)
                            showsBoundedBreakPicker = false
                        } label: {
                            boundedBreakOptionRow(
                                systemName: preset.systemImage,
                                title: preset.menuTitle
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showsBoundedBreakPicker = false
                        showsCustomBreakSheet = true
                    } label: {
                        boundedBreakOptionRow(systemName: "timer", title: "Custom time…")
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(AppColors.surface)
            .navigationTitle("Start a break")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showsBoundedBreakPicker = false }
                }
            }
        }
    }

    private func boundedBreakOptionRow(systemName: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primaryDark)
                .frame(width: 28, height: 28)
            Text(title)
                .font(AppFonts.subheadStrong())
                .foregroundColor(AppColors.primaryDark)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.background)
        .clipShape(Capsule())
    }

    /// V4 pause / resume — single tap, no glow shadow (clock-in keeps hold halo + shadow).
    private func symbolBreakButton(systemName: String, fill: Color, ink: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ink)
        }
        .frame(width: Self.idleButtonSize, height: Self.idleButtonSize)
    }

    private static let customBreakMinuteOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]

    private func startBoundedBreak(_ preset: BoundedBreakPreset) {
        startCustomBoundedBreak(minutes: preset.minutes, label: preset.rawValue)
    }

    private func startCustomBoundedBreak(
        minutes: Int,
        label: String = "Break",
        emoji: String? = nil
    ) {
        withAnimation(Self.breakTransition) {
            isHolding = false
            holdProgress = 0
            session.startBreak(
                breaksEnabled: breakSupportEnabled,
                label: label,
                plannedMinutes: minutes,
                emoji: emoji
            )
        }
    }

    /// Open-ended break — no planned duration; timer counts elapsed time up.
    private func startOpenEndedBreak(label: String = "Break", emoji: String? = nil) {
        withAnimation(Self.breakTransition) {
            isHolding = false
            holdProgress = 0
            session.startBreak(
                breaksEnabled: breakSupportEnabled,
                label: label,
                plannedMinutes: nil,
                emoji: emoji
            )
        }
    }

    private static func formatClock(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Play / Stop

    private var playControl: some View {
        ZStack {
            Circle()
                .stroke(AppColors.activeBackground.opacity(0.55), lineWidth: Self.ringLineWidth)
                .frame(width: buttonSize, height: buttonSize)
                .opacity((isHolding || holdProgress > 0) && activeHoldAction == .clockIn ? 1 : 0)

            Circle()
                .trim(from: 0, to: activeHoldAction == .clockIn ? holdProgress : 0)
                .stroke(
                    AppColors.primaryDark,
                    style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round)
                )
                .frame(width: buttonSize, height: buttonSize)
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(AppColors.activeBackground)
                .frame(
                    width: buttonSize - (isHolding && activeHoldAction == .clockIn ? 7 : 0),
                    height: buttonSize - (isHolding && activeHoldAction == .clockIn ? 7 : 0)
                )

            Image(systemName: "play.fill")
                .font(.system(size: playIconSize, weight: .medium))
                .foregroundColor(AppColors.primaryDark)
                .offset(x: playIconSize * 0.08)
        }
        .frame(width: buttonSize, height: buttonSize)
        .shadow(
            color: AppColors.primary.opacity(0.5),
            radius: isHolding && activeHoldAction == .clockIn ? 13.7 : 8.5,
            x: 0,
            y: 0
        )
        .contentShape(Circle())
        .gesture(holdGesture(for: .clockIn))
        .accessibilityLabel("Clock in")
        .accessibilityHint("Press and hold to clock in")
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isHolding)
    }

    private func stopControl(holdAction: HoldAction) -> some View {
        let isThisHold = isHolding && activeHoldAction == holdAction
        return ZStack {
            Circle()
                .stroke(AppColors.iconInactive.opacity(0.7), lineWidth: Self.ringLineWidth)
                .frame(width: buttonSize, height: buttonSize)
                .opacity(isThisHold || holdProgress > 0 && isThisHold ? 1 : 0)

            Circle()
                .trim(from: 0, to: isThisHold ? holdProgress : 0)
                .stroke(
                    AppColors.iconDefault,
                    style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round)
                )
                .frame(width: buttonSize, height: buttonSize)
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(AppColors.fontDefault)
                .frame(
                    width: buttonSize - (isThisHold ? 7 : 0),
                    height: buttonSize - (isThisHold ? 7 : 0)
                )

            Image(systemName: "stop.fill")
                .font(.system(size: stopIconSize, weight: .medium))
                .foregroundColor(AppColors.surface)
        }
        .frame(width: buttonSize, height: buttonSize)
        .shadow(
            color: Color(hex: "333E49").opacity(0.48),
            radius: isThisHold ? 13.7 : 8.5,
            x: 0,
            y: 0
        )
        .contentShape(Circle())
        .gesture(holdGesture(for: holdAction))
        .accessibilityLabel("Clock out")
        .accessibilityHint("Press and hold to clock out")
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isHolding)
    }

    // MARK: - Hold + break actions

    private func holdGesture(for action: HoldAction) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isHolding else { return }
                beginHold(action)
            }
            .onEnded { _ in
                endHold()
            }
    }

    private func beginHold(_ action: HoldAction) {
        activeHoldAction = action
        isHolding = true
        holdProgress = 0
        holdCompleted = false
        holdGeneration += 1
        let generation = holdGeneration

        withAnimation(.linear(duration: Self.holdDuration)) {
            holdProgress = 1
        }

        Task { @MainActor in
            let nanos = UInt64(Self.holdDuration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard generation == holdGeneration, isHolding, holdProgress >= 0.99 else { return }
            finishHold()
        }
    }

    private func endHold() {
        guard !holdCompleted else { return }

        holdGeneration += 1
        if holdProgress >= 0.99 {
            finishHold()
        } else {
            withAnimation(.easeOut(duration: 0.22)) {
                isHolding = false
                holdProgress = 0
            }
        }
    }

    private func finishHold() {
        guard !holdCompleted else { return }
        holdCompleted = true
        holdGeneration += 1

        switch activeHoldAction {
        case .clockIn: completeClockIn()
        case .clockOut: completeClockOut()
        }
    }

    private func toggleBreak() {
        if isOnBreak {
            endBreak()
        } else {
            startBreak()
        }
    }

    private func startBreak() {
        withAnimation(Self.breakTransition) {
            isHolding = false
            holdProgress = 0
            if breakSupportUIVersion.usesEditableBreakEmojiLabel {
                let emoji = v5SelectedEmoji.isEmpty ? "☕" : v5SelectedEmoji
                session.startBreak(breaksEnabled: breakSupportEnabled, emoji: emoji)
            } else {
                session.startBreak(breaksEnabled: breakSupportEnabled)
            }
        }
    }

    private func endBreak() {
        withAnimation(Self.breakTransition) {
            isHolding = false
            holdProgress = 0
            session.endBreak(breaksEnabled: breakSupportEnabled)
        }
    }

    private func completeClockIn() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            isHolding = false
            holdProgress = 0
            session.clockIn(breaksEnabled: breakSupportEnabled)
        }
    }

    private func completeClockOut() {
        // Auto-close an open break at clock-out (epic edge-case default).
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            isHolding = false
            holdProgress = 0
            session.clockOut()
        }
    }
}

// MARK: - Time entry detail (Figma 15640-637684)

struct TimeEntryDetailView: View {
    let entry: TimeEntryDetail

    @Environment(\.dismiss) private var dismiss
    @Environment(\.breakSupportEnabled) private var breakSupportEnabled
    @Environment(\.breakSupportUIVersion) private var breakSupportUIVersion
    @Environment(\.breaksNestedInTimeEntry) private var breaksNestedInTimeEntry
    @State private var showsEditSheet = false

    private var showBreaks: Bool {
        breakSupportEnabled && entry.hasBreaks
    }

    private var nestBreaks: Bool {
        showBreaks && breaksNestedInTimeEntry
    }

    private var showsBreakEmoji: Bool {
        breakSupportEnabled && breakSupportUIVersion.showsBreakEmoji
    }

    var body: some View {
        VStack(spacing: 0) {
            TimeTrackingDrillInHeader(title: "Time entry", onBack: { dismiss() }) {
                Button("Edit") {
                    showsEditSheet = true
                }
                .font(.system(size: 17, weight: .medium))
                .buttonStyle(.glass)
            }

            ScrollView {
                VStack(spacing: 36) {
                    VStack(alignment: .leading, spacing: 36) {
                        dateSection
                        if nestBreaks {
                            nestedPeriodSection
                        } else {
                            field(label: "Period", value: entry.periodText)
                            if showBreaks {
                                breaksSection
                            }
                        }
                        field(label: "Note", value: entry.noteText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        // Delete is prototype-only for now.
                    } label: {
                        Text("Delete entry")
                            .font(AppFonts.subheadStrong())
                            .foregroundColor(AppColors.dangerDefault)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(AppColors.surface)
        }
        .background(AppColors.surface)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $showsEditSheet) {
            EditTimeEntryView(entry: entry)
                .environment(\.breakSupportEnabled, breakSupportEnabled)
                .environment(\.breakSupportUIVersion, breakSupportUIVersion)
                .environment(\.breaksNestedInTimeEntry, breaksNestedInTimeEntry)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            field(label: "Date", value: entry.dateLabel)

            Text(entry.scheduleBannerText)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(AppColors.lightBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    /// Start → breaks → end as a timeline (+ total outside the rail).
    /// Bullets sit on Start, Breaks (title), and End — evenly spaced along the rail.
    private var nestedPeriodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                detailTimelineRow(isFirst: true, isLast: false) {
                    field(label: "Start", value: entry.start)
                        .padding(.bottom, 16)
                }

                detailTimelineRow(isFirst: false, isLast: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Breaks")
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontSecondary)

                        ForEach(Array(entry.breaks.enumerated()), id: \.element.id) { index, item in
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(index + 1)")
                                    .font(AppFonts.body())
                                    .tracking(-0.41)
                                    .foregroundColor(AppColors.fontSecondary)
                                    .frame(minWidth: 16, alignment: .leading)
                                if showsBreakEmoji, let emoji = item.emoji, !emoji.isEmpty {
                                    EmojiText(emoji: emoji, size: 18)
                                }
                                Text("\(item.start) – \(item.end) (\(item.duration))")
                                    .font(AppFonts.body())
                                    .tracking(-0.41)
                                    .foregroundColor(AppColors.fontDefault)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }

                detailTimelineRow(isFirst: false, isLast: true) {
                    field(label: "End", value: entry.end)
                }
            }

            field(label: "Total", value: nestedTotalText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// e.g. `8h` or `8h (45m break)` when breaks are present.
    private var nestedTotalText: String {
        guard showBreaks else { return entry.duration }
        return "\(entry.duration) (\(entry.breakHoursText) break)"
    }

    /// Bullet on a continuous vertical rail (spacing lives inside `content`, not between rows).
    /// Last row: line stops at the bullet center (does not run through End’s value).
    private func detailTimelineRow<Content: View>(
        isFirst: Bool,
        isLast: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .top) {
                if isLast {
                    // Top → bullet center only (bullet top inset 5 + half of 8).
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(width: 2, height: 9)
                } else {
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, isFirst ? 9 : 0)
                }

                Circle()
                    .fill(AppColors.iconInactive)
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)
            }
            .frame(width: 8, alignment: .top)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var breaksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breaks")
                .font(AppFonts.subheadline())
                .tracking(-0.24)
                .foregroundColor(AppColors.fontSecondary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.breaks.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .center, spacing: 8) {
                        Text("\(index + 1)")
                            .font(AppFonts.body())
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontSecondary)
                            .frame(minWidth: 16, alignment: .leading)
                        if showsBreakEmoji, let emoji = item.emoji, !emoji.isEmpty {
                            EmojiText(emoji: emoji, size: 18)
                        }
                        Text("\(item.start) – \(item.end) (\(item.duration))")
                            .font(AppFonts.body())
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontDefault)
                        Spacer(minLength: 0)
                    }
                }
                if entry.breaks.count > 1 {
                    Text("\(entry.breakHoursText) in total")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.subheadline())
                .tracking(-0.24)
                .foregroundColor(AppColors.fontSecondary)

            Text(value)
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Edit time entry (Figma 15640-637652 — Add entry layout, edit copy)

private struct EditableTimeEntryBreak: Identifiable {
    let id: UUID
    var start: Date
    var end: Date
    var emoji: String?

    init(id: UUID = UUID(), start: Date, end: Date, emoji: String? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.emoji = emoji
    }

    var durationMinutes: Int {
        max(0, Int(end.timeIntervalSince(start) / 60))
    }
}

/// Sheet form to add/edit a manual time entry: date, start/end, breaks, optional note, total banner, save.
struct EditTimeEntryView: View {
    enum Mode {
        case add
        case edit
    }

    let entry: TimeEntryDetail
    var mode: Mode = .edit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.breakSupportEnabled) private var breakSupportEnabled
    @Environment(\.breakSupportUIVersion) private var breakSupportUIVersion
    @Environment(\.breaksNestedInTimeEntry) private var breaksNestedInTimeEntry

    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var note: String
    @State private var breaks: [EditableTimeEntryBreak]
    @State private var emojiEditBreakId: UUID?
    @State private var isBreakEmojiKeyboardFocused = false

    private var showsBreakEmoji: Bool {
        breakSupportEnabled && breakSupportUIVersion.showsBreakEmoji
    }

    init(entry: TimeEntryDetail, mode: Mode = .edit) {
        self.entry = entry
        self.mode = mode
        let day = Self.parseDateLabel(entry.dateLabel) ?? Date()
        _selectedDate = State(initialValue: day)
        _startTime = State(initialValue: Self.time(from: entry.start, on: day))
        _endTime = State(initialValue: Self.time(from: entry.end, on: day))
        _note = State(initialValue: entry.note ?? "")
        _breaks = State(initialValue: entry.breaks.map { item in
            EditableTimeEntryBreak(
                start: Self.time(from: item.start, on: day),
                end: Self.time(from: item.end, on: day),
                emoji: item.emoji
            )
        })
    }

    /// Blank add form for today (Figma 15640-637652).
    static func addToday() -> EditTimeEntryView {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        let entry = TimeEntryDetail(
            dateLabel: formatter.string(from: today),
            scheduleRange: "09:00 - 17:00",
            start: "09:00",
            end: "17:00",
            duration: "8h"
        )
        return EditTimeEntryView(entry: entry, mode: .add)
    }

    private var navigationTitleText: String {
        mode == .add ? "Add time entry" : "Edit time entry"
    }

    private var primaryButtonTitle: String {
        mode == .add ? "Add time entry" : "Save time entry"
    }

    /// Start → end span. Breaks are included in this total (shown separately on the right).
    private var totalMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    private var breakMinutesTotal: Int {
        breaks.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalDurationText: String {
        Self.formatDuration(minutes: totalMinutes)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    dateField
                    if breakSupportEnabled && breaksNestedInTimeEntry {
                        nestedStartEndBreaksEditor
                    } else {
                        startEndFields
                        // Figma 15776:248126 base overlay + break options when support is on.
                        if breakSupportEnabled {
                            breaksEditor
                        }
                    }
                    noteField
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, isBreakEmojiKeyboardFocused ? 24 : 120)
            }

            // Don't pin totals / save over the emoji keyboard.
            if !isBreakEmojiKeyboardFocused {
                footer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(AppColors.surface)
        .animation(.easeInOut(duration: 0.2), value: isBreakEmojiKeyboardFocused)
        .background {
            if showsBreakEmoji {
                EmojiKeyboardField(
                    emoji: breakEmojiKeyboardBinding,
                    isFocused: $isBreakEmojiKeyboardFocused
                )
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
            }
        }
    }

    private var breakEmojiKeyboardBinding: Binding<String> {
        Binding(
            get: {
                guard let id = emojiEditBreakId,
                      let item = breaks.first(where: { $0.id == id }) else {
                    return "☕"
                }
                return item.emoji ?? "☕"
            },
            set: { newValue in
                guard let id = emojiEditBreakId,
                      let index = breaks.firstIndex(where: { $0.id == id }) else { return }
                breaks[index].emoji = newValue
            }
        )
    }

    private var header: some View {
        HStack {
            GlassSymbolButton(
                systemName: "xmark",
                fontWeight: .medium,
                accessibilityLabel: "Close",
                action: { dismiss() }
            )
            .frame(width: 85, alignment: .leading)

            Spacer(minLength: 0)

            // Balances the leading close control (Figma invisible Cancel).
            Text("Cancel")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.primaryDark)
                .opacity(0)
                .frame(width: 85, alignment: .trailing)
        }
        .overlay {
            Text(navigationTitleText)
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(AppColors.surface)
        .overlay(Rectangle().fill(Color(hex: "E1E6EB")).frame(height: 1), alignment: .bottom)
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date")
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.fontDefault)

            Text(entry.scheduleBannerText)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontSecondary)
        }
    }

    private var startEndFields: some View {
        HStack(alignment: .top, spacing: 36) {
            timeField(label: "Start at", selection: $startTime)
            timeField(label: "End at", selection: $endTime)
            Spacer(minLength: 0)
        }
    }

    /// Start → break rows → End (toggle: Breaks inside start / end).
    /// Bullets on Start, Breaks (title), and End — break rows sit under the Breaks bullet.
    private var nestedStartEndBreaksEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            editTimelineRow(isFirst: true, isLast: false) {
                timeField(label: "Start at", selection: $startTime)
                    .padding(.bottom, 20)
            }

            editTimelineRow(isFirst: false, isLast: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if !breaks.isEmpty {
                        Text("Breaks")
                            .font(AppFonts.footnote())
                            .tracking(-0.08)
                            .foregroundColor(AppColors.fontSecondary)
                    }

                    ForEach(Array(breaks.enumerated()), id: \.element.id) { index, _ in
                        breakRow(item: $breaks[index], number: index + 1)
                    }

                    Button {
                        addBreak()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text(breaks.isEmpty ? "Add break" : "Add another break")
                                .font(AppFonts.subheadStrong())
                        }
                        .foregroundColor(AppColors.primaryDark)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 20)
            }

            editTimelineRow(isFirst: false, isLast: true) {
                timeField(label: "End at", selection: $endTime)
            }
        }
    }

    /// Bullet on a continuous vertical rail (spacing lives inside `content`, not between rows).
    /// Last row: line stops at the bullet center (does not run through End at’s picker).
    private func editTimelineRow<Content: View>(
        isFirst: Bool,
        isLast: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .top) {
                if isLast {
                    // Top → bullet center only (bullet top inset 4 + half of 8).
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(width: 2, height: 8)
                } else {
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, isFirst ? 8 : 0)
                }

                Circle()
                    .fill(AppColors.iconInactive)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
            .frame(width: 8, alignment: .top)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func timeField(label: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)

            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.fontDefault)
        }
    }

    private var breaksEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !breaks.isEmpty {
                Text("Breaks")
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
            }

            if breaks.isEmpty {
                Button {
                    addBreak()
                } label: {
                    addBreakLabel(title: "Add break")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add break")
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(breaks.enumerated()), id: \.element.id) { index, _ in
                        editTimelineRow(
                            isFirst: index == 0,
                            isLast: index == breaks.count - 1
                        ) {
                            breakRow(item: $breaks[index], number: index + 1)
                                .padding(.bottom, index == breaks.count - 1 ? 0 : 12)
                        }
                    }
                }

                Button {
                    addBreak()
                } label: {
                    addBreakLabel(title: "Add another break")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add another break")
            }
        }
    }

    private func addBreakLabel(title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(AppFonts.subheadStrong())
        }
        .foregroundColor(AppColors.primaryDark)
    }

    private func breakRow(item: Binding<EditableTimeEntryBreak>, number: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text("\(number)")
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontSecondary)
                .frame(minWidth: 16, alignment: .leading)
                .accessibilityLabel("Break \(number)")

            if showsBreakEmoji {
                EmojiText(emoji: item.wrappedValue.emoji ?? "☕", size: 20)
                    .frame(width: 36, height: 36)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onTapGesture {
                        emojiEditBreakId = item.wrappedValue.id
                        isBreakEmojiKeyboardFocused = true
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Choose break emoji")
            }

            DatePicker("", selection: item.start, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.fontDefault)
                .accessibilityLabel("Break start")

            Text("-")
                .font(AppFonts.body())
                .foregroundColor(AppColors.iconDefault)

            DatePicker("", selection: item.end, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.fontDefault)
                .accessibilityLabel("Break end")

            Button {
                removeBreak(id: item.wrappedValue.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.dangerDefault)
                    .frame(width: 40, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove break")

            Spacer(minLength: 0)
        }
    }

    private func addBreak() {
        let calendar = Calendar.current
        // Default new break to a 30m window near midday inside the worked span.
        let base = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? startTime
        let start = max(startTime, min(base, endTime))
        let end = min(endTime, calendar.date(byAdding: .minute, value: 30, to: start) ?? start)
        breaks.append(
            EditableTimeEntryBreak(
                start: start,
                end: end,
                emoji: showsBreakEmoji ? "☕" : nil
            )
        )
    }

    private func removeBreak(id: UUID) {
        breaks.removeAll { $0.id == id }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 4) {
            (Text("Note") + Text(" (Optional)").foregroundColor(AppColors.fontSecondary))
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)

            TextField("", text: $note, axis: .vertical)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
                .lineLimit(1...4)

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(totalDurationText)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Text("in total")
                    .font(.system(size: 15))
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)

                Spacer(minLength: 8)

                if breakSupportEnabled, breakMinutesTotal > 0 {
                    Text("\(Self.formatDuration(minutes: breakMinutesTotal)) break")
                        .font(.system(size: 15))
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.informativeBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                saveEntry()
            } label: {
                Text(primaryButtonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.surface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.primary)
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(AppColors.surface)
    }

    private func saveEntry() {
        // Prototype: persist not wired. Home "Today · …" footer only appears after live clock-out.
        dismiss()
    }

    // MARK: - Parsing helpers

    private static func time(from string: String, on day: Date) -> Date {
        let parts = string.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return day }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? day
    }

    private static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0, mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(mins)m"
    }

    private static func parseDateLabel(_ label: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.date(from: label)
    }

    private static func combining(time: Date, on day: Date) -> Date {
        let calendar = Calendar.current
        let timeParts = calendar.dateComponents([.hour, .minute], from: time)
        var dayParts = calendar.dateComponents([.year, .month, .day], from: day)
        dayParts.hour = timeParts.hour
        dayParts.minute = timeParts.minute
        return calendar.date(from: dayParts) ?? time
    }
}
