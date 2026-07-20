import SwiftUI

struct RootView: View {
    @State private var selectedTab: TabItem = .home
    private static let showsAttendanceIssuesUIKey = "settings.showAttendanceIssuesUI"
    @AppStorage(AttendanceUIVersion.appStorageKey) private var attendanceUIVersionRaw =
        AttendanceUIVersion.defaultVersion.rawValue
    @AppStorage("settings.attendanceMVP") private var attendanceMVP = false
    @AppStorage("settings.attendanceNoIssues") private var attendanceNoIssues = false
    @AppStorage("settings.attendanceWorkingCase") private var attendanceWorkingCase = false
    @AppStorage("settings.attendanceTwoIssuesCase") private var attendanceTwoIssuesCase = false
    @AppStorage("settings.redesign") private var redesignEnabled = false
    @AppStorage(AttendanceNotifyStyle.appStorageKey) private var notifyStyleRaw =
        AttendanceNotifyStyle.inlineBells.rawValue

    private var attendanceUIVersion: AttendanceUIVersion {
        AttendanceUIVersion.resolved(from: attendanceUIVersionRaw)
    }

    private var notifyStyle: AttendanceNotifyStyle {
        AttendanceNotifyStyle(rawValue: notifyStyleRaw) ?? .inlineBells
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
            .environment(\.attendanceMVP, attendanceMVP)
            .environment(\.attendanceNoIssues, attendanceNoIssues)
            .environment(\.attendanceWorkingCase, attendanceWorkingCase)
            .environment(\.attendanceTwoIssuesCase, attendanceTwoIssuesCase)
            .environment(\.redesign, redesignEnabled)
            .environment(\.attendanceNotifyStyle, notifyStyle)

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
    @AppStorage("settings.redesign") private var redesignEnabled = false
    @AppStorage("settings.whatsAppEnabled") private var whatsAppEnabled = false
    @AppStorage("settings.surveysEnabled") private var surveysEnabled = false
    @AppStorage("settings.timeOffEnabled") private var timeOffEnabled = true
    @AppStorage("settings.hideAgentConfirmations") private var hideAgentConfirmations = false
    @AppStorage("settings.attendanceMVP") private var attendanceMVP = false
    @AppStorage("settings.attendanceNoIssues") private var attendanceNoIssues = false
    @AppStorage("settings.attendanceWorkingCase") private var attendanceWorkingCase = false
    @AppStorage("settings.attendanceTwoIssuesCase") private var attendanceTwoIssuesCase = false
    @AppStorage("settings.showDirectReports") private var showDirectReports = true
    @AppStorage(AttendanceNotifyStyle.appStorageKey) private var notifyStyle =
        AttendanceNotifyStyle.inlineBells.rawValue

    init(showsAttendanceIssuesUIKey: String) {
        self.showsAttendanceIssuesUIKey = showsAttendanceIssuesUIKey
        _showsAttendanceIssuesUI = AppStorage(wrappedValue: true, showsAttendanceIssuesUIKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Show attendance UI", isOn: $showsAttendanceIssuesUI)

                    if showsAttendanceIssuesUI {
                        Toggle("MVP (no notifications)", isOn: $attendanceMVP)

                        if !attendanceMVP {
                            Picker("Notify style", selection: $notifyStyle) {
                                ForEach(AttendanceNotifyStyle.allCases) { style in
                                    Text(style.rawValue).tag(style.rawValue)
                                }
                            }
                        }

                        Toggle("Direct reports", isOn: $showDirectReports)

                        Toggle("No attendance issues", isOn: $attendanceNoIssues)
                            .onChange(of: attendanceNoIssues) { enabled in
                                if enabled {
                                    attendanceWorkingCase = false
                                    attendanceTwoIssuesCase = false
                                }
                            }

                        Toggle("With issues", isOn: $attendanceWorkingCase)
                            .onChange(of: attendanceWorkingCase) { enabled in
                                if enabled {
                                    attendanceNoIssues = false
                                    attendanceTwoIssuesCase = false
                                }
                            }

                        Toggle("Two issues", isOn: $attendanceTwoIssuesCase)
                            .onChange(of: attendanceTwoIssuesCase) { enabled in
                                if enabled {
                                    attendanceNoIssues = false
                                    attendanceWorkingCase = false
                                }
                            }

                        Picker("UI version", selection: $attendanceUIVersion) {
                            ForEach(AttendanceUIVersion.allCases) { version in
                                Text(version.rawValue).tag(version.rawValue)
                            }
                        }

                        DisclosureGroup("UI version previews") {
                            AttendanceUIVersionSnippets(selectedVersion: $attendanceUIVersion)
                                .padding(.top, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

                Section {
                    Toggle("Redesign", isOn: $redesignEnabled)
                }

                Section {
                    Toggle("WhatsApp", isOn: $whatsAppEnabled)
                }

                Section {
                    Toggle("Surveys", isOn: $surveysEnabled)
                }

                Section {
                    Toggle("Time off", isOn: $timeOffEnabled)
                }

                Section {
                    Toggle("Hide agent confirmations", isOn: $hideAgentConfirmations)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
