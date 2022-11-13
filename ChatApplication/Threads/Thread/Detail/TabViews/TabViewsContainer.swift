//
//  TabViewsContainer.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import FanapPodChatSDK
import SwiftUI

struct TabViewsContainer: View {
    var thread: Conversation

    @State
    var selectedTabIndex: Int

    var body: some View {
        VStack(spacing: 0) {
            Tabs(selectedTabIndex: $selectedTabIndex, tabs: [
                .init(title: "Members", icon: "person"),
                .init(title: "Media", icon: "play.tv"),
                .init(title: "File", icon: "doc"),
                .init(title: "Music", icon: "music.note"),
                .init(title: "Voice", icon: "mic"),
                .init(title: "Link", icon: "link"),
                .init(title: "Gif", icon: "text.below.photo"),
            ])

            TabView(selection: $selectedTabIndex) {
                MemberView()
                    .environmentObject(ParticipantsViewModel(thread: thread))
                    .tag(0)
                MediaView(thread: thread)
                    .tag(1)
                FileView(thread: thread)
                    .tag(2)
                MusicView(thread: thread)
                    .tag(3)
                VoiceView(thread: thread)
                    .tag(4)
                LinkView(thread: thread)
                    .tag(5)
                GIFView(thread: thread)
                    .tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

struct Tabs: View {
    @Binding
    var selectedTabIndex: Int

    let tabs: [Tab]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(tabs, id: \.title) { tab in
                    let index = tabs.firstIndex(where: { $0.title == tab.title })

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
            .animation(.spring(), value: selectedTabIndex)
            .padding([.top, .leading, .trailing])
        }
    }
}

struct Tab {
    let title: String
    let icon: String
}

struct TabViewsContainer_Previews: PreviewProvider {
    static var previews: some View {
        TabViewsContainer(thread: MockData.thread, selectedTabIndex: 0)
    }
}
