//
//  ManuallyConnectionManagerView.swift
//  Talk
//
//  Created by hamed on 11/28/23.
//

import SwiftUI
import TalkUI
import Chat
import TalkViewModels

struct ManuallyConnectionManagerView: View {
    @FocusState var isFocused
    @State var recreate: Bool = false
    @State var token: String = ""

    var body: some View {
        List {
            TextField("token", text: $token)
                .focused($isFocused)
                .keyboardType(.phonePad)
                .font(.iransansBody)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "token", isFocused: isFocused) {
                    isFocused.toggle()
                }
            Toggle(isOn: $recreate) {
                Label("Recreate", systemImage: "repeat")
            }
            .toggleStyle(MyToggleStyle())
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack {
                SubmitBottomButton(text: "Refresh Token", color: Color.App.red) {
                    Task {
                        await TokenManager.shared.getNewTokenWithRefreshToken()
                    }
                }

                SubmitBottomButton(text: "Destroy token", color: Color.App.red) {
                    UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenKey)
                    UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenCreateDate)
                    UserDefaults.standard.synchronize()
                }

                SubmitBottomButton(text: "Close connections", color: Color.App.red) {
                    ChatManager.activeInstance?.dispose()
                }

                SubmitBottomButton(text: "Coneect", color: Color.App.green) {
                    ChatManager.activeInstance?.dispose()
                    ChatManager.activeInstance?.setToken(newToken: token, reCreateObject: recreate)
                }
            }
        }
    }
}

struct ManuallyConnectionManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ManuallyConnectionManagerView()
    }
}
