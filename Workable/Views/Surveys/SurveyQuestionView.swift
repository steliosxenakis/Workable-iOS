import SwiftUI

struct SurveyQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRating: Int? = nil
    @State private var currentQuestion = 1
    @State private var textAnswer = ""
    @State private var surveyCompleted = false
    private let totalQuestions = 5

    private func dismissSheet() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }
        root.presentedViewController?.dismiss(animated: true)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            anonymousBanner
            progressBar

            if surveyCompleted {
                completionCard
            } else {
                ScrollView(showsIndicators: false) {
                    Group {
                        if currentQuestion == 1 {
                            ratingQuestionCard
                        } else {
                            textQuestionCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }

                Spacer(minLength: 0)

                footerButtons
            }
        }
        .background(AppColors.background)
        .navigationTitle("Employee survey")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(AppColors.primaryDark)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Q1 engagement survey 2026")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.fontDefault)
                .lineSpacing(4)

            HStack(spacing: 4) {
                Text("2-3 min")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.fontSecondary)
                Text("to complete")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.fontSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.white.opacity(0.95))
    }

    // MARK: - Anonymous Banner

    private var anonymousBanner: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(AppColors.surface)
                    .frame(width: 25, height: 25)
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.fontSecondary)
            }

            Group {
                Text("Your answer are ")
                    .font(.system(size: 14, weight: .regular))
                +
                Text("completely anonymous")
                    .font(.system(size: 14, weight: .semibold))
                +
                Text(" and ")
                    .font(.system(size: 14, weight: .regular))
                +
                Text("can't be traced ")
                    .font(.system(size: 14, weight: .semibold))
                +
                Text("back to you.")
                    .font(.system(size: 14, weight: .regular))
            }
            .foregroundColor(AppColors.fontDefault)
            .lineSpacing(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.successBackground)
        .overlay(
            Rectangle()
                .fill(Color(hex: "CCF4DD"))
                .frame(height: 1),
            alignment: .top
        )
        .overlay(
            Rectangle()
                .fill(Color(hex: "CCF4DD"))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(hex: "F6F4F0"))
                    .frame(height: 2)
                Rectangle()
                    .fill(AppColors.fontDefault)
                    .frame(width: geo.size.width * CGFloat(currentQuestion) / CGFloat(totalQuestions), height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(height: 2)
    }

    // MARK: - Completion Card

    private var completionCard: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppColors.successBackground)
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(AppColors.activeBackground)
                        .frame(width: 56, height: 56)
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppColors.primaryDark)
                }

                Text("Thanks for sharing. Your feedback makes a difference.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.fontDefault)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    dismissSheet()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryDark)
                        .cornerRadius(26)
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface)
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Rating Question Card

    private var ratingQuestionCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your role and day-to-day work")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.fontDefault)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Question \(currentQuestion) of \(totalQuestions)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(0.03)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 4) {
                        Text("*")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.dangerDefault)
                        Text("I have a clear understanding of what is expected of me in my role.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.fontDefault)
                            .tracking(0.03)
                    }

                    ratingControl
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    // MARK: - Text Question Card

    private var textQuestionCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your role and day-to-day work")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.fontDefault)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Question \(currentQuestion) of \(totalQuestions)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(0.03)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 4) {
                        Text("*")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.dangerDefault)
                        Text("What's one change that would make your day-to-day work better?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.fontDefault)
                            .tracking(0.03)
                    }

                    textEditorControl
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    // MARK: - Text Editor Control

    private var textEditorControl: some View {
        VStack(alignment: .leading, spacing: 0) {
            formattingToolbar

            TextEditor(text: $textAnswer)
                .font(.system(size: 14))
                .foregroundColor(AppColors.fontDefault)
                .frame(minHeight: 200)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(Color(hex: "FBF8F5"))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: "F6F4F0"), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var formattingToolbar: some View {
        HStack(spacing: 16) {
            Image(systemName: "textformat.size")
                .font(.system(size: 16))
            Image(systemName: "bold")
                .font(.system(size: 16))
            Image(systemName: "italic")
                .font(.system(size: 16))
            Image(systemName: "list.bullet")
                .font(.system(size: 16))
            Image(systemName: "list.number")
                .font(.system(size: 16))
            Image(systemName: "link")
                .font(.system(size: 16))
        }
        .foregroundColor(AppColors.fontDefault)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Rectangle()
                .fill(Color(hex: "F6F4F0"))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Rating Control

    private var ratingControl: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Rating")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.iconDefault)
            }

            HStack(spacing: 2) {
                ForEach(1...10, id: \.self) { number in
                    Button {
                        selectedRating = number
                    } label: {
                        Text("\(number)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "636D77"))
                            .frame(width: 20, height: 20)
                            .background(
                                selectedRating == number
                                    ? Color(hex: "E7ECF3")
                                    : Color.white
                            )
                            .cornerRadius(2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(hex: "E7ECF3"), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color(hex: "FBF8F5"))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: "F6F4F0"), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    // MARK: - Footer Buttons

    private var footerButtons: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "EEECE6"))
                .frame(height: 1)

            HStack(spacing: 21) {
                Button {
                    if currentQuestion > 1 {
                        withAnimation { currentQuestion -= 1 }
                    }
                } label: {
                    Text("Previous")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.fontDefault)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color(hex: "E7ECF3"), lineWidth: 1)
                        )
                        .cornerRadius(26)
                }
                .buttonStyle(.plain)

                Button {
                    if currentQuestion < totalQuestions {
                        withAnimation { currentQuestion += 1 }
                    } else {
                        withAnimation { surveyCompleted = true }
                    }
                } label: {
                    Text(currentQuestion == totalQuestions ? "Submit" : "Next")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryDark)
                        .cornerRadius(26)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(AppColors.surface)
        }
    }
}

#Preview {
    NavigationStack {
        SurveyQuestionView()
    }
}
