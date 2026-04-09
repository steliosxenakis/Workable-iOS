import SwiftUI

enum TabItem: String, CaseIterable {
    case home = "Home"
    case jobs = "Jobs"
    case employees = "Employees"
    case inbox = "Inbox"
    case settings = "Settings"
    
    var assetIcon: String {
        switch self {
        case .home: return "tab-home"
        case .jobs: return "tab-jobs"
        case .employees: return "tab-employees"
        case .inbox: return "tab-inbox"
        case .settings: return "tab-settings"
        }
    }
}

struct TabBarView: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarItemView(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 83)
        .background(AppColors.surfaceDarker)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.separator),
            alignment: .top
        )
    }
}

struct TabBarItemView: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(tab.assetIcon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.iconDefault)
                
                Text(tab.rawValue)
                    .font(AppFonts.tabBar())
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.iconDefault)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
    }
}
