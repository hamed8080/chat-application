//
//  LoginView.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/17/21.
//

import AdditiveUI
import SwiftUI
import TalkExtensions
import TalkModels
import TalkUI
import TalkViewModels
import Combine

struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @State var path: NavigationPath = .init()
    var addNewuser = false
    var onNewUserAdded: (() -> Void)?

    var body: some View {
        NavigationStack(path: $path) {
            LoginContentView()
                .padding()
                .navigationDestination(for: LoginState.self) { _ in
                    VerifyContentView()
                        .padding()
                }
        }
        .onReceive(viewModel.$state) { newState in
            if newState == .verify {
                path.append(newState)
            } else if newState == .successLoggedIn {
                onNewUserAdded?()
            }
        }
        .animation(.easeOut, value: viewModel.state)
    }
}

enum VerifyFocusFileds: Int, Hashable, CaseIterable {
    case first = 0
    case second = 1
    case third = 2
    case fourth = 3
    case fifth = 4
    case sixth = 5
}

struct VerifyContentView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @FocusState var focusField: VerifyFocusFileds?

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image("global_app_icon")
                .resizable()
                .frame(width: 72, height: 72)
                .scaledToFit()
                .cornerRadius(8)
            Text("Login.Verify.enterCode")
                .font(.iransansTitle)
                .foregroundColor(.textBlueColor)

            HStack(spacing: 2) {
                Text("Login.Verfiy.verificationCodeSentTo")
                Text(viewModel.text)
                    .fontWeight(.heavy)
            }
            .font(.iransansSubheadline)
            .foregroundColor(.textBlueColor)

            HStack(spacing: 16) {
                ForEach(0 ..< VerifyFocusFileds.allCases.endIndex, id: \.self) { i in
                    TextField("", text: $viewModel.verifyCodes[i])
                        .frame(minHeight: 64)
                        .textFieldStyle(.customBordered)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.iransansBoldLargeTitle)
                        .focused($focusField, equals: VerifyFocusFileds.allCases.first(where: { i == $0.rawValue })!)
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.5 : 1)
                        .onChange(of: viewModel.verifyCodes[i]) { newString in

                            if newString.count > 2, i == VerifyFocusFileds.allCases.count - 1 {
                                viewModel.verifyCodes[i] = String(newString[newString.startIndex..<newString.index(newString.startIndex, offsetBy: 2)])
                                return
                            }

                            if !newString.hasPrefix("\u{200B}") {
                                viewModel.verifyCodes[i] = "\u{200B}" + newString
                            }

                            if newString.count == 0 , i > 0 {
                                viewModel.verifyCodes[i - 1] = "\u{200B}"
                                focusField = VerifyFocusFileds.allCases.first(where: { $0.rawValue == i - 1 })
                            }

                            /// Move focus to the next textfield if there is something inside the textfield.
                            if viewModel.verifyCodes[i].count == 2, i < VerifyFocusFileds.allCases.count - 1 {
                                viewModel.verifyCodes[i + 1] = "\u{200B}"
                                focusField = VerifyFocusFileds.allCases.first(where: { $0.rawValue == i + 1 })
                            }

                            if viewModel.verifyCodes[i].count == 2, i == VerifyFocusFileds.allCases.count - 1 {
                                // Submit automatically
                                Task {
                                    await viewModel.verifyCode()
                                }
                            }
                        }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .transition(.asymmetric(insertion: .scale(scale: 1), removal: .scale(scale: 0)))
            .onAppear {
                /// Add Zero-Width space 'hidden character' for using as a backspace.
                viewModel.verifyCodes[0] = "\u{200B}"
            }

            Button {
                Task {
                    await viewModel.verifyCode()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Label("Login.Verify.title", systemImage: "checkmark.shield")
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
            }
            .disabled(viewModel.isLoading)
            .font(.iransansBody)
            .buttonStyle(.bordered)

            if viewModel.state == .failed || viewModel.state == .verificationCodeIncorrect {
                let error = viewModel.state == .verificationCodeIncorrect ? "Errors.failedTryAgain" : "Errors.Login.Verify.incorrectCode"
                ErrorView(error: error)
            }
        }
        .frame(maxWidth: 364)
        .onChange(of: viewModel.state) { newState in
            if newState == .failed || newState == .verificationCodeIncorrect {
                hideKeyboard()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .animation(.easeInOut, value: viewModel.state)
        .transition(.move(edge: .trailing))
        .onAppear {
            focusField = VerifyFocusFileds.first
        }
    }
}

struct LoginContentView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @FocusState var isFocused

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image("global_app_icon")
                .resizable()
                .frame(width: 72, height: 72)
                .scaledToFit()
                .cornerRadius(8)
            Text("Login.title")
                .font(.iransansTitle)
                .foregroundColor(.textBlueColor)
            Text("Login.welcome")
                .font(.iransansSubheadline)
                .foregroundColor(.textBlueColor.opacity(0.7))

            TextField(viewModel.selectedServerType == .integration ? "Login.staticToken" : "Login.phoneNumber", text: $viewModel.text)
                .keyboardType(.phonePad)
                .font(.iransansSubtitle)
                .textFieldStyle(.customBorderedWith(minHeight: 36, cornerRadius: 8))
                .focused($isFocused)

            if viewModel.isValidPhoneNumber == false {
                ErrorView(error: "Errors.Login.invalidPhoneNumber")
            }

            Button {
                if viewModel.isPhoneNumberValid() {
                    Task {
                        await viewModel.login()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Label("Login.title", systemImage: "door.left.hand.open")
                        .font(.iransansBody)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
            }
            .disabled(viewModel.isLoading)
            .fontWeight(.medium)
            .buttonStyle(.bordered)

            if viewModel.state == .failed {
                ErrorView(error: "Errors.failedTryAgain")
            }

            Text("Login.footer")
                .multilineTextAlignment(.center)
                .font(.iransansFootnote)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray.opacity(1))
            if EnvironmentValues.isTalkTest {
                Picker("Server", selection: $viewModel.selectedServerType) {
                    ForEach(ServerTypes.allCases) { server in
                        Text(server.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .frame(maxWidth: 420)
        .onChange(of: viewModel.state) { newState in
            if newState != .failed {
                hideKeyboard()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .transition(.move(edge: .trailing))
        .onAppear {
            isFocused = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static let loginVewModel = LoginViewModel(delegate: ChatDelegateImplementation.sharedInstance)
    static var previews: some View {
        NavigationStack {
            VerifyContentView()
                .environmentObject(loginVewModel)
                .onAppear {
                    loginVewModel.text = "09369161601"
                    loginVewModel.animateObjectWillChange()
                }
        }
        .previewDisplayName("VerifyContentView")

        NavigationStack {
            LoginContentView()
                .environmentObject(loginVewModel)
        }
        .previewDisplayName("LoginContentView")

        LoginView()
            .environmentObject(loginVewModel)
            .previewDisplayName("LoginView")
    }
}
