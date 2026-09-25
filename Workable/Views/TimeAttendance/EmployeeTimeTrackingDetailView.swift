import SwiftUI

struct EmployeeTimeTrackingDetailView: View {
    let employee: EmployeeAnomaly

    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.approvalsEnabled") private var approvalsEnabled = false
    @AppStorage(ScheduleChangeRequestUIVersion.appStorageKey) private var scheduleChangeUIVersionRaw =
        ScheduleChangeRequestUIVersion.defaultVersion.rawValue
    @AppStorage(ScheduleChangeRequestPersona.appStorageKey) private var scheduleChangePersonaRaw =
        ScheduleChangeRequestPersona.defaultPersona.rawValue
    @State private var selectedTab = 2
    @State private var selectedSubTab = 0
    @State private var showsAddTimeEntrySheet = false
    @State private var showsRequestScheduleChangeSheet = false
    @State private var showsScheduleHistory = false

    var body: some View {
        VStack(spacing: 0) {
            TimeTrackingDrillInHeader(
                title: employee.name,
                tabs: ["Information", "Time off", "Attendance"],
                selectedTab: $selectedTab,
                onBack: { dismiss() }
            ) {
                if selectedTab == 2 {
                    timeTrackingHeaderActions(
                        canRequestScheduleChange: ScheduleChangeRequestPersona.showsScheduleHeaderButton(
                            approvalsEnabled: approvalsEnabled
                        ),
                        canCreateScheduleRequest: ScheduleChangeRequestPersona.showsEmployeeRequestUI(
                            approvalsEnabled: approvalsEnabled,
                            versionRaw: scheduleChangeUIVersionRaw,
                            personaRaw: scheduleChangePersonaRaw
                        ),
                        onAddEntry: { showsAddTimeEntrySheet = true },
                        onRequestScheduleChange: { showsRequestScheduleChangeSheet = true },
                        onViewScheduleChanges: { showsScheduleHistory = true }
                    )
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
                        showsAddTimeEntrySheet: $showsAddTimeEntrySheet,
                        showsClockInFAB: false
                    )
                default: Spacer()
                }
            }
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $showsRequestScheduleChangeSheet) {
            ScheduleChangeRequestSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .navigationDestination(isPresented: $showsScheduleHistory) {
            ScheduleChangeHistoryView()
        }
    }
}
