import Foundation

struct FavoriteGame: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var placeId: String
    var addedAt: Date
    var thumbnailURL: String?

    var deepLinkURL: URL? {
        URL(string: "roblox://placeId=\(placeId)")
    }
}
