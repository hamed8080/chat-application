//
//  LoginViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import FanapPodChatSDK
import Foundation
import UIKit

enum LoginState: String, Identifiable, Hashable {
    var id: Self { self }
    case handshake
    case login
    case verify
    case failed
    case refreshToken
    case successLoggedIn
    case verificationCodeIncorrect
}

class LoginViewModel: ObservableObject {
    @Published var isLoading = false

    // this two variable need to be set from Binding so public setter needed
    @Published var phoneNumber: String = ""
    @Published var verifyCodes: [String] = ["", "", "", "", "", ""]
    private(set) var isValidPhoneNumber: Bool?
    @Published var state: LoginState = .login
    private(set) var keyId: String?
    @Published var selectedServerType: ServerTypes = .main
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func isPhoneNumberValid() -> Bool {
        isValidPhoneNumber = !phoneNumber.isEmpty
        return !phoneNumber.isEmpty
    }

    func login() async {
        showLoading(true)
        let req = await HandshakeRequest(deviceName: UIDevice.current.name,
                                         deviceOs: UIDevice.current.systemName,
                                         deviceOsVersion: UIDevice.current.systemVersion,
                                         deviceType: "MOBILE_PHONE",
                                         deviceUID: UIDevice.current.identifierForVendor?.uuidString ?? "")
        var urlReq = URLRequest(url: URL(string: Routes.handshake)!)
        urlReq.httpBody = req.getParameterData()
        urlReq.httpMethod = "POST"
        do {
            let resp = try await session.data(for: urlReq)
            let response = try JSONDecoder().decode(HandshakeResponse.self, from: resp.0)
            await requestOTP(identity: phoneNumber, handskahe: response)
        } catch {
            showError(.failed)
        }
        showLoading(false)
    }

    func requestOTP(identity: String, handskahe: HandshakeResponse) async {
        guard let keyId = handskahe.result?.keyId else { return }
        showLoading(true)
        let req = AuthorizeRequest(identity: identity, keyId: keyId)
        var urlReq = URLRequest(url: URL(string: Routes.authorize)!)
        urlReq.allHTTPHeaderFields = ["keyId": req.keyId]
        urlReq.httpBody = req.getParameterData()
        urlReq.httpMethod = "POST"
        do {
            let resp = try await session.data(for: urlReq)
            _ = try JSONDecoder().decode(AuthorizeResponse.self, from: resp.0)
            await MainActor.run {
                state = .verify
                self.keyId = keyId
            }
        } catch {
            showError(.failed)
        }
        showLoading(false)
    }

    func verifyCode() async {
        guard let keyId = keyId else { return }
        showLoading(true)
        let req = VerifyRequest(identity: phoneNumber, keyId: keyId, otp: verifyCodes.joined())
        var urlReq = URLRequest(url: URL(string: Routes.verify)!)
        urlReq.allHTTPHeaderFields = ["keyId": req.keyId]
        urlReq.httpBody = req.getParameterData()
        urlReq.httpMethod = "POST"
        do {
            let resp = try await session.data(for: urlReq)
            guard let ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0).result else { return }
            await MainActor.run {
                TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
                let config = Config.config(token: ssoToken.accessToken ?? "", selectedServerType: selectedServerType)
                UserConfigManager.createChatObjectAndConnect(userId: nil, config: config)
                state = .successLoggedIn
            }
        } catch {
            showError(.verificationCodeIncorrect)
        }
        showLoading(false)
    }

    func resetState() {
        state = .login
        phoneNumber = ""
        keyId = nil
        isLoading = false
        verifyCodes = ["", "", "", "", "", ""]
    }

    func showError(_ state: LoginState) {
        Task {
            await MainActor.run {
                self.state = state
            }
        }
    }

    func showLoading(_ show: Bool) {
        Task {
            await MainActor.run {
                isLoading = show
            }
        }
    }
}

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    @Published var secondToExpire: Double = 0
    @Published private(set) var isLoggedIn = false // to update login logout ui
    static let ssoTokenKey = "ssoTokenKey"
    static let ssoTokenCreateDate = "ssoTokenCreateDate"
    let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
        getSSOTokenFromUserDefaults() // need first time app luanch to set hasToken
    }

    func getNewTokenWithRefreshToken() async {
        guard let refreshToken = getSSOTokenFromUserDefaults()?.refreshToken else { return }
        let urlReq = URLRequest(url: URL(string: Routes.refreshToken + "?refreshToken=\(refreshToken)")!)
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
                await getNewTokenWithRefreshToken()
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
