import SwiftUI
import UIKit

struct CandidateProfileView: View {
    let candidate: Candidate
    /// Temporary switch to hide the candidate timeline until finalized.
    private let showsCandidateTimeline = true
    @Environment(\.dismiss) private var dismiss
    @AppStorage(DisqualifyConfirmationSheet.suppressConfirmationAppStorageKey) private var suppressDisqualifyConfirmation = false
    @AppStorage("settings.hideAgentConfirmations") private var hideAgentConfirmations = false
    @AppStorage("settings.whatsAppEnabled") private var whatsAppEnabled = false
    @State private var selectedTab: Int
    @State private var showProfileContactMenu = false
    @State private var showOverflowActionMenu = false
    @State private var showSendEmailConfirmation = false
    @State private var showSendTextConfirmation = false
    @State private var showCreateEventConfirmation = false
    @State private var showEmailTemplateSheet = false
    @State private var showCreateEvent = false
    @State private var showCandidateFitSheet = false
    @State private var showMoveToJobConfirmation = false
    @State private var showDisqualifyConfirmation = false
    @State private var generatedMatchScore: Int?
    @State private var generatedMissingMustHaves: Int?
    @State private var isEvaluatingFit = false
    @State private var shouldAutoStartFitEvaluation = false
    /// Contact shortcuts on the **person** toolbar icon (original wireframe menu).
    private enum ProfileContactAction: CaseIterable {
        case sendEmail
        case sendText
        case createEvent
        case phoneCall
        case facetime

        var label: String {
            switch self {
            case .sendEmail:    return "Send an email"
            case .sendText:     return "Send a text message"
            case .createEvent:  return "Schedule event"
            case .phoneCall:    return "Phone call"
            case .facetime:     return "Facetime"
            }
        }

        var icon: String {
            switch self {
            case .sendEmail:    return "envelope.fill"
            case .sendText:     return "message.fill"
            case .createEvent:  return "calendar"
            case .phoneCall:    return "phone.fill"
            case .facetime:     return "video.fill"
            }
        }
    }

    /// Full candidate actions on the **⋯** toolbar icon.
    private enum OverflowMenuAction: CaseIterable {
        case comment
        case evaluate
        case moveToPhoneScreen
        case saveCandidate
        case share
        case copyToJob
        case moveToJob
        case editCandidate
        case stopAgentActions
        case disqualify

        var label: String {
            switch self {
            case .comment:             return "Comment"
            case .evaluate:            return "Evaluate"
            case .moveToPhoneScreen:   return "Move to Phone Screen"
            case .saveCandidate:       return "Save candidate"
            case .share:               return "Share"
            case .copyToJob:           return "Copy to job"
            case .moveToJob:           return "Move to job"
            case .editCandidate:       return "Edit candidate"
            case .stopAgentActions:    return "Stop Agent actions"
            case .disqualify:          return "Disqualify"
            }
        }

        var icon: String {
            switch self {
            case .comment:             return "bubble.left"
            case .evaluate:            return "bubble.left.and.bubble.right"
            case .moveToPhoneScreen:   return "arrow.right"
            case .saveCandidate:       return "bookmark"
            case .share:               return "square.and.arrow.up"
            case .copyToJob:           return "doc.on.doc"
            case .moveToJob:           return "arrow.turn.down.right"
            case .editCandidate:       return "pencil"
            case .stopAgentActions:    return "stop.fill"
            case .disqualify:          return "hand.raised.fill"
            }
        }

        var isDestructive: Bool {
            if case .disqualify = self { return true }
            return false
        }
    }

    /// `0` — Timeline, `1` — Profile (segmented control).
    init(candidate: Candidate, initialSelectedTab: Int = 0) {
        self.candidate = candidate
        _selectedTab = State(initialValue: initialSelectedTab)
        _generatedMatchScore = State(initialValue: candidate.matchScore)
        _generatedMissingMustHaves = State(initialValue: candidate.fitMissingMustHaves)
        _shouldAutoStartFitEvaluation = State(initialValue: candidate.fitEvaluationInProgress && candidate.matchScore == nil)
    }
    
    private struct ProfileTimelineItem: Identifiable {
        let id: String
        let title: String
        let time: String
        let actorInitials: String
        var actorAvatar: String? = nil
        var usesAIAgentAvatar: Bool = false
        var deliveryStatus: String? = nil
        var deliveryFailed: Bool = false
        var previewText: String? = nil
        var failedReason: String? = nil
        var sentViaWhatsApp: Bool = false
    }

    @State private var showTextMessageTimeline = false
    @State private var showTextMessageDetail = false
    @State private var showAgentCommentDetail = false
    @State private var sentMessageText = ""
    @State private var showWhatsAppNotAvailable = false

    private var profileTimelineItems: [ProfileTimelineItem] {
        var items: [ProfileTimelineItem] = []

        items.append(ProfileTimelineItem(
            id: "agent-comment",
            title: "Workable Agent added a comment",
            time: "just now",
            actorInitials: "AI",
            usesAIAgentAvatar: true,
            previewText: "The chat was terminated as “Completed”. The candidate provided a salary expectation of 130k, and indicated they had no further..."
        ))

        if candidate.name == "Tyler Anderson" {
            items.append(ProfileTimelineItem(
                id: "declined",
                title: "Tyler has declined messages about the Software Engineer role.",
                time: "1 day ago",
                actorInitials: "TA",
                actorAvatar: "avatar-tyler",
                deliveryStatus: "Not interested",
                deliveryFailed: true
            ))
            items.append(ProfileTimelineItem(
                id: "text",
                title: "Natalie Sung sent a text message",
                time: "1 day ago",
                actorInitials: "NS",
                deliveryStatus: "Not delivered",
                deliveryFailed: true,
                previewText: "Dear Rachael, thank you for applying for the Barista position. Just a clarification: do you have the CA food handlers certification? We..."
            ))
        } else if candidate.name == "Abdi Hassan" {
            items.append(ProfileTimelineItem(
                id: "text",
                title: "Natalie Sung sent a text message",
                time: "1 day ago",
                actorInitials: "NS",
                deliveryStatus: "Not delivered",
                deliveryFailed: true,
                previewText: "Dear Rachael, thank you for applying for the Barista position. Just a clarification: do you have the CA food handlers certification? We...",
                failedReason: "You have reached the limit of conversations with this candidate.",
                sentViaWhatsApp: true
            ))
        } else if showTextMessageTimeline {
            let isWhatsApp = whatsAppEnabled && candidate.name == "Emma Clark"
            items.append(ProfileTimelineItem(
                id: "text",
                title: "Natalie Sung sent a text message",
                time: "16 minutes ago",
                actorInitials: "NS",
                deliveryStatus: isWhatsApp ? "Read" : "Delivered",
                previewText: sentMessageText,
                sentViaWhatsApp: isWhatsApp
            ))
        }

        items.append(ProfileTimelineItem(id: "email", title: "Natalie Sung sent an email", time: "1 day ago", actorInitials: "NS"))
        return items
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                profileNavBar
                
                ScrollView {
                    VStack(spacing: 0) {
                        profileHeader

                        if isReviewingCandidate {
                            reviewingCandidateBanner
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }

                        if showsCandidateTimeline {
                            tabSwitcher

                            if selectedTab == 0 {
                                timelineContent
                            } else {
                                profileContent
                            }
                        } else {
                            profileContent
                        }
                    }
                }
                .background(AppColors.surface)
            }
            .background(AppColors.surface)
            
            if showProfileContactMenu || showOverflowActionMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            showProfileContactMenu = false
                            showOverflowActionMenu = false
                        }
                    }

                if showProfileContactMenu {
                    profileContactMenuPanel
                }

                if showOverflowActionMenu {
                    overflowActionMenuPanel
                }
            }
        }
        .sheet(isPresented: $showEmailTemplateSheet) {
            SelectTemplateSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showSendEmailConfirmation) {
            SendEmailConfirmationSheet(candidate: candidate) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showEmailTemplateSheet = true
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(10)
            .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showSendTextConfirmation) {
            SendTextConfirmationSheet(candidate: candidate, onSendText: performSendTextAction)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showTextMessageCompose) {
            ComposeTextMessageView(
                candidateName: candidate.name,
                candidatePhone: "+3069282893",
                onSend: { text in
                    sentMessageText = text
                    withAnimation { showTextMessageTimeline = true }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(10)
            .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView(candidateName: candidate.name, candidateRole: candidate.role)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showCreateEventConfirmation) {
            CreateEventConfirmationSheet(candidate: candidate) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showCreateEvent = true
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(10)
            .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showCandidateFitSheet) {
            CandidateFitView(candidate: candidate)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showMoveToJobConfirmation) {
            MoveToJobConfirmationSheet(candidate: candidate, onConfirm: {})
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
        .sheet(isPresented: $showDisqualifyConfirmation) {
            DisqualifyConfirmationSheet(candidate: candidate, onDisqualify: performDisqualifyAction)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
        .navigationDestination(isPresented: $showTextMessageDetail) {
            TextMessageDetailView(
                candidateName: candidate.name,
                candidateRole: candidate.role,
                candidateAvatar: candidate.avatarName ?? "avatar-emma",
                messageText: (candidate.name == "Tyler Anderson" || candidate.name == "Abdi Hassan") ? "Dear Rachael,\nthank you for applying for the Barista position. Just a clarification: do you have the CA food handlers certification? We would like to have a short call to schedule event you, are you available at 18.00 next Monday?\nYours sincerely,\nNatalie" : sentMessageText,
                deliveryFailed: candidate.name == "Tyler Anderson" || candidate.name == "Abdi Hassan",
                failedReason: candidate.name == "Abdi Hassan" ? "You have reached the limit of conversations with this candidate." : nil,
                sentViaWhatsApp: candidate.name == "Abdi Hassan" || candidate.name == "Tyler Anderson" || (whatsAppEnabled && candidate.name == "Emma Clark")
            )
        }
        .navigationDestination(isPresented: $showAgentCommentDetail) {
            AgentCommentDetailView(
                candidateName: candidate.name,
                candidateRole: candidate.role,
                candidateAvatar: candidate.avatarName ?? "avatar-emma"
            )
        }
        .alert("WhatsApp not available", isPresented: $showWhatsAppNotAvailable) {
            if candidate.name == "Liam Foster" {
                Button("Cancel", role: .cancel) {}
                Button("Send SMS") { performSendTextAction() }
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            if candidate.name == "Liam Foster" {
                Text("The WhatsApp integration needs attention, support team is working on it. You can still message this candidate by SMS.")
            } else {
                Text("The WhatsApp integration needs attention, support team is working on it.")
            }
        }
        .onAppear {
            if shouldAutoStartFitEvaluation {
                shouldAutoStartFitEvaluation = false
                startFitEvaluation()
            }
        }
    }

    private func performDisqualifyAction() {
        // TODO: Wire disqualify API / navigation when available.
    }

    private func performMoveToJobAction() {
        // TODO: Wire move-to-job API / navigation when available.
    }

    @State private var showTextMessageCompose = false

    private func performSendTextAction() {
        showTextMessageCompose = true
    }
    
    // MARK: - Nav Bar
    
    private var profileNavBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .regular))
                    Text("Back")
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.41)
                }
                .foregroundColor(AppColors.primaryDark)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            HStack(spacing: 24) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showOverflowActionMenu = false
                        showProfileContactMenu.toggle()
                    }
                } label: {
                    Image("icon-person-lines")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(AppColors.primaryDark)
                        .padding(14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showProfileContactMenu = false
                        showOverflowActionMenu.toggle()
                    }
                } label: {
                    Image("icon-menu-dots-horizontal")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(AppColors.primaryDark)
                        .padding(14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 30)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(AppColors.surface)
    }

    private var profileContactMenuPanel: some View {
        VStack(spacing: 0) {
            ForEach(Array(ProfileContactAction.allCases.enumerated()), id: \.offset) { index, action in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showProfileContactMenu = false
                    }
                    switch action {
                    case .sendEmail:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if hideAgentConfirmations {
                                showEmailTemplateSheet = true
                            } else {
                                showSendEmailConfirmation = true
                            }
                        }
                    case .sendText:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if candidate.name == "Liam Foster" || candidate.name == "Lucy Anderson" {
                                showWhatsAppNotAvailable = true
                            } else if hideAgentConfirmations {
                                performSendTextAction()
                            } else {
                                showSendTextConfirmation = true
                            }
                        }
                    case .createEvent:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if hideAgentConfirmations {
                                showCreateEvent = true
                            } else {
                                showCreateEventConfirmation = true
                            }
                        }
                    default:
                        break
                    }
                } label: {
                    HStack {
                        Text(action == .sendText && (whatsAppEnabled && candidate.name == "Emma Clark" || candidate.name == "Liam Foster" || candidate.name == "Lucy Anderson") ? "Send text message" : action.label)
                            .font(.system(size: 17, weight: .regular))
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontDefault)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        if action == .sendText && (whatsAppEnabled && candidate.name == "Emma Clark" || candidate.name == "Liam Foster" || candidate.name == "Lucy Anderson") {
                            Image("icon-whatsapp")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        } else if action == .sendText {
                            Image("icon-sms")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: action.icon)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.iconDefault)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < ProfileContactAction.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 0.5)
                }
            }
        }
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 22, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .frame(width: 240)
        .padding(.top, 50)
        .padding(.trailing, 16)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity),
            removal: .scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity)
        ))
    }

    private var overflowActionMenuPanel: some View {
        VStack(spacing: 0) {
            ForEach(Array(OverflowMenuAction.allCases.enumerated()), id: \.offset) { index, action in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showOverflowActionMenu = false
                    }
                    switch action {
                    case .moveToJob:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if hideAgentConfirmations {
                                performMoveToJobAction()
                            } else {
                                showMoveToJobConfirmation = true
                            }
                        }
                    case .disqualify:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if hideAgentConfirmations {
                                performDisqualifyAction()
                            } else {
                                showDisqualifyConfirmation = true
                            }
                        }
                    default:
                        break
                    }
                } label: {
                    HStack {
                        Text(action.label)
                            .font(.system(size: 17, weight: .regular))
                            .tracking(-0.41)
                            .foregroundColor(action.isDestructive ? AppColors.dangerDefault : AppColors.fontDefault)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Image(systemName: action.icon)
                            .font(.system(size: 16))
                            .foregroundColor(action.isDestructive ? AppColors.dangerDefault : AppColors.iconDefault)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < OverflowMenuAction.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 0.5)
                }
            }
        }
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 22, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .fixedSize(horizontal: true, vertical: false)
        .padding(.top, 50)
        .padding(.trailing, 16)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity),
            removal: .scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity)
        ))
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 8) {
            profileAvatar
                .opacity(isReviewingCandidate ? 0.8 : 1.0)
                .padding(.bottom, 4)
            
            VStack(spacing: 2) {
                Text(candidate.name)
                    .font(.system(size: 28, weight: .regular, design: .default))
                    .tracking(0.36)
                    .foregroundColor(AppColors.fontDefault)
                    .multilineTextAlignment(.center)
                
                Text(candidate.role)
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 4) {
                Text(jobAndStage)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
                    .multilineTextAlignment(.center)
                
                if let tags = candidate.tags, !tags.isEmpty {
                    Text(tags)
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.primaryDark)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
    }
    
    private var profileAvatar: some View {
        Group {
            if let name = candidate.avatarName, !name.isEmpty {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(hex: "E8E8ED")
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.iconDefault)
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
    }
    
    private var jobAndStage: String {
        let parts = candidate.stageInfo.components(separatedBy: " · ")
        let stage = parts.first ?? candidate.stageInfo
        return "Software Engineer · \(stage.replacingOccurrences(of: " stage", with: ""))"
    }
    
    // MARK: - Tab Switcher
    
    private var tabSwitcher: some View {
        Picker("", selection: $selectedTab) {
            Text("Timeline").tag(0)
            Text("Profile").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)

            ForEach(profileTimelineItems) { item in
                if item.id == "text" {
                    Button { showTextMessageDetail = true } label: {
                        profileTimelineRow(item: item)
                    }
                    .buttonStyle(.plain)
                } else if item.id == "agent-comment" {
                    Button { showAgentCommentDetail = true } label: {
                        profileTimelineRow(item: item)
                    }
                    .buttonStyle(.plain)
                } else {
                    profileTimelineRow(item: item)
                }

                Rectangle()
                    .fill(AppColors.separator)
                    .frame(height: 1)
            }
        }
    }
    
    private func profileTimelineRow(item: ProfileTimelineItem) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Circle()
                .fill(AppColors.informativeDefault)
                .frame(width: 6, height: 6)
                .padding(.leading, 6)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(AppFonts.headline())
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontDefault)

                        HStack(spacing: 4) {
                            Text(item.time)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontSecondary)

                            if let status = item.deliveryStatus {
                                if item.deliveryFailed {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.dangerDefault)
                                    Text(status)
                                        .font(AppFonts.subheadline())
                                        .tracking(-0.24)
                                        .foregroundColor(AppColors.dangerDefault)
                                } else {
                                    Text("·")
                                        .font(AppFonts.subheadline())
                                        .foregroundColor(AppColors.fontSecondary)
                                    Image("icon-delivered")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                    Text(status)
                                        .font(AppFonts.subheadline())
                                        .tracking(-0.24)
                                        .foregroundColor(AppColors.fontSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if item.usesAIAgentAvatar {
                        Image("icon-ai-agent")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } else if let avatar = item.actorAvatar {
                        Image(avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(hex: "8A8986"))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(item.actorInitials)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }

                if let preview = item.previewText {
                    Text(preview)
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                }
            }
            .padding(.leading, 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // MARK: - Profile Content
    
    private var profileContent: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)

            candidateFitSection

            profileSectionRow(title: "Email", value: "Not available yet")
            profileDivider
            profileSectionRow(title: "Phone", value: "Not available yet")
            profileDivider
            profileSectionRow(title: "Source", value: candidate.source)
            profileDivider
            
            if let location = candidate.location, !location.isEmpty {
                profileSectionRow(title: "Location", value: location)
                profileDivider
            }
            
            if let tags = candidate.tags, !tags.isEmpty {
                profileSectionRow(title: "Tags", value: tags)
                profileDivider
            }
            
            profileSectionRow(title: "Role", value: candidate.role)
            profileDivider
            profileSectionRow(title: "Stage", value: candidate.stageInfo)
            
            Rectangle()
                .fill(Color.clear)
                .frame(height: 32)
        }
    }

    private var candidateFitSection: some View {
        Group {
            if let fitScore = generatedMatchScore {
                CandidateFitProfileBanner(
                    matchScore: fitScore,
                    missingMustHaves: generatedMissingMustHaves ?? 2,
                    onOpenDetails: { showCandidateFitSheet = true }
                )
                .accessibilityHint("Score opens full fit. Chevron expands or collapses the summary.")
            } else if isEvaluatingFit {
                evaluatingBanner
            } else {
                startEvaluationBanner
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var isReviewingCandidate: Bool {
        candidate.agentIsReviewing || candidate.fitEvaluationInProgress
    }

    private struct AgentBannerState: Identifiable {
        let id: Int
        let boldPrefix: String
        let body: String
    }

    private let agentBannerStates: [AgentBannerState] = [
        AgentBannerState(id: 0, boldPrefix: "Agent is active: ", body: "Waiting for reply on interest email. Expires in 6 days, 2 days until follow up."),
        AgentBannerState(id: 1, boldPrefix: "Agent is active: ", body: "Waiting for reply about missing details. Expires in 6 days, 2 days until follow up."),
        AgentBannerState(id: 2, boldPrefix: "Agent is active: ", body: "Waiting for reply to follow-up email. Expires in 6 days, 2 days until follow up."),
        AgentBannerState(id: 3, boldPrefix: "Agent is active: ", body: "Waiting for reply to follow-up email. Expires in 6 days, 2 days until chat initiation."),
        AgentBannerState(id: 4, boldPrefix: "Agent status: ", body: "Chat in progress. Expires in 6 days."),
        AgentBannerState(id: 5, boldPrefix: "Agent review completed: ", body: "Candidate requests human communication"),
    ]

    @State private var agentBannerIndex = 0

    private var reviewingCandidateBanner: some View {
        let state = agentBannerStates[agentBannerIndex]
        return VStack(alignment: .leading, spacing: 10) {
            (Text(state.boldPrefix)
                .font(AppFonts.subheadStrong())
            + Text(state.body)
                .font(AppFonts.subheadline()))
                .tracking(-0.24)
                .foregroundColor(AppColors.fontDefault)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.informativeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                agentBannerIndex = (agentBannerIndex + 1) % agentBannerStates.count
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if value.translation.width < 0 {
                            agentBannerIndex = min(agentBannerIndex + 1, agentBannerStates.count - 1)
                        } else if value.translation.width > 0 {
                            agentBannerIndex = max(agentBannerIndex - 1, 0)
                        }
                    }
                }
        )
    }

    private var startEvaluationBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text("Candidate fit")
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)

                Spacer(minLength: 8)

                Text("?")
                    .font(AppFonts.caption1Strong())
                    .foregroundColor(AppColors.fontSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.background)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 12)

            Text("The Agent hasn't evaluated this candidate. Start processing candidates and discover who's the best fit for this role.")
                .font(AppFonts.subheadline())
                .tracking(-0.24)
                .foregroundColor(AppColors.fontSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)

            Button {
                startFitEvaluation()
            } label: {
                Text("Start evaluation")
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(AppColors.surface)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 4)
    }

    private var evaluatingBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(AppColors.primaryDark)
                Text("Evaluating candidate fit...")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.fontDefault)
            }

            Text("We are analyzing must-haves and profile strengths.")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 4)
    }

    private func startFitEvaluation() {
        guard !isEvaluatingFit else { return }
        isEvaluatingFit = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            generatedMatchScore = 70
            generatedMissingMustHaves = generatedMissingMustHaves ?? 2
            isEvaluatingFit = false
        }
    }
    
    private var profileDivider: some View {
        Rectangle()
            .fill(AppColors.separator)
            .frame(height: 1)
            .padding(.leading, 16)
    }
    
    private func profileSectionRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontSecondary)
            Text(value)
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Select Template Sheet

private struct SelectTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: String? = nil
    @State private var showCompose = false
    
    private let templates = [
        "Compose new email",
        "Main template",
        "Candidate template"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            templateSheetNavBar
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(templates.enumerated()), id: \.element) { index, template in
                        if index > 0 {
                            Color.clear.frame(height: 24)
                        }
                        templateRow(template: template)
                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                    }
                }
                .padding(.top, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface)
        .sheet(isPresented: $showCompose) {
            ComposeEmailView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
    }
    
    /// Figma `14969:341585` — Cancel + centered title + invisible trailing balance.
    private var templateSheetNavBar: some View {
        ZStack {
            Text("Select template")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
            
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.41)
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 0)
                
                Text("Cancel")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.primaryDark)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }
    
    private func templateRow(template: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTemplate = template
            }
            if template == "Compose new email" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showCompose = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primaryDark)
                    .opacity(selectedTemplate == template ? 1 : 0)
                    .frame(width: 16, height: 16)
                
                Text(template)
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 52, alignment: .center)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compose Email View

private struct ComposeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var toField = "c.sawyers@gmail.com"
    @State private var ccField = "adeline.law@gmail.com"
    @State private var subjectField = "Self schedule template"
    @State private var bodyText = "Hello Cindy,\n\nPlease complete the following \n\nBest,\nNatalie."
    @State private var showAttachMenu = false
    @State private var showSelfSchedule = false
    @FocusState private var isBodyFocused: Bool
    
    
    var body: some View {
        VStack(spacing: 0) {
            composeEmailNavBar
            
            ZStack {
                VStack(spacing: 0) {
                    emailHeaderRow(label: "To:", text: $toField, warmBackground: true)
                    emailHeaderRow(label: "Cc:", text: $ccField, warmBackground: true)
                    emailHeaderRow(label: "Re:", text: $subjectField, warmBackground: false)
                    
                    TextEditor(text: $bodyText)
                        .font(.system(size: 15, weight: .regular))
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontDefault)
                        .focused($isBodyFocused)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .scrollContentBackground(.hidden)
                        .background(AppColors.surface)
                    
                    visibleToFooter
                }
                .background(AppColors.surface)
                
                if showAttachMenu {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                showAttachMenu = false
                            }
                        }
                }
                
                if showAttachMenu {
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom) {
                            Spacer()
                            AttachmentContextMenu { label in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    showAttachMenu = false
                                }
                                if label == "Self-schedule link" {
                                    DispatchQueue.main.async {
                                        showSelfSchedule = true
                                    }
                                }
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 58)
                        }
                    }
                    .transition(
                        .scale(scale: 0.96, anchor: .bottomTrailing)
                            .combined(with: .opacity)
                    )
                    .allowsHitTesting(true)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showAttachMenu)
        }
        .onAppear { isBodyFocused = true }
        .sheet(isPresented: $showSelfSchedule) {
            SelfScheduleView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
    }
    
    /// Inline nav (Figma `14976:72145`) — avoids system toolbar glass/shadow on sheet actions.
    private var composeEmailNavBar: some View {
        ZStack {
            Text("Email")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.oxfordBlue)
            
            HStack(alignment: .center) {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.primaryDark)
                    .buttonStyle(.plain)
                
                Spacer(minLength: 0)
                
                Button("Send") {}
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.primary)
                    .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }
    
    /// Figma `14976:72147` / `72151` / `72155` — 13pt rows, 9pt gap, `py-12`; To/Cc on `background`, Re on white.
    private func emailHeaderRow(label: String, text: Binding<String>, warmBackground: Bool) -> some View {
        HStack(alignment: .center, spacing: 9) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .tracking(-0.08)
                .foregroundColor(AppColors.fontSecondary)
            
            TextField("", text: text)
                .font(.system(size: 13, weight: .regular))
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(warmBackground ? AppColors.background : AppColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }
    
    /// Figma `14976:72159` — border-top, 16/8 padding, vertical rule + 16px add.
    private var visibleToFooter: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Visible to")
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontSecondary)
                
                Text("Hiring Managers, Standard Members")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill(AppColors.separator)
                .frame(width: 1, height: 33)
            
            Button {
                isBodyFocused = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    showAttachMenu = true
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }
}

// MARK: - Attachment context menu (Figma `14976:71674`)

private struct AttachmentContextMenu: View {
    let onSelect: (String) -> Void

    private let actions: [(label: String, icon: String)] = [
        ("Survey", "doc.on.clipboard"),
        ("File", "icloud.and.arrow.up"),
        ("Self-schedule link", "clock")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, item in
                Button {
                    onSelect(item.label)
                } label: {
                    HStack(alignment: .center, spacing: 8) {
                        Text(item.label)
                            .font(.system(size: 17, weight: .regular))
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontDefault)
                        Spacer(minLength: 0)
                        Image(systemName: item.icon)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.iconDefault)
                            .frame(width: 16, height: 16)
                    }
                    .padding(.horizontal, 16)
                    .frame(width: 199, height: 48, alignment: .center)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < actions.count - 1 {
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                }
            }
        }
        .frame(width: 199)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Plain text field (no UITextField underline / border)

private struct SchedulePlainTextField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.backgroundColor = .clear
        tf.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        tf.textColor = .label
        tf.adjustsFontForContentSizeCategory = true
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: SchedulePlainTextField

        init(_ parent: SchedulePlainTextField) {
            self.parent = parent
        }

        @objc func editingChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }
    }
}

/// Read-only schedule row value: UIKit avoids SwiftUI data-detector underlines on times, dates, etc.
private struct SchedulePlainLabel: UIViewRepresentable {
    var text: String

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.isUserInteractionEnabled = false
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .kern: -0.41
        ]
        uiView.attributedText = NSAttributedString(string: text, attributes: attrs)
    }
}

// MARK: - Self-Schedule View

private struct SelfScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventType = "Interview"
    @State private var eventDuration = "30min"
    @State private var bufferDuration = "None"
    @State private var setDurationDefault = false
    @State private var firstAvailableDate = "Tomorrow"
    @State private var lastAvailableDate = "2 weeks"
    @State private var rescheduling = true
    @State private var linkName = "self-schedule link"
    @State private var includeGoogleMeet = true
    @State private var includeZoom = false
    @State private var visibilityInCalendar = "Use default settings"
    @State private var showVisibilitySheet = false
    @State private var personalAvailability = "Mon, Wed · 09:00-17:00"
    
    /// Vertical space between stacked rows inside a schedule card (link / event).
    private static let cardRowSpacingLarge: CGFloat = 24
    private static let cardRowSpacingMedium: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 0) {
            selfScheduleNavBar
            
            ScrollView {
                VStack(spacing: 16) {
                    infoBanner
                    interviewerCard
                    eventCard
                    availableDatesCard
                    reschedulingCard
                    linkAndTogglesCard
                    personalAvailabilityCard
                    Spacer().frame(height: 28)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(AppColors.surface)
        .sheet(isPresented: $showVisibilitySheet) {
            VisibilitySheet(selected: $visibilityInCalendar)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(AppColors.surface)
        }
    }
    
    /// Figma `25363:101403` — same chrome as Email / Select template sheets.
    private var selfScheduleNavBar: some View {
        ZStack {
            Text("Self-schedule link")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
            
            HStack(alignment: .center) {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.41)
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 0)
                
                Button {} label: {
                    Text("Create")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.41)
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }
    
    // MARK: - Card wrapper
    
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceDarker)
        .cornerRadius(16)
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        Text("The availability of the chosen calendar will be visible to Cindy Sawyers through this link.")
            .font(AppFonts.subheadline())
            .tracking(-0.24)
            .foregroundColor(AppColors.fontDefault)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.informativeBackground)
            .cornerRadius(16)
    }
    
    // MARK: - Interviewer Card
    
    private var interviewerCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Interviewer")
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "8A8986"))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("NS")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Natalie Sung")
                            .font(AppFonts.headline())
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontDefault)
                        Text(verbatim: "natalie.sung@spotify.com")
                            .font(AppFonts.subheadline())
                            .tracking(-0.24)
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.iconInactive)
                }
            }
        }
    }
    
    // MARK: - Event Card (type + duration + buffer + toggle)
    
    private var eventCard: some View {
        card {
            twoColumnField(
                leftLabel: "Event type", leftValue: eventType,
                rightLabel: "Event duration", rightValue: eventDuration
            )
            
            fieldWithArrow(label: "Buffer duration", value: bufferDuration)
                .padding(.top, Self.cardRowSpacingLarge)
            
            Text("Add time after your event to prepare or take a break.")
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontSecondary)
                .padding(.top, 12)
            
            HStack {
                Text("Set this duration as my default")
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Toggle("", isOn: $setDurationDefault)
                    .labelsHidden()
                    .tint(AppColors.successDefault)
            }
            .padding(.top, Self.cardRowSpacingMedium)
        }
    }
    
    // MARK: - Available Dates Card
    
    private var availableDatesCard: some View {
        card {
            twoColumnField(
                leftLabel: "First available date", leftValue: firstAvailableDate,
                rightLabel: "Last available date", rightValue: lastAvailableDate
            )
        }
    }
    
    // MARK: - Rescheduling Card
    
    private var reschedulingCard: some View {
        card {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Rescheduling")
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                    Spacer()
                    Toggle("", isOn: $rescheduling)
                        .labelsHidden()
                        .tint(AppColors.successDefault)
                }
                
                Text("Candidates can reschedule anytime")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.primaryDark)
            }
        }
    }
    
    // MARK: - Link + Toggles + Visibility Card
    
    private var linkAndTogglesCard: some View {
        card {
            inputField(label: "Link name", text: $linkName)
                .padding(.bottom, Self.cardRowSpacingLarge)
            
            HStack {
                Text("Include Google Meet link")
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Toggle("", isOn: $includeGoogleMeet)
                    .labelsHidden()
                    .tint(AppColors.successDefault)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include Zoom link")
                            .font(AppFonts.body())
                            .tracking(-0.41)
                            .foregroundColor(AppColors.fontDefault)
                        Text("Meeting hosted by the interviewer")
                            .font(AppFonts.footnote())
                            .tracking(-0.08)
                            .foregroundColor(AppColors.fontSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $includeZoom)
                        .labelsHidden()
                        .tint(AppColors.successDefault)
                }
            }
            .padding(.top, Self.cardRowSpacingMedium)
            
            fieldWithArrow(label: "Visibility in calendar", value: visibilityInCalendar)
                .contentShape(Rectangle())
                .onTapGesture { showVisibilitySheet = true }
                .accessibilityAddTraits(.isButton)
                .padding(.top, Self.cardRowSpacingLarge)
        }
    }
    
    // MARK: - Personal Availability Card
    
    private var personalAvailabilityCard: some View {
        card {
            fieldWithArrow(label: "Personal availability", value: personalAvailability)
        }
    }
    
    // MARK: - Reusable Field Helpers
    
    /// Full-width hairline under schedule value rows (matches reference screenshots).
    private var scheduleFieldStroke: some View {
        Rectangle()
            .fill(AppColors.iconInactive)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
    
    private func scheduleValueWithTrailingChevron(_ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                SchedulePlainLabel(text: value)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.iconInactive)
            }
            scheduleFieldStroke
        }
    }
    
    private func fieldWithArrow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: label)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 0) {
                    SchedulePlainLabel(text: value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.iconInactive)
                }
                scheduleFieldStroke
            }
        }
    }
    
    private func twoColumnField(leftLabel: String, leftValue: String, rightLabel: String, rightValue: String) -> some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: leftLabel)
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                scheduleValueWithTrailingChevron(leftValue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: rightLabel)
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                scheduleValueWithTrailingChevron(rightValue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func inputField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: label)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
            
            SchedulePlainTextField(text: text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 22)
            
            scheduleFieldStroke
        }
    }
}

// MARK: - Visibility in Calendar Sheet

private struct VisibilitySheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss
    
    private let options: [(title: String, description: String)] = [
        (title: "Use default settings", description: "Follows the visibility rules set in your Google Calendar."),
        (title: "Private", description: "Only attendees can see event details.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Visibility in calendar")
                .font(AppFonts.headline())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
            
            ForEach(Array(options.enumerated()), id: \.element.title) { index, option in
                Button {
                    selected = option.title
                    dismiss()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.fontDefault)
                            .frame(width: 16)
                            .padding(.top, 3)
                            .opacity(selected == option.title ? 1 : 0)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: option.title)
                                .font(AppFonts.body())
                                .tracking(-0.41)
                                .foregroundColor(AppColors.fontDefault)
                            
                            Text(verbatim: option.description)
                                .font(AppFonts.subheadline())
                                .tracking(-0.24)
                                .foregroundColor(AppColors.fontSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if index < options.count - 1 {
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                        .padding(.leading, 44)
                }
            }
            
            Spacer()
        }
        .background(AppColors.surface)
    }
}

// MARK: - Create Event View

private struct CreateEventView: View {
    let candidateName: String
    let candidateRole: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventType = "Interview"
    @State private var subject: String
    @State private var date = "18/03/2020"
    @State private var startTime = "10:30 AM"
    @State private var endTime = "11:00 AM"
    @State private var timezone = "Athens (GMT +02:00)"
    @State private var includeGoogleMeet = false
    @State private var includeZoom = false
    @State private var visibility = "Use default settings"
    @State private var organizer = "Natalie Sung"
    @State private var location = ""
    @State private var descriptionText = ""
    @State private var showVisibilitySheet = false
    
    init(candidateName: String, candidateRole: String) {
        self.candidateName = candidateName
        self.candidateRole = candidateRole
        _subject = State(initialValue: "Interview with \(candidateName) - \(candidateRole)")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            createEventNavBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    fieldWithUnderline(label: "Type of event", value: eventType)
                    inputWithUnderline(label: "Subject", text: $subject)
                    attendeesAndRoomSection
                    fieldWithUnderline(label: "Date", value: date)
                    timeRow
                    fieldWithUnderline(label: "Timezone", value: timezone)
                    callLinkSection
                    navFieldWithUnderline(label: "Visibility in calendar", value: visibility) {
                        showVisibilitySheet = true
                    }
                    navFieldWithUnderline(label: "Location", value: location.isEmpty ? "Add location" : location, isTeal: location.isEmpty) {}
                    descriptionField
                    fieldWithUnderline(label: "Organizer", value: organizer)
                    Spacer().frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(AppColors.surface)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface)
        .sheet(isPresented: $showVisibilitySheet) {
            VisibilitySheet(selected: $visibility)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(AppColors.surface)
        }
    }
    
    /// Figma `25363:101403` — matches Self-schedule / Email sheet nav (no system toolbar glass).
    private var createEventNavBar: some View {
        ZStack {
            Text("New event")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
            
            HStack(alignment: .center) {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.primaryDark)
                    .buttonStyle(.plain)
                
                Spacer(minLength: 0)
                
                Button("Create") {}
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.primaryDark)
                    .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }
    
    // MARK: - Field Helpers
    
    private var underline: some View {
        Rectangle()
            .fill(AppColors.iconInactive)
            .frame(height: 1)
    }
    
    private func fieldWithUnderline(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: label)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
            HStack(alignment: .center, spacing: 0) {
                Text(verbatim: value)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.iconInactive)
            }
            underline
        }
    }
    
    private func inputWithUnderline(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
            TextField("", text: text)
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
            underline
        }
    }
    
    private func navFieldWithUnderline(label: String, value: String, isTeal: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                HStack {
                    Text(value)
                        .font(isTeal ? AppFonts.headline() : AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(isTeal ? AppColors.primary : AppColors.fontDefault)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.iconInactive)
                }
                underline
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Attendees & Room
    
    /// Matches stacked attendee avatar diameter so Room row shares the same band height and underlines align.
    private static let attendeesRoomValueRowHeight: CGFloat = 30
    
    private var attendeesAndRoomSection: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Attendees")
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: -6) {
                        Circle()
                            .fill(Color(hex: "8A8986"))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("NS")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                        Circle()
                            .fill(Color(hex: "636D77"))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("AL")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(AppColors.surface, lineWidth: 2))
                        Circle()
                            .fill(Color(hex: "BFE4F5"))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.fontDefault)
                            )
                            .overlay(Circle().stroke(AppColors.surface, lineWidth: 2))
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.iconInactive)
                        .padding(.leading, 12)
                }
                .frame(minHeight: Self.attendeesRoomValueRowHeight, alignment: .center)
                underline
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Room")
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                HStack(alignment: .center, spacing: 4) {
                    Text("Add room")
                        .font(AppFonts.headline())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.primary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.iconInactive)
                }
                .frame(minHeight: Self.attendeesRoomValueRowHeight, alignment: .center)
                underline
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Time Row
    
    private var timeRow: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Start time")
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                HStack(spacing: 4) {
                    Text(startTime)
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.iconInactive)
                }
                underline
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("End time")
                    .font(AppFonts.footnote())
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontDefault)
                HStack(spacing: 4) {
                    Text(endTime)
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.iconInactive)
                }
                underline
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Call Link Section
    
    private var callLinkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Call link")
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
            
            HStack {
                Text("Include Google Meet link")
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Spacer()
                Toggle("", isOn: $includeGoogleMeet)
                    .labelsHidden()
                    .tint(AppColors.successDefault)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Include Zoom link")
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                    Text("Meeting hosted by the organizer")
                        .font(AppFonts.footnote())
                        .tracking(-0.08)
                        .foregroundColor(AppColors.iconDefault)
                }
                Spacer()
                Toggle("", isOn: $includeZoom)
                    .labelsHidden()
                    .tint(AppColors.successDefault)
            }
        }
    }
    
    // MARK: - Description Field
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .font(AppFonts.footnote())
                .tracking(-0.08)
                .foregroundColor(AppColors.fontDefault)
            HStack {
                if descriptionText.isEmpty {
                    Text("Add description")
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontSecondary)
                } else {
                    TextField("", text: $descriptionText)
                        .font(AppFonts.body())
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.iconInactive)
            }
            underline
        }
    }
}
