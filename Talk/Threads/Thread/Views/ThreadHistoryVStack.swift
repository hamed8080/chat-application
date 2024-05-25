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
    var viewModel: ThreadHistoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isEmptyThread {
            } else {
                ThreadHistoryList(viewModel: viewModel)
            }
        }
        .overlay(ThreadHistoryShimmerView().environmentObject(viewModel.shimmerViewModel))
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct ThreadHistoryList: View {
    var viewModel: ThreadHistoryViewModel

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

//            UnsentMessagesLoop(historyVM: viewModel)
//                .id(-4)

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

        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
//        .safeAreaInset(edge: .bottom) {
//            ThreadEmptySpaceView()
//        }
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
                        viewModel.onMessageAppear(vm.message)
                    }
                }
                .onDisappear {
                    Task {
                        viewModel.onMessegeDisappear(vm.message)
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
        ForEach(viewModel.rowViewModels, id: \.uniqueId) { messageRowVM in
            MessageRowFactory(viewModel: messageRowVM)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
        }
        .animation(.easeInOut, value: viewModel.rowViewModels.count)
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
