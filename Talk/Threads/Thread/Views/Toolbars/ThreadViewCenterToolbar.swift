//
//  ThreadViewCenterToolbar.swift
//  Talk
//
//  Created by hamed on 7/7/23.
//

import Chat
import ChatDTO
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadViewCenterToolbar: View {
    @EnvironmentObject var appState: AppState
    var viewModel: ThreadViewModel
    @State private var title: String = ""
    @State private var participantCount: Int?
    private let participantPublisher = NotificationCenter.default.publisher(for: .participant).compactMap { $0.object as? ParticipantEventTypes }
    private let threadPublisher = NotificationCenter.default.publisher(for: .thread).compactMap { $0.object as? ThreadEventTypes }

    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .fixedSize()
                .font(.iransansBoldSubheadline)
            if appState.connectionStatus != .connected {
                ConnectionStatusToolbar()
            } else if let signalMessageText = viewModel.signalMessageText {
                Text(signalMessageText)
                    .foregroundColor(Color.App.blue)
                    .font(.iransansCaption2)
            } else if let participantsCount = participantCount {
                Text("Members \(participantsCount)")
                    .fixedSize()
                    .foregroundColor(Color.App.gray1)
                    .font(.iransansFootnote)
            }
        }
        .onChange(of: viewModel.thread.computedTitle) { newValue in
            title = newValue
        }
        .onChange(of: viewModel.thread.participantCount) { newValue in
            participantCount = newValue
        }
        .onReceive(participantPublisher) { event in
            if case let .added(response) = event {
                withAnimation {
                    participantCount = (participantCount ?? 0) + (response.result?.count ?? 0)
                }
            }

            if case let .deleted(response) = event {
                withAnimation {
                    participantCount = max(0, (participantCount ?? 0) - (response.result?.count ?? 0))
                }
            }
        }
        .onReceive(threadPublisher) { event in
            if case let .updatedInfo(response) = event {
                withAnimation {
                    title = response.result?.computedTitle ?? ""
                }
            }
        }
        .onAppear {
            participantCount = viewModel.thread.participantCount
            title = viewModel.thread.computedTitle
        }
    }
}

struct ThreadViewCenterToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewCenterToolbar(viewModel: ThreadViewModel(thread: Conversation()))
    }
}
