import SwiftUI

// MARK: - Pending schedule change (Figma 16555-35623 / 35746 / 24871 / 16576-36223 / 36356)

/// A schedule-change request — either the single in-flight one awaiting approval, or a past,
/// already-resolved one kept for "Work schedule changes" history. Drives the "Pending change"
/// banner on the Work schedule sheet, the dashed highlight on the Attendance calendar, and the
/// full history list.
struct PendingScheduleChangeRequest: Identifiable {
    let id = UUID()
    /// `Calendar` weekday number (Sunday = 1 ... Saturday = 7) of the day being changed.
    let weekdayNumber: Int
    /// e.g. "Tuesday, September 16, 2025" — shown above the card in the history list.
    let dateLabel: String
    /// Struck-through "before" values.
    let oldRangesText: String
    let oldTotalText: String
    /// Values shown underneath, in the requested state.
    let newRangesText: String
    let newTotalText: String
    var isPending: Bool = true
    /// One-off requests only apply on these date spans. Empty falls back to `dateLabel`.
    var dateSpans: [PendingScheduleDateSpan] = []
    /// Weekly (or other) recurrence — same weekday repeats until `recurrenceEndDate`.
    var isRecurring: Bool = false
    var recurrenceEndDate: Date? = nil
    /// Requested working-hour blocks as chart hours (e.g. 12.0...18.0). Empty keeps the
    /// existing scheduled bar; a day-off request is `newRangesText == "Day off"`.
    var newHourRanges: [PendingScheduleHourRange] = []

    var requestedDate: Date? {
        if let first = dateSpans.first?.start { return Calendar.current.startOfDay(for: first) }
        return ScheduleChangeFormField.fullDateFormatter.date(from: dateLabel)
    }

    var isInPast: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if isRecurring {
            if let recurrenceEndDate {
                return calendar.startOfDay(for: recurrenceEndDate) < today
            }
            return false
        }
        if let last = dateSpans.map({ calendar.startOfDay(for: $0.end) }).max() {
            return last < today
        }
        guard let requestedDate else { return false }
        return calendar.startOfDay(for: requestedDate) < today
    }

    /// Whether this request should highlight `date` on the calendar / this week's schedule.
    func applies(to date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        if isRecurring {
            guard calendar.component(.weekday, from: date) == weekdayNumber else { return false }
            guard let start = requestedDate else { return false }
            if day < calendar.startOfDay(for: start) { return false }
            if let recurrenceEndDate, day > calendar.startOfDay(for: recurrenceEndDate) { return false }
            return true
        }
        if dateSpans.isEmpty, let requestedDate {
            return calendar.isDate(day, inSameDayAs: requestedDate)
        }
        return dateSpans.contains { span in
            let start = calendar.startOfDay(for: span.start)
            let end = calendar.startOfDay(for: span.end)
            return day >= start && day <= end
        }
    }
}

/// Inclusive start/end of a one-off schedule-change date range.
struct PendingScheduleDateSpan: Hashable {
    var start: Date
    var end: Date
}

/// One requested shift on the calendar chart, in hours from midnight (9.5 = 09:30).
struct PendingScheduleHourRange: Hashable {
    var start: Double
    var end: Double
}

/// Every schedule-change request, most recent first — any number of pending ones (one per day
/// at most — a new request for a day already pending replaces that day's) plus past,
/// already-resolved ones. Both request forms (V1/V2/V3) and the calendar's quick workplace-
/// change menu submit into this; the Work schedule sheet, Attendance calendar, and "Work
/// schedule changes" history all observe it.
@MainActor
final class PendingScheduleChangeStore: ObservableObject {
    static let shared = PendingScheduleChangeStore()
    private init() {
        requests = TimeAttendanceMockData.scheduleChangeHistorySeed
    }

    @Published private(set) var requests: [PendingScheduleChangeRequest]

    /// All requests currently awaiting approval — a week can have several, one per day.
    var pendingRequests: [PendingScheduleChangeRequest] {
        requests.filter { $0.isPending }
    }

    /// The single pending request, if callers only care whether *any* exists (e.g. the manager
    /// Inbox "just sent" fallback). Prefer `pending(for:)` or `pendingRequests` when a specific
    /// day matters.
    var current: PendingScheduleChangeRequest? {
        pendingRequests.first
    }

    /// The pending request (if any) covering `date` — each day has at most one.
    func pending(for date: Date, calendar: Calendar = .current) -> PendingScheduleChangeRequest? {
        pendingRequests.first { $0.applies(to: date, calendar: calendar) }
    }

    func submit(_ request: PendingScheduleChangeRequest) {
        // A new request for a day that already has one pending replaces it; pending requests
        // for other days are left alone, so several can coexist across the week.
        requests.removeAll { $0.isPending && overlaps($0, request) }
        requests.insert(request, at: 0)
    }

    private func overlaps(_ existing: PendingScheduleChangeRequest, _ new: PendingScheduleChangeRequest) -> Bool {
        guard existing.weekdayNumber == new.weekdayNumber else { return false }
        if existing.isRecurring || new.isRecurring { return true }
        guard let existingDate = existing.requestedDate, let newDate = new.requestedDate else { return true }
        return Calendar.current.isDate(existingDate, inSameDayAs: newDate)
    }

    func cancel(_ id: PendingScheduleChangeRequest.ID) {
        requests.removeAll { $0.id == id }
    }

    /// Manager Inbox / Home to-dos: every in-flight request the employee(s) sent, otherwise the
    /// seeded approval mock.
    var managerInboxItems: [ScheduleChangeRequestItem] {
        let pending = pendingRequests
        guard !pending.isEmpty else { return [ScheduleChangeRequestMockData.pending] }
        return pending.map { $0.asInboxItem() }
    }
}

extension PendingScheduleChangeRequest {
    func asInboxItem() -> ScheduleChangeRequestItem {
        let user = TimeAttendanceMockData.loggedInUser
        var changes: [ScheduleChangeField] = []
        if oldRangesText != newRangesText {
            changes.append(.init(label: "Working hours", oldValue: oldRangesText, newValue: newRangesText))
        }
        if oldTotalText != newTotalText {
            changes.append(.init(label: "Schedule", oldValue: oldTotalText, newValue: newTotalText))
        }
        if changes.isEmpty {
            changes.append(.init(label: "Working hours", oldValue: oldRangesText, newValue: newRangesText))
        }
        return ScheduleChangeRequestItem(
            id: id,
            requesterName: user.name,
            requesterAvatar: user.avatarName ?? "avatar-emma",
            timeAgo: "Just now",
            dateRange: dateLabel,
            changes: changes,
            note: nil,
            requestedOnText: "Requested on \(dateLabel)",
            isUnread: true
        )
    }
}

/// Weekly breakdown opened from the "Today's work schedule" banner on the Time tracking →
/// List view (Figma 3609-84050). Days are read-only; "Request schedule change" (Settings →
/// Approvals) is the single entry point into the request form (Figma Scopes 486-16581 /
/// Playground 506-68166).
struct WorkScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.approvalsEnabled") private var approvalsEnabled = false
    @AppStorage(ScheduleChangeRequestUIVersion.appStorageKey) private var scheduleChangeUIVersionRaw =
        ScheduleChangeRequestUIVersion.defaultVersion.rawValue
    @AppStorage(ScheduleChangeRequestPersona.appStorageKey) private var scheduleChangePersonaRaw =
        ScheduleChangeRequestPersona.defaultPersona.rawValue
    @ObservedObject private var pendingStore = PendingScheduleChangeStore.shared

    private var canRequestScheduleChange: Bool {
        ScheduleChangeRequestPersona.showsEmployeeRequestUI(
            approvalsEnabled: approvalsEnabled,
            versionRaw: scheduleChangeUIVersionRaw,
            personaRaw: scheduleChangePersonaRaw
        )
    }

    private var isManagerPersona: Bool {
        ScheduleChangeRequestPersona.showsManagerInboxRequest(
            approvalsEnabled: approvalsEnabled,
            versionRaw: scheduleChangeUIVersionRaw,
            personaRaw: scheduleChangePersonaRaw
        )
    }

    @State private var showsGeneralRequestSheet = false
    @State private var didSendRequest = false
    @State private var showsRequestSentToast = false
    var body: some View {
        NavigationStack {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if didSendRequest {
                        sentConfirmationBanner
                    }

                    Text("\(TimeAttendanceMockData.workScheduleName) | \(TimeAttendanceMockData.workScheduleSummary)")
                        .font(AppFonts.footnote())
                        .foregroundColor(AppColors.fontSecondary)

                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(TimeAttendanceMockData.workScheduleDays) { day in
                            dayRow(day)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }

            if canRequestScheduleChange {
                footer
            }
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
        .scheduleRequestSentToast(isPresented: $showsRequestSentToast)
        .sheet(isPresented: $showsGeneralRequestSheet) {
            ScheduleChangeRequestSheet(
                onSend: {
                    showsGeneralRequestSheet = false
                    withAnimation { didSendRequest = true }
                    triggerScheduleRequestSentToast($showsRequestSentToast)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        }
    }

    private var header: some View {
        HStack {
            WireframeSymbolButton(
                systemName: "xmark",
                accessibilityLabel: "Close",
                action: { dismiss() }
            )
            .frame(width: 85, alignment: .leading)

            Spacer(minLength: 0)

            Color.clear.frame(width: 85, height: 1)
        }
        .overlay {
            Text("This week's work schedule")
                .font(AppFonts.subheadStrong())
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.fontDefault)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

    private var sentConfirmationBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColors.fontSecondary)
            Text("Request sent — waiting for approval")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontDefault)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(AppColors.separator, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }

    /// Single entry point into the request form — for a change not tied to one of the
    /// listed days (e.g. a brand-new date).
    private var footer: some View {
        Button {
            didSendRequest = false
            showsGeneralRequestSheet = true
        } label: {
            Text("Request schedule change")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(AppColors.fontDefault, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .top)
    }

    private func dayRow(_ day: WorkScheduleDay) -> some View {
        let pending = pendingStore.pending(for: day.date())

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(day.weekday)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                    .lineLimit(1)
                    .frame(width: 108, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    if let pending {
                        // Current (soon-to-be-replaced) schedule, crossed out — the pending
                        // value is shown below it, not yet in effect (Figma 16555-35623).
                        Text(day.rangesText)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                            .strikethrough(color: AppColors.fontSecondary)
                        Text(day.totalText)
                            .font(AppFonts.footnote())
                            .foregroundColor(AppColors.fontSecondary)
                            .strikethrough(color: AppColors.fontSecondary)

                        Text(pending.newRangesText)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontDefault)
                            .padding(.top, 4)
                        Text(pending.newTotalText)
                            .font(AppFonts.footnote())
                            .foregroundColor(AppColors.fontSecondary)

                        pendingChangeBadge(for: pending)
                            .padding(.top, 4)
                    } else {
                        Text(day.rangesText)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontDefault)
                        Text(day.totalText)
                            .font(AppFonts.footnote())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }

                Spacer(minLength: 0)
            }

        }
    }

    /// "Pending change ›" opens this day's own request detail — approve/reject for managers,
    /// cancel for employees. Each day's badge links to its own pending request now that several
    /// can be pending across the week at once.
    private func pendingChangeBadge(for pending: PendingScheduleChangeRequest) -> some View {
        NavigationLink {
            ScheduleChangeRequestDetailView(
                item: pending.asInboxItem(),
                mode: isManagerPersona ? .managerReview : .employeePending
            )
        } label: {
            WireframePendingChangeBadge()
        }
        .buttonStyle(.plain)
    }
}

/// Every "Request schedule change" entry point — the full form and the calendar's quick
/// workplace-change menu — shows this same transient confirmation, auto-dismissing after 2s.
extension View {
    func scheduleRequestSentToast(isPresented: Binding<Bool>) -> some View {
        overlay {
            if isPresented.wrappedValue {
                Text(ScheduleChangeFormField.requestSentToastMessage)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.surface)
                    .padding(16)
                    .background(AppColors.fontDefault)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }
}

/// Call from an `onSend` handler alongside `.scheduleRequestSentToast(isPresented:)`.
@MainActor
func triggerScheduleRequestSentToast(_ isPresented: Binding<Bool>) {
    withAnimation(.easeInOut(duration: 0.2)) {
        isPresented.wrappedValue = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPresented.wrappedValue = false
        }
    }
}

// MARK: - Request a schedule change (Figma Scopes 486-16581 / 506-67295 / Playground 506-68166)

/// Shared field-building blocks used by the V1 (`RequestScheduleChangeView`), V2
/// (`RequestScheduleChangeViewV2`), and V3 (`RequestScheduleChangeViewV3`) request forms.
enum ScheduleChangeFormField {
    /// Shown in the toast after any schedule/workplace change is sent — the full "Request
    /// schedule change" form and the calendar's quick workplace-change menu both use this
    /// exact copy so the confirmation reads the same everywhere.
    static let requestSentToastMessage = "Schedule request sent."

    /// Default entry point (no specific day picked yet) opens on tomorrow, not today — a
    /// schedule change almost never applies to a day already in progress.
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    static let compactDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let clockTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// e.g. "Tuesday, September 16, 2025" — the pending/history card's date label.
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    /// e.g. 8.5 -> "8h 30m", 0.5 -> "30m", 8 -> "8h".
    static func durationText(hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    /// Builds the "ranges" / "total" summary for a pending request's new value from a
    /// workday's shifts — gaps between consecutive shifts are shown as the break.
    static func pendingWorkdaySummary(
        shifts: [EditableWorkScheduleShift],
        workplace: WorkplaceType
    ) -> (ranges: String, total: String) {
        let sorted = shifts.sorted { $0.start < $1.start }
        let ranges = sorted
            .map { "\(clockTimeFormatter.string(from: $0.start)) - \(clockTimeFormatter.string(from: $0.end))" }
            .joined(separator: ", ")

        let workedHours = sorted.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) / 3600 }
        var breakHours = 0.0
        if sorted.count > 1 {
            for index in 1..<sorted.count {
                breakHours += sorted[index].start.timeIntervalSince(sorted[index - 1].end) / 3600
            }
        }
        let breakSuffix = breakHours > 0 ? " (Break: \(durationText(hours: breakHours)))" : ""
        let total = "\(durationText(hours: workedHours))\(breakSuffix) | \(workplace.rawValue)"
        return (ranges, total)
    }

    static func hourOfDay(from date: Date) -> Double {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(parts.hour ?? 0) + Double(parts.minute ?? 0) / 60
    }

    static func hourRanges(from shifts: [EditableWorkScheduleShift]) -> [PendingScheduleHourRange] {
        shifts.map {
            PendingScheduleHourRange(start: hourOfDay(from: $0.start), end: hourOfDay(from: $0.end))
        }
    }

    /// A `DatePicker(.compact)` with our own fixed-format label on top. Two native
    /// `.compact` pickers side by side (start/end of a range) otherwise silently swap one
    /// to an abbreviated "16/9/26"-style format — seemingly based on how close the bound
    /// date is to today, not layout width, so `.fixedSize()`/`.frame(minWidth:)` don't help.
    /// Overlaying our own `Text` guarantees a consistent "d MMM yyyy" style regardless.
    @ViewBuilder
    static func compactDateField(
        selection: Binding<Date>,
        after minDate: Date? = nil,
        accessibilityLabel: String
    ) -> some View {
        ZStack {
            Group {
                if let minDate {
                    DatePicker("", selection: selection, in: minDate..., displayedComponents: .date)
                } else {
                    DatePicker("", selection: selection, displayedComponents: .date)
                }
            }
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AppColors.fontDefault)
            .opacity(0.011)

            Text(compactDateFormatter.string(from: selection.wrappedValue))
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.surfaceDarker)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .allowsHitTesting(false)
        }
        .fixedSize()
        .accessibilityLabel(accessibilityLabel)
    }

    static func requiredLabel(_ title: String) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
            Text("*")
                .font(AppFonts.footnote())
                .foregroundColor(AppColors.fontSecondary)
        }
    }

    /// A labeled control boxed in a bordered rounded rect, matching the Frequency/Ends
    /// dropdown-field look.
    @ViewBuilder
    static func boxedField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)

            HStack {
                content()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColors.separator, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

/// Wireframe request form — mirrors the web "Request a schedule change" drawer:
/// Date, Day type, Working hours (one or more shifts), Workplace, Note, Attach file.
struct RequestScheduleChangeView: View {
    @Environment(\.dismiss) private var dismiss

    /// Called once the (mock) request is "sent" — the caller dismisses this sheet.
    var onSend: () -> Void = {}

    @State private var date: Date
    /// End of the request range — equal to `date` for a single day (matching the
    /// approval-side mock in ScheduleChangeRequestMockData for a multi-day request).
    @State private var rangeEndDate: Date
    /// "Repeat every N Days/Weeks/Months, until [date]" — off by default, a one-off request.
    @State private var isRecurring = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .weekly
    @State private var recurrenceEndDate = Date()
    @State private var dayType: DayType
    @State private var shifts: [EditableWorkScheduleShift]
    @State private var workplace: WorkplaceType
    @State private var note = ""

    init(
        date: Date = ScheduleChangeFormField.tomorrow,
        dayType: DayType = .workday,
        shifts: [EditableWorkScheduleShift]? = nil,
        workplace: WorkplaceType = .onSite,
        onSend: @escaping () -> Void = {}
    ) {
        self.onSend = onSend
        _date = State(initialValue: date)
        _rangeEndDate = State(initialValue: date)
        _dayType = State(initialValue: dayType)
        _shifts = State(initialValue: shifts ?? [EditableWorkScheduleShift(defaultsFor: date)])
        _workplace = State(initialValue: workplace)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    dateField
                    dayTypeField
                    if dayType == .workday {
                        workingHoursField
                        workplaceField
                    }
                    recurrenceField
                    noteField
                    attachFileField
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }

            footer
        }
        .background(AppColors.surface)
        .animation(.easeInOut(duration: 0.15), value: dayType)
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

            Text("Close")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.primaryDark)
                .opacity(0)
                .frame(width: 85, alignment: .trailing)
        }
        .overlay {
            Text("Request schedule change")
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

    /// Start bumps end forward whenever it would otherwise land after start — a single day
    /// is simply the case where the two dates are equal.
    private var startDateBinding: Binding<Date> {
        Binding(
            get: { date },
            set: { newValue in
                date = newValue
                if rangeEndDate < newValue {
                    rangeEndDate = newValue
                }
            }
        )
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScheduleChangeFormField.requiredLabel("Date")

            HStack(alignment: .center, spacing: 8) {
                ScheduleChangeFormField.compactDateField(selection: startDateBinding, accessibilityLabel: "Start date")

                Text("-")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)

                ScheduleChangeFormField.compactDateField(
                    selection: $rangeEndDate,
                    after: date,
                    accessibilityLabel: "End date"
                )

                Spacer(minLength: 0)
            }
        }
    }

    /// Optional recurrence card: a toggle that reveals Frequency (dropdown) + Ends (date).
    private var recurrenceField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text("Recurring request")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.fontDefault)

                Spacer(minLength: 12)

                Toggle("", isOn: Binding(
                    get: { isRecurring },
                    set: { newValue in
                        if newValue {
                            recurrenceEndDate = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
                        }
                        withAnimation(.easeInOut(duration: 0.2)) { isRecurring = newValue }
                    }
                ))
                .labelsHidden()
                .tint(AppColors.fontDefault)
            }
            .padding(16)

            if isRecurring {
                VStack(alignment: .leading, spacing: 16) {
                    ScheduleChangeFormField.boxedField(label: "Frequency") {
                        Picker("Frequency", selection: $recurrenceFrequency) {
                            ForEach(RecurrenceFrequency.allCases) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.fontDefault)
                    }

                    ScheduleChangeFormField.boxedField(label: "Ends") {
                        DatePicker("", selection: $recurrenceEndDate, in: date..., displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(AppColors.fontDefault)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .background(AppColors.surfaceDarker)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var dayTypeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScheduleChangeFormField.requiredLabel("Day type")

            Picker("Day type", selection: $dayType) {
                ForEach(DayType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .tint(AppColors.fontSecondary)
        }
    }

    private var workingHoursField: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScheduleChangeFormField.requiredLabel("Working hours")

            ForEach(Array(shifts.enumerated()), id: \.element.id) { index, _ in
                shiftRow(item: $shifts[index], number: index + 1)
            }

            Button {
                shifts.append(EditableWorkScheduleShift(defaultsFor: date))
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("Add")
                        .font(AppFonts.subheadStrong())
                }
                .foregroundColor(AppColors.fontDefault)
            }
            .buttonStyle(.plain)
        }
    }

    private func shiftRow(item: Binding<EditableWorkScheduleShift>, number: Int) -> some View {
        HStack(alignment: .center, spacing: 4) {
            DatePicker("", selection: item.start, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.fontDefault)
                .accessibilityLabel("Shift \(number) start")

            Text("-")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)

            DatePicker("", selection: item.end, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.fontDefault)
                .accessibilityLabel("Shift \(number) end")

            Spacer(minLength: 0)

            if shifts.count > 1 {
                Button {
                    shifts.removeAll { $0.id == item.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.iconDefault)
                        .frame(width: 24, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove shift \(number)")
            }
        }
    }

    private var workplaceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScheduleChangeFormField.requiredLabel("Workplace")

            Picker("Workplace", selection: $workplace) {
                ForEach(WorkplaceType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .tint(AppColors.fontSecondary)
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Note")
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.separator, lineWidth: 1)

                if note.isEmpty {
                    Text("Add a note for your manager")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }

                TextEditor(text: $note)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .scrollContentBackground(.hidden)
                    .padding(8)
            }
            .frame(height: 100)
        }
    }

    private var attachFileField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Attach file")
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)

            Button {
                // Wireframe only — no real file picker wired up yet.
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.fontSecondary)
                    Text("Choose file or drag and drop here")
                        .font(AppFonts.footnote())
                        .foregroundColor(AppColors.fontSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.separator, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// The day currently on file for whichever weekday `date` falls on — the baseline the
    /// form is diffed against for both `hasAnyChange` and the summary card.
    private var originalDay: WorkScheduleDay? {
        let weekdayNumber = Calendar.current.component(.weekday, from: date)
        return TimeAttendanceMockData.workScheduleDays.first { $0.weekdayNumber == weekdayNumber }
    }

    /// Nothing to send while the form still matches what's already on file for that day.
    private var hasAnyChange: Bool {
        guard let originalDay else { return true }
        if dayType == .dayOff { return true }
        let summary = ScheduleChangeFormField.pendingWorkdaySummary(shifts: shifts, workplace: workplace)
        return summary.ranges != originalDay.rangesText || workplace != originalDay.workplace
    }

    /// "Ranges | Workplace" (or "Day off") for the current form state — the read-only summary
    /// card in the footer (Figma 16809-575733).
    private var summaryScheduleLine: String {
        dayType == .dayOff
            ? "Day off"
            : "\(ScheduleChangeFormField.pendingWorkdaySummary(shifts: shifts, workplace: workplace).ranges) | \(workplace.rawValue)"
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ScheduleChangeFormField.fullDateFormatter.string(from: date))
                .foregroundColor(AppColors.fontSecondary)
            Text(summaryScheduleLine)
                .foregroundColor(AppColors.fontDefault)
        }
        .font(AppFonts.body())
        .tracking(-0.41)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.informativeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 12) {
            summaryCard

            Button {
                submitPendingChange()
                onSend()
            } label: {
                Text("Send request")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.surface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.fontDefault)
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!hasAnyChange)
            .opacity(hasAnyChange ? 1 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(AppColors.surface)
    }

    /// Publishes this request to `PendingScheduleChangeStore` so the Work schedule sheet and
    /// Attendance calendar can show it as pending.
    private func submitPendingChange() {
        let weekdayNumber = Calendar.current.component(.weekday, from: date)
        let oldDay = originalDay

        let newRangesText: String
        let newTotalText: String
        let newHourRanges: [PendingScheduleHourRange]
        if dayType == .dayOff {
            newRangesText = "Day off"
            newTotalText = workplace.rawValue
            newHourRanges = []
        } else {
            let summary = ScheduleChangeFormField.pendingWorkdaySummary(shifts: shifts, workplace: workplace)
            newRangesText = summary.ranges
            newTotalText = summary.total
            newHourRanges = ScheduleChangeFormField.hourRanges(from: shifts)
        }

        PendingScheduleChangeStore.shared.submit(
            PendingScheduleChangeRequest(
                weekdayNumber: weekdayNumber,
                dateLabel: ScheduleChangeFormField.fullDateFormatter.string(from: date),
                oldRangesText: oldDay?.rangesText ?? "Not scheduled",
                oldTotalText: oldDay?.totalText ?? "",
                newRangesText: newRangesText,
                newTotalText: newTotalText,
                dateSpans: [PendingScheduleDateSpan(start: date, end: rangeEndDate)],
                isRecurring: isRecurring,
                recurrenceEndDate: isRecurring ? recurrenceEndDate : nil,
                newHourRanges: newHourRanges
            )
        )
    }
}

extension EditableWorkScheduleShift {
    /// A default 09:00–18:00 shift on the given day (blank "Add another day" case).
    init(defaultsFor day: Date) {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
        let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
        self.init(start: start, end: end)
    }
}

#Preview("Work schedule") {
    WorkScheduleView()
}

#Preview("Request schedule change") {
    RequestScheduleChangeView()
}
