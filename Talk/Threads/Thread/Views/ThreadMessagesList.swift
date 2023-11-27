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
            .background(ThreadbackgroundView(threadId: viewModel.threadId))
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { originY in
                viewModel.setNewOrigin(newOriginY: originY)
            }
            .onAppear {
                viewModel.scrollProxy = scrollProxy
            }
            .overlay(alignment: .center) {
                CenterLoading()
            }
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.isProgramaticallyScroll = false
                    viewModel.messageViewModels.filter(\.showReactionsOverlay).forEach { rowViewModel in
                        rowViewModel.showReactionsOverlay = false
                        rowViewModel.animateObjectWillChange()
                    }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.isProgramaticallyScroll = false
                    viewModel.messageViewModels.filter(\.showReactionsOverlay).forEach { rowViewModel in
                        rowViewModel.showReactionsOverlay = false
                        rowViewModel.animateObjectWillChange()
                    }
                }
        )
    }
}

struct CenterLoading: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    
    var body: some View {
        ListLoadingView(isLoading: $viewModel.centerLoading)
            .frame(width: viewModel.centerLoading ? 48 : 0, height: viewModel.centerLoading ? 48 : 0)
            .id(-3)
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
            .colorMultiply(colorScheme == .dark ? Color.App.white : Color.App.cyan)
            .ignoresSafeArea()
    }
}

struct MessagesLazyStack: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        LazyVStack(spacing: 0) {
            ListLoadingView(isLoading: $viewModel.topLoading)
                .id(-1)
                .padding([.top, .bottom])
            ForEach(viewModel.sections) { section in
                SectionView(section: section)
                MessageList(messages: section.messages, viewModel: viewModel)
            }

            UploadMessagesLoop(threadViewModel: viewModel)
                .environmentObject(viewModel.uploadMessagesViewModel)
            UnsentMessagesLoop(threadViewModel: viewModel)
                .environmentObject(viewModel.unssetMessagesViewModel)

            ListLoadingView(isLoading: $viewModel.bottomLoading)
                .id(-2)
                .padding([.top, .bottom])
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
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .background(Color.App.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius:(24)))
            .foregroundStyle(Color.App.text)
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

struct UploadMessagesLoop: View {
    let threadViewModel: ThreadViewModel
    @EnvironmentObject var viewModel: ThreadUploadMessagesViewModel

    var body: some View {
        /// We must use uniqueId with messageId to force swiftUI to delete the row and make a new one after uploading successfully.
        ForEach(viewModel.uploadMessages, id: \.uniqueId) { uploadFileMessage in
            MessageRowFactory(viewModel: threadViewModel.messageViewModel(for: uploadFileMessage))
                .id("\(uploadFileMessage.uniqueId ?? "")\(uploadFileMessage.id ?? 0)")
        }
        .animation(.easeInOut, value: viewModel.uploadMessages.count)
    }
}

struct UnsentMessagesLoop: View {
    let threadViewModel: ThreadViewModel
    @EnvironmentObject var viewModel: ThreadUnsentMessagesViewModel

    var body: some View {
        /// We have to use \.uniqueId to force the ForLoop to use uniqueId instead of default \.id because id is nil when a message is unsent.
        ForEach(viewModel.unsentMessages, id: \.uniqueId) { unsentMessage in
            MessageRowFactory(viewModel: threadViewModel.messageViewModel(for: unsentMessage))
                .id(unsentMessage.uniqueId)
        }
        .animation(.easeInOut, value: viewModel.unsentMessages.count)
    }
}

struct ThreadMessagesList_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: ThreadViewModel

        init() {
            let metadata = "{\"name\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11\",\"file\": {\"hashCode\": \"UJMUIT4M194C5WLJ\",\"mimeType\": \"image/png\",\"fileHash\": \"UJMUIT4M194C5WLJ\",\"actualWidth\": 1290,\"actualHeight\": 2796,\"parentHash\": \"6MIPH7UM1P7OIZ2L\",\"size\": 1569454,\"link\": \"https://podspace.pod.ir/api/images/UJMUIT4M194C5WLJ?checkUserGroupAccess=true\",\"name\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11\",\"originalName\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11.png\"},\"fileHash\": \"UJMUIT4M194C5WLJ\"}"
            let message = Message(message: "Please download this file.",
                                  messageType: .file,
                                  metadata: metadata.string,
                                  conversation: .init(id: 1))

            let viewModel = ThreadViewModel(thread: Conversation(id: 1), threadsViewModel: .init())
            viewModel.sections.append(MessageSection(date: .init(), messages: [message]))
            viewModel.animateObjectWillChange()
            self._viewModel = StateObject(wrappedValue: viewModel)
        }

        var body: some View {
            ThreadMessagesList(viewModel: viewModel)
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
