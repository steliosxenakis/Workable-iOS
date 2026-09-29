import SwiftUI

/// Real-UI counterpart of V3 — same layout (Date / Frequency / toggle-card "What would you like
/// to change?" with an always-visible Workday/Day off tab and Remote → Home/Travel sub-pills),
/// drawn with glass chrome and filled capsules instead of V3's wireframe boxes. A copy of V2's
/// visual language, since V2 already matches V3's layout field-for-field.
struct RequestScheduleChangeViewV4: View {
    @Environment(\.dismiss) private var dismiss

    var onSend: () -> Void = {}
    private let mode: ScheduleChangeRequestMode

    @State private var dateRanges: [ScheduleChangeDateRange]
    @State private var frequency: ScheduleChangeFrequency = .doesNotRepeat
    @State private var recurrenceEndDate: Date

    @State private var dayType: DayType

    @State private var changesWorkplace = false
    @State private var workplace: WorkplaceType
    @State private var remoteDetail: RemoteWorkplaceDetail

    @State private var changesWorkHours = false
    @State private var shifts: [EditableWorkScheduleShift]

    @State private var showsNotesOrFiles = false
    @State private var note = ""

    init(
        date: Date = ScheduleChangeFormField.tomorrow,
        dayType: DayType = .workday,
        shifts: [EditableWorkScheduleShift]? = nil,
        workplace: WorkplaceType = .onSite,
        remoteDetail: RemoteWorkplaceDetail = .home,
        mode: ScheduleChangeRequestMode = .full,
        onSend: @escaping () -> Void = {}
    ) {
        self.onSend = onSend
        self.mode = mode
        _dateRanges = State(initialValue: [ScheduleChangeDateRange(start: date, end: date)])
        _recurrenceEndDate = State(initialValue: Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date)
        _dayType = State(initialValue: dayType)
        _shifts = State(initialValue: shifts ?? [EditableWorkScheduleShift(defaultsFor: date)])
        _workplace = State(initialValue: workplace)
        _remoteDetail = State(initialValue: remoteDetail)
    }

    private var isWorkplaceOnly: Bool { mode == .workplaceOnly }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    dateField
                    if isWorkplaceOnly {
                        workplaceOnlySection
                    } else {
                        frequencyField
                        requestTypeSection
                        if showsNotesOrFiles {
                            noteField
                            attachFileField
                        } else {
                            addNotesOrFilesButton
                        }
                    }
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
            Text(isWorkplaceOnly ? "Workplace change" : "Schedule change")
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

    /// Bare — no boxed field or "Frequency" header — since the picker's own selected value
    /// ("Doesn't repeat" by default) already says what it is.
    private var frequencyField: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            .labelsHidden()

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

            dayTypeTab

            if dayType == .workday {
                toggleCard(title: "Workplace (remote ↔ on-site)", isOn: $changesWorkplace) {
                    workplaceOnlyContent
                }

                toggleCard(title: "Working hours", isOn: $changesWorkHours) {
                    workHoursContent
                }
            }
        }
    }

    /// Always-visible tab (not a toggle card) — the request always sets one or the other, so
    /// there's nothing to opt in/out of the way there is for Workplace/Working hours.
    /// Full-width, evenly split — a "Workday / Day off" label would just repeat the pills'
    /// own text.
    private var dayTypeTab: some View {
        HStack(spacing: 8) {
            ForEach(DayType.allCases) { option in
                let selected = option == dayType
                Button {
                    dayType = option
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
                    .frame(maxWidth: .infinity)
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
        }
    }

    /// Workplace pill row plus, only when Remote is selected, a second-level Home/Travel row.
    private var workplaceOnlyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            pillRow($workplace)
            if workplace == .remote {
                remoteDetailPillRow
            }
        }
    }

    /// Home/Travel sub-choice — only shown once Remote is selected (Figma 16816-594680's
    /// calendar icons are the home/travel distinction this feeds).
    private var remoteDetailPillRow: some View {
        HStack(spacing: 8) {
            ForEach(RemoteWorkplaceDetail.allCases) { option in
                let selected = option == remoteDetail
                Button {
                    remoteDetail = option
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: option.systemImage)
                            .font(.system(size: 13, weight: .semibold))
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

    private var workplaceOnlySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScheduleChangeFormField.requiredLabel("Workplace")
            workplaceOnlyContent
        }
    }

    /// A card with a title + toggle; when on, reveals `content` below it.
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

    /// Tertiary — plain text, no background — reveals the Note/File fields on tap instead of
    /// always showing two optional fields most requests don't need.
    private var addNotesOrFilesButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { showsNotesOrFiles = true }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                Text("Add notes or files")
                    .font(AppFonts.subheadStrong())
            }
            .foregroundColor(AppColors.fontSecondary)
        }
        .buttonStyle(.plain)
    }

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
                // No real file picker wired up yet.
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

    /// Whether the day currently on file is a workday or a day off — the baseline the always-
    /// visible Workday/Day off tab is compared against.
    private var baselineDayType: DayType {
        originalDay != nil ? .workday : .dayOff
    }

    /// Nothing to send until something actually differs from the day on file.
    private var hasAnyChange: Bool {
        if isWorkplaceOnly {
            return workplace != (originalDay?.workplace ?? workplace)
        }
        return dayType != baselineDayType || changesWorkplace || changesWorkHours
    }

    /// Merges whichever cards are toggled on with `oldDay` for the untouched fields — shared by
    /// the pending-request summary (`submitPendingChange`) and the read-only summary card. With
    /// no `oldDay` on file (e.g. a weekend), the form's own current hours/workplace are shown
    /// regardless of which cards are toggled — there's nothing else to fall back to.
    private func resultingSchedule(mergingWith oldDay: WorkScheduleDay?) -> (
        isDayOff: Bool, ranges: String, total: String, workplace: WorkplaceType, hourRanges: [PendingScheduleHourRange]
    ) {
        let changesWorkplaceEffective = isWorkplaceOnly ? true : changesWorkplace
        let newWorkplace = changesWorkplaceEffective ? workplace : (oldDay?.workplace ?? workplace)
        if !isWorkplaceOnly, dayType == .dayOff {
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

#Preview("Request schedule change V4") {
    RequestScheduleChangeViewV4()
}
