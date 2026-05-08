import SwiftUI
import UIKit

struct CandidateFitView: View {
    @Environment(\.dismiss) private var dismiss
    let candidate: Candidate
    
    @State private var selectedTab = 0
    @State private var selectedTrait: Trait? = nil
    @State private var showCriteriaExplanation = false
    
    @State private var mustHaveTraits: [Trait] = [
        Trait(name: "AWS Certified Solutions Architect or equivalent cloud certification", status: .notMet, description: "No cloud certification found in the candidate's profile."),
        Trait(name: "Hands-on experience with RESTful APIs", status: .notMet, description: "No RESTful API experience found in the candidate's background."),
        Trait(name: "Fintech experience or familiarity with regulated industries", status: .unknown, description: "Unable to determine from the candidate's profile."),
        Trait(name: "BSc degree in Computer Science", status: .partiallyMet, description: "Degree titles in the candidate's CV matched to Computer Science field."),
        Trait(name: "Experience building and maintaining SaaS", status: .partiallyMet, description: "The candidate mentions SaaS experience but details are limited."),
        Trait(name: "3+ years professional experience with Python (ideally in backend or full-stack roles)", status: .partiallyMet, description: "Candidate has Python experience but years are unclear."),
        Trait(name: "Familiarity with SQL and relational databases", status: .partiallyMet, description: "The candidate mentions working with databases but no specific SQL experience listed."),
        Trait(name: "Right to work in EU", status: .partiallyMet, description: "Location suggests EU residency but no explicit work permit mentioned."),
        Trait(name: "Proficiency in Python 3.x", status: .met, description: "Candidate lists Python 3.x as a primary skill with 4+ years of experience."),
        Trait(name: "Available full time", status: .met, description: "Candidate has confirmed full-time availability in their application."),
        Trait(name: "Certified Python Developer (PCAP)", status: .met, description: "PCAP certification verified from candidate's credentials.")
    ]
    
    @State private var niceToHaveTraits: [Trait] = [
        Trait(name: "Experience with Docker or Kubernetes", status: .notMet, description: "No containerization experience found in the candidate's profile."),
        Trait(name: "Familiarity with CI/CD pipelines", status: .unknown, description: "Unable to determine from the candidate's profile."),
        Trait(name: "Knowledge of microservices architecture", status: .partiallyMet, description: "Candidate mentions distributed systems but not microservices specifically."),
        Trait(name: "Experience with Agile/Scrum methodologies", status: .met, description: "Candidate has worked in Agile teams for 3+ years."),
        Trait(name: "Strong written communication skills", status: .met, description: "Candidate's cover letter and application demonstrate strong writing."),
        Trait(name: "Open source contributions", status: .partiallyMet, description: "Candidate has a GitHub profile but limited public contributions.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            navBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    candidateHeader
                        .padding(.horizontal, 16)
                    
                    summaryText
                        .padding(.horizontal, 16)
                    
                    tabSection
                    
                    traitsList
                        .padding(.horizontal, 16)
                    
                    infoBanner
                        .padding(.horizontal, 16)
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(AppColors.surface)
    }
    
    // MARK: - Nav Bar
    
    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Close")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.primaryDark)
            }
            
            Spacer()
            
            Text("Candidate fit")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
            
            Spacer()
            
            Text("Close")
                .font(AppFonts.body())
                .foregroundColor(.clear)
        }
        .padding(16)
        .background(AppColors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.separator),
            alignment: .bottom
        )
    }
    
    // MARK: - Candidate Header
    
    private var candidateHeader: some View {
        HStack(spacing: 12) {
            AvatarWithScoreView(
                matchScore: candidate.matchScore,
                agentIsReviewing: candidate.agentIsReviewing,
                fitEvaluationInProgress: candidate.fitEvaluationInProgress,
                imageName: candidate.avatarName,
                avatarURL: candidate.avatarURL
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                    .lineLimit(1)
                
                Text("\(candidate.role) · Sourced")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Summary Text
    
    private var summaryText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                (Text("The candidate holds a ")
                    .font(AppFonts.subheadline())
                +
                Text("Bachelor's degree")
                    .font(AppFonts.subheadStrong())
                +
                Text(" and demonstrates ")
                    .font(AppFonts.subheadline())
                +
                Text("Thai fluency")
                    .font(AppFonts.subheadStrong())
                +
                Text(" (native/bilingual). The background includes customer-facing coordination via email and phone in ")
                    .font(AppFonts.subheadline())
                +
                Text("Account Executive")
                    .font(AppFonts.subheadStrong())
                +
                Text(" and Program Coordinator roles.")
                    .font(AppFonts.subheadline()))
                .foregroundColor(AppColors.fontDefault)
            }
            
            Group {
                (Text("Holds a Bachelor's degree and demonstrates ")
                    .font(AppFonts.subheadline())
                +
                Text("Thai fluency")
                    .font(AppFonts.subheadStrong())
                +
                Text(" (native/bilingual). The background includes customer-facing coordination via email and phone in ")
                    .font(AppFonts.subheadline())
                +
                Text("Account Executive")
                    .font(AppFonts.subheadStrong())
                +
                Text(" and Program Coordinator roles.")
                    .font(AppFonts.subheadline()))
                .foregroundColor(AppColors.fontDefault)
            }
            
            Group {
                (Text("However, the candidate stated they do not have 2+ years of direct contact-centre experience, which is a must-have. No ")
                    .font(AppFonts.subheadline())
                +
                Text("FX/financial services")
                    .font(AppFonts.subheadStrong())
                +
                Text(" support experience is evidenced, and clarification is needed on SOP exposure, English proficiency level, and shift-schedule availability.")
                    .font(AppFonts.subheadline()))
                .foregroundColor(AppColors.fontDefault)
            }
        }
    }
    
    // MARK: - Tab Section
    
    private var tabSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tabButton(title: "Must have", index: 0)
                tabButton(title: "Nice to have", index: 1)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button { selectedTab = index } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(selectedTab == index ? AppColors.primaryDark : AppColors.fontSecondary)
                
                Rectangle()
                    .fill(selectedTab == index ? AppColors.primaryDark : AppColors.separator)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Traits List
    
    private var traitsList: some View {
        let traits = orderedTraits(for: selectedTab == 0 ? mustHaveTraits : niceToHaveTraits)
        return VStack(spacing: 0) {
            ForEach(Array(traits.enumerated()), id: \.element.id) { index, trait in
                Button { selectedTrait = trait } label: {
                    TraitRow(trait: trait)
                }
                .buttonStyle(.plain)
                if index < traits.count - 1 {
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                }
            }
        }
        .sheet(item: $selectedTrait) { trait in
            TraitDetailSheet(trait: trait) { newStatus in
                applyTraitStatusChange(id: trait.id, status: newStatus)
            }
                .presentationDetents([.height(220), .medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(AppColors.surface)
        }
    }
    
    /// Keep row order stable inside each status bucket while always placing `met` criteria at the end.
    private func orderedTraits(for traits: [Trait]) -> [Trait] {
        traits
            .enumerated()
            .sorted { lhs, rhs in
                let lhsRank = statusSortRank(lhs.element.status)
                let rhsRank = statusSortRank(rhs.element.status)
                if lhsRank == rhsRank {
                    return lhs.offset < rhs.offset
                }
                return lhsRank < rhsRank
            }
            .map(\.element)
    }
    
    private func statusSortRank(_ status: TraitStatus) -> Int {
        switch status {
        case .disqualifying: return 0
        case .notMet: return 1
        case .unknown: return 2
        case .partiallyMet: return 3
        case .met: return 4
        }
    }
    
    private func applyTraitStatusChange(id: UUID, status: TraitStatus) {
        if let i = mustHaveTraits.firstIndex(where: { $0.id == id }) {
            mustHaveTraits[i].status = status
        } else if let i = niceToHaveTraits.firstIndex(where: { $0.id == id }) {
            niceToHaveTraits[i].status = status
        }
        if var t = selectedTrait, t.id == id {
            t.status = status
            selectedTrait = t
        }
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        Button { showCriteriaExplanation = true } label: {
            HStack(spacing: 12) {
                Text("Criteria explanation")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.informativeDefault)
            }
            .padding(16)
            .background(AppColors.informativeBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showCriteriaExplanation) {
            CriteriaExplanationSheet()
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(AppColors.surface)
        }
    }
}

// MARK: - Trait Model

enum TraitStatus: Hashable {
    case met, partiallyMet, notMet, disqualifying, unknown

    var label: String {
        switch self {
        case .met:           return "Met"
        case .partiallyMet:  return "Partially met"
        case .notMet:        return "Not met"
        case .disqualifying: return "Disqualifying"
        case .unknown:       return "Unknown"
        }
    }

    var iconColor: Color {
        switch self {
        case .met, .partiallyMet: return AppColors.successDefault
        case .notMet:             return AppColors.warningDefault
        case .disqualifying:      return AppColors.dangerDefault
        case .unknown:            return AppColors.fontSecondary
        }
    }

    var iconBackground: Color {
        switch self {
        case .met, .partiallyMet: return AppColors.successBackground
        case .notMet:             return AppColors.warningBackground
        case .disqualifying:      return AppColors.dangerBackground
        case .unknown:            return AppColors.background
        }
    }

    var iconImageName: String {
        switch self {
        case .met:                return "icon-done-all"
        case .partiallyMet:       return "icon-check"
        case .notMet, .disqualifying: return "icon-close"
        case .unknown:            return "icon-question-mark"
        }
    }
}

struct Trait: Identifiable {
    let id = UUID()
    let name: String
    var status: TraitStatus
    var description: String = ""
}

// MARK: - Trait Row

private struct TraitRow: View {
    let trait: Trait
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            
            Text(trait.name)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontDefault)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundColor(AppColors.iconInactive)
        }
        .padding(.vertical, 12)
    }
    
    private var statusIcon: some View {
        Image(trait.status.iconImageName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundColor(trait.status.iconColor)
            .padding(2)
            .background(trait.status.iconBackground)
            .cornerRadius(4)
    }
}

// MARK: - Criteria toast (window — sheet clips; screen center needs key window)

private struct CriteriaUpdateToastLabel: View {
    var body: some View {
        Text("Criteria have been updated.")
            .font(.system(size: 15, weight: .regular))
            .tracking(-0.24)
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColors.oxfordBlue)
            )
            .fixedSize(horizontal: true, vertical: true)
    }
}

/// Full-screen clear host so the label is centered on the **device window**, not the bottom sheet.
private struct CriteriaUpdateToastWindowRoot: View {
    var body: some View {
        ZStack {
            Color.clear
            CriteriaUpdateToastLabel()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum CriteriaUpdateToastPresenter {
    private static let overlayTag = 8_721_901
    private static var hostingController: UIHostingController<CriteriaUpdateToastWindowRoot>?
    
    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    static func show(duration: TimeInterval = 2.0) {
        DispatchQueue.main.async {
            guard let window = keyWindow else { return }
            
            window.viewWithTag(overlayTag)?.removeFromSuperview()
            hostingController?.view.removeFromSuperview()
            hostingController = nil
            
            let host = UIHostingController(rootView: CriteriaUpdateToastWindowRoot())
            host.view.backgroundColor = .clear
            host.view.tag = overlayTag
            host.view.isUserInteractionEnabled = false
            host.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController = host
            
            window.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: window.topAnchor),
                host.view.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                host.view.bottomAnchor.constraint(equalTo: window.bottomAnchor)
            ])
            
            host.view.alpha = 0
            UIView.animate(withDuration: 0.18) {
                host.view.alpha = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.2, animations: {
                    host.view.alpha = 0
                }, completion: { _ in
                    host.view.removeFromSuperview()
                    if hostingController === host {
                        hostingController = nil
                    }
                })
            }
        }
    }
}

/// Softer label copy/color changes when the criteria pill updates (iOS 17+).
private struct PillStatusLabelTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.contentTransition(.opacity)
        } else {
            content
        }
    }
}

// MARK: - Trait Detail Sheet

private struct TraitDetailSheet: View {
    let trait: Trait
    let onStatusChange: (TraitStatus) -> Void
    @State private var selectedStatus: TraitStatus
    @State private var didEditCriteriaPill = false
    
    init(trait: Trait, onStatusChange: @escaping (TraitStatus) -> Void = { _ in }) {
        self.trait = trait
        self.onStatusChange = onStatusChange
        _selectedStatus = State(initialValue: trait.status)
    }
    
    private var pillUsesSuccessBackground: Bool {
        selectedStatus == .met || selectedStatus == .partiallyMet
    }
    
    /// Crossfades solid fills instead of animating one `Color` (avoids muddy intermediate hues).
    private var pillStatusBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.successBackground)
                .opacity(pillUsesSuccessBackground ? 1 : 0)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.warningBackground)
                .opacity(selectedStatus == .notMet ? 1 : 0)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.dangerBackground)
                .opacity(selectedStatus == .disqualifying ? 1 : 0)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.background)
                .opacity(selectedStatus == .unknown ? 1 : 0)
        }
        .allowsHitTesting(false)
    }
    
    /// Max intrinsic width of label + chevron (14pt semibold); keeps pill width stable when status changes.
    private static let pillLabelRowMaxWidth: CGFloat = {
        let labels = ["Met", "Partially met", "Not met", "Unknown", "Disqualifying"]
        let font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let widths = labels.map { label -> CGFloat in
            (label as NSString).size(withAttributes: [.font: font]).width
        }
        let chevronReserve: CGFloat = 12 + 4
        // Small slack so SwiftUI text isn’t tighter than NSString measurement.
        return ceil((widths.max() ?? 120) + chevronReserve) + 4
    }()
    
    /// Icon (20) + gap (12) + label row — fixed track so short labels center without lopsided right padding.
    private static let pillContentTrackWidth: CGFloat = 20 + 12 + pillLabelRowMaxWidth
    
    /// Figma Label pill (`26338:96424`): row `h-[25px]`, `items-center` with 20px prefix icon.
    private static let pillRowAlignmentHeight: CGFloat = 25
    
    /// Figma `material.question_mark` in 20×20: `inset` top / right / bottom / left as % of 20pt box (node `26338:96426`).
    private static let questionMarkPillInsets = EdgeInsets(
        top: 20 * (12.5 / 100),
        leading: 20 * (30.64 / 100),
        bottom: 20 * (15 / 100),
        trailing: 20 * (29.06 / 100)
    )
    
    private static let allStatuses: [TraitStatus] = [.met, .partiallyMet, .notMet, .unknown, .disqualifying]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    
                    Menu {
                        ForEach(Self.allStatuses, id: \.self) { status in
                            Button {
                                let previous = selectedStatus
                                guard status != previous else { return }
                                // Defer until after the menu dismisses; animate pill separately from menu transition.
                                DispatchQueue.main.async {
                                    selectedStatus = status
                                    didEditCriteriaPill = true
                                    onStatusChange(status)
                                    DispatchQueue.main.async {
                                        CriteriaUpdateToastPresenter.show()
                                    }
                                }
                            } label: {
                                if status == selectedStatus {
                                    Label(status.label, systemImage: "checkmark")
                                } else {
                                    Text(status.label)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            HStack(alignment: .center, spacing: 12) {
                                pillIcon
                                    .frame(width: 20, height: Self.pillRowAlignmentHeight, alignment: .center)
                                HStack(alignment: .center, spacing: 4) {
                                    Text(selectedStatus.label)
                                        .font(AppFonts.subheadStrong())
                                        .foregroundColor(selectedStatus.iconColor)
                                        .lineLimit(1)
                                        .modifier(PillStatusLabelTransitionModifier())
                                    pillMenuChevron
                                        .foregroundColor(selectedStatus.iconColor)
                                }
                                .frame(height: Self.pillRowAlignmentHeight, alignment: .center)
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(width: TraitDetailSheet.pillContentTrackWidth)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(pillStatusBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .animation(.easeInOut(duration: 0.28), value: selectedStatus)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                Rectangle()
                    .fill(AppColors.separator)
                    .frame(height: 1)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(trait.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                    
                    if didEditCriteriaPill {
                        Text("Edited by Stelios Xenakis on March 26, 2026.")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                    } else if !trait.description.isEmpty {
                        Text(trait.description)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
                
                Spacer()
            }
            .background(AppColors.surface)
    }
    
    /// Figma `Icon/16px/Filled/Small-arrow-right`: 12×12 cell, shape `top` ~1.95pt (node `26338:96429`).
    private var pillMenuChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 11, weight: .semibold))
            .frame(width: 12, height: 12)
            .offset(y: CGFloat(2) / 3)
    }
    
    /// Stacked template images avoid swapping `switch` branches (cheaper than identity churn during updates).
    private var pillIcon: some View {
        ZStack(alignment: .center) {
            Image("icon-done-all")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(AppColors.successDefault)
                .opacity(selectedStatus == .met ? 1 : 0)
            Image("icon-check")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(AppColors.successDefault)
                .opacity(selectedStatus == .partiallyMet ? 1 : 0)
            Image("icon-close")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(AppColors.warningDefault)
                .opacity(selectedStatus == .notMet ? 1 : 0)
            Image("icon-close")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(AppColors.dangerDefault)
                .opacity(selectedStatus == .disqualifying ? 1 : 0)
            Image("icon-question-mark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .padding(TraitDetailSheet.questionMarkPillInsets)
                .foregroundColor(AppColors.fontSecondary)
                .opacity(selectedStatus == .unknown ? 1 : 0)
        }
        .frame(width: 20, height: 20, alignment: .center)
    }
    
    private var statusBadgeIcon: some View {
        Image(selectedStatus.iconImageName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundColor(selectedStatus.iconColor)
            .padding(2)
            .background(selectedStatus.iconBackground)
            .cornerRadius(4)
    }
}

// MARK: - Criteria Explanation Sheet

private struct CriteriaExplanationSheet: View {
    private let explanations: [TraitStatus] = [.disqualifying, .notMet, .unknown, .partiallyMet, .met]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Criteria explanation")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.fontDefault)
                .padding(.top, 24)
                .padding(.bottom, 20)
            
            VStack(spacing: 0) {
                ForEach(Array(explanations.enumerated()), id: \.offset) { index, status in
                    explanationRow(status: status)
                    
                    if index < explanations.count - 1 {
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(AppColors.surface)
    }
    
    private func explanationRow(status: TraitStatus) -> some View {
        HStack(spacing: 12) {
            Image(status.iconImageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(status.iconColor)
                .padding(2)
                .background(status.iconBackground)
                .cornerRadius(4)

            Text(status.label)
                .font(AppFonts.body())
                .foregroundColor(status == .disqualifying ? AppColors.dangerDefault : AppColors.fontDefault)

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    CandidateFitView(
        candidate: Candidate(
            name: "Lucy Anderson",
            role: "Software Engineer",
            matchScore: 50,
            stageInfo: "Sourced stage",
            avatarName: "avatar-lucy"
        )
    )
}
