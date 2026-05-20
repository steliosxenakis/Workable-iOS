import SwiftUI

/// Direct reports list — [Figma 15276-14308](https://www.figma.com/design/N4rPYxlp1AxdJWGSghlQXP/%F0%9F%93%B1-Time-tracking?node-id=15276-14308)
struct DirectReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.showAttendanceIssuesUI") private var showsAttendanceIssuesUI = true

    private let people = TimeAttendanceMockData.directReportsInFigmaOrder

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(people.enumerated()), id: \.element.id) { index, employee in
                    NavigationLink {
                        EmployeeTimeTrackingDetailView(employee: employee)
                    } label: {
                        DirectReportRow(employee: employee, showAnomalyPills: showsAttendanceIssuesUI)
                    }
                    .buttonStyle(.plain)

                    if index < people.count - 1 {
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
                Text("Direct reports")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
            }
        }
    }
}

// MARK: - Row (avatar, name, role; optional calendar badge — Figma)

private struct DirectReportRow: View {
    @Environment(\.attendanceUIVersion) private var attendanceUIVersion
    let employee: EmployeeAnomaly
    var showAnomalyPills: Bool = true

    private var showCalendarBadge: Bool {
        employee.hasScheduleIcon
    }

    var body: some View {
        Group {
            if attendanceUIVersion.usesV4EmployeeCardStatus {
                v4RowBody
            } else {
                legacyRowBody
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private var v4RowBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                avatarStack
                VStack(alignment: .leading, spacing: 4) {
                    Text(employee.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.41)
                    Text(employee.role)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.fontSecondary)
                        .tracking(-0.24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showAnomalyPills {
                EmployeeAnomalyV4IssueBanner(employee: employee)
            }
        }
    }

    private var legacyRowBody: some View {
        HStack(alignment: .top, spacing: 12) {
            avatarStack

            VStack(alignment: .leading, spacing: 6) {
                Text(employee.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                Text(employee.role)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)

                if showAnomalyPills {
                    if attendanceUIVersion.usesProgressBarEmployeeStatus {
                        EmployeeAnomalyProgressStatus(employee: employee)
                    } else {
                        EmployeeAnomalyStatusPills(employee: employee)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var avatarStack: some View {
        ZStack(alignment: .bottomTrailing) {
            avatar
            if showCalendarBadge {
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(AppColors.fontDefault)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.surface, lineWidth: 0.5))
                    .offset(x: 4, y: 4)
            }
        }
        .frame(width: 50, height: 50)
    }

    private var avatar: some View {
        Group {
            if let name = employee.avatarName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color(hex: "E8E8ED"))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.iconDefault)
                }
            }
        }
    }
}
