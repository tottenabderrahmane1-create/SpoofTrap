import AppKit
import Foundation

struct GameSearchResult: Identifiable {
    let id: Int
    let name: String
    let placeId: Int
    let playerCount: Int
    let maxPlayers: Int
    let thumbnailURL: URL?
    let creatorName: String
    let rating: Int?
}

@MainActor
final class GameSearchManager: ObservableObject {
    @Published var query: String = ""
    @Published var results: [GameSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    var proxyPort: Int? = nil

    private var searchTask: Task<Void, Never>?

    private func makeSession() -> URLSession {
        if let port = proxyPort {
            let config = URLSessionConfiguration.ephemeral
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: true,
                kCFNetworkProxiesHTTPProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPPort: port,
                kCFNetworkProxiesHTTPSEnable: true,
                kCFNetworkProxiesHTTPSProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPSPort: port,
            ]
            config.timeoutIntervalForRequest = 15
            return URLSession(configuration: config)
        }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        searchTask?.cancel()
        isSearching = true
        errorMessage = nil

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            let session = makeSession()
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed

            guard let url = URL(string: "https://games.roblox.com/v1/games/list?model.keyword=\(encoded)&model.startRows=0&model.maxRows=12") else {
                isSearching = false
                errorMessage = "Invalid search query"
                return
            }

            do {
                let (data, response) = try await session.data(from: url)

                guard !Task.isCancelled else { return }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    isSearching = false
                    errorMessage = "Roblox API returned \(httpResponse.statusCode)"
                    results = []
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let games = json["games"] as? [[String: Any]] else {
                    isSearching = false

                    if let str = String(data: data.prefix(200), encoding: .utf8), !str.isEmpty {
                        errorMessage = "Unexpected response format"
                    } else {
                        errorMessage = "Empty response from Roblox"
                    }
                    results = []
                    return
                }

                var searchResults: [GameSearchResult] = []
                var universeIds: [Int] = []

                for game in games {
                    guard let universeId = game["universeId"] as? Int,
                          let name = game["name"] as? String,
                          let placeId = game["placeId"] as? Int else { continue }

                    let playerCount = game["playerCount"] as? Int ?? 0
                    let totalUpVotes = game["totalUpVotes"] as? Int ?? 0
                    let totalDownVotes = game["totalDownVotes"] as? Int ?? 0
                    let creatorName = (game["creatorName"] as? String) ?? "Unknown"

                    let totalVotes = totalUpVotes + totalDownVotes
                    let rating = totalVotes > 0 ? Int(Double(totalUpVotes) / Double(totalVotes) * 100) : nil

                    searchResults.append(GameSearchResult(
                        id: universeId,
                        name: name,
                        placeId: placeId,
                        playerCount: playerCount,
                        maxPlayers: 0,
                        thumbnailURL: nil,
                        creatorName: creatorName,
                        rating: rating
                    ))
                    universeIds.append(universeId)
                }

                if searchResults.isEmpty {
                    isSearching = false
                    results = []
                    errorMessage = nil
                    return
                }

                let thumbnails = await fetchThumbnails(universeIds: universeIds, session: session)

                guard !Task.isCancelled else { return }

                for i in searchResults.indices {
                    if let thumbURL = thumbnails[searchResults[i].id] {
                        searchResults[i] = GameSearchResult(
                            id: searchResults[i].id,
                            name: searchResults[i].name,
                            placeId: searchResults[i].placeId,
                            playerCount: searchResults[i].playerCount,
                            maxPlayers: searchResults[i].maxPlayers,
                            thumbnailURL: thumbURL,
                            creatorName: searchResults[i].creatorName,
                            rating: searchResults[i].rating
                        )
                    }
                }

                results = searchResults
                isSearching = false
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch let error as URLError where error.code == .timedOut {
                guard !Task.isCancelled else { return }
                isSearching = false
                results = []
                errorMessage = proxyPort != nil
                    ? "Request timed out — Roblox API may be slow"
                    : "Request timed out — start a session first so requests route through the bypass"
            } catch {
                guard !Task.isCancelled else { return }
                isSearching = false
                results = []
                errorMessage = proxyPort != nil
                    ? "Connection failed: \(error.localizedDescription)"
                    : "Connection failed — start a session to route through bypass"
            }
        }
    }

    func clear() {
        searchTask?.cancel()
        query = ""
        results = []
        isSearching = false
        errorMessage = nil
    }

    private func fetchThumbnails(universeIds: [Int], session: URLSession) async -> [Int: URL] {
        guard !universeIds.isEmpty else { return [:] }

        let ids = universeIds.map(String.init).joined(separator: ",")
        guard let url = URL(string: "https://thumbnails.roblox.com/v1/games/icons?universeIds=\(ids)&returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false") else { return [:] }

        guard let (data, _) = try? await session.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]] else { return [:] }

        var result: [Int: URL] = [:]
        for item in items {
            if let targetId = item["targetId"] as? Int,
               let imageUrl = item["imageUrl"] as? String,
               let url = URL(string: imageUrl) {
                result[targetId] = url
            }
        }
        return result
    }
}
