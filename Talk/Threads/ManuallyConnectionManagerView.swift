//
//  ManuallyConnectionManagerView.swift
//  Talk
//
//  Created by hamed on 11/28/23.
//

import SwiftUI
import TalkUI
import Chat

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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack {
                SubmitBottomButton(text: "Close connections", color: Color.App.red) {
                    ChatManager.activeInstance?.dispose()
                }
                SubmitBottomButton(text: "Coneect", color: Color.App.green) {
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
