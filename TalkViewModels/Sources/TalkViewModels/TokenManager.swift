//
//  TokenManager.swift
//  TalkViewModels
//
//  Created by hamed on 3/16/23.
//

import Chat
import Combine
import Foundation
import ChatModels
import TalkModels
import OSLog

public final class TokenManager: ObservableObject {
    public static let shared = TokenManager()
    @Published public var secondToExpire: Double = 0
    @Published public private(set) var isLoggedIn = false // to update login logout ui
    public static let ssoTokenKey = "ssoTokenKey"
    public static let ssoTokenCreateDate = "ssoTokenCreateDate"
    public let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
        getSSOTokenFromUserDefaults() // need first time app luanch to set hasToken
    }

    public func getNewTokenWithRefreshToken() async {
        guard let ssoTokenModel = getSSOTokenFromUserDefaults(),
              let refreshToken = ssoTokenModel.refreshToken,
              let keyId = ssoTokenModel.keyId
        else { return }
        do {
            let config = ChatManager.activeInstance?.config
            let serverType = Config.serverType(config: config) ?? .main
            var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: serverType).refreshToken)!)
            urlReq.url?.append(queryItems: [.init(name: "refreshToken", value: refreshToken)])
            urlReq.allHTTPHeaderFields = ["keyId": keyId]
            let resp = try await session.data(for: urlReq)
            let ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0)
            await MainActor.run {
                var ssoToken = ssoToken
                ssoToken.keyId = keyId
                saveSSOToken(ssoToken: ssoToken)
                ChatManager.activeInstance?.setToken(newToken: ssoToken.accessToken ?? "", reCreateObject: false)
                AppState.shared.connectionStatus = .connected
            }
        } catch {
#if DEBUG
            Logger.viewModels.info("error on getNewTokenWithRefreshToken:\(error.localizedDescription, privacy: .sensitive)")
#endif
        }
    }

    @discardableResult
    public func getSSOTokenFromUserDefaults() -> SSOTokenResponse? {
        if let data = UserDefaults.standard.data(forKey: TokenManager.ssoTokenKey), let ssoToken = try? JSONDecoder().decode(SSOTokenResponse.self, from: data) {
            return ssoToken
        } else {
            return nil
        }
    }

    /// For checking the user is login at application launch
    public func initSetIsLogin() {
        isLoggedIn = getSSOTokenFromUserDefaults() != nil
    }

    public func saveSSOToken(ssoToken: SSOTokenResponse) {
        let data = (try? JSONEncoder().encode(ssoToken)) ?? Data()
        let str = String(data: data, encoding: .utf8)
#if DEBUG
        Logger.viewModels.info("save token:\n\(str ?? "", privacy: .sensitive)")
#endif
        UserConfigManagerVM.instance.updateToken(ssoToken)
        refreshCreateTokenDate()
        startTimerToGetNewToken()
        if let encodedData = try? JSONEncoder().encode(ssoToken) {
            Task {
                await MainActor.run {
                    UserDefaults.standard.set(encodedData, forKey: TokenManager.ssoTokenKey)
                    UserDefaults.standard.synchronize()
                }
            }
        }
        setIsLoggedIn(isLoggedIn: true)
    }

    public func refreshCreateTokenDate() {
        Task.detached(priority: .background) {
            await MainActor.run {
                UserDefaults.standard.set(Date(), forKey: TokenManager.ssoTokenCreateDate)
            }
        }
    }

    public func getCreateTokenDate() -> Date? {
        UserDefaults.standard.value(forKey: TokenManager.ssoTokenCreateDate) as? Date
    }

    public func startTimerToGetNewToken() {
        if let ssoToken = getSSOTokenFromUserDefaults(), let createDate = getCreateTokenDate() {
            let timeToStart = createDate.advanced(by: Double(ssoToken.expiresIn)).timeIntervalSince1970 - Date().timeIntervalSince1970
            Task {
                try? await Task.sleep(for: .seconds(timeToStart))
                await getNewTokenWithRefreshToken()
            }
        }
    }

    public func setIsLoggedIn(isLoggedIn: Bool) {
        Task {
            await MainActor.run {
                self.isLoggedIn = isLoggedIn
            }
        }
    }

    public func clearToken() {
        UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenKey)
        UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenCreateDate)
        UserDefaults.standard.synchronize()
        setIsLoggedIn(isLoggedIn: false)
    }

    public func startTokenTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if let createDate = TokenManager.shared.getCreateTokenDate(), let ssoTokenExipreTime = TokenManager.shared.getSSOTokenFromUserDefaults()?.expiresIn {
                let expireIn = createDate.advanced(by: Double(ssoTokenExipreTime)).timeIntervalSince1970 - Date().timeIntervalSince1970
                self?.secondToExpire = Double(expireIn)
            }
        }
    }
}
