import SwiftUI

/// First-step confirmation for Send text action.
struct SendTextConfirmationSheet: View {
    static let suppressConfirmationAppStorageKey = "candidateProfile.suppressSendTextAgentConfirmation"

    let candidate: Candidate
    var onSendText: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(Self.suppressConfirmationAppStorageKey) private var suppressConfirmation: Bool = false
    @State private var dontShowAgain = false
    @State private var showFollowUp = false

    private var candidateFirstName: String {
        let trimmed = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(separator: " ", omittingEmptySubsequences: true).first else {
            return trimmed
        }
        return String(first)
    }

    private var explanation: String {
        "Sending a text from here means the AI agent will stop for \(candidateFirstName), and you will take over communication with this candidate."
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        warningIllustration
                            .padding(.bottom, 24)

                        Text("Send text and take over")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.fontDefault)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)

                        Text(explanation)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.fontSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 36)

                        ConfirmationSheetFitBanner(candidate: candidate)
                            .padding(.horizontal, 16)
                    }
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(AppColors.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.primaryDark)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionBar
                    .background(AppColors.surface)
            }
        }
    }

    private var warningIllustration: some View {
        ZStack {
            Circle()
                .fill(AppColors.warningBadge)
                .frame(width: 76, height: 63)
                .blur(radius: 14)
                .opacity(0.6)

            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 52, height: 52)

            Text("!")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(AppColors.warningDefault)
        }
        .frame(width: 140, height: 140)
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 36) {
                HStack(spacing: 8) {
                    Text("Don\u{2019}t show this again")
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                    Toggle("", isOn: $dontShowAgain)
                        .labelsHidden()
                        .tint(AppColors.successDefault)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                primaryButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [AppColors.surface.opacity(0), AppColors.surface],
                startPoint: .top,
                endPoint: .center
            )
        )
    }

    private var primaryButton: some View {
        Button {
            if dontShowAgain { suppressConfirmation = true }
            onSendText()
            dismiss()
        } label: {
            Text("Text & take over")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.primaryDark)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .background(AppColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.primaryDark, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .buttonStyle(.plain)
    }
}

#Preview {
    SendTextConfirmationSheet(
        candidate: Candidate(
            name: "Rachael",
            role: "Designer",
            stageInfo: "Applied stage",
            avatarName: nil
        ),
        onSendText: {}
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.hidden)
    .presentationBackground(AppColors.surface)
}
