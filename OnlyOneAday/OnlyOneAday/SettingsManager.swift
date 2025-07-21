import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    private let githubTokenKey = "github_access_token"
    private let defaultUserNameKey = "default_github_username"
    
    @Published var githubAccessToken: String {
        didSet {
            userDefaults.set(githubAccessToken, forKey: githubTokenKey)
        }
    }
    
    @Published var defaultGitHubUsername: String {
        didSet {
            userDefaults.set(defaultGitHubUsername, forKey: defaultUserNameKey)
        }
    }
    
    private init() {
        self.githubAccessToken = userDefaults.string(forKey: githubTokenKey) ?? ""
        self.defaultGitHubUsername = userDefaults.string(forKey: defaultUserNameKey) ?? ""
    }
    
    func clearGitHubToken() {
        githubAccessToken = ""
        userDefaults.removeObject(forKey: githubTokenKey)
    }
    
    func hasGitHubToken() -> Bool {
        return !githubAccessToken.isEmpty
    }
} 