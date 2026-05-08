import SwiftUI

/// Agent activity banner shown inside confirmation/take-over sheets,
/// replacing the old Agent Status timeline card.
struct ConfirmationSheetFitBanner: View {
    let candidate: Candidate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("Agent is active: ")
                .font(AppFonts.subheadStrong())
            + Text("Waiting for reply on interest email. Expires in 6 days, 2 days until follow up.")
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
    }
}

#Preview {
    VStack(spacing: 16) {
        ConfirmationSheetFitBanner(
            candidate: Candidate(name: "Rachael", role: "Designer", matchScore: 70, stageInfo: "Applied", fitMissingMustHaves: 2)
        )
        ConfirmationSheetFitBanner(
            candidate: Candidate(name: "Cindy", role: "Designer", stageInfo: "Applied", fitEvaluationInProgress: true)
        )
    }
    .padding()
    .background(AppColors.background)
}
