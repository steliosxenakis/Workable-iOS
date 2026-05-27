import SwiftUI

struct SurveyWelcomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToQuestions = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    welcomeCard
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                }

                startButton
            }
            .background(AppColors.background)
            .navigationTitle("Employee survey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.primaryDark)
                }
            }
            .navigationDestination(isPresented: $navigateToQuestions) {
                SurveyQuestionView()
            }
        }
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 48) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to Q1 engagement survey 2026")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.fontDefault)
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: 16) {
                    subtitleRow

                    Text("""
                    This survey is your opportunity to share honest feedback about your experience at work as we start the year. Your responses help us understand what's working well, where we can improve, and how we can better support you and your team moving forward.

                    Your feedback is anonymous. Responses are collected and reported only in aggregate, and results are shown only when a minimum response threshold is met. This means individual answers can't be linked back to you. The survey should take around [X] minutes to complete. There are no right or wrong answers—we're interested in your genuine experience and perspective.

                    Thank you for sharing your voice. Your feedback helps shape the decisions we make and the way we work together.
                    """)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "333E49"))
                    .lineSpacing(4)
                    .tracking(0.03)

                    anonymousBanner
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color(hex: "6F7073").opacity(0.08), radius: 5, x: 0, y: 1)
        .shadow(color: Color(hex: "6F7073").opacity(0.14), radius: 10, x: 0, y: 4)
    }

    private var subtitleRow: some View {
        HStack(spacing: 4) {
            Text("2-3 min")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.fontSecondary)
            Text("to complete")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.fontSecondary)
        }
    }

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
                Text("Anonymous survey. ")
                    .font(.system(size: 14, weight: .semibold))
                +
                Text("Your answers are completely anonymous and can't be linked back to you.")
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: "CCF4DD"), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var startButton: some View {
        Button { navigateToQuestions = true } label: {
            Text("Start survey")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .tracking(-0.41)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.primaryDark)
                .cornerRadius(26)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    SurveyWelcomeSheet()
}
