import SwiftUI

/// Confirmation when moving a candidate who has an active agent (Figma `27642:63009`).
struct MoveToJobConfirmationSheet: View {
    let candidate: Candidate
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showFollowUp = false

    private var explanation: String {
        "This candidate has an active chat invitation from the AI agent. Moving them will remove their chat access and stop all agent actions for this candidate."
    }

    private var candidateFirstName: String {
        let trimmed = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(separator: " ", omittingEmptySubsequences: true).first else {
            return trimmed
        }
        return String(first)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        warningIllustration
                            .padding(.bottom, 24)

                        Text("Agent will stop for \(candidateFirstName)")
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
            .sheet(isPresented: $showFollowUp) {
                MoveToJobSecondaryFollowUpSheet(candidate: candidate) {
                    onConfirm()
                    dismiss()
                }
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
            VStack(spacing: 12) {
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

    @State private var showJobPicker = false

    private var primaryButton: some View {
        Button {
            showJobPicker = true
        } label: {
            Text("Move candidate & take over")
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
        .sheet(isPresented: $showJobPicker) {
            SelectJobSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(10)
                .presentationBackground(AppColors.surface)
        }
    }
}

#Preview {
    MoveToJobConfirmationSheet(
        candidate: Candidate(
            name: "Rachael",
            role: "Designer",
            stageInfo: "Applied stage",
            avatarName: nil
        ),
        onConfirm: {}
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .presentationBackground(AppColors.surface)
}
