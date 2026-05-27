import SwiftUI

struct ComposeTextMessageView: View {
    let candidateName: String
    let candidatePhone: String
    var onSend: ((String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    private let characterLimit = 1600

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Text message")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.41)
                    .foregroundColor(AppColors.fontDefault)

                Spacer()

                Button {
                    onSend?(messageText)
                    dismiss()
                } label: {
                    Text("Send")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(messageText.isEmpty ? AppColors.fontSecondary : AppColors.primaryDark)
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surface)

            Divider()

            recipientBar

            Divider()

            textArea

            Spacer(minLength: 0)

            footer
        }
        .background(AppColors.surface)
    }

    private var recipientBar: some View {
        HStack(spacing: 4) {
            Text("To:")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.24)

            Text(candidateName)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppColors.fontDefault)
                .tracking(-0.24)

            Text(candidatePhone)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.24)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.background)
    }

    private var textArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if messageText.isEmpty {
                    Text("Type your message here...")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontSecondary)
                        .padding(.top, 8)
                }

                TextEditor(text: $messageText)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 30)
                    .onChange(of: messageText) { newValue in
                        if newValue.count > characterLimit {
                            messageText = String(newValue.prefix(characterLimit))
                        }
                    }
            }

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
