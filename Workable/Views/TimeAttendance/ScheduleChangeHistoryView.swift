import SwiftUI

/// "Work schedule changes" — the full history of schedule-change requests, most recent
/// (including the current pending one, if any) first (Figma 16576-36223 / 16576-36356).
/// Pushed from Attendance as a full page.
struct ScheduleChangeHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.approvalsEnabled") private var approvalsEnabled = false
    @AppStorage(ScheduleChangeRequestUIVersion.appStorageKey) private var scheduleChangeUIVersionRaw =
        ScheduleChangeRequestUIVersion.defaultVersion.rawValue
    @AppStorage(ScheduleChangeRequestPersona.appStorageKey) private var scheduleChangePersonaRaw =
        ScheduleChangeRequestPersona.defaultPersona.rawValue
    @ObservedObject private var pendingStore = PendingScheduleChangeStore.shared

    private var isManagerPersona: Bool {
        ScheduleChangeRequestPersona.showsManagerInboxRequest(
            approvalsEnabled: approvalsEnabled,
            versionRaw: scheduleChangeUIVersionRaw,
            personaRaw: scheduleChangePersonaRaw
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TimeTrackingDrillInHeader(title: "Work schedule changes", onBack: { dismiss() }) {
                Color.clear
                    .frame(width: GlassSymbolButton.size, height: GlassSymbolButton.size)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if visibleRequests.isEmpty {
                        emptyState
                    } else {
                        ForEach(visibleRequests) { request in
                            NavigationLink {
                                ScheduleChangeRequestDetailView(
                                    item: request.asInboxItem(),
                                    mode: isManagerPersona ? .managerReview : .employeePending
                                )
                            } label: {
                                entryCard(request)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(AppColors.surface)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    private var visibleRequests: [PendingScheduleChangeRequest] {
        pendingStore.requests.filter { !$0.isInPast }
    }

    private var emptyState: some View {
        Text("No schedule change requests yet.")
            .font(AppFonts.subheadline())
            .foregroundColor(AppColors.fontSecondary)
            .padding(.top, 8)
    }

    private func entryCard(_ request: PendingScheduleChangeRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(request.dateLabel)
                .font(AppFonts.footnote())
                .foregroundColor(AppColors.fontSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(request.oldRangesText)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .strikethrough(color: AppColors.fontSecondary)
                Text(request.oldTotalText)
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.fontSecondary)
                    .strikethrough(color: AppColors.fontSecondary)

                Text(request.newRangesText)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontDefault)
                    .padding(.top, 4)
                Text(request.newTotalText)
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.fontSecondary)

                if request.isPending {
                    pendingLabel
                        .padding(.top, 6)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(AppColors.separator, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
        }
    }

    /// Static — history is read-only; cancelling only happens from the Work schedule sheet.
    private var pendingLabel: some View {
        WireframePendingChangeBadge()
    }
}

#Preview("Work schedule changes") {
    NavigationStack {
        ScheduleChangeHistoryView()
    }
}
