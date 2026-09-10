import SwiftUI

/// Figma 31619:217261 — Agent chat transcript.
struct AgentChatView: View {
    let candidateName: String
    let candidateAvatar: String

    @Environment(\.dismiss) private var dismiss

    private var messages: [ChatMessage] {
        [
            ChatMessage(
                id: "1",
                isAgent: true,
                senderName: "Workable Agent",
                timestamp: "9:40 Aug 16, 2026",
                body: """
                Hi Rachel — hope you’re doing well. As mentioned earlier in the email, I reached out because we consider you a good candidate for the role of Lead Mobile QA Engineer at startrek. Note that everything you share here remains private and confidential.

                I already have some context from your profile. I’ll ask a few short questions to fill in any gaps and make sure we don’t make assumptions based on incomplete information. To start, do you have a recent resume you can share?
                """
            ),
            ChatMessage(
                id: "2",
                isAgent: false,
                senderName: candidateName,
                timestamp: "9:39 Aug 16, 2026",
                body: "Here’s my CV. I can send an updated version if that’s helpful."
            ),
            ChatMessage(
                id: "3",
                isAgent: true,
                senderName: "Workable Agent",
                timestamp: "9:30 Aug 16, 2026",
                body: "Have you worked with cloud platforms such as AWS, GCP, or Azure?"
            ),
            ChatMessage(
                id: "4",
                isAgent: false,
                senderName: candidateName,
                timestamp: "9:39 Aug 16, 2026",
                body: "Yes, I have experience with cloud platforms."
            ),
            ChatMessage(
                id: "5",
                isAgent: true,
                senderName: "Workable Agent",
                timestamp: "9:30 Aug 16, 2026",
                body: "Last question - are you open to hybrid work based in Athens?"
            ),
            ChatMessage(
                id: "6",
                isAgent: false,
                senderName: candidateName,
                timestamp: "9:41 Aug 16, 2026",
                body: "Yes, I’m open to hybrid work based in Athens."
            ),
            ChatMessage(
                id: "7",
                isAgent: true,
                senderName: "Workable Agent",
                timestamp: "9:42 Aug 16, 2026",
                body: "That’s all I needed — thanks for your time. I’ll share this with the hiring team and someone will follow up if there’s a next step."
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            customNavBar

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 15) {
                    ForEach(messages) { message in
                        chatRow(message)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, TabBarView.menuTopFromBottom + 24)
            }
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
    }

    private var customNavBar: some View {
        HStack {
            GlassSymbolButton(
                systemName: "chevron.left",
                accessibilityLabel: "Back",
                action: { dismiss() }
            )

            Spacer()

            Text("Agent chat")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

            // Balance back button so title stays centered.
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.surface)
    }

    private func chatRow(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                avatar(for: message)

                Text(message.senderName)
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)

                Spacer(minLength: 8)

                Text(message.timestamp)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.08)
                    .foregroundColor(AppColors.fontSecondary)
            }

            Text(message.body)
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.oxfordBlue)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 38)
        }
    }

    @ViewBuilder
    private func avatar(for message: ChatMessage) -> some View {
        if message.isAgent {
            Image("icon-ai-agent")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
        } else {
            Image(candidateAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
        }
    }

    private struct ChatMessage: Identifiable {
        let id: String
        let isAgent: Bool
        let senderName: String
        let timestamp: String
        let body: String
    }
}
