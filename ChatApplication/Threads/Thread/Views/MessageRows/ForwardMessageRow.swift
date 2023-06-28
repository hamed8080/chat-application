//
//  ForwardMessageRow.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ForwardMessageRow: View {
    var forwardInfo: ForwardInfo
    @State var showReadOnlyThreadView: Bool = false

    @ViewBuilder var body: some View {
        if let forwardThread = forwardInfo.conversation {
            NavigationLink {
                ThreadView(thread: forwardThread)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        if let name = forwardInfo.participant?.name {
                            Text(name)
                                .italic()
                                .font(.iransansBoldCaption2)
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                        Image(systemName: "arrowshape.turn.up.right")
                            .foregroundColor(Color.blue)
                    }
                    .padding([.leading, .trailing, .top], 8)
                    .frame(minHeight: 36)
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding([.top], 4)
                }
            }
        }
    }
}
