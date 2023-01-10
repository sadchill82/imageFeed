import UIKit
import WebKit

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    private enum NetworkError: Error {
        case codeError
    }
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    
    private(set) var profile: Profile?
    
    private func makeUserDataRequest(token: String) -> URLRequest {
        var url = Constants.defaultBaseURL
        url.appendPathComponent("me")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func fetchProfile(_ token: String?, handler: @escaping (Result<ProfileResult, Error>) -> Void){
        assert(Thread.isMainThread)
        guard lastToken != token, let token = token else { return }
        task?.cancel()
        lastToken = token

        let request = makeUserDataRequest(token: token)
        let session = URLSession.shared
        
        let fulfillCompletionOnMainThread: (Result<ProfileResult, Error>) -> Void = { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    let convertedProfile = convert(profile: profile)
                    self.profile = Profile(username: convertedProfile.username, name: convertedProfile.name, loginName: convertedProfile.loginName, bio: convertedProfile.bio)
                    handler(result)
                case .failure:
                    self.lastToken = nil
                    self.task?.cancel()
                    handler(.failure(NetworkError.codeError))
                }
            }
        }
        
        let task = session.objectTask(for: request, completion: fulfillCompletionOnMainThread)
        self.task = task
        task.resume()
    }
    
    func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}


