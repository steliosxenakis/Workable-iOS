import SwiftUI

/// Picks between V1 (`RequestScheduleChangeView`), V2 (`RequestScheduleChangeViewV2`), and
/// V3 (`RequestScheduleChangeViewV3`) request-change form layouts, per Settings → Schedule
/// change request. Every call site opens this instead of a specific version, so switching
/// the setting updates every entry point.
struct ScheduleChangeRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ScheduleChangeRequestUIVersion.appStorageKey) private var uiVersionRaw =
        ScheduleChangeRequestUIVersion.defaultVersion.rawValue

    private let date: Date
    private let dayType: DayType
    private let shifts: [EditableWorkScheduleShift]?
    private let workplace: WorkplaceType
    private let onSend: () -> Void

    private func handleSend() {
        onSend()
        dismiss()
    }

    init(
        date: Date = ScheduleChangeFormField.tomorrow,
        dayType: DayType = .workday,
        shifts: [EditableWorkScheduleShift]? = nil,
        workplace: WorkplaceType = .onSite,
        onSend: @escaping () -> Void = {}
    ) {
        self.date = date
        self.dayType = dayType
        self.shifts = shifts
        self.workplace = workplace
        self.onSend = onSend
    }

    var body: some View {
        switch ScheduleChangeRequestUIVersion(rawValue: uiVersionRaw) ?? .v1 {
        case .v1:
            RequestScheduleChangeView(date: date, dayType: dayType, shifts: shifts, workplace: workplace, onSend: handleSend)
        case .v2:
            RequestScheduleChangeViewV2(date: date, dayType: dayType, shifts: shifts, workplace: workplace, onSend: handleSend)
        case .v3:
            RequestScheduleChangeViewV3(date: date, dayType: dayType, shifts: shifts, workplace: workplace, onSend: handleSend)
        }
    }
}

/// One Date-range row on the V2 form — plain start/end, no recurrence of its own (that's the
/// separate top-level Frequency dropdown).
struct ScheduleChangeDateRange: Identifiable {
    let id = UUID()
    var start: Date
    var end: Date
}

/// Wireframe V2 of the "Request schedule change" form (Figma 16426-301502 / 301581 / 301619 /
/// 301675). Instead of always-shown fields, "What would you like to change?" breaks the
/// change into three independent toggle cards — Workplace, Working hours, Workday — so a
/// requester only fills in the part of the day that's actually changing.
struct RequestScheduleChangeViewV2: View {
    @Environment(\.dismiss) private var dismiss

    var onSend: () -> Void = {}

    @State private var dateRanges: [ScheduleChangeDateRange]
    @State private var frequency: ScheduleChangeFrequency = .doesNotRepeat
    @State private var recurrenceEndDate: Date

    @State private var changesType = false
    @State private var dayType: DayType

    @State private var changesWorkplace = false
    @State private var workplace: WorkplaceType

    @State private var changesWorkHours = false
    @State private var shifts: [EditableWorkScheduleShift]

    @State private var note = ""

    init(
        date: Date = ScheduleChangeFormField.tomorrow,
        dayType: DayType = .workday,
        shifts: [EditableWorkScheduleShift]? = nil,
        workplace: WorkplaceType = .onSite,
        onSend: @escaping () -> Void = {}
    ) {
        self.onSend = onSend
        _dateRanges = State(initialValue: [ScheduleChangeDateRange(start: date, end: date)])
        _recurrenceEndDate = State(initialValue: Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date)
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
                    frequencyField
                    requestTypeSection
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
            Text("Schedule change")
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

    // MARK: - Date

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScheduleChangeFormField.requiredLabel("Date")

            ForEach(Array(dateRanges.enumerated()), id: \.element.id) { index, _ in
                dateRangeRow(item: $dateRanges[index], index: index)
            }

            Button {
                let last = dateRanges.last?.end ?? Date()
                dateRanges.append(ScheduleChangeDateRange(start: last, end: last))
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("Add dates")
                        .font(AppFonts.subheadStrong())
                }
                .foregroundColor(AppColors.fontDefault)
            }
            .buttonStyle(.plain)
        }
    }

    private func dateRangeRow(item: Binding<ScheduleChangeDateRange>, index: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            ScheduleChangeFormField.compactDateField(
                selection: startBinding(item),
                accessibilityLabel: "Start date \(index + 1)"
            )

            Text("-")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)

            ScheduleChangeFormField.compactDateField(
                selection: item.end,
                after: item.wrappedValue.start,
                accessibilityLabel: "End date \(index + 1)"
            )

            if dateRanges.count > 1 {
                Button {
                    dateRanges.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.iconDefault)
                        .frame(width: 24, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove date range \(index + 1)")
            }

            Spacer(minLength: 0)
        }
    }

    /// Start bumps end forward whenever it would otherwise land before start.
    private func startBinding(_ item: Binding<ScheduleChangeDateRange>) -> Binding<Date> {
        Binding(
            get: { item.wrappedValue.start },
            set: { newValue in
                item.wrappedValue.start = newValue
                if item.wrappedValue.end < newValue {
                    item.wrappedValue.end = newValue
                }
            }
        )
    }

    // MARK: - Frequency

    private var frequencyField: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScheduleChangeFormField.boxedField(label: "Frequency") {
                Picker("Frequency", selection: Binding(
                    get: { frequency },
                    set: { newValue in
                        if newValue != .doesNotRepeat, frequency == .doesNotRepeat {
                            let start = dateRanges.first?.start ?? Date()
                            recurrenceEndDate = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? start
                        }
                        withAnimation(.easeInOut(duration: 0.15)) { frequency = newValue }
                    }
                )) {
                    ForEach(ScheduleChangeFrequency.allCases) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(.menu)
                .tint(frequency == .doesNotRepeat ? AppColors.fontSecondary : AppColors.fontDefault)
            }

            if frequency != .doesNotRepeat {
                ScheduleChangeFormField.boxedField(label: "Ends on") {
                    DatePicker(
                        "",
                        selection: $recurrenceEndDate,
                        in: (dateRanges.first?.start ?? Date())...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(AppColors.fontDefault)
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - What would you like to change?

    private var requestTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What would you like to change?")
                .font(AppFonts.subheadStrong())
                .foregroundColor(AppColors.fontDefault)

            toggleCard(title: "Workplace (remote ↔ on-site)", isOn: $changesWorkplace) {
                pillRow($workplace)
            }

            toggleCard(title: "Working hours", isOn: $changesWorkHours) {
                workHoursContent
            }

            toggleCard(title: "Workday (workday ↔ day off)", isOn: $changesType) {
                pillRow($dayType)
            }
        }
    }

    /// A card with a title + toggle; when on, reveals `content` below it. Matches the V1
    /// "Recurring request" card styling for a consistent wireframe language.
    private func toggleCard<Content: View>(
        title: String,
        isOn: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.fontDefault)

                Spacer(minLength: 12)

                Toggle("", isOn: Binding(
                    get: { isOn.wrappedValue },
                    set: { newValue in withAnimation(.easeInOut(duration: 0.2)) { isOn.wrappedValue = newValue } }
                ))
                .labelsHidden()
                .tint(AppColors.fontDefault)
            }
            .padding(16)

            if isOn.wrappedValue {
                content()
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

    /// A row of selectable pills for any plain string-backed enum (`DayType`, `WorkplaceType`)
    /// — the selected pill gets a checkmark, mirroring the Figma "Workday / Day off" and
    /// "On-site / Remote" pill groups.
    private func pillRow<T: CaseIterable & Identifiable & RawRepresentable & Equatable>(
        _ selection: Binding<T>
    ) -> some View where T.RawValue == String, T.AllCases: RandomAccessCollection {
        HStack(spacing: 8) {
            ForEach(T.allCases) { option in
                let selected = option == selection.wrappedValue
                Button {
                    selection.wrappedValue = option
                } label: {
                    HStack(spacing: 4) {
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text(option.rawValue)
                            .font(AppFonts.subheadStrong())
                    }
                    .foregroundColor(selected ? AppColors.fontDefault : AppColors.fontSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selected ? AppColors.surface : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selected ? AppColors.iconInactive : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var workHoursContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(shifts.enumerated()), id: \.element.id) { index, _ in
                shiftRow(item: $shifts[index], number: index + 1)
            }

            Button {
                shifts.append(EditableWorkScheduleShift(defaultsFor: dateRanges.first?.start ?? Date()))
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("Add hours")
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

    // MARK: - Note / Attach file / Footer

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Note (Optional)")
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
            Text("File (Optional)")
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)

            Button {
                // Wireframe only — no real file picker wired up yet.
            } label: {
                Text("Upload a file")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.fontDefault)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppColors.separator, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    /// The day currently on file for whichever weekday the first date range falls on — the
    /// baseline both `submitPendingChange` and the summary card diff against.
    private var originalDay: WorkScheduleDay? {
        guard let start = dateRanges.first?.start else { return nil }
        let weekdayNumber = Calendar.current.component(.weekday, from: start)
        return TimeAttendanceMockData.workScheduleDays.first { $0.weekdayNumber == weekdayNumber }
    }

    /// Nothing to send until at least one "What would you like to change?" card is on.
    private var hasAnyChange: Bool {
        changesType || changesWorkplace || changesWorkHours
    }

    /// Merges whichever cards are toggled on with `oldDay` for the untouched fields — shared by
    /// the pending-request summary (`submitPendingChange`) and the read-only summary card. With
    /// no `oldDay` on file (e.g. a weekend), the form's own current hours/workplace are shown
    /// regardless of which cards are toggled — there's nothing else to fall back to.
    private func resultingSchedule(mergingWith oldDay: WorkScheduleDay?) -> (
        isDayOff: Bool, ranges: String, total: String, workplace: WorkplaceType, hourRanges: [PendingScheduleHourRange]
    ) {
        let newWorkplace = changesWorkplace ? workplace : (oldDay?.workplace ?? workplace)
        if changesType, dayType == .dayOff {
            return (true, "Day off", newWorkplace.rawValue, newWorkplace, [])
        }
        if let oldDay, !changesWorkHours {
            let breakSuffix = oldDay.breakText.map { " (Break: \($0))" } ?? ""
            return (
                false, oldDay.rangesText, "\(oldDay.totalHoursText)\(breakSuffix) | \(newWorkplace.rawValue)", newWorkplace, []
            )
        }
        let summary = ScheduleChangeFormField.pendingWorkdaySummary(shifts: shifts, workplace: newWorkplace)
        return (false, summary.ranges, summary.total, newWorkplace, ScheduleChangeFormField.hourRanges(from: shifts))
    }

    private var summaryCard: some View {
        let resulting = resultingSchedule(mergingWith: originalDay)
        return VStack(alignment: .leading, spacing: 4) {
            Text(ScheduleChangeFormField.fullDateFormatter.string(from: dateRanges.first?.start ?? Date()))
                .foregroundColor(AppColors.fontSecondary)
            Text(resulting.isDayOff ? "Day off" : "\(resulting.ranges) | \(resulting.workplace.rawValue)")
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

    /// Only the toggled-on cards represent an actual change — the others keep the existing
    /// schedule's value in the "new" summary shown on the pending banner.
    private func submitPendingChange() {
        guard let start = dateRanges.first?.start else { return }
        let weekdayNumber = Calendar.current.component(.weekday, from: start)
        let oldDay = originalDay
        let resulting = resultingSchedule(mergingWith: oldDay)

        PendingScheduleChangeStore.shared.submit(
            PendingScheduleChangeRequest(
                weekdayNumber: weekdayNumber,
                dateLabel: ScheduleChangeFormField.fullDateFormatter.string(from: start),
                oldRangesText: oldDay?.rangesText ?? "Not scheduled",
                oldTotalText: oldDay?.totalText ?? "",
                newRangesText: resulting.ranges,
                newTotalText: resulting.total,
                dateSpans: dateRanges.map { PendingScheduleDateSpan(start: $0.start, end: $0.end) },
                isRecurring: frequency != .doesNotRepeat,
                recurrenceEndDate: frequency != .doesNotRepeat ? recurrenceEndDate : nil,
                newHourRanges: resulting.hourRanges
            )
        )
    }
}

#Preview("Request schedule change V2") {
    RequestScheduleChangeViewV2()
}
