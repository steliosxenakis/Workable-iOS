import SwiftUI

struct SelectJobSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private struct JobOption: Identifiable {
        let id = UUID()
        let title: String
        let details: String
    }

    private let jobs: [JobOption] = [
        JobOption(title: "Principal Software Engineer", details: "Engineering \u{00B7} Remote \u{00B7} Boston / Athens / Rome / Paris..."),
        JobOption(title: "Account manager", details: "Accounting \u{00B7} Hybrid \u{00B7} Athens, Attiki, Greece"),
        JobOption(title: "Billing Analyst", details: "Accounting \u{00B7} On-site \u{00B7} Athens, Attiki, Greece"),
    ]

    private var filteredJobs: [JobOption] {
        guard !searchText.isEmpty else { return jobs }
        return jobs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.details.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredJobs) { job in
                            Button {
                                dismiss()
                            } label: {
                                jobRow(job)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .background(AppColors.surface)
            .navigationTitle("Select job")
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

    private func jobRow(_ job: JobOption) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)

                Text(job.details)
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()
                .padding(.leading, 16)
        }
    }
}

#Preview {
    SelectJobSheet()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.surface)
}
