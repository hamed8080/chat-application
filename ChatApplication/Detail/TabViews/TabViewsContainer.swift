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
    @State var selectedTabIndex: Int
    let tabs: [Tab] = [
        .init(title: "Members", icon: "person"),
        .init(title: "Media", icon: "play.tv"),
        .init(title: "File", icon: "doc"),
        .init(title: "Music", icon: "music.note"),
        .init(title: "Voice", icon: "mic"),
        .init(title: "Link", icon: "link"),
        .init(title: "Gif", icon: "text.below.photo"),
    ]
    var body: some View {
        Tabs(selectedTabIndex: $selectedTabIndex, tabs: tabs)
        switch selectedTabIndex {
        case 0:
            MemberView()
                .ignoresSafeArea(.all)
                .environmentObject(ParticipantsViewModel(thread: thread))
        case 1:
            MediaView(thread: thread)
        case 2:
            FileView(thread: thread)
        case 3:
            MusicView(thread: thread)
        case 4:
            VoiceView(thread: thread)
        case 5:
            LinkView(thread: thread)
        case 6:
            GIFView(thread: thread)
        default:
            EmptyView()
        }
    }
}

struct Tabs: View {
    @Binding var selectedTabIndex: Int
    let tabs: [Tab]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(tabs) { tab in
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
