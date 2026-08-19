import SwiftUI

/// Figma 31619:215896 — Agent comment detail with “View chat”.
struct AgentCommentDetailView: View {
    let candidateName: String
    let candidateRole: String
    let candidateAvatar: String
    var commentTime: String = "16 minutes ago"

    @Environment(\.dismiss) private var dismiss
    @State private var showAgentChat = false

    private let commentBody = """
    The chat was terminated as “Completed”.

    Nice to meet you
    The candidate provided a salary expectation of 130k, and indicated they had no further questions or comments. They were concise and responsive throughout.
    """

    var body: some View {
        VStack(spacing: 0) {
            customNavBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    candidateHeader

                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)

                    commentSection

                    visibilityRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            Spacer(minLength: 0)

            viewChatBar
                // Sit above the floating tab bar (Figma 31619:215896).
                .padding(.bottom, TabBarView.menuTopFromBottom)
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showAgentChat) {
            AgentChatView(
                candidateName: candidateName,
                candidateAvatar: candidateAvatar
            )
        }
    }

    private var customNavBar: some View {
        HStack {
            GlassSymbolButton(
                systemName: "chevron.left",
                accessibilityLabel: "Back",
                action: { dismiss() }
            )

            Spacer()

            Text("Comment")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

            HStack(spacing: 12) {
                GlassSymbolButton(
                    systemName: "arrow.uturn.backward",
                    accessibilityLabel: "Undo",
                    action: {}
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private var candidateHeader: some View {
        HStack(spacing: 8) {
            Image(candidateAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(candidateName)
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)
                Text(candidateRole)
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Workable Agent says:")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)

                Spacer(minLength: 8)

                Text(commentTime)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontSecondary)
            }

            Text(commentBody)
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.oxfordBlue)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var visibilityRow: some View {
        HStack(spacing: 4) {
            Text("Visible to")
                .font(.system(size: 13, weight: .regular))
                .tracking(-0.08)
                .foregroundColor(AppColors.fontSecondary)
            Text("All hiring team")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.primaryDark)
            Spacer(minLength: 0)
        }
    }

    private var viewChatBar: some View {
        Button { showAgentChat = true } label: {
            Text("View chat")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.primaryDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .background(AppColors.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
        .accessibilityLabel("View chat")
    }
}
