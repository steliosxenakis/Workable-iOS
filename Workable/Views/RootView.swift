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
        AttendanceNotifyStyle.final.rawValue
    @AppStorage(BreakSupportUIVersion.enabledAppStorageKey) private var breakSupportEnabled = true
    @AppStorage(BreakSupportUIVersion.appStorageKey) private var breakSupportUIVersionRaw =
        BreakSupportUIVersion.defaultVersion.rawValue
    @AppStorage(BreakSupportUIVersion.nestedInTimeEntryAppStorageKey) private var breaksNestedInTimeEntry = false

    private var attendanceUIVersion: AttendanceUIVersion {
        AttendanceUIVersion.resolved(from: attendanceUIVersionRaw)
    }

    private var notifyStyle: AttendanceNotifyStyle {
        AttendanceNotifyStyle(rawValue: notifyStyleRaw) ?? .final
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
        .onOpenURL { url in
            guard let destination = WidgetDeepLink.destination(for: url) else { return }
            switch destination {
            case .home:
                selectedTab = .home
            case .timeOff:
                // Personal time-off requests surface in Inbox until there's a
                // dedicated time-off tab.
                selectedTab = .inbox
            case .recruiting:
                selectedTab = .jobs
            }
        }
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
    @AppStorage("settings.approvalsEnabled") private var approvalsEnabled = false
    @AppStorage("settings.hideAgentConfirmations") private var hideAgentConfirmations = false
    @AppStorage(BreakSupportUIVersion.enabledAppStorageKey) private var breakSupportEnabled = true
    @AppStorage(BreakSupportUIVersion.appStorageKey) private var breakSupportUIVersion =
        BreakSupportUIVersion.defaultVersion.rawValue
    @AppStorage(BreakSupportUIVersion.nestedInTimeEntryAppStorageKey) private var breaksNestedInTimeEntry = false
    @AppStorage(WorkablePlan.appStorageKey) private var planRaw = WorkablePlan.defaultPlan.rawValue
    @AppStorage(WidgetGlanceUIVersion.appStorageKey) private var widgetGlanceUIVersion =
        WidgetGlanceUIVersion.defaultVersion.rawValue
    @AppStorage(TodosSectionUIVersion.appStorageKey) private var todosUIVersionRaw =
        TodosSectionUIVersion.defaultVersion.rawValue
    @AppStorage("settings.todosRevampEnabled") private var todosRevampEnabled = false
    @AppStorage(ScheduleChangeRequestUIVersion.appStorageKey) private var scheduleChangeUIVersionRaw =
        ScheduleChangeRequestUIVersion.defaultVersion.rawValue
    @AppStorage(ScheduleChangeRequestPersona.appStorageKey) private var scheduleChangePersonaRaw =
        ScheduleChangeRequestPersona.defaultPersona.rawValue

    init(showsAttendanceIssuesUIKey: String) {
        self.showsAttendanceIssuesUIKey = showsAttendanceIssuesUIKey
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DisclosureGroup {
                        ForEach(ScheduleChangeRequestUIVersion.allCases) { version in
                            let selected = scheduleChangeUIVersionRaw == version.rawValue
                            Button {
                                scheduleChangeUIVersionRaw = version.rawValue
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(
                                            selected && approvalsEnabled
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
                            .disabled(!approvalsEnabled)
                            .opacity(approvalsEnabled ? 1 : 0.55)
                        }
                    } label: {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(scheduleChangeUIVersionRaw)
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                    .opacity(approvalsEnabled ? 1 : 0.55)
                } header: {
                    Text("Schedule change request")
                } footer: {
                    Text("V1 is fixed fields shown together. V2 (Figma 16426-301502) is toggle cards — Type, Workplace, Work hours — so a requester only fills in what's changing. V3 adds Employee / Manager / Employee without Time tracking personas. Applies to every entry point once Approvals is on.")
                }

                if scheduleChangeUIVersionRaw == ScheduleChangeRequestUIVersion.v3.rawValue {
                    Section {
                        ForEach(ScheduleChangeRequestPersona.allCases) { persona in
                            let selected = scheduleChangePersonaRaw == persona.rawValue
                            Button {
                                scheduleChangePersonaRaw = persona.rawValue
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(
                                            selected && approvalsEnabled
                                                ? AppColors.primaryDark
                                                : AppColors.iconInactive
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(persona.rawValue)
                                            .font(AppFonts.subheadStrong())
                                            .foregroundColor(AppColors.fontDefault)
                                        Text(persona.caption)
                                            .font(AppFonts.caption1())
                                            .foregroundColor(AppColors.fontSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(!approvalsEnabled)
                            .opacity(approvalsEnabled ? 1 : 0.55)
                        }
                    } header: {
                        Text("V3 persona")
                    } footer: {
                        Text("Employee is the request form. Employee without Time tracking sees the schedule calendar only. Manager sees that request in Inbox.")
                    }
                }

                Section {
                    NavigationLink {
                        AttendanceSettingsView(showsAttendanceIssuesUIKey: showsAttendanceIssuesUIKey)
                    } label: {
                        Text("Attendance")
                    }
                }

                Section {
                    Toggle("Break support", isOn: $breakSupportEnabled)

                    DisclosureGroup {
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
                    } label: {
                        HStack {
                            Text("UI version")
                            Spacer()
                            Text(BreakSupportUIVersion.resolved(from: breakSupportUIVersion).rawValue)
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                    .opacity(breakSupportEnabled ? 1 : 0.55)

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
                    DisclosureGroup {
                        Picker("Plan", selection: $planRaw) {
                            ForEach(WorkablePlan.allCases) { plan in
                                Text(plan.rawValue).tag(plan.rawValue)
                            }
                        }
                        .onChange(of: planRaw) { _, newValue in
                            if let plan = WorkablePlan(rawValue: newValue) {
                                WidgetPlanStore.save(plan)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Plan")
                            Spacer()
                            Text(planRaw)
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                } header: {
                    Text("Plan")
                } footer: {
                    Text("Gates which sections the “Today” home-screen widget shows — ATS-only accounts don't see time tracking or time off; HRIS-only accounts don't see new candidates.")
                }

                Section {
                    DisclosureGroup {
                        ForEach(WidgetGlanceUIVersion.allCases) { version in
                            let selected = widgetGlanceUIVersion == version.rawValue
                            Button {
                                widgetGlanceUIVersion = version.rawValue
                                WidgetGlanceUIVersionStore.save(version)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selected ? AppColors.primaryDark : AppColors.iconInactive)
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
                        }
                    } label: {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(widgetGlanceUIVersion)
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                } header: {
                    Text("Today widget")
                } footer: {
                    Text("V1 is the forest-green time-tracking widget. V2 uses a black card with mint and purple glow.")
                }

                Section {
                    Toggle("To-dos revamp", isOn: $todosRevampEnabled)

                    DisclosureGroup {
                        ForEach(TodosSectionUIVersion.allCases) { version in
                            let selected = todosUIVersionRaw == version.rawValue
                            Button {
                                todosUIVersionRaw = version.rawValue
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selected ? AppColors.primaryDark : AppColors.iconInactive)
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
                            .disabled(!todosRevampEnabled)
                            .opacity(todosRevampEnabled ? 1 : 0.55)
                        }
                    } label: {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(todosUIVersionRaw)
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                    .opacity(todosRevampEnabled ? 1 : 0.55)
                } header: {
                    Text("To-dos section (Home)")
                } footer: {
                    Text("Off shows the original flat scrolling row. On: V1 is a notification-style stack per category. V2 (Figma Dashboard 5281-28001) is one combined stack with Show more/less, plus category pills.")
                }

                Section {
                    Toggle("Redesign", isOn: $redesignEnabled)
                    Toggle("WhatsApp", isOn: $whatsAppEnabled)
                    Toggle("Surveys", isOn: $surveysEnabled)
                    Toggle("Time off", isOn: $timeOffEnabled)
                    Toggle("Approvals", isOn: $approvalsEnabled)
                    Toggle("Hide agent confirmations", isOn: $hideAgentConfirmations)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                let resolved = BreakSupportUIVersion.resolved(from: breakSupportUIVersion)
                if breakSupportUIVersion != resolved.rawValue {
                    breakSupportUIVersion = resolved.rawValue
                }
                if let plan = WorkablePlan(rawValue: planRaw) {
                    WidgetPlanStore.save(plan)
                }
                WidgetGlanceUIVersionStore.save(
                    WidgetGlanceUIVersion(rawValue: widgetGlanceUIVersion) ?? .defaultVersion
                )
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
        AttendanceNotifyStyle.final.rawValue

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
                        DisclosureGroup {
                            Picker("Notify style", selection: $notifyStyle) {
                                ForEach(AttendanceNotifyStyle.allCases) { style in
                                    Text(style.rawValue).tag(style.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text("Notify style")
                                Spacer()
                                Text(notifyStyle)
                                    .foregroundColor(AppColors.fontSecondary)
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
                    DisclosureGroup {
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
                    } label: {
                        HStack {
                            Text("UI version")
                            Spacer()
                            Text(AttendanceUIVersion.resolved(from: attendanceUIVersion).rawValue)
                                .foregroundColor(AppColors.fontSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Attendance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
