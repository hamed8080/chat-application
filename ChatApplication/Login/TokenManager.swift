//
//  TokenManager.swift
//  ChatApplication
//
//  Created by hamed on 3/16/23.
//

import Combine
import FanapPodChatSDK
import Foundation

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    @Published var secondToExpire: Double = 0
    @Published private(set) var isLoggedIn = false // to update login logout ui
    static let ssoTokenKey = "ssoTokenKey"
    static let ssoTokenCreateDate = "ssoTokenCreateDate"
    let session: URLSession
    var refreshTokenTask: Task<Void, Never>?

    private init(session: URLSession = .shared) {
        self.session = session
        getSSOTokenFromUserDefaults() // need first time app luanch to set hasToken
    }

    func getNewTokenWithRefreshToken() {
        if refreshTokenTask != nil { return }
        guard let refreshToken = getSSOTokenFromUserDefaults()?.refreshToken else { return }
        let urlReq = URLRequest(url: URL(string: Routes.refreshToken + "?refreshToken=\(refreshToken)")!, timeoutInterval: 5)
        refreshTokenTask = Task {
            do {
                let resp = try await session.data(for: urlReq)
                guard let ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0).result else { return }
                await MainActor.run {
                    saveSSOToken(ssoToken: ssoToken)
                    ChatManager.activeInstance?.setToken(newToken: ssoToken.accessToken ?? "", reCreateObject: false)
                    AppState.shared.connectionStatus = .connected
                }
            } catch {
                print("error on getNewTokenWithRefreshToken:\(error.localizedDescription)")
            }
            refreshTokenTask?.cancel()
            refreshTokenTask = nil
        }
    }

    @discardableResult
    func getSSOTokenFromUserDefaults() -> SSOTokenResponseResult? {
        if let data = UserDefaults.standard.data(forKey: TokenManager.ssoTokenKey), let ssoToken = try? JSONDecoder().decode(SSOTokenResponseResult.self, from: data) {
            return ssoToken
        } else {
            return nil
        }
    }

    /// For checking the user is login at application launch
    func initSetIsLogin() {
        setIsLoggedIn(isLoggedIn: getSSOTokenFromUserDefaults() != nil)
    }

    func saveSSOToken(ssoToken: SSOTokenResponseResult) {
        let data = (try? JSONEncoder().encode(ssoToken)) ?? Data()
        let str = String(data: data, encoding: .utf8)
        print("save token:\n\(str ?? "")")
        refreshCreateTokenDate()
        startTimerToGetNewToken()
        if let encodedData = try? JSONEncoder().encode(ssoToken) {
            UserDefaults.standard.set(encodedData, forKey: TokenManager.ssoTokenKey)
            UserDefaults.standard.synchronize()
        }
        setIsLoggedIn(isLoggedIn: true)
    }

    func refreshCreateTokenDate() {
        UserDefaults.standard.set(Date(), forKey: TokenManager.ssoTokenCreateDate)
    }

    func getCreateTokenDate() -> Date? {
        UserDefaults.standard.value(forKey: TokenManager.ssoTokenCreateDate) as? Date
    }

    func startTimerToGetNewToken() {
        if let ssoToken = getSSOTokenFromUserDefaults(), let createDate = getCreateTokenDate() {
            let timeToStart = createDate.advanced(by: Double(ssoToken.expiresIn)).timeIntervalSince1970 - Date().timeIntervalSince1970
            Task {
                try? await Task.sleep(for: .seconds(timeToStart))
                getNewTokenWithRefreshToken()
            }
        }
    }

    func setIsLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }

    func clearToken() {
        UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenKey)
        UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenCreateDate)
        UserDefaults.standard.synchronize()
        setIsLoggedIn(isLoggedIn: false)
    }

    func startTokenTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if let createDate = TokenManager.shared.getCreateTokenDate(), let ssoTokenExipreTime = TokenManager.shared.getSSOTokenFromUserDefaults()?.expiresIn {
                let expireIn = createDate.advanced(by: Double(ssoTokenExipreTime)).timeIntervalSince1970 - Date().timeIntervalSince1970
                self?.secondToExpire = Double(expireIn)
            }
        }
    }
}
