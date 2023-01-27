//
//  LoginView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import SwiftUI

enum ServerTypes: String, CaseIterable, Identifiable {
    var id: Self { self }
    case main
    case sandbox
    case integration
}

struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @State var path: NavigationPath = .init()

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
                .font(.title.weight(.medium))
                .foregroundColor(.textBlueColor)

            Text("Verification code sent to: **\(viewModel.phoneNumber)**")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.textBlueColor)

            HStack(spacing: 16) {
                ForEach(0 ..< VerifyFocusFileds.allCases.endIndex, id: \.self) { i in
                    TextField("", text: $viewModel.verifyCodes[i])
                        .frame(minHeight: 64)
                        .textFieldStyle(.customBordered)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .fontDesign(.rounded)
                        .font(.system(.largeTitle).weight(.medium))
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
                                viewModel.verifyCode()
                            }
                        }
                }
            }
            .transition(.asymmetric(insertion: .scale(scale: 1), removal: .scale(scale: 0)))

            Button {
                viewModel.verifyCode()
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
            .fontWeight(.medium)
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
    @State var selectedServer: ServerTypes = .main
    @FocusState var isFocused
    @State var myText = ""

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image("global_app_icon")
                .resizable()
                .frame(width: 72, height: 72)
                .scaledToFit()
                .cornerRadius(8)
            Text("Login")
                .font(.title.weight(.medium))
                .foregroundColor(.textBlueColor)
            Text("**Welcome** to Fanap Chats")
                .font(.headline.weight(.medium))
                .foregroundColor(.textBlueColor.opacity(0.7))

            TextField("Enter your Phone number here", text: $viewModel.phoneNumber)
                .keyboardType(.phonePad)
                .textFieldStyle(.customBorderedWith(minHeight: 36, cornerRadius: 8))
                .focused($isFocused)

            VStack {
                TextField("", text: $myText)
                    .transition(AnyTransition.push(from: .bottom).animation(.interactiveSpring()))
                    .id("MyTitleComponent" + myText)
                Button("Button") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        myText = "Vote for my post🤩"
                    }
                }
            }

            if viewModel.isValidPhoneNumber == false {
                ErrorView(error: "Please input correct phone number")
            }

            Button {
                if viewModel.isPhoneNumberValid() {
                    viewModel.login()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Label("Login".uppercased(), systemImage: "door.left.hand.open")
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
            }
            .disabled(viewModel.isLoading)
            .fontWeight(.medium)
            .buttonStyle(.bordered)

            if viewModel.state == .failed {
                ErrorView(error: "An error occured! try again.")
            }

            Text("If you get in trouble with the login, contact the support team.")
                .multilineTextAlignment(.center)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray.opacity(1))

            Picker("Server", selection: $selectedServer) {
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
                .font(.footnote.weight(.medium))
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
                    vm.phoneNumber = "09369161601"
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
