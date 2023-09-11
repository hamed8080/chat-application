//
//  LoginViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Chat
import Foundation
import UIKit
import TalkModels
import TalkExtensions

public final class LoginViewModel: ObservableObject {
    @Published public var isLoading = false
    // This two variable need to be set from Binding so public setter needed.
    // It will use for phone number or static token for the integration server.
    @Published public var text: String = ""
    @Published public var verifyCodes: [String] = ["", "", "", "", "", ""]
    public private(set) var isValidPhoneNumber: Bool?
    @Published public  var state: LoginState = .login
    public private(set) var keyId: String?
    @Published public var selectedServerType: ServerTypes = .main
    public let session: URLSession
    public weak var delegate: ChatDelegate?

    public init(delegate: ChatDelegate, session: URLSession = .shared) {
        self.delegate = delegate
        self.session = session
    }

    public func isPhoneNumberValid() -> Bool {
        isValidPhoneNumber = !text.isEmpty
        return !text.isEmpty
    }

    public func login() async {
        showLoading(true)
        if selectedServerType == .integration {
            let ssoToken = SSOTokenResponse(accessToken: text,
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

    public func requestOTP(identity: String, handskahe: HandshakeResponse) async {
        guard let keyId = handskahe.keyId else { return }
        showLoading(true)
        var urlReq = URLRequest(url: URL(string: AppRoutes.authorize)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: identity)])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
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

    public func saveTokenAndCreateChatObject(_ ssoToken: SSOTokenResponse) async {
        await MainActor.run {
            TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
            let config = Config.config(token: ssoToken.accessToken ?? "", selectedServerType: selectedServerType)
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: nil, config: config, delegate: self.delegate)
            state = .successLoggedIn
        }
    }

    public func verifyCode() async {
        guard let keyId = keyId else { return }
        showLoading(true)
        var urlReq = URLRequest(url: URL(string: AppRoutes.verify)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: text), .init(name: "otp", value: verifyCodes.joined())])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        do {
            let resp = try await session.data(for: urlReq)
            var ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0)
            ssoToken.keyId = keyId
            await saveTokenAndCreateChatObject(ssoToken)
        } catch {
            showError(.verificationCodeIncorrect)
        }
        showLoading(false)
    }

    public func resetState() {
        state = .login
        text = ""
        keyId = nil
        isLoading = false
        verifyCodes = ["", "", "", "", "", ""]
    }

    public func showError(_ state: LoginState) {
        Task {
            await MainActor.run {
                self.state = state
            }
        }
    }

    public func showLoading(_ show: Bool) {
        Task {
            await MainActor.run {
                isLoading = show
            }
        }
    }
}
