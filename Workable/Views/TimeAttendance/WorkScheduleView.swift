import SwiftUI

/// Weekly breakdown opened from the "Today's work schedule" banner on the Time tracking →
/// List view (Figma 3609-84050). Approvals v2 (Settings → Approvals): each day row is
/// tappable and opens the request-change form preselected/prefilled for that day
/// (Figma Scopes 486-16581 / Playground 506-68166).
struct WorkScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.approvalsEnabled") private var approvalsEnabled = false

    @State private var requestDay: WorkScheduleDay?
    @State private var didSendRequest = false

    var body: some View {
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
        }
        .background(AppColors.surface)
        .sheet(item: $requestDay) { day in
            RequestScheduleChangeView(
                date: day.date(),
                shifts: day.shifts.map { EditableWorkScheduleShift(day: day.date(), start: $0.start, end: $0.end) },
                onSend: {
                    requestDay = nil
                    withAnimation { didSendRequest = true }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
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
            Text("Work schedule")
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
        .background(AppColors.surfaceDarker)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Approvals v2: when enabled, tapping a day opens the request form preselected for it.
    private func dayRow(_ day: WorkScheduleDay) -> some View {
        Group {
            if approvalsEnabled {
                Button {
                    requestDay = day
                } label: {
                    dayRowLabel(day, showsChevron: true)
                }
                .buttonStyle(.plain)
            } else {
                dayRowLabel(day, showsChevron: false)
            }
        }
    }

    private func dayRowLabel(_ day: WorkScheduleDay, showsChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(day.weekday)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
                .frame(width: 92, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(day.rangesText)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                Text("(\(day.totalText))")
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.fontSecondary)
            }

            Spacer(minLength: 0)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.iconInactive)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Request a schedule change (Figma Scopes 486-16581 / 506-67295 / Playground 506-68166)

/// Wireframe request form — mirrors the web "Request a schedule change" drawer:
/// Date, Day type, Working hours (one or more shifts), Workplace, Note, Attach file.
struct RequestScheduleChangeView: View {
    @Environment(\.dismiss) private var dismiss

    /// Called once the (mock) request is "sent" — the caller dismisses this sheet.
    var onSend: () -> Void = {}

    @State private var date: Date
    @State private var dayType: DayType
    @State private var shifts: [EditableWorkScheduleShift]
    @State private var workplace: WorkplaceType
    @State private var note = ""

    init(
        date: Date = Date(),
        dayType: DayType = .workday,
        shifts: [EditableWorkScheduleShift]? = nil,
        workplace: WorkplaceType = .onSite,
        onSend: @escaping () -> Void = {}
    ) {
        self.onSend = onSend
        _date = State(initialValue: date)
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

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 4) {
            requiredLabel("Date")

            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.fontDefault)
        }
    }

    private var dayTypeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            requiredLabel("Day type")

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
            requiredLabel("Working hours")

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
            requiredLabel("Workplace")

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

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(AppColors.surface)
    }

    private func requiredLabel(_ title: String) -> some View {
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
}

private extension EditableWorkScheduleShift {
    /// Builds a shift on `day` from "HH:mm" time strings (Work schedule mock data).
    init(day: Date, start: String, end: String) {
        self.init(
            start: Self.time(start, on: day),
            end: Self.time(end, on: day)
        )
    }

    /// A default 09:00–18:00 shift on the given day (blank "Add another day" case).
    init(defaultsFor day: Date) {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
        let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
        self.init(start: start, end: end)
    }

    private static func time(_ text: String, on day: Date) -> Date {
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return day }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day) ?? day
    }
}

#Preview("Work schedule") {
    WorkScheduleView()
}

#Preview("Request schedule change") {
    RequestScheduleChangeView()
}
