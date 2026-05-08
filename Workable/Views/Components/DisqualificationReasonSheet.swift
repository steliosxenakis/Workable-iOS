import SwiftUI

struct DisqualificationReasonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var addNote = false

    private let reasons: [(section: String, items: [String])] = [
        ("Candidate rejected", [
            "Doesn\u{2019}t meet job requirements",
            "Doesn\u{2019}t have required experience",
            "Doesn\u{2019}t match job location",
            "Area of speciality doesn\u{2019}t match job",
            "Job no longer receiving applications",
            "Other candidate is more suitable",
            "Salary expectations too high",
            "Unsuccessful interview",
        ]),
    ]

    private var filteredReasons: [(section: String, items: [String])] {
        guard !searchText.isEmpty else { return reasons }
        return reasons.compactMap { section in
            let filtered = section.items.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
            return filtered.isEmpty ? nil : (section.section, filtered)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                addNoteRow
                    .padding(.horizontal, 16)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(filteredReasons, id: \.section) { section in
                            Section {
                                ForEach(section.items, id: \.self) { reason in
                                    Button {
                                        dismiss()
                                    } label: {
                                        reasonRow(reason)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                sectionHeader(section.section)
                            }
                        }
                    }
                }
            }
            .background(AppColors.surface)
            .navigationTitle("Disqualification reason")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.primaryDark)
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.fontSecondary)
                .font(.system(size: 15))

            TextField("Search", text: $searchText)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var addNoteRow: some View {
        HStack {
            Text("Add note")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
            Spacer()
            Toggle("", isOn: $addNote)
                .labelsHidden()
                .tint(AppColors.successDefault)
        }
        .padding(.vertical, 12)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.footnote())
                .foregroundColor(AppColors.fontSecondary)
                .textCase(nil)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.surface)
    }

    private func reasonRow(_ reason: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(reason)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.fontSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            Divider()
                .padding(.leading, 16)
        }
    }
}

#Preview {
    DisqualificationReasonSheet()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.surface)
}
