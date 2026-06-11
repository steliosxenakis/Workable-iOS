import SwiftUI

struct TextMessageDetailView: View {
    let candidateName: String
    let candidateRole: String
    let candidateAvatar: String
    let messageText: String
    var deliveryFailed: Bool = false
    var failedReason: String? = nil
    var sentViaWhatsApp: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            customNavBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    candidateHeader

                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)

                    if deliveryFailed {
                        failedBanner

                        Rectangle()
                            .fill(AppColors.separator)
                            .frame(height: 1)
                    }

                    messageSection

                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)

                    metaSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            Spacer(minLength: 0)
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
    }

    private var customNavBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .regular))
                    Text("Back")
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.41)
                }
                .foregroundColor(AppColors.primaryDark)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Text message")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primaryDark)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
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

            Spacer()
        }
    }

    private var failedBanner: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.dangerDefault)
                .padding(.top, 1)
            if let reason = failedReason {
                Text("Text message not delivered. \(reason)")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.dangerDefault)
            } else {
                Text("Text message not delivered.")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.dangerDefault)
            }
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text("Natalie Sung wrote:")
                    .font(AppFonts.subheadline())
                    .tracking(-0.24)
                    .foregroundColor(AppColors.fontSecondary)

                Spacer()

                if !deliveryFailed {
                    HStack(spacing: 4) {
                        Image("icon-delivered")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("16m")
                            .font(.system(size: 13, weight: .regular))
                            .tracking(-0.08)
                            .foregroundColor(AppColors.fontSecondary)
                    }
                } else {
                    Text("16m")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(-0.08)
                        .foregroundColor(AppColors.fontSecondary)
                }
            }

            Text(messageText)
                .font(AppFonts.body())
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)
        }
    }

    private var metaSection: some View {
        HStack(spacing: 4) {
            Text("Sent via \(sentViaWhatsApp ? "WhatsApp" : "SMS") · Visible to")
                .font(.system(size: 13, weight: .regular))
                .tracking(-0.08)
                .foregroundColor(AppColors.fontSecondary)
            Text("All hiring team")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.primaryDark)
        }
    }
}
