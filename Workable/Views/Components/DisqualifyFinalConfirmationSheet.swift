import SwiftUI

/// Final irreversible confirmation in disqualify flow.
struct DisqualifyFinalConfirmationSheet: View {
    let candidate: Candidate
    var onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showReasonPicker = false

    private var candidateFirstName: String {
        let trimmed = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(separator: " ", omittingEmptySubsequences: true).first else {
            return trimmed
        }
        return String(first)
    }

    private var explanation: String {
        "\(candidateFirstName) will be disqualified and removed from active consideration in this job pipeline."
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        warningIllustration
                            .padding(.bottom, 24)

                        Text("Final confirmation")
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
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Go back")
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

                Button {
                    showReasonPicker = true
                } label: {
                    Text("Disqualify candidate")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.dangerDefault)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
                .background(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.dangerDefault, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .buttonStyle(.plain)
                .sheet(isPresented: $showReasonPicker) {
                    DisqualificationReasonSheet()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                        .presentationCornerRadius(10)
                        .presentationBackground(AppColors.surface)
                }
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
}

#Preview {
    DisqualifyFinalConfirmationSheet(
        candidate: Candidate(
            name: "Rachael",
            role: "Designer",
            stageInfo: "Applied stage",
            avatarName: nil
        ),
        onConfirm: {}
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.hidden)
    .presentationBackground(AppColors.surface)
}
