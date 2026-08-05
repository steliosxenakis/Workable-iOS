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

/// Liquid-glass floating tab bar (Figma 15629-634787).
struct TabBarView: View {
    @Binding var selectedTab: TabItem
    @Namespace private var selectionNamespace

    /// Outer chrome height including top/bottom padding (FABs / content insets).
    static let barHeight: CGFloat = 95
    /// Glass capsule height (tab items).
    static let menuHeight: CGFloat = 54
    /// Home-indicator padding below the glass capsule.
    static let menuBottomPadding: CGFloat = 25
    /// Distance from the screen bottom to the top of the glass menu.
    static var menuTopFromBottom: CGFloat { menuBottomPadding + menuHeight }

    private let selectionSpring = Animation.spring(response: 0.38, dampingFraction: 0.82)

    var body: some View {
        HStack(spacing: -8) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarItemView(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    selectionNamespace: selectionNamespace
                ) {
                    withAnimation(selectionSpring) {
                        selectedTab = tab
                    }
                }
                .frame(width: 75)
            }
        }
        .padding(.horizontal, 2)
        .background {
            Capsule(style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.interactive())
                .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
                .padding(-4)
        }
        .padding(.horizontal, 25)
        .padding(.top, 16)
        .padding(.bottom, Self.menuBottomPadding)
        .frame(maxWidth: .infinity)
    }
}

struct TabBarItemView: View {
    let tab: TabItem
    let isSelected: Bool
    var selectionNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: isSelected ? 1 : 0.5) {
                Image(tab.assetIcon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontDefault)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(isSelected ? -0.1 : 0)
                    .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontDefault)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 7)
            .frame(height: 54)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color(hex: "EDEDED"))
                        .padding(.horizontal, -2)
                        .matchedGeometryEffect(id: "tabSelection", in: selectionNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppColors.background.ignoresSafeArea()
        TabBarView(selectedTab: .constant(.home))
    }
}
