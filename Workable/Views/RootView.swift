import SwiftUI

struct RootView: View {
    @State private var selectedTab: TabItem = .home
    private static let showsAttendanceIssuesUIKey = "settings.showAttendanceIssuesUI"

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .jobs:
                    NavigationStack {
                        CandidatesBrowserView()
                    }
                case .settings:
                    SettingsTabView(showsAttendanceIssuesUIKey: Self.showsAttendanceIssuesUIKey)
                default:
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(AppColors.background)
    }
}

#Preview {
    RootView()
}

private struct SettingsTabView: View {
    let showsAttendanceIssuesUIKey: String
    @AppStorage private var showsAttendanceIssuesUI: Bool

    init(showsAttendanceIssuesUIKey: String) {
        self.showsAttendanceIssuesUIKey = showsAttendanceIssuesUIKey
        _showsAttendanceIssuesUI = AppStorage(wrappedValue: true, showsAttendanceIssuesUIKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Attendance") {
                    Toggle("Show attendance UI", isOn: $showsAttendanceIssuesUI)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
