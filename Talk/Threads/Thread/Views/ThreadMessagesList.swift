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
import Chat

struct ThreadMessagesList: View {
    let viewModel: ThreadViewModel

    var body: some View {
        ScrollViewReader { scrollProxy in
            MessagesLazyStack()
            .background(ThreadbackgroundView(threadId: viewModel.threadId))
            .overlay(alignment: .bottom) {
                VStack {
                    MoveToBottomButton()
                    SendContainerOverButtons()
                }
            }
            .onAppear {
                viewModel.scrollVM.scrollProxy = scrollProxy
                UICollectionViewCell.appearance().backgroundView = UIView()
                UITableViewHeaderFooterView.appearance().backgroundView = UIView()
            }
            .overlay(alignment: .center) {
                CenterLoading()
            }
        }
        .simultaneousGesture(tap.simultaneously(with: drag))
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { newValue in
                viewModel.scrollVM.isProgramaticallyScroll = false
                viewModel.scrollVM.scrollingUP = newValue.translation.height > 10
                viewModel.scrollVM.animateObjectWillChange()
            }
    }

    private var tap: some Gesture {
        TapGesture()
            .onEnded { _ in
                hideKeyboardOnTapOrDrag()
            }
    }

    private func hideKeyboardOnTapOrDrag() {
        if viewModel.searchedMessagesViewModel.searchText.isEmpty {
            NotificationCenter.default.post(name: .cancelSearch, object: true)
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        viewModel.historyVM.messageViewModels.filter{ $0.showReactionsOverlay == true }.forEach { rowViewModel in
            rowViewModel.showReactionsOverlay = false
            rowViewModel.animateObjectWillChange()
        }
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
            .opacity(colorScheme == .dark ? 0.2 : 0.25)
            .colorInvert()
            .colorMultiply(colorScheme == .dark ? Color.App.white : Color.App.cyan)
            .ignoresSafeArea()
    }
}

struct MessagesLazyStack: View {
    @EnvironmentObject var viewModel: ThreadHistoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            List {
                ListLoadingView(isLoading: $viewModel.topLoading)
                    .id(-1)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                    .padding([.top, .bottom])
                ForEach(viewModel.sections) { section in
                    Section {
                        MessageList(messages: section.messages, viewModel: viewModel)
                    } header: {
                        SectionView(section: section)
                    }
                }
                UploadMessagesLoop(historyVM: viewModel)
                UnsentMessagesLoop(historyVM: viewModel)
                ListLoadingView(isLoading: $viewModel.bottomLoading)
                    .id(-2)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                    .padding([.top, .bottom])
            }
            .listStyle(.plain)
            KeyboardHeightView()
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct SectionView: View {
    let section: MessageSection
    @State private var yearText = ""

    var body: some View {
        HStack {
            Spacer()
            Text(verbatim: yearText)
                .font(.iransansCaption)
                .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .background(Color.App.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius:(24)))
                .foregroundStyle(Color.App.text)
            Spacer()
        }
        .task {
            Task {
                yearText = section.date.yearCondence ?? ""
            }
        }
    }
}

struct MessageList: View {
    let messages: ContiguousArray<Message>
    let viewModel: ThreadHistoryViewModel

    var body: some View {
        ForEach(messages) { message in
            MessageRowFactory(viewModel: viewModel.messageViewModel(for: message))
                .id(message.uniqueId)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .onAppear {
                    viewModel.onMessageAppear(message)
                }
                .onDisappear {
                    viewModel.onMessegeDisappear(message)
                }
        }
    }
}

struct UploadMessagesLoop: View {
    let historyVM: ThreadHistoryViewModel
    @EnvironmentObject var viewModel: ThreadUploadMessagesViewModel

    var body: some View {
        /// We must use uniqueId with messageId to force swiftUI to delete the row and make a new one after uploading successfully.
        ForEach(viewModel.uploadMessages, id: \.uniqueId) { uploadFileMessage in
            MessageRowFactory(viewModel: historyVM.messageViewModel(for: uploadFileMessage))
                .id("\(uploadFileMessage.uniqueId ?? "")\(uploadFileMessage.id ?? 0)")
        }
        .animation(.easeInOut, value: viewModel.uploadMessages.count)
    }
}

struct UnsentMessagesLoop: View {
    let historyVM: ThreadHistoryViewModel
    @EnvironmentObject var viewModel: ThreadUnsentMessagesViewModel

    var body: some View {
        /// We have to use \.uniqueId to force the ForLoop to use uniqueId instead of default \.id because id is nil when a message is unsent.
        ForEach(viewModel.unsentMessages, id: \.uniqueId) { unsentMessage in
            MessageRowFactory(viewModel: historyVM.messageViewModel(for: unsentMessage))
                .id(unsentMessage.uniqueId)
        }
        .animation(.easeInOut, value: viewModel.unsentMessages.count)
    }
}

struct KeyboardHeightView: View {
    @EnvironmentObject var viewModel: ThreadScrollingViewModel
    /// We use isInAnimating to prevent multiple calling onKeyboardSize.
    @State var isInAnimating = false

    var body: some View {
        Rectangle()
            .id("KeyboardHeightView")
            .frame(width: 0, height: 0)
            .onKeyboardSize { size in
                if !isInAnimating {
                    isInAnimating = true
                    viewModel.disableExcessiveLoading()
                    if size.height > 0, viewModel.isAtBottomOfTheList {
                        updateHeight(size.height)
                    } else if viewModel.isAtBottomOfTheList {
                        updateHeight(size.height)
                    } else {
                        isInAnimating = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .message)) { notif in
                if let event = notif.object as? MessageEventTypes {
                    if case .new(let response) = event, response.result?.conversation?.id == viewModel.threadVM.threadId, viewModel.isAtBottomOfTheList {
                        updateHeight(0)
                    }
                }
            }
    }

    private func updateHeight(_ height: CGFloat) {
        // We have to wait until all the animations for clicking on TextField are finished and then start our animation.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                viewModel.scrollProxy?.scrollTo(viewModel.threadVM.thread.lastMessageVO?.uniqueId ?? "", anchor: .bottom)
                isInAnimating = false
            }
        }
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
            viewModel.historyVM.sections.append(MessageSection(date: .init(), messages: [message]))
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
