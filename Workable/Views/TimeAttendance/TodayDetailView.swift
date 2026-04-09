import SwiftUI

struct TodayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int
    @State private var selectedFilters: Set<AnomalyFilterCategory>
    @State private var selectedDepartment: String?
    @State private var selectedEntity: String?
    @State private var searchText = ""

    private let tabs = ["Events", "Celebrations", "On leave", "Time & Attendance"]
    private let employees = TimeAttendanceMockData.employees

    init(initialTab: Int = 0, initialFilters: Set<AnomalyFilterCategory> = []) {
        _selectedTab = State(initialValue: initialTab)
        _selectedFilters = State(initialValue: initialFilters)
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            Group {
                switch selectedTab {
                case 0:  eventsTab
                case 1:  celebrationsTab
                case 2:  onLeaveTab
                case 3:  timeTrackingTab
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
                Text("6 January 2024")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {} label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primaryDark)
                }
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

    // MARK: - Events Tab

    private var eventsTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                eventRow(title: "Call with John Doe",             time: "10:30 - 11:00", subtitle: "Software Engineer")
                Rectangle().fill(AppColors.separator).frame(height: 1)
                eventRow(title: "Interview with Elissa McArthur", time: "9:30 - 10:00",  subtitle: "Product Designer")
            }
            .padding(.top, 8)
        }
    }

    private func eventRow(title: String, time: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Text("\(time) · \(subtitle)")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.iconDefault)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Celebrations Tab

    private var celebrationsTab: some View {
        ScrollView {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hex: "F8ECEB"))
                        .frame(width: 36, height: 36)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "E9756D"))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Birthdays")
                        .font(AppFonts.footnote())
                        .foregroundColor(AppColors.fontSecondary)
                    Text("Doe, John +2")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontDefault)
                }
                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - On Leave Tab

    private var onLeaveTab: some View {
        ScrollView {
            HStack {
                Text("No employees on leave")
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Time Tracking Tab

    private var filteredEmployees: [EmployeeAnomaly] {
        var result = employees.filtered(by: selectedFilters, department: selectedDepartment, entity: selectedEntity)
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.role.lowercased().contains(query)
            }
        }
        return result
    }

    private var timeTrackingTab: some View {
        VStack(spacing: 0) {
            AnomalyFilterBar(selectedFilters: $selectedFilters, selectedDepartment: $selectedDepartment, selectedEntity: $selectedEntity, searchText: $searchText)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.iconDefault)
                TextField("Search employees", text: $searchText)
                    .font(AppFonts.body())
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.iconDefault)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(AppColors.lightBackground)
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface)

            TimeAttendanceAnomaliesListContent(
                employees: filteredEmployees
            )
            .padding(.horizontal, 16)
        }
    }
}
