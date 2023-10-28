//
//  VerifyContentView.swift
//  Talk
//
//  Created by hamed on 10/24/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct VerifyContentView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @FocusState fileprivate var focusField: VerifyFocusFileds?
    @Environment(\.layoutDirection) var direction

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Button {
                    viewModel.cancelTimer()
                    viewModel.path.removeLast()
                } label: {
                    Image(systemName: direction == .rightToLeft ? "arrow.right" : "arrow.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.messageText)
                        .padding()
                        .fontWeight(.heavy)
                }
                Spacer()
            }
            Spacer()
            VStack(spacing: 0) {
                Text("Login.Verify.verifyPhoneNumber")
                    .font(.iransansBoldLargeTitle)
                    .foregroundColor(.textBlueColor)
                    .padding(.bottom, 2)

                HStack(spacing: 2) {
                    let localized = String(localized: "Login.Verfiy.verificationCodeSentTo")
                    let formatted = String(format: localized, viewModel.text)
                    Text(formatted)
                        .foregroundStyle(Color.hint)
                        .font(.iransansBody)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 64)
                        .multilineTextAlignment(.center)
                }
                .font(.iransansSubheadline)
                .foregroundColor(.textBlueColor)
            }
            .padding(.bottom, 40)

            HStack {
                Text("Login.verifyCode")
                    .foregroundColor(Color.messageText)
                    .font(.iransansBoldCaption)
                Spacer()
            }
            .frame(maxWidth: 420)
            .padding(.horizontal)
            .padding(.bottom, 8)
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
            .frame(maxWidth: 420)
            .padding(.horizontal)
            .environment(\.layoutDirection, .leftToRight)
            .transition(.asymmetric(insertion: .scale(scale: 1), removal: .scale(scale: 0)))
            .onAppear {
                /// Add Zero-Width space 'hidden character' for using as a backspace.
                viewModel.verifyCodes[0] = "\u{200B}"
            }

            HStack {
                if !viewModel.timerHasFinished {
                    let localized = String(localized: .init("Login.Verify.timer"))
                    let formatted = String(format: localized, viewModel.timerString)
                    Text(formatted)
                        .foregroundStyle(Color.hint)
                        .font(.iransansCaption)
                        .padding(.top, 20)
                } else {
                    Button {
                        viewModel.resend()
                    } label: {
                        HStack {
                            Image(systemName: "gobackward")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(.blue)
                            Text("Login.Verify.resendCode")
                        }
                    }
                    .foregroundStyle(Color.blue)
                    .padding(.top, 20)
                    .font(.iransansCaption)

                }
                Spacer()
            }
            .frame(maxWidth: 420)

            Spacer()

            SubmitBottomButton(text: "Login.Verify.title",
                               enableButton: Binding(get: {!viewModel.isLoading}, set: {_ in}),
                               isLoading: $viewModel.isLoading,
                               maxInnerWidth: 420
            ) {
                Task {
                    await viewModel.verifyCode()
                }
            }
            .disabled(viewModel.isLoading)

            if viewModel.state == .failed || viewModel.state == .verificationCodeIncorrect {
                let error = viewModel.state == .verificationCodeIncorrect ? "Errors.failedTryAgain" : "Errors.Login.Verify.incorrectCode"
                ErrorView(error: error)
            }
        }
        .background(Color.bgColor)
        .animation(.easeInOut, value: viewModel.state)
        .animation(.easeInOut, value: viewModel.timerHasFinished)
        .transition(.move(edge: .trailing))
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.state) { newState in
            if newState == .failed || newState == .verificationCodeIncorrect {
                hideKeyboard()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            focusField = VerifyFocusFileds.first
        }
    }
}

fileprivate enum VerifyFocusFileds: Int, Hashable, CaseIterable {
    case first = 0
    case second = 1
    case third = 2
    case fourth = 3
    case fifth = 4
    case sixth = 5
}

struct VerifyContentView_Previews: PreviewProvider {
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
    }
}
