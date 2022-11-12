//
//  LoginViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import FanapPodChatSDK
import Foundation
import UIKit

class LoginViewModel: ObservableObject {
    @Published
    var model = LoginModel()
    
    @Published
    var isLoading = false
    
    var tokenManager = TokenManager.shared
    let handshakeClient = RestClient<HandshakeResponse>()
    let authorizationClient = RestClient<AuthorizeResponse>()
    let ssoClient = RestClient<SSOTokenResponse>()
    
    func login() {
        isLoading = true
        let req = HandshakeRequest(deviceName: UIDevice.current.name,
                                   deviceOs: UIDevice.current.systemName,
                                   deviceOsVersion: UIDevice.current.systemVersion,
                                   deviceType: "MOBILE_PHONE",
                                   deviceUID: UIDevice.current.identifierForVendor?.uuidString ?? "")
        handshakeClient
            .setUrl(Routes.HANDSHAKE)
            .setMethod(.post)
            .enablePrint(enable: true)
            .setParamsAsQueryString(req)
            .setOnError { _, error in
                print("error on login:\(error.debugDescription)")
                self.isLoading = false
                self.model.setState(.FAILED)
            }
            .request { [weak self] response in
                self?.isLoading = false
                guard let self = self else { return }
                self.requestOTP(identity: self.model.phoneNumber, handskahe: response)
            }
    }
    
    func requestOTP(identity: String, handskahe: HandshakeResponse) {
        guard let keyId = handskahe.result?.keyId else { return }
        let req = AuthorizeRequest(identity: identity, keyId: keyId)
        isLoading = true
        authorizationClient
            .setUrl(Routes.AUTHORIZE)
            .setMethod(.post)
            .enablePrint(enable: true)
            .setParamsAsQueryString(req)
            .addRequestHeader(key: "keyId", value: req.keyId)
            .setOnError { _, error in
                print("error on requestOTP:\(error.debugDescription)")
                self.isLoading = false
                self.model.setState(.FAILED)
            }
            .request { [weak self] response in
                self?.isLoading = false
                guard let self = self else { return }
                if let _ = response.result?.identity {
                    self.model.setIsInVerifyState(true)
                    self.model.setKeyId(keyId)
                }
            }
    }
    
    func verifyCode() {
        guard let keyId = model.keyId else { return }
        
        let req = VerifyRequest(identity: model.phoneNumber, keyId: keyId, otp: model.verifyCode)
        isLoading = true
        ssoClient
            .setUrl(Routes.VERIFY)
            .setMethod(.post)
            .enablePrint(enable: true)
            .setParamsAsQueryString(req)
            .addRequestHeader(key: "keyId", value: req.keyId)
            .setOnError { _, error in
                print("error on verifyCode:\(error.debugDescription)")
                self.isLoading = false
                self.model.setState(.VERIFICATION_CODE_INCORRECT)
            }
            .request { [weak self] response in
                self?.isLoading = false
                guard let self = self else { return }
                // save refresh token
                if let ssoToken = response.result {
                    self.model.setState(.SUCCESS_LOGGED_IN)
                    Chat.sharedInstance.setToken(newToken: ssoToken.accessToken ?? "", reCreateObject: true)
                    self.tokenManager.saveSSOToken(ssoToken: ssoToken)
                }
            }
    }
}

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    private let refreshTokenClient = RestClient<SSOTokenResponse>()

    @Published
    var secondToExpire: Double = 0

    @Published
    private(set) var isLoggedIn = false // to update login logout ui
    private init() {
        _ = getSSOTokenFromUserDefaults() // need first time app luanch to set hasToken
    }
    
    private var timer: Timer?
    private static let SSO_TOKEN_KEY = "SSO_TOKEN"
    private static let SSO_TOKEN_CREATE_DATE = "SSO_TOKEN_CREATE_DATE"
    
    func getNewTokenWithRefreshToken() {
        if let refreshToken = getSSOTokenFromUserDefaults()?.refreshToken {
            refreshTokenClient
                .enablePrint(enable: true)
                .setUrl(Routes.REFRESH_TOKEN + "?refreshToken=\(refreshToken)")
                .setOnError { _, error in
                    print("error on getNewTokenWithRefreshToken:\(error.debugDescription)")
                }
                .request { [weak self] response in
                    guard let self = self else { return }
                    // save refresh token
                    if let ssoToken = response.result {
                        self.saveSSOToken(ssoToken: ssoToken)
                        Chat.sharedInstance.setToken(newToken: ssoToken.accessToken ?? "", reCreateObject: false)
                    }
                }
        }
    }

    func getSSOTokenFromUserDefaults()->SSOTokenResponse.Result? {
        if let data = UserDefaults.standard.data(forKey: TokenManager.SSO_TOKEN_KEY), let ssoToken = try? JSONDecoder().decode(SSOTokenResponse.Result.self, from: data) {
            return ssoToken
        } else {
            return nil
        }
    }

    /// For checking the user is login at application launch
    func initSetIsLogin() {
        setIsLoggedIn(isLoggedIn: getSSOTokenFromUserDefaults() != nil)
    }

    func saveSSOToken(ssoToken: SSOTokenResponse.Result) {
        let data = (try? JSONEncoder().encode(ssoToken)) ?? Data()
        let str = String(data: data, encoding: .utf8)
        print("save token:\n\(str ?? "")")
        refreshCreateTokenDate()
        startTimerToGetNewToken()
        if let encodedData = try? JSONEncoder().encode(ssoToken) {
            UserDefaults.standard.set(encodedData, forKey: TokenManager.SSO_TOKEN_KEY)
            UserDefaults.standard.synchronize()
        }
        setIsLoggedIn(isLoggedIn: true)
    }
    
    func refreshCreateTokenDate() {
        UserDefaults.standard.set(Date(), forKey: TokenManager.SSO_TOKEN_CREATE_DATE)
    }
    
    func getCreateTokenDate()->Date? {
        UserDefaults.standard.value(forKey: TokenManager.SSO_TOKEN_CREATE_DATE) as? Date
    }
    
    func startTimerToGetNewToken() {
        if let ssoToken = getSSOTokenFromUserDefaults(), let createDate = getCreateTokenDate() {
            timer?.invalidate()
            timer = nil
            let timeToStart = createDate.advanced(by: Double(ssoToken.expiresIn)).timeIntervalSince1970 - Date().timeIntervalSince1970
            timer = Timer.scheduledTimer(withTimeInterval: timeToStart, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.getNewTokenWithRefreshToken()
            }
        }
    }
    
    func setIsLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: TokenManager.SSO_TOKEN_KEY)
        UserDefaults.standard.removeObject(forKey: TokenManager.SSO_TOKEN_CREATE_DATE)
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
