import Foundation
import Combine

// GitHub GraphQL APIのレスポンスモデル
struct GitHubResponse: Codable {
    let data: UserData?
    let errors: [GraphQLError]?
}

struct UserData: Codable {
    let user: User?
}

struct User: Codable {
    let contributionsCollection: ContributionsCollection?
}

struct ContributionsCollection: Codable {
    let contributionCalendar: ContributionCalendar?
}

struct ContributionCalendar: Codable {
    let totalContributions: Int
    let weeks: [Week]
}

struct Week: Codable {
    let contributionDays: [ContributionDay]
}

struct ContributionDay: Codable {
    let contributionCount: Int
    let date: String
}

struct GraphQLError: Codable {
    let message: String
}

// GitHub GraphQLクライアント
class GitHubGraphQLClient: ObservableObject {
    private let baseURL = "https://api.github.com/graphql"
    private let settingsManager = SettingsManager.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var contributionData: ContributionCalendar?
    
    init() {
        // SettingsManagerの変更を監視
        settingsManager.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    private var accessToken: String? {
        return settingsManager.githubAccessToken.isEmpty ? nil : settingsManager.githubAccessToken
    }
    
    func fetchUserContributions(userName: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let query = """
        query($userName:String!) {
          user(login: $userName){
            contributionsCollection {
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                  }
                }
              }
            }
          }
        }
        """
        
        let variables = ["userName": userName]
        
        let requestBody: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        guard let url = URL(string: baseURL) else {
            await MainActor.run {
                errorMessage = "無効なURLです"
                isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            await MainActor.run {
                errorMessage = "リクエストの作成に失敗しました: \(error.localizedDescription)"
                isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    errorMessage = "無効なレスポンスです"
                    isLoading = false
                }
                return
            }
            
            if httpResponse.statusCode != 200 {
                await MainActor.run {
                    errorMessage = "APIエラー: \(httpResponse.statusCode)"
                    isLoading = false
                }
                return
            }
            
            let decoder = JSONDecoder()
            let githubResponse = try decoder.decode(GitHubResponse.self, from: data)
            
            if let errors = githubResponse.errors, !errors.isEmpty {
                await MainActor.run {
                    errorMessage = "GraphQLエラー: \(errors.first?.message ?? "不明なエラー")"
                    isLoading = false
                }
                return
            }
            
            if let contributionCalendar = githubResponse.data?.user?.contributionsCollection?.contributionCalendar {
                await MainActor.run {
                    self.contributionData = contributionCalendar
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "ユーザーが見つからないか、コントリビューション情報がありません"
                    isLoading = false
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "ネットワークエラー: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
} 