import SwiftUI

/// Confirmation when disqualifying while the agent is active (Figma `27653:127104`).
struct DisqualifyConfirmationSheet: View {
    /// `UserDefaults` / `@AppStorage` key: when `true`, skip this sheet on future Disqualify taps (after user confirms once with “Don’t show this again” on).
    static let suppressConfirmationAppStorageKey = "candidateProfile.suppressDisqualifyAgentConfirmation"

    let candidate: Candidate
    var onDisqualify: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(Self.suppressConfirmationAppStorageKey) private var suppressConfirmation: Bool = false
    @State private var dontShowAgain = false
    @State private var showFollowUp = false

    private var explanation: String {
        "The Agent will stop for this candidate. You\u{2019}ll take over communication and any further actions. Any links already sent will keep working."
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        warningIllustration
                            .padding(.bottom, 24)

                        Text("Disqualify candidate and take over")
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

                        candidateFitCard
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
            .onAppear { dontShowAgain = false }
            .sheet(isPresented: $showFollowUp) {
                DisqualificationReasonSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(10)
                    .presentationBackground(AppColors.surface)
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

    private var candidateFitCard: some View {
        ConfirmationSheetFitBanner(candidate: candidate)
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 36) {
                // Figma `27653:127103` — subhead label #8A8986, 8pt gap, switch tint success green.
                HStack(spacing: 8) {
                    Text("Don\u{2019}t show this again")
                        .font(AppFonts.subheadline())
                        .tracking(-0.24)
                        .foregroundColor(AppColors.fontSecondary)
                        .multilineTextAlignment(.center)

                    Toggle("", isOn: $dontShowAgain)
                        .labelsHidden()
                        .accessibilityLabel("Don\u{2019}t show this again")
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
            showFollowUp = true
        } label: {
            Text("Disqualify & take over")
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
    DisqualifyConfirmationSheet(
        candidate: Candidate(
            name: "Rachael",
            role: "Designer",
            stageInfo: "Applied stage",
            avatarName: nil
        ),
        onDisqualify: {}
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.hidden)
    .presentationBackground(AppColors.surface)
}
