//
//  ForwardMessageRow.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ForwardMessageRow: View {
    let forwardInfo: ForwardInfo
    @EnvironmentObject var navVM: NavigationModel

    @ViewBuilder var body: some View {
        if let forwardThread = forwardInfo.conversation {
            Button {
                navVM.append(thread: forwardThread)
            } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.App.red)
                        .frame(width: 3)
                        .frame(minHeight: 0, maxHeight: 36)
                    if let name = forwardInfo.participant?.name {
                        Text(name)
                            .italic()
                            .font(.iransansBoldCaption2)
                            .foregroundColor(Color.App.red)
                    }
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .foregroundColor(Color.App.primary)
                    Spacer()
                }
                .frame(minHeight: 52, maxHeight: 52)
            }
        }
    }
}
