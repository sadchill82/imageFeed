import UIKit

class OAuth2Service {
    
    private enum NetworkError: Error {
        case codeError
    }
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    private func makeRequest(code: String) -> URLRequest {
        var urlComponents = URLComponents(string: AuthConfiguration.constants.oauthString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: AuthConfiguration.constants.accessKey),
            URLQueryItem(name: "client_secret", value: AuthConfiguration.constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: AuthConfiguration.constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = urlComponents.url else {
            fatalError("makeRequest Error")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    func fetchAuthToken(
        code: String,
        handler: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void) {
            
            assert(Thread.isMainThread)
            guard lastCode != code else { return }
            task?.cancel()
            lastCode = code
            
            let request = makeRequest(code: code)
            let session = URLSession.shared
            let task = session.objectTask(for: request, completion: handler)
            self.task = task
            task.resume()
        }
}

extension URLSession {
    
    private enum NetworkError: Error {
        case codeError
    }
    
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let task = dataTask(with: request) { data, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let response = response as? HTTPURLResponse,
               response.statusCode < 200 || response.statusCode >= 300 {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.codeError))
                }
                return
            }
            
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        return task
    }
}
