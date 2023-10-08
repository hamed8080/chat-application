//
//  ThreadEventView.swift
//  Talk
//
//  Created by hamed on 11/30/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadEventView: View {
    @EnvironmentObject var viewModel: ThreadEventViewModel
    var smt: SMT { viewModel.smt ?? .unknown }

    var body: some View {
        if let event = smt.titleAndIcon {
            HStack {
                Image(systemName: event.image)
                    .resizable()
                    .foregroundColor(.main)
                    .frame(width: 16, height: 16)

                Text(.init(localized: .init(event.title)))
                    .lineLimit(1)
                    .font(.iransansBoldCaption2)
                    .foregroundColor(.main)
            }
            .frame(height: viewModel.isShowingEvent ? 16 : 0)
        }
    }
}

struct ThreadIsTypingView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadEventView()
            .environmentObject(ThreadEventViewModel(threadId: -1))
    }
}
