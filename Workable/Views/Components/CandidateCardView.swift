import SwiftUI

struct CandidateCardView: View {
    let candidate: Candidate
    var onAvatarTap: (() -> Void)? = nil
    var onCardTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                AvatarWithScoreView(
                    matchScore: candidate.matchScore,
                    agentIsReviewing: candidate.agentIsReviewing,
                    imageName: candidate.avatarName,
                    avatarURL: candidate.avatarURL,
                    onTap: onAvatarTap
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                        .lineLimit(1)

                    Text(candidate.role)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.fontDefault)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let location = candidate.location, !location.isEmpty {
                        Text(location)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let tags = candidate.tags, !tags.isEmpty {
                        Text(tags)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.primaryDark)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    sourceView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { onCardTap?() }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(cardAccessibilityLabel)
                .accessibilityHint("Opens candidate profile")
            }
            
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
            
            Text(candidate.stageInfo)
                .font(AppFonts.footnote())
                .foregroundColor(AppColors.fontSecondary)
                .onTapGesture { onCardTap?() }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
    
    private var cardAccessibilityLabel: String {
        var parts = [candidate.name, candidate.role]
        if let location = candidate.location, !location.isEmpty { parts.append(location) }
        if let score = candidate.matchScore { parts.append("Match score: \(score) percent") }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var sourceView: some View {
        HStack(spacing: 2) {
            Text("via")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
            Text(candidate.source)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
        }
    }
}

struct AvatarWithScoreView: View {
    let matchScore: Int?
    var agentIsReviewing: Bool = false
    let imageName: String?
    let avatarURL: URL?
    var onTap: (() -> Void)?

    @State private var isPressed = false

    private let avatarSize: CGFloat = 50
    private let ringWidth: CGFloat = 2.5

    init(
        matchScore: Int?,
        agentIsReviewing: Bool = false,
        imageName: String? = nil,
        avatarURL: URL? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.matchScore = matchScore
        self.agentIsReviewing = agentIsReviewing
        self.imageName = imageName
        self.avatarURL = avatarURL
        self.onTap = onTap
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                ZStack {
                    // Track ring (light separator)
                    Circle()
                        .stroke(AppColors.separator, lineWidth: ringWidth)
                        .frame(width: avatarSize, height: avatarSize)

                    // Purple progress arc proportional to match score
                    if let score = matchScore {
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100)
                            .stroke(
                                AppColors.aiDefault.opacity(agentIsReviewing ? 0.38 : 1),
                                style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                            )
                            .frame(width: avatarSize, height: avatarSize)
                            .rotationEffect(.degrees(90))
                    }

                    if agentIsReviewing, matchScore != nil {
                        reviewingHaloShimmer(color: AppColors.aiDefault)
                    }

                    // Avatar image inset inside the ring
                    Group {
                        if let url = avatarURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    avatarPlaceholder
                                case .empty:
                                    ProgressView()
                                        .frame(width: avatarSize, height: avatarSize)
                                @unknown default:
                                    avatarPlaceholder
                                }
                            }
                        } else if let name = imageName, !name.isEmpty {
                            Image(name)
                                .resizable()
                                .scaledToFill()
                        } else {
                            avatarPlaceholder
                        }
                    }
                    .frame(width: avatarSize - ringWidth * 2 - 2,
                           height: avatarSize - ringWidth * 2 - 2)
                    .clipShape(Circle())
                }
                
                if let score = matchScore {
                    HStack(spacing: 0) {
                        Text("\(score)")
                            .font(AppFonts.caption1Strong())
                        Text("%")
                            .font(AppFonts.caption1())
                    }
                    .foregroundColor(AppColors.aiDefault)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(AppColors.aiBackground)
                    .cornerRadius(8)
                    .offset(y: 10)
                }
            }
        }
        .frame(width: avatarSize)
        .scaleEffect(isPressed ? 0.88 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    if matchScore != nil {
                        onTap?()
                    }
                }
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }

    private var accessibilityLabel: String {
        var base = matchScore.map { "Candidate fit: \($0) percent. Tap to view details." } ?? "View candidate fit"
        if agentIsReviewing { base += " Agent is reviewing." }
        return base
    }

    /// Travelling highlight on the halo while the agent is in the review step.
    private func reviewingHaloShimmer(color: Color) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0, paused: false)) { timeline in
            let period = 2.0
            let t = timeline.date.timeIntervalSinceReferenceDate
            let angleDegrees = (t.truncatingRemainder(dividingBy: period) / period) * 360.0
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: color.opacity(0.15), location: 0),
                            .init(color: color.opacity(0.45), location: 0.22),
                            .init(color: color, location: 0.42),
                            .init(color: color.opacity(0.45), location: 0.62),
                            .init(color: color.opacity(0.15), location: 1)
                        ]),
                        center: .center,
                        angle: .degrees(angleDegrees - 90)
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: avatarSize, height: avatarSize)
        }
    }
    
    private var avatarPlaceholder: some View {
        ZStack {
            Color(hex: "E8E8ED")
            Image(systemName: "person.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.iconDefault)
        }
    }
}
