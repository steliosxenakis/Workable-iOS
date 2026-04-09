import SwiftUI

struct PersonalTimeTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSubTab = 0

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
                    Text("Time tracking")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                }
            }
    }
}
