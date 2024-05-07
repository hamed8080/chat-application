//
//  VerifyContentView.swift
//  Talk
//
//  Created by hamed on 10/24/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import AdditiveUI
import TalkModels

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
                        .foregroundStyle(Color.App.textPrimary)
                        .padding()
                        .fontWeight(.heavy)
                }
                Spacer()
            }
            Spacer()
            VStack(spacing: 0) {
                Text("Login.Verify.verifyPhoneNumber")
                    .font(.iransansBoldLargeTitle)
                    .foregroundColor(Color.App.textPrimary)
                    .padding(.bottom, 2)

                HStack(spacing: 2) {
                    let localized = String(localized: "Login.Verfiy.verificationCodeSentTo", bundle: Language.preferedBundle)
                    let formatted = String(format: localized, viewModel.text)
                    Text(formatted)
                        .foregroundStyle(Color.App.textSecondary)
                        .font(.iransansBody)
                        .padding(EdgeInsets(top: 4, leading: 64, bottom: 4, trailing: 64))
                        .multilineTextAlignment(.center)
                }
                .font(.iransansSubheadline)
                .foregroundColor(Color.App.textPrimary)
            }
            .padding(.bottom, 40)

            HStack {
                Text("Login.verifyCode")
                    .foregroundColor(Color.App.textPrimary)
                    .font(.iransansBoldCaption)
                Spacer()
            }
            .frame(maxWidth: 420)
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            HStack(spacing: 16) {
                ForEach(0 ..< VerifyFocusFileds.allCases.endIndex, id: \.self) { i in
                    TextField("", text: $viewModel.verifyCodes[i])
                        .frame(minHeight: 56)
                        .textFieldStyle(BorderedTextFieldStyle(minHeight: 56,
                                                               cornerRadius: 12,
                                                               bgColor: Color.App.bgInput,
                                                               borderColor: viewModel.showSuccessAnimation ? Color.App.color2 : Color.clear,
                                                               padding: 0))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.iransansBoldLargeTitle)
                        .focused($focusField, equals: VerifyFocusFileds.allCases.first(where: { i == $0.rawValue })!)
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showSuccessAnimation)
                        .onChange(of: viewModel.verifyCodes[i]) { newString in

                            if newString.count == viewModel.verifyCodes.count, let integers = getIntegers(newString) {
                                setVerifyCodes(integers)
                                return
                            }

                            if newString.count > 2, i == VerifyFocusFileds.allCases.count - 1 {
                                viewModel.verifyCodes[i] = String(newString[newString.startIndex..<newString.index(newString.startIndex, offsetBy: 2)])
                                return
                            }

                            if !newString.hasPrefix("\u{200B}") {
                                viewModel.verifyCodes[i] = "\u{200B}" + newString
                            }

                            if newString.count == 0 && i == 0 {
                                viewModel.verifyCodes[0] = ""
                            }

                            if newString.count == 0 , i > 0 {
                                viewModel.verifyCodes[i - 1] = "\u{200B}"
                                focusField = VerifyFocusFileds.allCases.first(where: { $0.rawValue == i - 1 })
                            }

                            /// Move focus to the next textfield if there is something inside the textfield.
                            if viewModel.verifyCodes[i].count == 2, i < VerifyFocusFileds.allCases.count - 1 {
                                if viewModel.verifyCodes[i + 1].count == 0 {
                                    viewModel.verifyCodes[i + 1] = "\u{200B}"
                                }
                                focusField = VerifyFocusFileds.allCases.first(where: { $0.rawValue == i + 1 })
                            }

                            if viewModel.verifyCodes[i].count == 2, i == VerifyFocusFileds.allCases.count - 1 {
                                // Submit automatically
                                Task {
                                    // After the user clicked on the sms we have to make sure that the last filed is selected
                                    focusField = .sixth
                                    // We wait 500 millisecond to fill out all text fields if the user clicked on sms
                                    try? await Task.sleep(for: .milliseconds(500))
                                    viewModel.verifyCode()
                                }
                            }
                        }
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal)
            .environment(\.layoutDirection, .leftToRight)
            .transition(.asymmetric(insertion: .scale(scale: 1), removal: .scale(scale: 0)))

            HStack {
                if !viewModel.timerHasFinished {
                    let localized = String(localized: .init("Login.Verify.timer"), bundle: Language.preferedBundle)
                    let formatted = String(format: localized, viewModel.timerString)
                    Text(formatted)
                        .foregroundStyle(Color.App.textSecondary)
                        .font(.iransansCaption)
                        .padding(EdgeInsets(top: 20, leading: AppState.isInSlimMode ? 12 : 6, bottom: 0, trailing: 0))
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
                    .foregroundStyle(Color.App.textPrimary)
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
                viewModel.verifyCode()
            }
            .disabled(viewModel.isLoading)

            if viewModel.state == .failed || viewModel.state == .verificationCodeIncorrect {
                let error = viewModel.state == .verificationCodeIncorrect ? "Errors.failedTryAgain" : "Errors.Login.Verify.incorrectCode"
                ErrorView(error: error)
            }
        }
        .background(Color.App.bgPrimary)
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
            /// Add Zero-Width space 'hidden character' for using as a backspace.
//            viewModel.verifyCodes[0] = "\u{200B}"
            focusField = VerifyFocusFileds.first
        }
    }

    private func getIntegers(_ newString: String) -> [Int]? {
        var intArray: [Int] = []
        for ch in newString {
            let intVal = Int("\(ch)")
            if let intVal = intVal {
                intArray.append(intVal)
            } else {
                break
            }
        }
        if intArray.count == 0 { return nil }
        return intArray
    }

    private func setVerifyCodes(_ integers: [Int]) {
        viewModel.verifyCodes = integers.map({"\($0)"})
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
