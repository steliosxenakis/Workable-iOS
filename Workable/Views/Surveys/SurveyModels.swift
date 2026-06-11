import Foundation

struct SurveyItem: Identifiable, Hashable {
    let id = UUID()
    let surveyName: String
    let senderName: String
    let senderAvatar: String
    let timeAgo: String
    let category: String
    let previewText: String
    let bodyText: String
    let isUnread: Bool
    var isReminder: Bool = false
    var deadline: String? = nil
}

enum SurveyMockData {
    static let items: [SurveyItem] = [
        SurveyItem(
            surveyName: "Employee Engagement survey",
            senderName: "Natalie Sung",
            senderAvatar: "avatar-sophia",
            timeAgo: "1 day ago",
            category: "Employee survey",
            previewText: "",
            bodyText: """
            Just a heads-up — survey closes soon and we still need your response.

            Your feedback is incredibly important to us. It helps shape the decisions we make as a company and ensures that your voice is heard. The survey only takes about **[X minutes] to complete.**

            Thank you for taking the time!
            """,
            isUnread: true,
            isReminder: true
        ),
        SurveyItem(
            surveyName: "Employee Engagement survey",
            senderName: "Natalie Sung",
            senderAvatar: "avatar-sophia",
            timeAgo: "2 days ago",
            category: "Employee survey",
            previewText: "We'd love to hear from you",
            bodyText: """
            We'd love to hear from you.

            Hi Nick,

            We believe that a great workplace is build together and that starts with listening to you.
            We're inviting all employees to participate to our upcoming survey. It's a dedicated space for you to share your honest thoughts, experiences and ideas.

            It only takes a few minutes to complete, and your input makes a genuine difference.

            Thank you in advance for your time and honesty.

            Warm regards,
            Natalie Sung
            """,
            isUnread: true
        ),
        SurveyItem(
            surveyName: "Workplace Satisfaction survey",
            senderName: "Natalie Sung",
            senderAvatar: "avatar-sophia",
            timeAgo: "5 days ago",
            category: "Employee survey",
            previewText: "",
            bodyText: """
            Just a heads-up — survey closes on **April 27, 2026** at **10.00 AM** and we still need your response.

            Your feedback is incredibly important to us. It helps shape the decisions we make as a company and ensures that your voice is heard. The survey only takes about **[X minutes] to complete.**

            Thank you for taking the time!
            """,
            isUnread: false,
            isReminder: true,
            deadline: "April 27, 2026 at 10.00 AM"
        )
    ]
}
