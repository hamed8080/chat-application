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
import SwiftUI
import Additive

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

    public var timerValue: Int = 0
    public var timer: Timer?
    @Published public var expireIn: Int = 60
    @Published public var timerString = "00:00"
    @Published public var timerHasFinished = false
    @Published public var path: NavigationPath = .init()

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
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: selectedServerType).handshake)!)
        urlReq.httpBody = req.parameterData
        urlReq.method = .post
        do {
            let resp = try await session.data(for: urlReq)
            let decodecd = try JSONDecoder().decode(HandshakeResponse.self, from: resp.0)
            if let keyId = decodecd.keyId {
                await requestOTP(identity: text, keyId: keyId)
            }
            await MainActor.run {
                expireIn = decodecd.client?.accessTokenExpiryTime ?? 60
            }
            await startTimer()
        } catch {
            showError(.failed)
        }
        showLoading(false)
    }

    public func requestOTP(identity: String, keyId: String, resend: Bool = false) async {
        showLoading(true)
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: selectedServerType).authorize)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: identity.replaceRTLNumbers())])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        do {
            let resp = try await session.data(for: urlReq)
            _ = try JSONDecoder().decode(AuthorizeResponse.self, from: resp.0)
            await MainActor.run {
                if !resend {
                    state = .verify
                }
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
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: selectedServerType).verify)!)
        let codes = verifyCodes.joined(separator:"").replacingOccurrences(of: "\u{200B}", with: "").replaceRTLNumbers()
        urlReq.url?.append(queryItems: [.init(name: "identity", value: text.replaceRTLNumbers()), .init(name: "otp", value: codes)])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        do {
            let resp = try await session.data(for: urlReq)
            var ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0)
            ssoToken.keyId = keyId
            await saveTokenAndCreateChatObject(ssoToken)
            await MainActor.run {
                resetState()
                doHaptic()
            }
        } catch {
            doHaptic(failed: true)
            showError(.verificationCodeIncorrect)
        }
        showLoading(false)
    }

    public func resetState() {
        path.removeLast()
        state = .login
        text = ""
        keyId = nil
        isLoading = false
        verifyCodes = ["", "", "", "", "", ""]
    }

    public func showError(_ state: LoginState) {
        Task { [weak self] in
            guard let self = self else { return }
            await MainActor.run {
                self.state = state
            }
        }
    }

    public func showLoading(_ show: Bool) {
        Task { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                isLoading = show
            }
        }
    }

    public func resend() {
        if let keyId = keyId {
            Task { [weak self] in
                guard let self = self else { return }
                await requestOTP(identity: text, keyId: keyId, resend: true)
                await startTimer()
            }
        }
    }

    @MainActor
    public func startTimer() async {
        timerHasFinished = false
        timer?.invalidate()
        timer = nil
        timerValue = expireIn
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            if timerValue != 0 {
                timerValue -= 1
                timerString = timerValue.timerString(locale: Language.preferredLocale) ?? ""
            } else {
                timerHasFinished = true
                timer.invalidate()
                self.timer = nil
            }
        }
    }

    public func cancelTimer() {
        timerHasFinished = false
        timer?.invalidate()
        timer = nil
    }

    private func doHaptic(failed: Bool = false) {
        UIImpactFeedbackGenerator(style: failed ? .rigid : .soft).impactOccurred()
    }

}
