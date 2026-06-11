import SwiftUI

struct SurveyDetailView: View {
    let survey: SurveyItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingSurveySheet = false
    @State private var showArchivedToast = false

    var body: some View {
        VStack(spacing: 0) {
            customNavBar

            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        senderHeader
                        Divider()
                        messageBody
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomAction
                }

                if showArchivedToast {
                    toastView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 120)
                }
            }
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSurveySheet, onDismiss: {
            withAnimation { showArchivedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showArchivedToast = false }
            }
        }) {
            SurveyWelcomeSheet()
        }
    }

    private var toastView: some View {
        Text("Archived")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "323234"))
            .cornerRadius(26)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
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

            Text("Employee survey")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

            Button {} label: {
                Image(systemName: "archivebox")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primaryDark)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
    }

    private var senderHeader: some View {
        HStack(spacing: 8) {
            Image(survey.senderAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(survey.senderName)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                Text(survey.timeAgo)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.iconDefault)
                    .tracking(-0.24)
            }

            Spacer()
        }
    }

    private var messageBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            let paragraphs = survey.bodyText.components(separatedBy: "\n\n")
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                if paragraph.trimmingCharacters(in: .whitespaces).lowercased() == "start survey" ||
                   paragraph.trimmingCharacters(in: .whitespaces).hasPrefix("Start survey") {
                    EmptyView()
                } else {
                    Text(markdownText(paragraph))
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.41)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button { showingSurveySheet = true } label: {
                Text("Start survey")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.primaryDark)
                    .tracking(-0.41)
            }
            .buttonStyle(.plain)
        }
    }

    private func markdownText(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)

            Button { showingSurveySheet = true } label: {
                Text("Start survey")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.primary)
                    .tracking(-0.41)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
        .padding(.bottom, 48)
        .background(AppColors.surface)
    }
}

#Preview {
    NavigationStack {
        SurveyDetailView(survey: SurveyMockData.items[0])
    }
}
