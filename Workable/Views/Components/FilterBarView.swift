import SwiftUI

enum CandidateSortOption: String, CaseIterable, Identifiable {
    case newestFirst = "Newest first"
    case oldestFirst = "Oldest first"
    case aiStatusAndScore = "AI status & score"

    var id: String { rawValue }
}

struct FilterBarView: View {
    @State private var showFilters = false
    @Binding var selectedSort: CandidateSortOption
    var resultsCount: Int = 136
    
    var body: some View {
        HStack {
            Menu {
                ForEach(CandidateSortOption.allCases) { option in
                    Button {
                        selectedSort = option
                    } label: {
                        if selectedSort == option {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.fontSecondary)
                    Text(selectedSort.rawValue)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontSecondary)
                }
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
