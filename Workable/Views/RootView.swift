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
    @AppStorage(BreakSupportUIVersion.enabledAppStorageKey) private var breakSupportEnabled = true
    @AppStorage(BreakSupportUIVersion.appStorageKey) private var breakSupportUIVersionRaw =
        BreakSupportUIVersion.defaultVersion.rawValue
    @AppStorage(BreakSupportUIVersion.nestedInTimeEntryAppStorageKey) private var breaksNestedInTimeEntry = false

    private var attendanceUIVersion: AttendanceUIVersion {
        AttendanceUIVersion.resolved(from: attendanceUIVersionRaw)
    }

    private var notifyStyle: AttendanceNotifyStyle {
        AttendanceNotifyStyle(rawValue: notifyStyleRaw) ?? .inlineBells
    }

    private var breakSupportUIVersion: BreakSupportUIVersion {
        BreakSupportUIVersion.resolved(from: breakSupportUIVersionRaw)
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
            .environment(\.breakSupportEnabled, breakSupportEnabled)
            .environment(\.breakSupportUIVersion, breakSupportUIVersion)
            .environment(\.breaksNestedInTimeEntry, breaksNestedInTimeEntry && breakSupportEnabled)

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
    @AppStorage("settings.redesign") private var redesignEnabled = false
    @AppStorage("settings.whatsAppEnabled") private var whatsAppEnabled = false
    @AppStorage("settings.surveysEnabled") private var surveysEnabled = false
    @AppStorage("settings.timeOffEnabled") private var timeOffEnabled = true
    @AppStorage("settings.hideAgentConfirmations") private var hideAgentConfirmations = false
    @AppStorage(BreakSupportUIVersion.enabledAppStorageKey) private var breakSupportEnabled = true
    @AppStorage(BreakSupportUIVersion.appStorageKey) private var breakSupportUIVersion =
        BreakSupportUIVersion.defaultVersion.rawValue
    @AppStorage(BreakSupportUIVersion.nestedInTimeEntryAppStorageKey) private var breaksNestedInTimeEntry = false

    init(showsAttendanceIssuesUIKey: String) {
        self.showsAttendanceIssuesUIKey = showsAttendanceIssuesUIKey
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        AttendanceSettingsView(showsAttendanceIssuesUIKey: showsAttendanceIssuesUIKey)
                    } label: {
                        Text("Attendance")
                    }
                }

                Section {
                    Toggle("Break support", isOn: $breakSupportEnabled)

                    Picker("UI version", selection: $breakSupportUIVersion) {
                        ForEach(BreakSupportUIVersion.allCases) { version in
                            Text(version.rawValue).tag(version.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!breakSupportEnabled)
                    .onChange(of: breakSupportUIVersion) { _, _ in
                        // Picking a version implies you want break UI on.
                        if !breakSupportEnabled {
                            breakSupportEnabled = true
                        }
                    }

                    ForEach(BreakSupportUIVersion.allCases) { version in
                        let selected = BreakSupportUIVersion.resolved(from: breakSupportUIVersion) == version
                        Button {
                            breakSupportUIVersion = version.rawValue
                            breakSupportEnabled = true
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(
                                        selected && breakSupportEnabled
                                            ? AppColors.primaryDark
                                            : AppColors.iconInactive
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(version.rawValue)
                                        .font(AppFonts.subheadStrong())
                                        .foregroundColor(AppColors.fontDefault)
                                    Text(version.caption)
                                        .font(AppFonts.caption1())
                                        .foregroundColor(AppColors.fontSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                        .opacity(breakSupportEnabled ? 1 : 0.55)
                    }

                    Toggle("Breaks inside start / end", isOn: $breaksNestedInTimeEntry)
                        .disabled(!breakSupportEnabled)
                        .onChange(of: breaksNestedInTimeEntry) { _, enabled in
                            if enabled, !breakSupportEnabled {
                                breakSupportEnabled = true
                            }
                        }
                } header: {
                    Text("Break support (PROD-82468)")
                } footer: {
                    Text("V1–V13 change the home widget. “Breaks inside start / end” nests break rows between start and end on the time entry detail and edit screens.")
                }

                Section {
                    Toggle("Redesign", isOn: $redesignEnabled)
                    Toggle("WhatsApp", isOn: $whatsAppEnabled)
                    Toggle("Surveys", isOn: $surveysEnabled)
                    Toggle("Time off", isOn: $timeOffEnabled)
                    Toggle("Hide agent confirmations", isOn: $hideAgentConfirmations)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                let resolved = BreakSupportUIVersion.resolved(from: breakSupportUIVersion)
                if breakSupportUIVersion != resolved.rawValue {
                    breakSupportUIVersion = resolved.rawValue
                }
            }
        }
    }
}

private struct AttendanceSettingsView: View {
    let showsAttendanceIssuesUIKey: String
    @AppStorage private var showsAttendanceIssuesUI: Bool
    @AppStorage(AttendanceUIVersion.appStorageKey) private var attendanceUIVersion =
        AttendanceUIVersion.defaultVersion.rawValue
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
        Form {
            Section {
                Toggle("Show attendance UI", isOn: $showsAttendanceIssuesUI)
            }

            if showsAttendanceIssuesUI {
                Section {
                    Toggle("MVP (no notifications)", isOn: $attendanceMVP)

                    if !attendanceMVP {
                        Picker("Notify style", selection: $notifyStyle) {
                            ForEach(AttendanceNotifyStyle.allCases) { style in
                                Text(style.rawValue).tag(style.rawValue)
                            }
                        }
                    }

                    Toggle("Direct reports", isOn: $showDirectReports)
                }

                Section("Preview cases") {
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
                }

                Section {
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
        }
        .navigationTitle("Attendance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
