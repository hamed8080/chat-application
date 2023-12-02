//
//  MusicView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct MusicView: View {
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
        MessageListMusicView()
            .padding(.top, 8)
            .environmentObject(viewModel)
    }
}

struct MessageListMusicView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: DetailViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            MusicRowView(message: message)
                .environmentObject(detailViewModel.threadVM?.messageViewModel(for: message).downloadFileVM ?? DownloadFileViewModel(message: message))
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
}

struct MusicRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var downloadViewModel: DownloadFileViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            if downloadViewModel.state == .completed, let fileURL = downloadViewModel.fileURL {
                DownloadedMusicPlayer(message: message, fileURL: fileURL)
            } else {
                DownloadMusicButtonView()
                    .frame(width: 48, height: 48)
                    .padding(4)
            }

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
        .padding([.leading, .trailing])
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                threadVM?.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
                viewModel.dismiss = true
            } label: {
                Label("General.showMessage", systemImage: "bubble.middle.top")
            }
        }
        .onTapGesture {
            if downloadViewModel.state != .completed {
                downloadViewModel.startDownload()
            } else {
                AppState.shared.objectsContainer.audioPlayerVM.toggle()
            }
        }
    }
}

struct DownloadedMusicPlayer: View {
    let message: Message
    let fileURL: URL
    @EnvironmentObject var viewModel: AVAudioPlayerViewModel
    var isSameFile: Bool { viewModel.fileURL?.absoluteString == fileURL.absoluteString }

    var body: some View {
        Button {
            viewModel.setup(message: message,
                            fileURL: fileURL,
                            ext: message.fileMetaData?.file?.mimeType?.ext,
                            title: message.fileMetaData?.name,
                            subtitle: message.fileMetaData?.file?.originalName ?? "")
            viewModel.toggle()
        } label: {
            ZStack {
                Image(systemName: viewModel.isPlaying  && isSameFile ? "pause.fill" : "play.fill" )
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.App.text)

                Circle()
                    .trim(from: 0.0, to: isSameFile ? min(viewModel.currentTime / viewModel.duration, 1.0) : 0)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.App.text)
                    .rotationEffect(Angle(degrees: 270))
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 36, height: 36)
            .background(Color.App.primary)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .contentShape(Rectangle())
        }
        .frame(width: 48, height: 48)
        .padding(4)
    }
}

struct DownloadMusicButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    var body: some View {
        DownloadFileView(viewModel: veiwModel, config: .detail)
            .frame(width: 72, height: 72)
    }
}

struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        MusicView(conversation: MockData.thread, messageType: .podSpaceSound)
    }
}
