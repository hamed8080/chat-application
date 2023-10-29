//
//  TabViewsContainer.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct TabViewsContainer: View {
    var thread: Conversation
    @State var selectedTabIndex: Int

    let tabs: [Tab] = [
        .init(title: "Thread.Tabs.members", icon: nil),
        .init(title: "Thread.Tabs.mutualgroup", icon: nil),
        .init(title: "Thread.Tabs.photos", icon: nil),
        .init(title: "Thread.Tabs.videos", icon: nil),
        .init(title: "Thread.Tabs.file", icon: nil),
        .init(title: "Thread.Tabs.music", icon: nil),
        .init(title: "Thread.Tabs.voice", icon: nil),
        .init(title: "Thread.Tabs.link", icon: nil),
    ]

    var body: some View {
        Tabs(selectedTabIndex: $selectedTabIndex, tabs: tabs, thread: thread)
        switch selectedTabIndex {
        case 0:
            MemberView()
                .ignoresSafeArea(.all)
        case 1:
            MutualThreadsView()
                .ignoresSafeArea(.all)
        case 2:
            PictureView(conversation: thread, messageType: .podSpacePicture)
        case 3:
            VideoView(conversation: thread, messageType: .podSpaceVideo)
        case 4:
            FileView(conversation: thread, messageType: .podSpaceFile)
        case 5:
            MusicView(conversation: thread, messageType: .podSpaceSound)
        case 6:
            VoiceView(conversation: thread, messageType: .podSpaceVoice)
        case 7:
            LinkView(conversation: thread, messageType: .link)
        default:
            EmptyView()
        }
    }
}

struct Tabs: View {
    @Binding var selectedTabIndex: Int
    let tabs: [Tab]
    let thread: Conversation
    @Namespace var id

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(tabs) { tab in
                    let index = tabs.firstIndex(where: { $0.title == tab.title })

                    if index == 1, thread.group == true {
                        EmptyView()
                    } else {
                        Button {
                            selectedTabIndex = index ?? 0
                        } label: {
                            VStack {
                                HStack(spacing: 8) {
                                    if let icon = tab.icon {
                                        Image(systemName: icon)
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(Color.App.gray1)
                                            .fixedSize()
                                    }
                                    Text(String(localized: .init(tab.title)))
                                        .font(index == selectedTabIndex ? . iransansBoldCaption : .iransansCaption)
                                        .fixedSize()
                                        .foregroundStyle(index == selectedTabIndex ? Color.App.text : Color.App.hint)
                                }
                                .padding([.trailing, .leading], 8)

                                if index == selectedTabIndex {
                                    Rectangle()
                                        .fill(Color.App.primary)
                                        .frame(height: 3)
                                        .cornerRadius(2, corners: [.topLeft, .topRight])
                                        .matchedGeometryEffect(id: "DetailTabSeparator", in: id)

                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .animation(.spring(), value: selectedTabIndex)
            .padding([.top, .leading, .trailing])
        }
    }
}

struct Tab: Identifiable {
    var id: String { title }
    let title: String
    let icon: String?
}

struct TabViewsContainer_Previews: PreviewProvider {
    static var previews: some View {
        let conversation = MockData.thread
        let viewModel = ParticipantsViewModel(thread: conversation)
        TabViewsContainer(thread: conversation, selectedTabIndex: 0)
            .environmentObject(viewModel)
            .environmentObject(DetailViewModel(thread: conversation))
            .onAppear {
                viewModel.appendParticipants(participants: MockData.generateParticipants())
            }
    }
}
