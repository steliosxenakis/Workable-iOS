import SwiftUI

/// Figma 31619:217261 / share 31627:247644 — Agent chat transcript with CV attachment.
struct AgentChatView: View {
    let candidateName: String
    let candidateAvatar: String

    @Environment(\.dismiss) private var dismiss
    @State private var sharePDFURL: URL?
    @State private var showsShareSheet = false

    private let cvFileName = "adlawrencecv.pdf"
    private let cvFileSizeLabel = "155 KB"

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
                body: "Here’s my CV.",
                attachmentName: cvFileName
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
        .sheet(isPresented: $showsShareSheet) {
            if let sharePDFURL {
                ActivityShareSheet(items: [sharePDFURL])
            }
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

            VStack(alignment: .leading, spacing: 10) {
                Text(message.body)
                    .font(AppFonts.body())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.oxfordBlue)
                    .fixedSize(horizontal: false, vertical: true)

                if let attachment = message.attachmentName {
                    attachmentCard(fileName: attachment, sizeLabel: cvFileSizeLabel)
                }
            }
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

    private func attachmentCard(fileName: String, sizeLabel: String) -> some View {
        Button { presentShareSheet() } label: {
            HStack(spacing: 8) {
                Text(fileName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primaryDark)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(sizeLabel)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.08)
                    .foregroundColor(AppColors.iconDefault)

                Image(systemName: "trash.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.iconDefault)
            }
            .padding(16)
            .background(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColors.iconInactive, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share \(fileName)")
    }

    private func presentShareSheet() {
        sharePDFURL = Self.ensureShareablePDF(named: cvFileName)
        showsShareSheet = sharePDFURL != nil
    }

    private static func ensureShareablePDF(named fileName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: url.path) {
            let placeholder = Data("%PDF-1.4\n% Workable prototype CV placeholder\n".utf8)
            try? placeholder.write(to: url, options: .atomic)
        }
        return url
    }

    private struct ChatMessage: Identifiable {
        let id: String
        let isAgent: Bool
        let senderName: String
        let timestamp: String
        let body: String
        var attachmentName: String? = nil
    }
}

/// UIKit share sheet wrapper for prototype PDF sharing.
private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
