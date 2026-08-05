import SwiftUI

struct EmployeeTimeTrackingDetailView: View {
    let employee: EmployeeAnomaly

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 2
    @State private var selectedSubTab = 0
    @State private var showsAddTimeEntrySheet = false

    var body: some View {
        VStack(spacing: 0) {
            TimeTrackingDrillInHeader(
                title: employee.name,
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
