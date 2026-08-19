import Foundation

struct Candidate: Identifiable, Equatable, Hashable {
    static func == (lhs: Candidate, rhs: Candidate) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: UUID
    let name: String
    let role: String
    let location: String?
    let source: String
    let matchScore: Int?
    let tags: String?
    let stageInfo: String
    let avatarName: String?
    let avatarURL: URL?
    /// When set, drives “Missing N must-haves” on the profile fit banner; defaults in UI if nil.
    let fitMissingMustHaves: Int?
    /// Agent is on the “review” step — show an animated shimmer on the match halo.
    let agentIsReviewing: Bool
    /// Candidate fit evaluation has started but score is not ready yet.
    let fitEvaluationInProgress: Bool

    init(
        id: UUID = UUID(),
        name: String,
        role: String,
        location: String? = nil,
        source: String = "Workable Agent",
        matchScore: Int? = nil,
        tags: String? = nil,
        stageInfo: String,
        avatarName: String? = nil,
        avatarURL: URL? = nil,
        fitMissingMustHaves: Int? = nil,
        agentIsReviewing: Bool = false,
        fitEvaluationInProgress: Bool = false
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.location = location
        self.source = source
        self.matchScore = matchScore
        self.tags = tags
        self.stageInfo = stageInfo
        self.avatarName = avatarName
        self.avatarURL = avatarURL
        self.fitMissingMustHaves = fitMissingMustHaves
        self.agentIsReviewing = agentIsReviewing
        self.fitEvaluationInProgress = fitEvaluationInProgress
    }

    /// Stage name from `stageInfo`, e.g. `"Sourced stage · Uploaded 3 days ago"` → `"Sourced"`.
    var pipelineStageName: String {
        if let range = stageInfo.range(of: " stage", options: .caseInsensitive) {
            return String(stageInfo[..<range.lowerBound])
        }
        return stageInfo
    }

    /// Upload fragment for per-stage footers, e.g. `"Uploaded 3 days ago"`.
    var uploadedLabel: String {
        if let range = stageInfo.range(of: "Uploaded ", options: .caseInsensitive) {
            return String(stageInfo[range.lowerBound...])
        }
        return stageInfo
    }
}
