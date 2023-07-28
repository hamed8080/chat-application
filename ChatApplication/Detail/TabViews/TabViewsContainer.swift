//
//  TabViewsContainer.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatAppUI
import ChatModels
import SwiftUI

struct TabViewsContainer: View {
    var thread: Conversation
    @State var selectedTabIndex: Int
    let tabs: [Tab] = [
        .init(title: "Members", icon: "person"),
        .init(title: "Mutual Groups", icon: "person.3"),
        .init(title: "Photos", icon: "photo.stack"),
        .init(title: "Videos", icon: "play.tv"),
        .init(title: "File", icon: "doc"),
        .init(title: "Music", icon: "music.note"),
        .init(title: "Voice", icon: "mic"),
        .init(title: "Link", icon: "link"),
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
                                    Image(systemName: tab.icon)
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(Color.gray)
                                        .fixedSize()
                                    Text(tab.title)
                                        .font(.iransansBoldBody)
                                        .fixedSize()
                                }
                                .padding([.trailing, .leading], 8)

                                if index == selectedTabIndex {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(height: 3)
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
    let icon: String
}

struct TabViewsContainer_Previews: PreviewProvider {
    static var previews: some View {
        TabViewsContainer(thread: MockData.thread, selectedTabIndex: 0)
    }
}
