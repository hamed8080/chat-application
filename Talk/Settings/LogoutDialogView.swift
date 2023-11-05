//
//  LogoutDialogView.swift
//  Talk
//
//  Created by hamed on 11/4/23.
//

import SwiftUI
import TalkViewModels
import Chat
import TalkUI

struct LogoutDialogView: View {
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Settings.logoutFromAccount")
                .foregroundStyle(Color.App.text)
                .font(.iransansBoldSubtitle)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("Settings.areYouSureToLogout")
                .foregroundStyle(Color.App.text)
                .font(.iransansSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.placeholder)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    container.appOverlayVM.dialogView = nil
                    ChatManager.activeInstance?.user.logOut()
                    TokenManager.shared.clearToken()
                    UserConfigManagerVM.instance.logout(delegate: ChatDelegateImplementation.sharedInstance)
                    container.reset()
                } label: {
                    Text("Settings.logout")
                        .foregroundStyle(Color.App.red)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 6)
        .background(MixMaterialBackground())
    }
}

struct LogoutDialogView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutDialogView()
    }
}
