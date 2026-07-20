import Foundation

enum TimeOffInboxKind: Hashable {
    case reviewRequest
    case cancelled
}

struct TimeOffInboxItem: Identifiable, Hashable {
    let id = UUID()
    let kind: TimeOffInboxKind
    let title: String
    let senderName: String
    let senderAvatar: String
    let requesterName: String
    let requesterAvatar: String
    let timeAgo: String
    let category: String
    let previewText: String
    let leaveType: TimeOffType
    let dateRange: String
    let duration: String
    let note: String?
    let bodyText: String
    let isUnread: Bool

    var cancellationDescription: String? {
        guard kind == .cancelled else { return nil }
        return "The following time-off request has been cancelled by \(requesterName)"
    }
}

enum TimeOffInboxMockData {
    static let reviewRequest = TimeOffInboxItem(
        kind: .reviewRequest,
        title: "Review a time-off request for Chloe Dylan",
        senderName: "Chloe Dylan",
        senderAvatar: "avatar-lucy",
        requesterName: "Chloe Dylan",
        requesterAvatar: "avatar-lucy",
        timeAgo: "1 hour ago",
        category: "Time off",
        previewText: "Paid time off · Jun 1–3, 2026",
        leaveType: .paidTimeOff,
        dateRange: "Jun 1–3, 2026",
        duration: "3 days",
        note: nil,
        bodyText: """
        Hi,

        I'd like to request 3 days of paid time off from Jun 1–3, 2026.

        Please let me know if you need anything else.

        Thanks,
        Chloe
        """,
        isUnread: true
    )

    static let cancelledRequest = TimeOffInboxItem(
        kind: .cancelled,
        title: "Chloe Dylan's time-off request has been cancelled",
        senderName: "Chloe Dylan",
        senderAvatar: "avatar-lucy",
        requesterName: "Chloe Dylan",
        requesterAvatar: "avatar-lucy",
        timeAgo: "1 day ago",
        category: "Time-off request",
        previewText: "",
        leaveType: .paidTimeOff,
        dateRange: "6 October 2026 - 12 October 2026",
        duration: "4 days",
        note: nil,
        bodyText: "",
        isUnread: true
    )
}

enum InboxEntry: Identifiable, Hashable {
    case survey(SurveyItem)
    case timeOff(TimeOffInboxItem)

    var id: UUID {
        switch self {
        case .survey(let item): return item.id
        case .timeOff(let item): return item.id
        }
    }

    var title: String {
        switch self {
        case .survey(let item):
            return item.isReminder
                ? "Reminder to complete \(item.surveyName)"
                : "Start \(item.surveyName)"
        case .timeOff(let item):
            return item.title
        }
    }

    var subtitle: String {
        switch self {
        case .survey(let item):
            return "\(item.timeAgo) · \(item.category)"
        case .timeOff(let item):
            return "\(item.timeAgo) · \(item.category)"
        }
    }

    var previewText: String {
        switch self {
        case .survey(let item): return item.previewText
        case .timeOff(let item): return item.previewText
        }
    }

    var avatarName: String {
        switch self {
        case .survey(let item): return item.senderAvatar
        case .timeOff(let item): return item.requesterAvatar
        }
    }

    var showsAvatar: Bool {
        switch self {
        case .survey, .timeOff: return true
        }
    }

    var isUnread: Bool {
        switch self {
        case .survey(let item): return item.isUnread
        case .timeOff(let item): return item.isUnread
        }
    }
}
