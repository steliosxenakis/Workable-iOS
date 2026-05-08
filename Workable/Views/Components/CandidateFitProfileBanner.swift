import SwiftUI

/// Candidate fit summary card on the Profile tab (Figma `23609:132236`).
struct CandidateFitProfileBanner: View {
    let matchScore: Int
    let missingMustHaves: Int
    var onOpenDetails: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text("Candidate fit")
                    .font(AppFonts.headline())
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)

                Spacer(minLength: 8)

                Button(action: onOpenDetails) {
                    scorePill
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View candidate fit details")
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Missing \(missingMustHaves) must-haves")
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.warningDefault)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppColors.warningBackground)
                    .clipShape(Capsule())

                summaryText
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { onOpenDetails() }
        .accessibilityAddTraits(.isButton)
    }

    private var scorePill: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: "\(max(0, min(100, matchScore)))")
                .font(AppFonts.caption1Strong())
            Text(verbatim: "%")
                .font(AppFonts.caption1())
        }
        .foregroundColor(AppColors.aiFitPillText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColors.aiFitPillFill)
        .clipShape(Capsule())
    }

    /// Matches Figma copy and emphasis (subhead 15 / subhead strong 14).
    private var summaryText: some View {
        VStack(alignment: .leading, spacing: 12) {
            fitParagraph(
                regular("The candidate holds a ") +
                    emphasized("Bachelor’s degree") +
                    regular(" and demonstrates ") +
                    emphasized("Thai fluency") +
                    regular(" (native/bilingual). The background includes customer-facing coordination via email and phone in ") +
                    emphasized("Account Executive") +
                    regular(" and ") +
                    emphasized("Program Coordinator") +
                    regular(" roles.")
            )

            fitParagraph(
                regular("However, the candidate stated they do not have 2+ years of direct contact-centre experience, which is a must-have. No ") +
                    emphasized("FX/financial services") +
                    regular(" support experience is evidenced, and clarification is needed on SOP exposure, English proficiency level, and shift-schedule availability.")
            )
        }
    }

    private func regular(_ s: String) -> Text {
        Text(s)
            .font(AppFonts.subheadline())
            .tracking(-0.24)
            .foregroundColor(AppColors.fontSecondary)
    }

    private func emphasized(_ s: String) -> Text {
        Text(s)
            .font(AppFonts.subheadStrong())
            .tracking(-0.24)
            .foregroundColor(AppColors.fontDefault)
    }

    private func fitParagraph(_ content: Text) -> some View {
        content
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    VStack(spacing: 24) {
        CandidateFitProfileBanner(matchScore: 70, missingMustHaves: 2)
        CandidateFitProfileBanner(matchScore: 70, missingMustHaves: 2, onOpenDetails: {})
    }
    .padding()
    .background(AppColors.background)
}
