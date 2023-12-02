//
//  DeleteThreadView.swift
//  Talk
//
//  Created by hamed on 11/25/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct DeleteThreadView: View {
    let threadId: Int?
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Thread.Delete.footer")
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
                    container.threadsVM.delete(threadId)
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.delete")
                        .foregroundStyle(Color.App.red)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct DeleteThreadView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteThreadView(threadId: 1)
    }
}