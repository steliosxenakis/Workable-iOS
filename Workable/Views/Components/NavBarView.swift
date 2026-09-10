import SwiftUI

struct NavBarView: View {
    let title: String
    @Binding var searchText: String
    let onBack: () -> Void
    
    init(title: String, searchText: Binding<String> = .constant(""), onBack: @escaping () -> Void) {
        self.title = title
        self._searchText = searchText
        self.onBack = onBack
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title row: circular glass back + Candidates + balance
            HStack {
                GlassSymbolButton(
                    systemName: "chevron.left",
                    accessibilityLabel: "Back",
                    action: onBack
                )

                Spacer()

                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)

                Spacer()

                Color.clear
                    .frame(width: GlassSymbolButton.size, height: GlassSymbolButton.size)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            
            // Search bar
            SearchBarView(placeholder: "Search candidates", text: $searchText)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
        .background(AppColors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.separator),
            alignment: .bottom
        )
    }
}

struct SearchBarView: View {
    let placeholder: String
    @Binding var text: String
    
    init(placeholder: String, text: Binding<String> = .constant("")) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(AppColors.fontSecondary)
            
            TextField(placeholder, text: $text)
                .font(AppFonts.callout())
                .foregroundColor(AppColors.fontDefault)
        }
        .padding(10)
        .frame(height: 39)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .cornerRadius(8)
    }
}
