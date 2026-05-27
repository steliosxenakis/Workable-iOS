import SwiftUI

struct RootView: View {
    @State private var selectedTab: TabItem = .home
    private static let showsAttendanceIssuesUIKey = "settings.showAttendanceIssuesUI"
    @AppStorage(AttendanceUIVersion.appStorageKey) private var attendanceUIVersionRaw =
        AttendanceUIVersion.defaultVersion.rawValue

    private var attendanceUIVersion: AttendanceUIVersion {
        AttendanceUIVersion.resolved(from: attendanceUIVersionRaw)
    }

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
                case .inbox:
                    InboxView()
                case .settings:
                    SettingsTabView(showsAttendanceIssuesUIKey: Self.showsAttendanceIssuesUIKey)
                default:
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.attendanceUIVersion, attendanceUIVersion)

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
    @AppStorage(AttendanceUIVersion.appStorageKey) private var attendanceUIVersion =
        AttendanceUIVersion.defaultVersion.rawValue
    @AppStorage("settings.whatsAppEnabled") private var whatsAppEnabled = false
    @AppStorage("settings.surveysEnabled") private var surveysEnabled = false
    @AppStorage("settings.hideAgentConfirmations") private var hideAgentConfirmations = false

    init(showsAttendanceIssuesUIKey: String) {
        self.showsAttendanceIssuesUIKey = showsAttendanceIssuesUIKey
        _showsAttendanceIssuesUI = AppStorage(wrappedValue: true, showsAttendanceIssuesUIKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Attendance") {
                    Toggle("Show attendance UI", isOn: $showsAttendanceIssuesUI)

                    if showsAttendanceIssuesUI {
                        Picker("UI version", selection: $attendanceUIVersion) {
                            ForEach(AttendanceUIVersion.allCases) { version in
                                Text(version.rawValue).tag(version.rawValue)
                            }
                        }

                        AttendanceUIVersionSnippets(selectedVersion: $attendanceUIVersion)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16))
                            .listRowBackground(AppColors.background)
                    }
                }

                Section("Messaging") {
                    Toggle("WhatsApp", isOn: $whatsAppEnabled)
                }

                Section("Features") {
                    Toggle("Surveys", isOn: $surveysEnabled)
                }

                Section("Agent") {
                    Toggle("Hide agent confirmations", isOn: $hideAgentConfirmations)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
