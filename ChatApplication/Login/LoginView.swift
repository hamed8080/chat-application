//
//  LoginView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import SwiftUI

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
            Text("Enter Verication Code")
                .font(.iransansTitle)
                .foregroundColor(.textBlueColor)

            Text("Verification code sent to: **\(viewModel.text)**")
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
                        .onChange(of: viewModel.verifyCodes[i]) { _ in
                            if viewModel.verifyCodes[i].count == 1 {
                                focusField = VerifyFocusFileds.allCases.first(where: { $0.rawValue == i + 1 })
                            }
                            if viewModel.verifyCodes[i].count > 1 {
                                let firstChar = viewModel.verifyCodes[i][viewModel.verifyCodes[i].startIndex]
                                viewModel.verifyCodes[i] = String(firstChar)
                            }
                            if viewModel.verifyCodes[i].count == 1, i == VerifyFocusFileds.allCases.count - 1 {
                                // Submit automatically
                                Task {
                                    await viewModel.verifyCode()
                                }
                            }
                        }
                }
            }
            .transition(.asymmetric(insertion: .scale(scale: 1), removal: .scale(scale: 0)))

            Button {
                Task {
                    await viewModel.verifyCode()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Label("Verify".uppercased(), systemImage: "checkmark.shield")
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
            }
            .disabled(viewModel.isLoading)
            .font(.iransansBody)
            .buttonStyle(.bordered)

            if viewModel.state == .failed || viewModel.state == .verificationCodeIncorrect {
                let error = viewModel.state == .verificationCodeIncorrect ? "An error occured! try again." : "Your verification code is incorrect."
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
            Text("Login")
                .font(.iransansTitle)
                .foregroundColor(.textBlueColor)
            Text("**Welcome** to Fanap Chats")
                .font(.iransansSubheadline)
                .foregroundColor(.textBlueColor.opacity(0.7))

            let titleString = viewModel.selectedServerType == .integration ? "Enter your static token here." : "Enter your Phone number here."
            TextField(titleString, text: $viewModel.text)
                .keyboardType(.phonePad)
                .font(.iransansSubtitle)
                .textFieldStyle(.customBorderedWith(minHeight: 36, cornerRadius: 8))
                .focused($isFocused)

            if viewModel.isValidPhoneNumber == false {
                ErrorView(error: "Please input correct phone number")
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
                    Label("Login".uppercased(), systemImage: "door.left.hand.open")
                        .font(.iransansBody)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
            }
            .disabled(viewModel.isLoading)
            .fontWeight(.medium)
            .buttonStyle(.bordered)

            if viewModel.state == .failed {
                ErrorView(error: "An error occured! try again.")
            }

            Text("Contact the support team if you have gotten into trouble with the login.")
                .multilineTextAlignment(.center)
                .font(.iransansFootnote)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray.opacity(1))

            Picker("Server", selection: $viewModel.selectedServerType) {
                ForEach(ServerTypes.allCases) { server in
                    Text(server.rawValue)
                }
            }
            .pickerStyle(.menu)
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

struct ErrorView: View {
    var error: String

    var body: some View {
        HStack {
            Text(error.capitalizingFirstLetter())
                .font(.iransansCaption2)
                .foregroundColor(.red.opacity(0.7))
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.7), lineWidth: 1)
        )
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let vm = LoginViewModel()
            VerifyContentView()
                .environmentObject(vm)
                .onAppear {
                    vm.text = "09369161601"
                    vm.objectWillChange.send()
                }
        }
        .previewDisplayName("VerifyContentView")

        NavigationStack {
            LoginContentView()
                .environmentObject(LoginViewModel())
        }
        .previewDisplayName("LoginContentView")

        LoginView()
            .environmentObject(LoginViewModel())
            .previewDisplayName("LoginView")
    }
}
