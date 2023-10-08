//
//  ThreadMessagesList.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import AdditiveUI
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadMessagesList: View {
    let viewModel: ThreadViewModel

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                MessagesLazyStack()
            }
            .overlay(alignment: .bottomTrailing) {
                MoveToBottomButton()
                    .offset(y: 48)
            }
            .safeAreaInset(edge: .top) {
                Spacer()
                    .frame(height: viewModel.thread.pinMessage != nil ? 48 : 0)
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: 96)
            }
            .background(ThreadbackgroundView(threadId: viewModel.threadId))
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { originY in
                viewModel.setNewOrigin(newOriginY: originY)
            }
            .onAppear {
                viewModel.scrollProxy = scrollProxy
            }
        }
        .simultaneousGesture(TapGesture().onEnded { _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
    }
}

struct ThreadbackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    let threadId: Int

    var body: some View {
        Image("chat_bg")
            .resizable(resizingMode: .tile)
            .renderingMode(.template)
            .id("chat_bg_\(threadId)")
            .opacity(colorScheme == .dark ? 0.9 : 0.25)
            .colorInvert()
            .colorMultiply(colorScheme == .dark ? Color.white : Color.cyan)
    }
}

struct MessagesLazyStack: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        LazyVStack(spacing: 8) {
            ListLoadingView(isLoading: $viewModel.topLoading)
                .id(-1)
            ForEach(viewModel.sections) { section in
                SectionView(section: section)
                MessageList(messages: section.messages, viewModel: viewModel)
            }
            .padding([.leading, .trailing])
            ListLoadingView(isLoading: $viewModel.bottomLoading)
                .id(-2)
        }
        .environment(\.layoutDirection, .leftToRight)
        .background(
            GeometryReader {
                Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
            }
        )
        .padding(.bottom)
    }
}

struct SectionView: View {
    let section: MessageSection

    var body: some View {
        Text(verbatim: section.date.yearCondence ?? "")
            .font(.iransansCaption)
            .padding([.leading, .trailing], 8)
            .padding([.top, .bottom], 4)
            .background(Color.main.opacity(0.1))
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .foregroundColor(.secondaryLabel)
            .padding(16)
    }
}

struct MessageList: View {
    let messages: [Message]
    let viewModel: ThreadViewModel

    var body: some View {
        ForEach(messages) { message in
            MessageRowFactory(viewModel: viewModel.messageViewModel(for: message))
                .id(message.uniqueId)
                .onAppear {
                    viewModel.onMessageAppear(message)
                }
        }
    }
}

struct ThreadMessagesList_Previews: PreviewProvider {
    struct Preview: View {
        @State var viewModel = ThreadViewModel(thread: Conversation())

        var body: some View {
            ThreadMessagesList(viewModel: viewModel)
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.thread = Conversation(unreadCount: 1)
                    viewModel.objectWillChange.send()
                }
        }
    }

    static var previews: some View {
        Preview()
    }
}
