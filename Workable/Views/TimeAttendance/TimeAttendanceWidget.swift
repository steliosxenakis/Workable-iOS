import SwiftUI

struct TimeAttendanceWidget: View {
    let summaryItems: [AnomalySummaryItem]
    @State private var selectedItem: AnomalySummaryItem?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                AnomalySummaryTagsView(items: summaryItems, pillBackground: AppColors.surface) { item in
                    selectedItem = item
                }

                NavigationLink {
                    AttendanceAnomaliesStandaloneView()
                } label: {
                    VStack(spacing: 2) {
                        Text("View")
                            .font(AppFonts.caption1())
                        Text("all")
                            .font(AppFonts.headline())
                    }
                    .foregroundColor(AppColors.fontSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .fixedSize()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationDestination(item: $selectedItem) { item in
            AttendanceAnomaliesStandaloneView(initialFilters: item.matchingFilters)
        }
    }
}
