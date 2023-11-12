//
//  ThreadPinMessage.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import Chat
import ChatDTO
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadPinMessage: View {
    private var thread: Conversation { threadVM.thread }
    @State private var message: PinMessage?
    let threadVM: ThreadViewModel
    @State var thumbnailData: Data?
    @State var requestUniqueId: String?
    private var icon: String? { fileMetadata?.file?.mimeType?.systemImageNameForFileExtension }
    var isEnglish: Bool { message?.text?.naturalTextAlignment == .leading }
    private var title: String {
        if let text = message?.text, !text.isEmpty {
            return text.prefix(150).replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let fileName = fileMetadata?.name {
            return fileName
        } else {
            return ""
        }
    }

    private let downloadPublisher = NotificationCenter.default.publisher(for: .download).compactMap { $0.object as? DownloadEventTypes }
    private let messagePublisher = NotificationCenter.default.publisher(for: .message).compactMap { $0.object as? MessageEventTypes }

    var body: some View {
        VStack(spacing: 0) {
            if message != nil {
                HStack {
                    if isEnglish {
                        LTRDesign
                    } else {
                        RTLDesign
                    }
                }
                .padding(.leading, isEnglish ? 4 : 8)
                .padding(.trailing, isEnglish ? 8 : 4)
                .frame(height: 40)
                .background(MixMaterialBackground())
                .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
                .onTapGesture {
                    if let time = message?.time, let messageId = message?.messageId {
                        threadVM.moveToTime(time, messageId)
                    }
                }
            }
        }
        .onReceive(downloadPublisher) { event in
            onDownloadEvent(event)
        }
        .onReceive(messagePublisher) { event in
            onMessageEvent(event)
        }
        .onAppear {
            message = thread.pinMessage
            downloadImageThumbnail()
        }
    }

    @ViewBuilder private var LTRDesign: some View {
        closeButton
        Spacer()
        imageView
        textView
        pinButton
        separator
    }

    @ViewBuilder private var RTLDesign: some View {
        separator
        pinButton
        imageView
        textView
        Spacer()
        closeButton
    }

    private var separator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.App.primary)
            .frame(width: 3, height: 24)
    }

    private var pinButton: some View {
        Button {
            threadVM.unpinMessage(message?.messageId ?? -1)
        } label: {
            Label("Thread.unpin", systemImage: "pin.fill")
                .labelStyle(.iconOnly)
                .foregroundColor(Color.App.primary)
        }
    }

    private var textView: some View {
        Text(title)
            .font(.iransansBody)
    }

    @ViewBuilder private var imageView: some View {
        if let thumbnailData = thumbnailData, let image = UIImage(data: thumbnailData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .cornerRadius(4)
        } else if let icon = icon {
            Image(systemName: icon)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.App.hint, .clear)
        }
    }

    var closeButton: some View {
        Button {
            withAnimation {
                threadVM.unpinMessage(message?.messageId ?? -1)
            }
        } label: {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.App.gray5)
                .frame(width: 12, height: 12)
        }
        .frame(width: 36, height: 36)
        .buttonStyle(.borderless)
        .fontWeight(.light)
    }

    var fileMetadata: FileMetaData? {
        guard let metdataData = message?.metadata?.data(using: .utf8),
              let file = try? JSONDecoder.instance.decode(FileMetaData.self, from: metdataData)
        else { return nil }
        return file
    }

    private func downloadImageThumbnail() {
        guard let file = fileMetadata,
              let hashCode = file.file?.hashCode,
              file.file?.mimeType == "image/jpeg" || file.file?.mimeType == "image/png"
        else {
            thumbnailData = nil
            return
        }

        let req = ImageRequest(hashCode: hashCode, quality: 0.1, size: .SMALL, thumbnail: true)
        requestUniqueId = req.uniqueId
        ChatManager.activeInstance?.file.get(req)
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) {
        switch event {
        case let .image(chatResponse, _):
            if requestUniqueId == chatResponse.uniqueId {
                thumbnailData = chatResponse.result
            }
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case let .pin(response):
            if threadVM.threadId == response.subjectId {
                withAnimation(.easeInOut) {
                    message = response.result
                    downloadImageThumbnail()
                }
            }
        case let .unpin(response):
            if threadVM.threadId == response.subjectId {
                withAnimation(.easeInOut) {
                    message = nil
                }
            }
        case .edited(let response):
            if response.result?.id == message?.id, let message = response.result {
                withAnimation(.easeInOut) {
                    self.message = PinMessage(message: message)
                }
            }
        default:
            break
        }
    }
}

struct ThreadPinMessage_Previews: PreviewProvider {
    static var previews: some View {
        ThreadPinMessage(threadVM: ThreadViewModel(thread: Conversation()))
    }
}
