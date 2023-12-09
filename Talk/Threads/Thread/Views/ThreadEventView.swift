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
        let event = smt.titleAndIcon
        HStack {
            Text(.init(localized: .init(event?.title ?? "")))
                .lineLimit(1)
                .font(.iransansBoldCaption2)
                .foregroundColor(Color.App.primary)
        }
        .frame(height: 16)
        .animation(.easeInOut, value: viewModel.isShowingEvent)        
    }
}

struct ThreadIsTypingView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadEventView()
            .environmentObject(ThreadEventViewModel(threadId: -1))
    }
}
