import SwiftUI

final class CandidatesBrowserViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var isListView = true

    let resultsCount = 136
    let jobTitle: String
    let jobSubtitle: String

    init(jobTitle: String = "Software Engineer",
         jobSubtitle: String = "Engineering · Hybrid · Amsterdam / London / Prag...") {
        self.jobTitle = jobTitle
        self.jobSubtitle = jobSubtitle
    }

    let candidates: [Candidate] = [
        Candidate(
            name: "Emma Clark",
            role: "Senior Software Engineer, Front-end",
            location: nil,
            source: "Workable Agent",
            matchScore: 70,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 3 days ago",
            avatarName: "avatar-emma"
        ),
        Candidate(
            name: "Lucy Anderson",
            role: "Software Engineer",
            location: "Athens, Attiki, Greece",
            source: "Workable Agent",
            matchScore: 50,
            tags: "#senior #promising",
            stageInfo: "Sourced stage · Uploaded 4 days ago",
            avatarName: "avatar-lucy"
        ),
        Candidate(
            name: "Abdi Hassan",
            role: "Senior Software Engineer, Full-stack",
            location: "New York, New York, United States",
            source: "Workable Agent",
            matchScore: 10,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 5 days ago",
            avatarName: "avatar-abdi"
        ),
        Candidate(
            name: "Tyler Anderson",
            role: "Staff Software Engineer",
            location: "Athens, Attiki, Greece",
            source: "Workable Agent",
            matchScore: 60,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 2 days ago",
            avatarName: "avatar-tyler"
        ),
        Candidate(
            name: "Michael Thompson",
            role: "Software Engineer, Platform & Reliability",
            location: "London, United Kingdom",
            source: "Workable Agent",
            matchScore: 85,
            tags: nil,
            stageInfo: "Sourced stage · Uploaded 1 day ago",
            avatarName: "avatar-michael"
        )
    ]
}

struct CandidatesBrowserView: View {
    @StateObject private var viewModel: CandidatesBrowserViewModel
    @State private var candidateFitCandidate: Candidate? = nil
    @State private var profileCandidate: Candidate? = nil
    @Environment(\.dismiss) private var dismiss

    init(jobTitle: String = "Software Engineer",
         jobSubtitle: String = "Engineering · Hybrid · Amsterdam / London / Prag...") {
        _viewModel = StateObject(wrappedValue: CandidatesBrowserViewModel(
            jobTitle: jobTitle,
            jobSubtitle: jobSubtitle
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Nav bar (sticky)
                VStack(spacing: 0) {
                    NavBarView(title: "Candidates", searchText: $viewModel.searchText) {
                        dismiss()
                    }

                    FilterBarView()
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
                            subtitle: viewModel.jobSubtitle
                        )
                        .padding(.horizontal, 16)

                        VStack(spacing: 8) {
                            ForEach(viewModel.candidates) { candidate in
                                CandidateCardView(
                                    candidate: candidate,
                                    onAvatarTap: { candidateFitCandidate = candidate },
                                    onCardTap: { profileCandidate = candidate }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
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
                CandidateProfileView(candidate: candidate)
                    .navigationBarHidden(true)
            }
        }
        .sheet(item: $candidateFitCandidate) { candidate in
            CandidateFitView(candidate: candidate)
                .presentationCornerRadius(20)
                .presentationBackground(AppColors.surface)
        }
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
    CandidatesBrowserView()
}

#Preview("iPhone 17 Pro") {
    ZStack {
        Color(hex: "E8E8ED")
            .ignoresSafeArea()
        
        IPhoneFrameView {
            CandidatesBrowserView()
        }
        .shadow(color: .black.opacity(0.25), radius: 40, x: 0, y: 20)
        .scaleEffect(0.7)
    }
}
