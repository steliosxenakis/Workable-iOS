import SwiftUI

struct EmployeeTimeTrackingDetailView: View {
    let employee: EmployeeAnomaly

    @Environment(\.dismiss) private var dismiss
    @Environment(\.attendanceUIVersion) private var attendanceUIVersion
    @State private var selectedTab = 2
    @State private var selectedSubTab = 0

    private var tabs: [String] {
        let timeLabel = attendanceUIVersion.usesModernAttendanceChrome ? "Attendance" : "Time tracking"
        return ["Information", "Time off", timeLabel]
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Group {
                switch selectedTab {
                case 0: placeholderTab("Information")
                case 1: placeholderTab("Time off")
                case 2: TimeTrackingWeekCalendarContent(selectedSubTab: $selectedSubTab)
                default: Spacer()
                }
            }
        }
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
                Text(employee.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index } } label: {
                        VStack(spacing: 8) {
                            Text(title)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(selectedTab == index ? AppColors.primaryDark : AppColors.fontSecondary)
                                .padding(.horizontal, 16)
                            Rectangle()
                                .fill(selectedTab == index ? AppColors.primaryDark : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Placeholder

    private func placeholderTab(_ title: String) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontSecondary)
            Spacer()
        }
    }
}
