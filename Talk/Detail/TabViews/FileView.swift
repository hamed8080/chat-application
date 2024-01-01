//
//  FileView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatDTO
import ChatModels
import Combine
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import ActionableContextMenu

struct FileView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
    }

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
            .onAppear {
                if viewModel.messages.count == 0 {
                    viewModel.loadMore()
                }
            }
        MessageListFileView()
            .padding(.top, 8)
            .environmentObject(viewModel)
    }
}

struct MessageListFileView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: DetailViewModel
    
    var body: some View {
        ForEach(viewModel.messages) { message in
            FileRowView(message: message)
                .environmentObject(downloadMV(message))
                .overlay(alignment: .bottom) {
                    if message != viewModel.messages.last {
                        Rectangle()
                            .fill(Color.App.divider)
                            .frame(height: 0.5)
                            .padding(.leading)
                    }
                }
                .onAppear {
                    if message == viewModel.messages.last {
                        viewModel.loadMore()
                    }
                }
        }
        DetailLoading()
    }
    
    private func downloadMV(_ message: Message) -> DownloadFileViewModel {
        detailViewModel.threadVM?.historyVM.messageViewModel(for: message).downloadFileVM ?? DownloadFileViewModel(message: message)
    }
}

struct FileRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss
    @State var shareDownloadedFile = false
    @EnvironmentObject var downloadViewModel: DownloadFileViewModel

    var body: some View {
        HStack {
            DownloadFileButtonView()
            VStack(alignment: .leading) {
                Text(message.fileMetaData?.name ?? message.messageTitle)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.text)
                HStack {
                    Text(message.time?.date.localFormattedTime ?? "" )
                        .foregroundColor(Color.App.hint)
                        .font(.iransansCaption2)
                    Spacer()
                    Text(message.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) ?? "")
                        .foregroundColor(Color.App.hint)
                        .font(.iransansCaption3)
                }
            }
            Spacer()
        }
        .padding(.all)
        .background(Color.App.bgPrimary)
        .contentShape(Rectangle())
        .sheet(isPresented: $shareDownloadedFile) {
            ActivityViewControllerWrapper(activityItems: [message.tempURL], title: message.fileMetaData?.file?.originalName)
        }
        .onTapGesture {
            if downloadViewModel.state == .completed {
                Task {
                    _ = await message.makeTempURL()
                    await MainActor.run {
                        shareDownloadedFile.toggle()
                    }
                }
            } else {
                downloadViewModel.startDownload()
            }
        }
        .customContextMenu(id: message.id, self: self.environmentObject(downloadVM)) {
            VStack {
                ContextMenuButton(title: "General.showMessage", image: "message.fill") {
                    threadVM?.historyVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
                    viewModel.dismiss = true
                }
            }
            .foregroundColor(.primary)
            .frame(width: 196)
            .background(MixMaterialBackground())
            .clipShape(RoundedRectangle(cornerRadius:((12))))
        }
    }
}

struct DownloadFileButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    var body: some View {
        DownloadFileView(viewModel: veiwModel)
            .frame(width: 42, height: 42)
            .padding(4)
            .clipped()
            .cornerRadius(4) /// We round the corner of the file is an image we show a thumbnail of the file not the icon.
    }
}

struct FileView_Previews: PreviewProvider {
    static let thread = MockData.thread

    static var previews: some View {
        FileView(conversation: thread, messageType: .file)
    }
}
