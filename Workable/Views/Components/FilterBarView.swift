import SwiftUI

struct FilterBarView: View {
    @State private var showFilters = false
    var resultsCount: Int = 136
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.fontSecondary)
                Text("Newest first")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontSecondary)
            }
            
            Spacer()
            
            Button {
                showFilters = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.fontSecondary)
                    Text("Filters")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontSecondary)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showFilters) {
                FiltersOverlayView(resultsCount: resultsCount)
                    .presentationCornerRadius(20)
                    .presentationBackground(AppColors.surface)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.separator),
            alignment: .bottom
        )
    }
}
