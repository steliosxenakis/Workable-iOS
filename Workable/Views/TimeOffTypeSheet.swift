import SwiftUI

enum TimeOffType: String, CaseIterable, Identifiable, Hashable {
    case paidTimeOff = "Paid time off"
    case unpaidTimeOff = "Unpaid time off"
    case sickLeave = "Sick leave"
    case parental = "Parental"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .paidTimeOff:   return Color(hex: "F8D8AB")
        case .unpaidTimeOff: return Color(hex: "A7C3FA")
        case .sickLeave:     return Color(hex: "F6C8FB")
        case .parental:      return Color(hex: "E1E6EB")
        }
    }

    var availableDays: Int {
        switch self {
        case .paidTimeOff:   return 3
        case .unpaidTimeOff: return 0
        case .sickLeave:     return 5
        case .parental:      return 10
        }
    }
}

// MARK: - Flow entry

struct TimeOffRequestSheet: View {
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        NavigationStack {
            TimeOffTypePickerView(onClose: dismissSheet)
                .navigationDestination(for: TimeOffType.self) { type in
                    AddTimeOffEntryView(selectedType: type, onClose: dismissSheet)
                }
        }
    }
}

// Backward-compatible alias
typealias TimeOffTypeSheet = TimeOffRequestSheet

// MARK: - Type picker (Figma 16370-46614)

private struct TimeOffTypePickerView: View {
    var onClose: DismissAction

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader(title: "Time-off type") { onClose() }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(TimeOffType.allCases) { type in
                        NavigationLink(value: type) {
                            typeRow(type)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
    }

    private func typeRow(_ type: TimeOffType) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Color.clear
                    .frame(width: 16, height: 16)

                Text(type.rawValue)
                    .font(.system(size: 17))
                    .foregroundColor(AppColors.fontDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)

                timeOffColorSwatch(type.color)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Divider()
                .padding(.top, 24)
        }
    }
}

// MARK: - Add entry form (Figma 16370-46545)

private struct AddTimeOffEntryView: View {
    let selectedType: TimeOffType
    var onClose: DismissAction
    @Environment(\.dismiss) private var popToTypePicker
    @State private var startDate = TimeOffMockDates.firstAllowedRequestDate
    @State private var endDate = TimeOffMockDates.firstAllowedRequestDate
    @State private var note = ""

    private var isRequestDateValid: Bool {
        let calendar = Calendar.current
        let allowed = calendar.startOfDay(for: TimeOffMockDates.firstAllowedRequestDate)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return start >= allowed && end >= allowed
    }

    private var requestedDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let daySpan = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(daySpan + 1, 1)
    }

    private var remainingDays: Int {
        max(selectedType.availableDays - requestedDays, 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader(title: "Add time entry") { onClose() }

            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    probationBanner

                    typeField

                    dateField(title: "Start date", selection: $startDate)
                    dateField(title: "End date", selection: $endDate)

                    noteField
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }

            footer
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
        .onChange(of: startDate) { newStart in
            if endDate < newStart { endDate = newStart }
        }
    }

    private var probationBanner: some View {
        Text("You are currently on probation until May 31, 2026. You can request time off starting from June 1, 2026.")
            .font(.system(size: 15))
            .foregroundColor(AppColors.fontDefault)
            .tracking(-0.24)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.warningBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var typeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type")
                .font(.system(size: 13))
                .foregroundColor(AppColors.fontDefault)

            Button { popToTypePicker() } label: {
                HStack(spacing: 8) {
                    timeOffColorSwatch(selectedType.color)

                    Text(selectedType.rawValue)
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.fontDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.fontSecondary)
                }
            }
            .buttonStyle(.plain)

            Divider()

            Text("Currently \(selectedType.availableDays) days available.")
                .font(.system(size: 13))
                .foregroundColor(AppColors.fontSecondary)
        }
    }

    private func dateField(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(AppColors.fontDefault)

            DatePicker(
                "",
                selection: selection,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AppColors.fontDefault)
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            (Text("Note") + Text(" (Optional)").foregroundColor(AppColors.fontSecondary))
                .font(.system(size: 13))
                .foregroundColor(AppColors.fontDefault)

            TextField("", text: $note, axis: .vertical)
                .font(.system(size: 17))
                .foregroundColor(AppColors.fontDefault)
                .lineLimit(1...4)

            Divider()
        }
    }

    private var footer: some View {
        VStack(spacing: 16) {
            if isRequestDateValid {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You're requesting \(requestedDays) day\(requestedDays == 1 ? "" : "s") off.")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.fontDefault)

                    Text("You'll have \(remainingDays) days of \(selectedType.rawValue.lowercased()) remaining.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppColors.informativeBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button { onClose() } label: {
                Text("Request time off")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isRequestDateValid ? .white : AppColors.iconDefault)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(isRequestDateValid ? AppColors.primary : AppColors.separator)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .disabled(!isRequestDateValid)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(AppColors.surface)
    }
}

// MARK: - Shared

private enum TimeOffMockDates {
    /// Earliest date employees on probation can request time off from.
    static var firstAllowedRequestDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }
}

private func sheetHeader(title: String, onClose: @escaping () -> Void) -> some View {
    HStack {
        GlassSymbolButton(
            systemName: "xmark",
            fontWeight: .medium,
            accessibilityLabel: "Close",
            action: onClose
        )
        .frame(width: 85, alignment: .leading)

        Spacer(minLength: 0)

        Text("Cancel")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AppColors.primaryDark)
            .opacity(0)
            .frame(width: 85, alignment: .trailing)
    }
    .overlay {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AppColors.fontDefault)
    }
    .padding(16)
    .background(AppColors.surface)
    .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
}

private func timeOffColorSwatch(_ color: Color) -> some View {
    RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(color)
        .frame(width: 18, height: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 1)
        )
}
