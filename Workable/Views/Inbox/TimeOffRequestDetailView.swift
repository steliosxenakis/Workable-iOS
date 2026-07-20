import SwiftUI

struct TimeOffRequestDetailView: View {
    let item: TimeOffInboxItem
    @Environment(\.dismiss) private var dismiss
    @State private var showArchivedToast = false

    var body: some View {
        VStack(spacing: 0) {
            customNavBar

            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        senderHeader
                        Divider()
                        requestSummary
                        messageBody
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomActions
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

            Text("Time off")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

            Button {
                withAnimation { showArchivedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showArchivedToast = false }
                }
            } label: {
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
            Image(item.senderAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.senderName)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                timeOffColorSwatch(item.leaveType.color)

                Text(item.leaveType.rawValue)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.dateRange)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)

                Text(item.duration)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .tracking(-0.24)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var messageBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(item.bodyText.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)

            HStack(spacing: 12) {
                Button {} label: {
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

                Button {} label: {
                    Text("Approve")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.primary)
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
}

private func timeOffColorSwatch(_ color: Color) -> some View {
    RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(color)
        .frame(width: 18, height: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(AppColors.separator, lineWidth: 1)
        )
}

// MARK: - Cancelled request detail (Figma 16363-23630)

struct TimeOffCancelledDetailView: View {
    let item: TimeOffInboxItem
    @Environment(\.dismiss) private var dismiss
    @State private var showArchivedToast = false

    var body: some View {
        VStack(spacing: 0) {
            customNavBar

            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            senderHeader
                            Divider()
                            if let description = item.cancellationDescription {
                                Text(description)
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.fontDefault)
                                    .tracking(-0.41)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        timeOffDetailsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }

                if showArchivedToast {
                    toastView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 40)
                }
            }
        }
        .background(AppColors.surface)
        .navigationBarHidden(true)
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

            Text("Time-off request")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.41)
                .foregroundColor(AppColors.fontDefault)

            Spacer()

            Button {
                withAnimation { showArchivedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showArchivedToast = false }
                }
            } label: {
                Image(systemName: "archivebox")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primaryDark)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .overlay(Rectangle().fill(AppColors.separator).frame(height: 1), alignment: .bottom)
    }

    private var senderHeader: some View {
        HStack(spacing: 8) {
            Image(item.senderAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.senderName)
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

    private var timeOffDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time-off details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "F9F9F9"))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            VStack(alignment: .leading, spacing: 28) {
                employeeField
                cancelledDetailField(title: "Type", value: item.leaveType.rawValue)
                cancelledDetailField(title: "Period", value: item.dateRange)
                cancelledDetailField(title: "Amount", value: item.duration)

                Button {} label: {
                    Text("View more")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color(hex: "F2F4F5"), lineWidth: 1)
            )
        }
    }

    private var employeeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Employee")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.24)

            HStack(spacing: 8) {
                Image(item.requesterAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())

                Text(item.requesterName)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
            }
        }
    }

    private func cancelledDetailField(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
                .tracking(-0.24)

            Text(value)
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
                .tracking(-0.41)
        }
    }
}
