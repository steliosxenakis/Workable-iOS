import SwiftUI

/// Manager-side review of a pending "request schedule change" — the approval counterpart to
/// the employee-side `RequestScheduleChangeView` (Figma Playground 511-224462). Grey/wireframe
/// styling to match the rest of the Approvals flow.
struct ScheduleChangeRequestDetailView: View {
    let item: ScheduleChangeRequestItem

    @Environment(\.dismiss) private var dismiss
    @State private var decisionToast: String?

    var body: some View {
        VStack(spacing: 0) {
            customNavBar

            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        senderHeader
                        Divider()
                        requestSummary
                        if let note = item.note, !note.isEmpty {
                            noteSection(note)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomActions
                }

                if let decisionToast {
                    toastView(decisionToast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 120)
                }
            }
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
    }

    private func toastView(_ text: String) -> some View {
        Text(text)
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
                .foregroundColor(AppColors.fontDefault)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Schedule change request")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

            // Balances the leading back control.
            Color.clear.frame(width: 44, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
    }

    private var senderHeader: some View {
        HStack(spacing: 8) {
            Image(item.requesterAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.requesterName)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                Text(item.timeAgo)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.iconDefault)
                    .tracking(-0.24)
            }

            Spacer()
        }
    }

    private var requestSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.dateRange)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
                .tracking(-0.41)

            VStack(alignment: .leading, spacing: 16) {
                Text("CHANGES")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.4)
                    .foregroundColor(AppColors.fontSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(item.changes, id: \.self) { change in
                        changeRow(change)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Requested on")
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.fontSecondary)
                Text(item.requestedOnText.replacingOccurrences(of: "Requested on ", with: ""))
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceDarker)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func changeRow(_ change: ScheduleChangeField) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(change.label)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.24)

            HStack(spacing: 6) {
                Text(change.oldValue)
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.fontSecondary)
                    .strikethrough(color: AppColors.fontSecondary)

                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.iconInactive)

                Text(change.newValue)
                    .font(AppFonts.subheadStrong())
                    .foregroundColor(AppColors.fontDefault)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(AppColors.iconInactive, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }

    private func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Note")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.24)
            Text(note)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
                .tracking(-0.41)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)

            HStack(spacing: 12) {
                Button {
                    showDecision("Declined")
                } label: {
                    Text("Decline")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.41)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(AppColors.separator)
                    .frame(width: 1, height: 24)

                Button {
                    showDecision("Approved")
                } label: {
                    Text("Approve")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.41)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
        .padding(.bottom, 48)
        .background(AppColors.surface)
    }

    /// Decision is prototype-only for now — just a toast, then back to the inbox.
    private func showDecision(_ text: String) {
        withAnimation { decisionToast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            dismiss()
        }
    }
}

#Preview {
    ScheduleChangeRequestDetailView(item: ScheduleChangeRequestMockData.pending)
}
