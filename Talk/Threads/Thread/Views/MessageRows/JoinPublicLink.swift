//
//  JoinPublicLink.swift
//  Talk
//
//  Created by hamed on 12/4/23.
//

import SwiftUI
import TalkViewModels
import ChatModels
import TalkModels
import TalkUI

struct JoinPublicLink: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        if message.message?.contains(AppRoutes.joinLink) == true {
            Button {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(JoinToPublicConversationDialog(message: message))
            } label: {
                HStack {
                    Text("Thread.join")
                        .foregroundStyle(Color.App.text)
                        .font(.iransansBoldBody)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.plain)
                .frame(height: 52)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 196)
                .background(Color.App.bgSecond)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .stroke(Color.App.gray8, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
        }
    }
}


struct JoinToPublicConversationDialog: View {
    let message: Message
    var appOverlayVM: AppOverlayViewModel {AppState.shared.objectsContainer.appOverlayVM}

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Thread.Join.question")
                .foregroundStyle(Color.App.text)
                .font(.iransansBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Button {
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.placeholder)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    if let publicName = message.message?.replacingOccurrences(of: AppRoutes.joinLink, with: "")  {
                        AppState.shared.objectsContainer.threadsVM.joinPublicGroup(publicName)
                    }
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("Thread.join")
                        .foregroundStyle(Color.App.orange)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct JoinPublicLink_Previews: PreviewProvider {
    static var previews: some View {
        JoinPublicLink(viewModel: .init(message: .init(message: "\(AppRoutes.joinLink)FAKEUNIQUENAME") , viewModel: .init(thread: .init(id: 1))))
    }
}
