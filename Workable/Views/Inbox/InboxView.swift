import SwiftUI

struct InboxView: View {
    @AppStorage("settings.surveysEnabled") private var surveysEnabled = false

    private var inboxItems: [SurveyItem] {
        surveysEnabled ? SurveyMockData.items : []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Inbox")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.41)
                        .foregroundColor(AppColors.fontDefault)
                    Spacer()
                    Button {} label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.primaryDark)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.surface)

                List {
                    ForEach(inboxItems) { item in
                        ZStack {
                            NavigationLink(value: item) {
                                EmptyView()
                            }
                            .opacity(0)

                            InboxItemRow(item: item)
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                        .listRowSeparatorTint(AppColors.separator)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in -16 }
                        .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] + 16 }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if inboxItems.isEmpty {
                        emptyState
                    }
                }
            }
            .background(AppColors.surface)
            .navigationBarHidden(true)
            .navigationDestination(for: SurveyItem.self) { item in
                SurveyDetailView(survey: item)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No messages")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
            Text("You're all caught up.")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.fontSecondary)
        }
    }
}

private struct InboxItemRow: View {
    let item: SurveyItem

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            unreadIndicator
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.isReminder ? "Reminder to complete \(item.surveyName)" : "Start \(item.surveyName)")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.fontDefault)
                    .tracking(-0.41)
                    .lineLimit(2)

                Text("\(item.timeAgo) · \(item.category)")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.iconDefault)
                    .tracking(-0.24)

                if !item.previewText.isEmpty {
                    Text(item.previewText)
                        .font(AppFonts.callout())
                        .foregroundColor(AppColors.fontDefault)
                        .tracking(-0.32)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            Image(item.senderAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var unreadIndicator: some View {
        if item.isUnread {
            Circle()
                .fill(AppColors.primary)
                .frame(width: 6, height: 6)
                .padding(.leading, 6)
        } else {
            Color.clear
                .frame(width: 6, height: 6)
                .padding(.leading, 6)
        }
    }
}

#Preview {
    InboxView()
}
