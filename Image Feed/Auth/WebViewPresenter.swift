import Foundation

public protocol WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

final class WebViewPresenter: WebViewPresenterProtocol {
    
    private let authHelper: AuthHelperProtocol
    
    func viewDidLoad() {
        let request = authHelper.authRequest()
        
        didUpdateProgressValue(0)
        
        view?.load(request: request)
    }
    
    init(authHelper: AuthHelperProtocol) {
        self.authHelper = authHelper
    }
    
    weak var view: WebViewViewControllerProtocol?
    
    func didUpdateProgressValue(_ newValue: Double) {
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)
        
        let shouldHideProgress = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHideProgress)
    }
    
    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }
    
    func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }
}
