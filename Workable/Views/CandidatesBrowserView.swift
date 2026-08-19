import SwiftUI
import UIKit

final class CandidatesBrowserViewModel: ObservableObject {
    @Published var searchText = ""
    /// `false` = per-stage (Figma timeline), `true` = flat list.
    @Published var isListView = false

    /// Shown in the results header and filters (e.g. from the job row on Home).
    let resultsCount: Int
    let jobTitle: String
    let jobSubtitle: String

    init(
        jobTitle: String = "Software Engineer",
        jobSubtitle: String = "Engineering · Hybrid · Amsterdam / London / Prag...",
        resultsCount: Int = 136
    ) {
        self.jobTitle = jobTitle
        self.jobSubtitle = jobSubtitle
        self.resultsCount = resultsCount
    }

    var candidates: [Candidate] {
        switch jobTitle {
        case "UX Writer":
            return Self.uxWriterCandidates
        case "Product Manager":
            return Self.productManagerCandidates
        default:
            return Self.softwareEngineerCandidates
        }
    }

    private static let softwareEngineerCandidates: [Candidate] = [
        Candidate(
            name: "Tyler Anderson",
            role: "Software Engineer at Workable",
            location: "Athens, Attiki, Greece",
            source: "Workable Agent",
            matchScore: 60,
            tags: nil,
            stageInfo: "Applied stage · Uploaded 2 days ago",
            avatarName: "avatar-tyler"
        ),
        Candidate(
            name: "Emma Clark",
            role: "Senior Software Engineer",
            location: nil,
            source: "Workable Agent",
            matchScore: 70,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 3 days ago",
            avatarName: "avatar-emma",
            agentIsReviewing: true
        ),
        Candidate(
            name: "Lucy Anderson",
            role: "Front-end Developer",
            location: "Athens, Attiki, Greece",
            source: "Workable Agent",
            matchScore: 50,
            tags: "#senior #promising",
            stageInfo: "Sourced stage · Uploaded 4 days ago",
            avatarName: "avatar-lucy"
        ),
        Candidate(
            name: "Abdi Hassan",
            role: "Product Engineer at Tribal",
            location: "New York, New York, United States",
            source: "Workable Agent",
            matchScore: 10,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 5 days ago",
            avatarName: "avatar-abdi"
        ),
        Candidate(
            name: "Michael Thompson",
            role: "Software Engineer, Platform & Reliability",
            location: "London, United Kingdom",
            source: "Workable Agent",
            matchScore: 85,
            tags: nil,
            stageInfo: "Interview stage · Uploaded 1 day ago",
            avatarName: "avatar-michael"
        ),
        Candidate(
            name: "Cindy Sawyers",
            role: "Software Engineer",
            location: "Athens, Attiki, Greece",
            source: "Workable Agent",
            matchScore: 78,
            tags: "#new profile",
            stageInfo: "Interview stage · Uploaded 6 days ago",
            avatarName: "avatar-lucy"
        ),
        Candidate(
            name: "Liam Foster",
            role: "Software Engineer, Back-end",
            location: "London, United Kingdom",
            source: "Workable Agent",
            matchScore: 62,
            tags: "#evaluation",
            stageInfo: "Hired stage · Uploaded 7 days ago",
            avatarName: "avatar-tyler",
            fitEvaluationInProgress: true
        ),
        Candidate(
            name: "Priya Shah",
            role: "iOS Engineer",
            location: "Remote",
            source: "Workable Agent",
            matchScore: 91,
            tags: "#offer accepted",
            stageInfo: "Hired stage · Uploaded 2 weeks ago",
            avatarName: "avatar-priya"
        )
    ]

    private static let uxWriterCandidates: [Candidate] = [
        Candidate(
            name: "Olivia Bennett",
            role: "Senior UX Writer",
            location: "London, United Kingdom",
            source: "Workable Agent",
            matchScore: 72,
            tags: nil,
            stageInfo: "Applied stage · Uploaded 2 days ago",
            avatarName: "avatar-emma"
        ),
        Candidate(
            name: "Daniel Chen",
            role: "Content Designer",
            location: "Berlin, Germany",
            source: "Workable Agent",
            matchScore: 45,
            tags: "#portfolio",
            stageInfo: "Sourced stage · Uploaded 5 days ago",
            avatarName: "avatar-abdi"
        ),
        Candidate(
            name: "Priya Shah",
            role: "UX Writer",
            location: "Remote",
            source: "Workable Agent",
            matchScore: 55,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 1 week ago",
            avatarName: "avatar-lucy"
        ),
        Candidate(
            name: "Marcus Webb",
            role: "Principal Content Strategist",
            location: "Dublin, Ireland",
            source: "Workable Agent",
            matchScore: 88,
            tags: nil,
            stageInfo: "Phone Screen stage · Uploaded 3 days ago",
            avatarName: "avatar-michael"
        )
    ]

    private static let productManagerCandidates: [Candidate] = [
        Candidate(
            name: "Elena Vasquez",
            role: "Senior Product Manager",
            location: "New York, United States",
            source: "Workable Agent",
            matchScore: 80,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 2 days ago",
            avatarName: "avatar-lucy"
        ),
        Candidate(
            name: "Chris Okonkwo",
            role: "Associate Product Manager",
            location: "Remote · US",
            source: "Workable Agent",
            matchScore: 35,
            tags: nil,
            stageInfo: "Applied stage · Uploaded 6 days ago",
            avatarName: "avatar-tyler"
        ),
        Candidate(
            name: "Hannah Fischer",
            role: "Group Product Manager",
            location: "Boston, United States",
            source: "Workable Agent",
            matchScore: 92,
            tags: "#leadership",
            stageInfo: "Interview · Uploaded 1 day ago",
            avatarName: "avatar-emma"
        ),
        Candidate(
            name: "Jonas Lindström",
            role: "Product Manager, Platform",
            location: "Stockholm, Sweden",
            source: "Workable Agent",
            matchScore: 63,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 4 days ago",
            avatarName: "avatar-abdi"
        )
    ]
}

struct CandidatesBrowserView: View {
    private enum PresentedSheet: Identifiable, Equatable {
        case jobFilters
        case agentStatus(Candidate)
        case candidateFit(Candidate)

        var id: String {
            switch self {
            case .jobFilters:
                return "jobFilters"
            case .agentStatus(let candidate):
                return "agent-\(candidate.id.uuidString)"
            case .candidateFit(let candidate):
                return "fit-\(candidate.id.uuidString)"
            }
        }
    }

    @StateObject private var viewModel: CandidatesBrowserViewModel
    @State private var presentedSheet: PresentedSheet? = nil
    @State private var agentStatusSheetHeight: CGFloat = 380
    @State private var selectedSortOption: CandidateSortOption = .aiStatusAndScore
    @State private var profileCandidate: Candidate? = nil
    @State private var profileInitialTab: Int = 0
    @Environment(\.dismiss) private var dismiss

    init(
        jobTitle: String = "Software Engineer",
        jobSubtitle: String = "Engineering · Hybrid · Amsterdam / London / Prag...",
        resultsCount: Int = 14
    ) {
        _viewModel = StateObject(wrappedValue: CandidatesBrowserViewModel(
            jobTitle: jobTitle,
            jobSubtitle: jobSubtitle,
            resultsCount: resultsCount
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
                // Nav bar (sticky)
                VStack(spacing: 0) {
                    NavBarView(title: "Candidates", searchText: $viewModel.searchText) {
                        dismiss()
                    }

                    FilterBarView(
                        selectedSort: $selectedSortOption,
                        resultsCount: viewModel.resultsCount
                    )
                }
                .background(AppColors.surface)
                .zIndex(2)

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(viewModel.resultsCount) results")
                                .font(AppFonts.footnote())
                                .foregroundColor(AppColors.volcanicAsh)

                            Spacer()

                            BrowserSwitchView(isListView: $viewModel.isListView)
                        }
                        .padding(.horizontal, 16)

                        JobHeaderView(
                            title: viewModel.jobTitle,
                            subtitle: viewModel.jobSubtitle,
                            onTap: { presentedSheet = .jobFilters }
                        )
                        .padding(.horizontal, 16)

                        if viewModel.isListView {
                            candidateListSection(candidates: sortedCandidates, showsStageInFooter: true)
                        } else {
                            perStageSections
                        }
                    }
                    .padding(.top, 8)
                }
                .background(AppColors.background)
                .zIndex(1)
            }
            .background(AppColors.background)
            .ignoresSafeArea(edges: .bottom)
            .navigationBarHidden(true)
            .navigationDestination(item: $profileCandidate) { candidate in
                CandidateProfileView(candidate: candidate, initialSelectedTab: profileInitialTab)
                    .id("\(candidate.id.uuidString)-\(profileInitialTab)")
                    .navigationBarHidden(true)
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .jobFilters:
                    FiltersOverlayView(
                        resultsCount: viewModel.resultsCount,
                        jobSummary: "\(viewModel.jobTitle) · \(viewModel.jobSubtitle)"
                    )
                        .presentationCornerRadius(20)
                        .presentationBackground(AppColors.surface)
                case .agentStatus(let candidate):
                    AgentStatusSheet(candidate: candidate) {
                        presentedSheet = .candidateFit(candidate)
                    }
                    .onPreferenceChange(AgentStatusSheetContentHeightKey.self) { height in
                        guard height > 80 else { return }
                        let maxH = UIScreen.main.bounds.height * 0.92
                        let buffered = height + 4
                        let clamped = min(buffered, maxH)
                        if abs(agentStatusSheetHeight - clamped) > 2 {
                            agentStatusSheetHeight = clamped
                        }
                    }
                    .presentationDetents([.height(agentStatusSheetHeight), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
                    .presentationBackground(AppColors.surface)
                case .candidateFit(let candidate):
                    CandidateFitView(candidate: candidate)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(20)
                        .presentationBackground(AppColors.surface)
                }
            }
            .onChange(of: presentedSheet) { _, newSheet in
                if case .agentStatus = newSheet {
                    agentStatusSheetHeight = 380
                }
            }
    }

    private var perStageSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(candidatesGroupedByStage, id: \.stage) { group in
                VStack(alignment: .leading, spacing: 8) {
                    stageSectionHeader(title: group.stage, count: group.candidates.count)
                    candidateListSection(
                        candidates: group.candidates,
                        showsStageInFooter: false
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
    }

    private func stageSectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(AppFonts.subheadline())
                .tracking(-0.24)
                .foregroundColor(AppColors.volcanicAsh)

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "88929E"))
                Text("\(count)")
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.08)
                    .foregroundColor(Color(hex: "88929E"))
            }
        }
    }

    private func candidateListSection(candidates: [Candidate], showsStageInFooter: Bool) -> some View {
        VStack(spacing: 8) {
            ForEach(candidates) { candidate in
                CandidateCardView(
                    candidate: candidate,
                    showsStageInFooter: showsStageInFooter,
                    onAvatarTap: candidate.matchScore != nil
                        ? { presentedSheet = .candidateFit(candidate) }
                        : nil,
                    onCardTap: {
                        profileInitialTab = 0
                        profileCandidate = candidate
                    }
                )
            }
        }
        .padding(.horizontal, showsStageInFooter ? 16 : 0)
        .padding(.bottom, showsStageInFooter ? 100 : 0)
    }

    private var candidatesGroupedByStage: [(stage: String, candidates: [Candidate])] {
        let grouped = Dictionary(grouping: sortedCandidates, by: \.pipelineStageName)
        let preferredOrder = ["Applied", "Sourced", "Phone Screen", "Interview", "Offer", "Hired"]
        return grouped.keys
            .sorted { lhs, rhs in
                let li = preferredOrder.firstIndex(of: lhs) ?? preferredOrder.count
                let ri = preferredOrder.firstIndex(of: rhs) ?? preferredOrder.count
                if li != ri { return li < ri }
                return lhs < rhs
            }
            .map { stage in (stage: stage, candidates: grouped[stage] ?? []) }
    }

    private var sortedCandidates: [Candidate] {
        switch selectedSortOption {
        case .newestFirst:
            return viewModel.candidates.sorted {
                uploadAgeInDays(from: $0.stageInfo) < uploadAgeInDays(from: $1.stageInfo)
            }
        case .oldestFirst:
            return viewModel.candidates.sorted {
                uploadAgeInDays(from: $0.stageInfo) > uploadAgeInDays(from: $1.stageInfo)
            }
        case .aiStatusAndScore:
            return viewModel.candidates.sorted { lhs, rhs in
                let lhsPriority = aiStatusPriority(for: lhs)
                let rhsPriority = aiStatusPriority(for: rhs)
                if lhsPriority != rhsPriority {
                    return lhsPriority > rhsPriority
                }
                if (lhs.matchScore ?? -1) != (rhs.matchScore ?? -1) {
                    return (lhs.matchScore ?? -1) > (rhs.matchScore ?? -1)
                }
                return uploadAgeInDays(from: lhs.stageInfo) < uploadAgeInDays(from: rhs.stageInfo)
            }
        }
    }

    private func aiStatusPriority(for candidate: Candidate) -> Int {
        if candidate.agentIsReviewing || candidate.fitEvaluationInProgress { return 0 }
        if candidate.matchScore == nil { return 0 }
        return 1
    }

    private func uploadAgeInDays(from stageInfo: String) -> Int {
        let lowered = stageInfo.lowercased()
        guard let uploadedRange = lowered.range(of: "uploaded ") else { return .max }
        let suffix = lowered[uploadedRange.upperBound...]
        let parts = suffix.split(separator: " ")
        guard let first = parts.first, let value = Int(first) else { return .max }
        if suffix.contains("week") {
            return value * 7
        }
        return value
    }
}

/// Browser switch: Timeline (grid) vs List-bullet. Figma: separator bg, 2pt padding, 4pt radius.
struct BrowserSwitchView: View {
    @Binding var isListView: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Grid (Timeline icon in Figma)
            Button {
                isListView = false
            } label: {
                Image("icon-timeline")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(isListView ? AppColors.fontSecondary : AppColors.fontDefault)
                    .padding(6)
                    .background(isListView ? Color.clear : AppColors.surface)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            
            // List (Icon/16px/Filled/List-bullet)
            Button {
                isListView = true
            } label: {
                Image("icon-list-bullet")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(isListView ? AppColors.fontDefault : AppColors.fontSecondary)
                    .padding(6)
                    .background(isListView ? AppColors.surface : Color.clear)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(2)
        .background(AppColors.separator)
        .cornerRadius(4)
    }
}

#Preview("Full Screen") {
    NavigationStack {
        CandidatesBrowserView()
    }
}

#Preview("iPhone 17 Pro") {
    ZStack {
        Color(hex: "E8E8ED")
            .ignoresSafeArea()
        
        IPhoneFrameView {
            NavigationStack {
                CandidatesBrowserView()
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 40, x: 0, y: 20)
        .scaleEffect(0.7)
    }
}
