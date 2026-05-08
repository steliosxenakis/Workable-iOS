import SwiftUI

struct ComposeTextMessageView: View {
    let candidateName: String
    let candidatePhone: String

    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    private let characterLimit = 1600

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                recipientBar

                Divider()

                textArea

                Spacer(minLength: 0)

                footer
            }
            .background(AppColors.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Text message")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.primaryDark)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Send")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(messageText.isEmpty ? AppColors.fontSecondary : AppColors.primaryDark)
                    }
                    .disabled(messageText.isEmpty)
                }
            }
        }
    }

    private var recipientBar: some View {
        HStack(spacing: 6) {
            Text("To:")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontSecondary)

            Text(candidateName)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)

            Text(candidatePhone)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontSecondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var textArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if messageText.isEmpty {
                    Text("Type your message here...")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontSecondary)
                        .padding(.top, 0)
                }

                TextEditor(text: $messageText)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFieldFocused)
                    .onChange(of: messageText) { newValue in
                        if newValue.count > characterLimit {
                            messageText = String(newValue.prefix(characterLimit))
                        }
                    }
            }
            .frame(minHeight: 100)

            Text("\(messageText.count)/\(characterLimit)")
                .font(AppFonts.caption1())
                .foregroundColor(AppColors.fontSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Visible to")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                    Text("Standard Members and above, External Recrui...")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.primaryDark)
                        .lineLimit(1)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Template")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.fontSecondary)
                    Text("Select")
                        .font(AppFonts.caption1())
                        .foregroundColor(AppColors.primaryDark)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    ComposeTextMessageView(
        candidateName: "Cindy Sawyers",
        candidatePhone: "+3069282893"
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .presentationBackground(AppColors.surface)
}
