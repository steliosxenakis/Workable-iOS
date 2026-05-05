import SwiftUI

/// Compatibility shim — always presents standalone attendance (no Events/Celebrations/On leave tabs, title “Attendance”).
struct TimeAttendanceAnomaliesListView: View {
    private let initialFilters: Set<AnomalyFilterCategory>

    init(initialFilters: Set<AnomalyFilterCategory> = []) {
        self.initialFilters = initialFilters
    }

    var body: some View {
        AttendanceAnomaliesStandaloneView(initialFilters: initialFilters)
    }
}
