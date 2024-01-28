//
//  ConversationDetailTabViews.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ConversationDetailTabViews: View {
    @State var selectedTabId: Int = 0
    var thread: Conversation
    let tabs: [Tab]

    init(thread: Conversation) {
        self.thread = thread
        var tabs: [Tab] = [
            .init(title: "Thread.Tabs.members", view: AnyView(MemberView().ignoresSafeArea(.all))),
//            .init(title: "Thread.Tabs.mutualgroup", view: AnyView(MutualThreadsView().ignoresSafeArea(.all))),
            .init(title: "Thread.Tabs.photos", view: AnyView(PictureView(conversation: thread, messageType: .podSpacePicture))),
            .init(title: "Thread.Tabs.videos", view: AnyView(VideoView(conversation: thread, messageType: .podSpaceVideo))),
            .init(title: "Thread.Tabs.file", view: AnyView(FileView(conversation: thread, messageType: .podSpaceFile))),
            .init(title: "Thread.Tabs.music", view: AnyView(MusicView(conversation: thread, messageType: .podSpaceSound))),
            .init(title: "Thread.Tabs.voice", view: AnyView(VoiceView(conversation: thread, messageType: .podSpaceVoice))),
            .init(title: "Thread.Tabs.link", view: AnyView(LinkView(conversation: thread, messageType: .link)))
        ]
        if thread.group == false || thread.group == nil {
            tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
        }
        if thread.group == true, thread.type?.isChannelType == true, (thread.admin == false || thread.admin == nil) {
            tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
        }
//        if thread.group == true || thread.type == .selfThread || !EnvironmentValues.isTalkTest {
//            tabs.removeAll(where: {$0.title == "Thread.Tabs.mutualgroup"})
//        }
        self.tabs = tabs
    }

    var body: some View {
        CustomTabView(selectedTabIndex: $selectedTabId, tabs: tabs)
    }
}

struct TabViewsContainer_Previews: PreviewProvider {
    static var previews: some View {
        let conversation = MockData.thread
        let viewModel = ParticipantsViewModel(thread: conversation)
        ConversationDetailTabViews(thread: conversation)
            .environmentObject(viewModel)
            .environmentObject(ThreadDetailViewModel())
            .onAppear {
                viewModel.appendParticipants(participants: MockData.generateParticipants())
            }
    }
}
