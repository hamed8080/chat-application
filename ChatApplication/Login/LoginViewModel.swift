//
//  LoginViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Chat
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

final class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    // This two variable need to be set from Binding so public setter needed.
    // It will use for phone number or static token for the integration server.
    @Published var text: String = ""
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
        isValidPhoneNumber = !text.isEmpty
        return !text.isEmpty
    }

    func login() async {
        showLoading(true)
        if selectedServerType == .integration {
            let ssoToken = SSOTokenResponseResult(accessToken: text,
                                                  expiresIn: Int(Calendar.current.date(byAdding: .year, value: 1, to: .now)?.millisecondsSince1970 ?? 0),
                                                  idToken: nil,
                                                  refreshToken: nil,
                                                  scope: nil,
                                                  tokenType: nil)
            await saveTokenAndCreateChatObject(ssoToken)
            showLoading(false)
            return
        }
        let req = await HandshakeRequest(deviceName: UIDevice.current.name,
                                         deviceOs: UIDevice.current.systemName,
                                         deviceOsVersion: UIDevice.current.systemVersion,
                                         deviceType: "MOBILE_PHONE",
                                         deviceUID: UIDevice.current.identifierForVendor?.uuidString ?? "")
        var urlReq = URLRequest(url: URL(string: AppRoutes.handshake)!)
        urlReq.httpBody = req.parameterData
        urlReq.method = .post
        do {
            let resp = try await session.data(for: urlReq)
            let response = try JSONDecoder().decode(HandshakeResponse.self, from: resp.0)
            await requestOTP(identity: text, handskahe: response)
        } catch {
            showError(.failed)
        }
        showLoading(false)
    }

    func requestOTP(identity: String, handskahe: HandshakeResponse) async {
        guard let keyId = handskahe.result?.keyId else { return }
        showLoading(true)
        let req = AuthorizeRequest(identity: identity, keyId: keyId)
        var urlReq = URLRequest(url: URL(string: AppRoutes.authorize)!)
        urlReq.allHTTPHeaderFields = ["keyId": req.keyId]
        urlReq.httpBody = req.parameterData
        urlReq.method = .post
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

    fileprivate func saveTokenAndCreateChatObject(_ ssoToken: SSOTokenResponseResult) async {
        await MainActor.run {
            TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
            let config = Config.config(token: ssoToken.accessToken ?? "", selectedServerType: selectedServerType)
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: nil, config: config)
            state = .successLoggedIn
        }
    }

    func verifyCode() async {
        guard let keyId = keyId else { return }
        showLoading(true)
        let req = VerifyRequest(identity: text, keyId: keyId, otp: verifyCodes.joined())
        var urlReq = URLRequest(url: URL(string: AppRoutes.verify)!)
        urlReq.allHTTPHeaderFields = ["keyId": req.keyId]
        urlReq.httpBody = req.parameterData
        urlReq.method = .post
        do {
            let resp = try await session.data(for: urlReq)
            guard let ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0).result else { return }
            await saveTokenAndCreateChatObject(ssoToken)
        } catch {
            showError(.verificationCodeIncorrect)
        }
        showLoading(false)
    }

    func resetState() {
        state = .login
        text = ""
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
