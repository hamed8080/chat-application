//
//  LoginView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 12) {
                GeometryReader { reader in
                    VStack {
                        HStack {
                            Spacer()
                            if viewModel.model.isInVerifyState == false {
                                LoginContentView(viewModel: viewModel)
                                    .frame(width: isIpad ? reader.size.width * 50 / 100 : .infinity)

                            } else {
                                VerifyContentView(viewModel: viewModel)
                                    .frame(width: isIpad ? reader.size.width * 50 / 100 : .infinity)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
                if viewModel.isLoading {
                    LoadingView()
                        .frame(width: 36, height: 36)
                }
                Spacer()
            }
            .padding()
            .padding()
        }
        .animation(.easeInOut, value: viewModel.model.isInVerifyState)
    }
}

struct VerifyContentView: View {
    @StateObject var viewModel: LoginViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            CustomNavigationBar(title: "Verification") {
                viewModel.model.setIsInVerifyState(false)
            }
            .padding([.bottom], 48)
            Image("global_app_icon")
                .resizable()
                .frame(width: 72, height: 72)
                .scaledToFit()
                .cornerRadius(8)
            Text("Enter Verication Code")
                .font(.title.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue"))

            Text("Verification code sent to:")
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue").opacity(0.7))
                + Text(" \(viewModel.model.phoneNumber)")
                .font(.subheadline.weight(.bold))
            PrimaryTextField(title: "Enter Verification Code", textBinding: $viewModel.model.verifyCode, backgroundColor: Color.primary.opacity(0.1)) {
                viewModel.verifyCode()
            }
            Button("Verify".uppercased()) {
                viewModel.verifyCode()
            }
            .buttonStyle(PrimaryButtonStyle())

            if viewModel.model.state == .failed || viewModel.model.state == .verificationCodeIncorrect {
                let error = viewModel.model.state == .verificationCodeIncorrect ? "An error occured! Try again." : "Your verification code is incorrect."
                Text(error.uppercased())
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .onChange(of: viewModel.model.state, perform: { newState in
            if newState == .failed || newState == .verificationCodeIncorrect {
                hideKeyboard()
            }
        })
        .onTapGesture {
            hideKeyboard()
        }
        .animation(.easeInOut, value: viewModel.model.state)
        .transition(.move(edge: .trailing))
    }
}

struct LoginContentView: View {
    @StateObject var viewModel: LoginViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image("global_app_icon")
                .resizable()
                .frame(width: 72, height: 72)
                .scaledToFit()
                .cornerRadius(8)
            Text("Login")
                .font(.title.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue"))
            Text("Welcome to Fanap Chats")
                .font(.headline.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue").opacity(0.7))
            Text(viewModel.model.state?.rawValue ?? "")

            PrimaryTextField(title: "Phone number", textBinding: $viewModel.model.phoneNumber, backgroundColor: Color.primary.opacity(0.1)) {}

            if viewModel.model.isValidPhoneNumber == false {
                Text("Please input correct phone number")
                    .foregroundColor(.init("red_soft"))
            }

            Button("Login".uppercased()) {
                if viewModel.model.isPhoneNumberValid() {
                    viewModel.login()
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            if viewModel.model.state == .failed {
                Text("An error occured! Try again.".uppercased())
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.red.opacity(0.8))
                    .transition(.slide)
            }

            Text("If you get in trouble with the login, contact the support team.")
                .multilineTextAlignment(.center)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue").opacity(0.7))
        }
        .onChange(of: viewModel.model.state, perform: { newState in
            if newState != .failed {
                hideKeyboard()
            }
        })
        .onTapGesture {
            hideKeyboard()
        }
        .animation(.easeInOut, value: viewModel.model.state)
        .transition(.move(edge: .trailing))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = LoginViewModel()
        LoginView()
            .environmentObject(LoginViewModel())
            .onAppear {
                //            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                //                vm.model.setIsInVerifyState(true)
                //            }
                vm.model.setIsInVerifyState(true)
            }
    }
}
