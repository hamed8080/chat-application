//
//  ThreadHistoryVStack.swift
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
import TalkModels

struct ThreadHistoryVStack: View {
    @EnvironmentObject var viewModel: ThreadHistoryViewModel

    var body: some View {
        ThreadHistoryList()
            .overlay {
                if viewModel.isEmptyThread {
                    EmptyThreadView()
                }
            }
            .overlay(ThreadHistoryShimmerView().environmentObject(viewModel.shimmerViewModel))
            .environment(\.layoutDirection, .leftToRight)
    }
}

struct ThreadHistoryList: View {
    @EnvironmentObject var viewModel: ThreadHistoryViewModel

    var body: some View {
        List {
            ListLoadingView(isLoading: .constant(viewModel.topLoading))
                .id(-1)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .padding([.top, .bottom])
                .padding([.top, .bottom], viewModel.topLoading ? 8 : 0)
                .animation(.easeInOut, value: viewModel.topLoading)
                .onAppear {
                    viewModel.isTopEndListAppeared = true
                }
                .onDisappear {
                    viewModel.isTopEndListAppeared = false
                }

            ForEach(viewModel.sections, id: \.id) { section in
                SectionView(section: section)
                MessageList(vms: section.vms, viewModel: viewModel)
            }

            SpaceForAttachment()
                .id(-3)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
            
            ListLoadingView(isLoading: .constant(viewModel.bottomLoading))
                .id(-2)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .padding([.top, .bottom], viewModel.bottomLoading ? 8 : 0)
                .animation(.easeInOut, value: viewModel.bottomLoading)

            //                UnsentMessagesLoop(historyVM: viewModel)
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
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
                .background(Color.black.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(24)))
                .foregroundStyle(Color.App.white)
            Spacer()
        }
        .task {
            Task.detached(priority: .background) {
                if yearText == "" {
                    let yearText = section.date.yearCondence ?? ""
                    await MainActor.run {
                        self.yearText = yearText
                    }
                }
            }
        }
    }
}

struct MessageList: View {
    let vms: ContiguousArray<MessageRowViewModel>
    let viewModel: ThreadHistoryViewModel

    var body: some View {
        ForEach(vms, id: \.uniqueId) { vm in
            MessageRowFactory(viewModel: vm)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .onAppear {
                    Task {
                        await viewModel.onMessageAppear(vm.message)
                    }
                }
                .onDisappear {
                    Task {
                        await viewModel.onMessegeDisappear(vm.message)
                    }
                }
        }
    }
}

struct UnsentMessagesLoop: View {
    let historyVM: ThreadHistoryViewModel
    @EnvironmentObject var viewModel: ThreadUnsentMessagesViewModel

    var body: some View {
        /// We have to use \.uniqueId to force the ForLoop to use uniqueId instead of default \.id because id is nil when a message is unsent.
        ForEach(viewModel.unsentMessages, id: \.uniqueId) { unsentMessage in
            if let messageRowVM = historyVM.messageViewModel(for: unsentMessage) {
                MessageRowFactory(viewModel: messageRowVM)
                    .id(unsentMessage.uniqueId)
            }
        }
        .animation(.easeInOut, value: viewModel.unsentMessages.count)
    }
}

/// Pull the view up when there is an attachment over history and prevents it to show the last message.
struct SpaceForAttachment: View {
    @EnvironmentObject var viewModel: AttachmentsViewModel

    var body: some View {
        if viewModel.attachments.count > 0 {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 72)
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
            viewModel.historyVM.sections.append(MessageSection(date: .init(), vms: [.init(message: message, viewModel: viewModel)]))
            viewModel.animateObjectWillChange()
            self._viewModel = StateObject(wrappedValue: viewModel)
        }

        var body: some View {
          EmptyView()
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
