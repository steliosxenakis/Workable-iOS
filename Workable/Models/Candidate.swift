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
        avatarURL: URL? = nil
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
    }
}
