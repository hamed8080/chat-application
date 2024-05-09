//
//  LoginView.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/17/21.
//

import SwiftUI
import TalkModels
import TalkViewModels

import TalkUI

struct LoginNavigationContainerView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    var addNewuser = false
    var onNewUserAdded: (() -> Void)?

    var body: some View {
        NavigationStack(path: $viewModel.path) {
//            LoginContentView()
//                .navigationDestination(for: LoginState.self) { _ in
//                    VerifyContentView()
//                }
        }
        .onReceive(viewModel.$state) { newState in
            if newState == .verify {
                viewModel.path.append(newState)
            } else if newState == .successLoggedIn {
                onNewUserAdded?()
            }
        }
        .animation(.easeOut, value: viewModel.state)
        .onAppear {
            // Example-specific values
            let bundleIdentifier = Bundle.main.bundleIdentifier!
            let auth0domain = "accounts.pod.ir"
            let authorizeURL = "https://\(auth0domain)/oauth2/authorize"
            let tokenURL = "https://\(auth0domain)/oauth2/token"
            let clientId = "88413l69cd4051a039cf115ee4e073"
            let redirectUri = "talk://login"
            // Example-agnostic code
            let parameters = OAuth2PKCEParameters(authorizeUrl: authorizeURL,
                                                  tokenUrl: tokenURL,
                                                  clientId: clientId,
                                                  redirectUri: redirectUri,
                                                  callbackURLScheme: bundleIdentifier)
            let authenticator = OAuth2PKCEAuthenticator()
            authenticator.authenticate(parameters: parameters) { result in
                switch result {
                case .success(let accessTokenResponse):
                    Task {
                        let ssoToken = accessTokenResponse
                        await AppState.shared.objectsContainer.loginVM.saveTokenAndCreateChatObject(ssoToken)
                    }
                case .failure(let error):
                    let message = error.localizedDescription
                }
            }
        }
    }
}

struct LoginNavigationContainerView_Previews: PreviewProvider {
    static let loginVewModel = LoginViewModel(delegate: ChatDelegateImplementation.sharedInstance)
    static var previews: some View {
        LoginNavigationContainerView()
            .environmentObject(loginVewModel)
            .previewDisplayName("LoginNavigationContainerView")
    }
}
