import SwiftUI

/// Full-screen attendance anomalies list (filters + grouped employees). Previously the “Attendance” tab inside day detail.
struct AttendanceAnomaliesStandaloneView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFieldFocused: Bool
    @State private var selectedFilters: Set<AnomalyFilterCategory>
    @State private var selectedDepartment: String?
    @State private var selectedEntity: String?
    @State private var searchText = ""
    @State private var showSearchRow = false

    private let employees = TimeAttendanceMockData.employees

    private let directReportNames = Set(["Doe, Joanne", "Gutmann, Elyssa", "Carty, Joe"])

    init(initialFilters: Set<AnomalyFilterCategory> = []) {
        _selectedFilters = State(initialValue: initialFilters)
    }

    private var eligibleEmployees: [EmployeeAnomaly] {
        employees.filter { !$0.hasScheduleIcon }
    }

    private var filterCounts: [AnomalyFilterCategory: Int] {
        var counts: [AnomalyFilterCategory: Int] = [:]
        for category in AnomalyFilterCategory.allCases {
            counts[category] = eligibleEmployees.filter { category.matchingTypes.contains($0.anomalyType) }.count
        }
        return counts
    }

    private var filteredEmployees: [EmployeeAnomaly] {
        var result = eligibleEmployees.filtered(by: selectedFilters, department: selectedDepartment, entity: selectedEntity)
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.role.lowercased().contains(query)
            }
        }
        return result
    }

    private var directReportEmployees: [EmployeeAnomaly] {
        filteredEmployees.filter { directReportNames.contains($0.name) }
    }

    private var otherEmployees: [EmployeeAnomaly] {
        filteredEmployees.filter { !directReportNames.contains($0.name) }
    }

    var body: some View {
        content
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
                    Text("Attendance")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchRow = true
                        }
                        isSearchFieldFocused = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search")

                    Menu {
                        DepartmentEntityFilterMenuContent(
                            selectedDepartment: $selectedDepartment,
                            selectedEntity: $selectedEntity
                        )
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    .accessibilityLabel("Filters")
                }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            AnomalyFilterBar(
                selectedFilters: $selectedFilters,
                searchText: $searchText,
                searchFieldFocused: $isSearchFieldFocused,
                filterCounts: filterCounts,
                isSearchRowVisible: showSearchRow
            )
            .animation(.easeInOut(duration: 0.2), value: showSearchRow)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !directReportEmployees.isEmpty {
                        employeeSection(title: "Direct reports", employees: directReportEmployees)
                    }
                    if !otherEmployees.isEmpty {
                        employeeSection(title: "Other employees", employees: otherEmployees)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private func employeeSection(title: String, employees: [EmployeeAnomaly]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.08)

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(employees.enumerated()), id: \.element.id) { index, employee in
                    NavigationLink(destination: EmployeeTimeTrackingDetailView(employee: employee)) {
                        EmployeeAnomalyRow(employee: employee)
                    }
                    .buttonStyle(.plain)
                    if index < employees.count - 1 {
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(16)
        }
    }
}
