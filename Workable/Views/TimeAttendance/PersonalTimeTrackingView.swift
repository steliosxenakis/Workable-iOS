import SwiftUI

struct PersonalTimeTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.attendanceUIVersion) private var attendanceUIVersion
    @State private var selectedSubTab = 0

    private var navigationTitle: String {
        attendanceUIVersion.usesModernAttendanceChrome ? "Attendance" : "Time tracking"
    }

    var body: some View {
        TimeTrackingWeekCalendarContent(selectedSubTab: $selectedSubTab)
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(AppColors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(AppFonts.body())
                        }
                        .foregroundColor(AppColors.primaryDark)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(navigationTitle)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                }
            }
    }
}
