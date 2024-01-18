//
//  TextMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import Combine
import TalkModels
import TalkExtensions
import ChatCore
import Logger

//struct TextMessageType: View {
//    private var message: Message { viewModel.message }
//    private var threadVM: ThreadViewModel? { viewModel.threadVM }
//    let viewModel: MessageRowViewModel
//
//    var body: some View {
//        HStack(spacing: 0) {
//            if !viewModel.isMe {
//                SelectMessageRadio()
//            }
//
//            if viewModel.isMe {
//                Spacer()
//            }
//
//            VStack(spacing: 0) {
//                Spacer()
//                AvatarViewWapper(viewModel: viewModel)
//            }
//
//            MutableMessageView(viewModel: viewModel)
//
//            if !viewModel.isMe {
//                Spacer()
//            }
//
//            if viewModel.isMe {
//                SelectMessageRadio()
//            }
//        }
//        .environmentObject(viewModel)
//        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
//    }
//}

final class TextMessageTypeCell: UITableViewCell {
    private let messageContainer = UIView()
    private let vStack = UIStackView()
    public var viewModel: MessageRowViewModel!
    private let avatar = AvatarView()
    private let radio = SelectMessageRadio()

    private let messageRowFileDownloader = MessageRowFileDownloader()
    private let messageRowImageDownloader = MessageRowImageDownloader()
    private let messageRowVideoDownloader = MessageRowVideoDownloader()
    private let messageRowAudioDownloader = MessageRowAudioDownloader()
    private let locationRowView = LocationRowView()
    private let groupParticipantNameView = GroupParticipantNameView()
    private let replyInfoMessageRow = ReplyInfoMessageRow()
    private let forwardMessageRow = ForwardMessageRow()
    private let uploadImage = UploadMessageImageView()
    private let uploadFile = UploadMessageFileView()
    private let messageTextView = MessageTextView()
    private let joinPublicLink = JoinPublicLink()
    private let unsentMessageView = UnsentMessageView()
    private var cancellable = Set<AnyCancellable>()

    convenience init(viewModel: MessageRowViewModel) {
        self.init(style: .default, reuseIdentifier: "MessageUITableViewCell")
        self.viewModel = viewModel
        configureView()
        setupObservers()
    }

    private func setupObservers() {
        viewModel.objectWillChange.sink { [weak self] _ in
            guard let self = self else { return }
            self.setValues(viewModel: viewModel)
        }
        .store(in: &cancellable)
    }

    public func configureView() {
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        avatar.translatesAutoresizingMaskIntoConstraints = false
        radio.translatesAutoresizingMaskIntoConstraints = false
        vStack.translatesAutoresizingMaskIntoConstraints = false

        vStack.axis = .vertical
        vStack.spacing = 10
        vStack.distribution = .fill
        vStack.addArrangedSubviews([
            messageRowFileDownloader,
            messageRowImageDownloader,
            messageRowVideoDownloader,
            messageRowAudioDownloader,
            locationRowView,
            groupParticipantNameView,
            replyInfoMessageRow,
            forwardMessageRow,
            uploadImage,
            uploadFile,
            messageTextView,
            joinPublicLink,
            unsentMessageView
        ])
        messageContainer.addSubview(vStack)
        messageContainer.addSubview(avatar)
        messageContainer.addSubview(radio)
        addSubview(messageContainer)
        setConstraints()
    }

    private func setConstraints() {
        if !viewModel.isMe && viewModel.isNextMessageTheSameUser {
            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: 36),
                avatar.heightAnchor.constraint(equalToConstant: 36),
                avatar.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 8),
                avatar.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant:  -8),
                vStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8)
            ])
        } else if viewModel.isInSelectMode {
            NSLayoutConstraint.activate([
                radio.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -8),
                radio.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 8),
                vStack.leadingAnchor.constraint(equalTo: radio.trailingAnchor, constant: 8)
            ])
        } else if !viewModel.message.messageTitle.isEmpty, !viewModel.isPublicLink {
            messageTextView.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 8).isActive = true
        }

        if !viewModel.isMe {
            messageContainer.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        } else {
            messageContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            vStack.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor),
            vStack.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            vStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 128),
            messageContainer.topAnchor.constraint(equalTo: topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: viewModel.imageWidth ?? ThreadViewModel.maxAllowedWidth),
            messageContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 128),
        ])
    }

    private func resetViews() {
        let message = viewModel.message
        messageContainer.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        messageRowFileDownloader.isHidden = !showFileRow
        messageRowImageDownloader.isHidden = !viewModel.canShowImageView
        messageRowVideoDownloader.isHidden = !showVideoRow
        messageRowAudioDownloader.isHidden = !showAudioRow
        locationRowView.isHidden = !viewModel.isMapType
        groupParticipantNameView.isHidden = !canShowName
        replyInfoMessageRow.isHidden = message.replyInfo == nil
        forwardMessageRow.isHidden = message.forwardInfo == nil
        uploadImage.isHidden = !showUploadImage
        uploadFile.isHidden = !showUploadFile
        messageTextView.isHidden = !showTextMessageRow
        joinPublicLink.isHidden = message.message?.contains(AppRoutes.joinLink) == false
        unsentMessageView.isHidden = !message.isUnsentMessage
        avatar.isHidden = !showAvatar
        radio.isHidden = !showRadio
    }

    public func setValues(viewModel: MessageRowViewModel) {
        resetViews()
        avatar.setValues(viewModel: viewModel)
        messageTextView.setValues(viewModel: viewModel)
        replyInfoMessageRow.setValues(viewModel: viewModel)
        forwardMessageRow.setValues(viewModel: viewModel)
        messageRowImageDownloader.setValues(viewModel: viewModel)
        groupParticipantNameView.setValues(viewModel: viewModel)
        locationRowView.setValues(viewModel: viewModel)
        messageRowFileDownloader.setValues(viewModel: viewModel)
        messageRowAudioDownloader.setValues(viewModel: viewModel)
        messageRowVideoDownloader.setValues(viewModel: viewModel)
        joinPublicLink.setValues(viewModel: viewModel)
        unsentMessageView.setValues(viewModel: viewModel)
    }

    var canShowName: Bool {
        !viewModel.isMe && viewModel.threadVM?.thread.group == true && viewModel.threadVM?.thread.type?.isChannelType == false
    }

    private var showVideoRow: Bool {
        let message = viewModel.message
        return !message.isUploadMessage && message.isVideo == true
    }

    private var showFileRow: Bool {
        let message = viewModel.message
        return !message.isUploadMessage && message.isFileType && !viewModel.isMapType && !message.isImage && !message.isAudio && !message.isVideo
    }

    private var showAudioRow: Bool {
        let message = viewModel.message
        return !message.isUploadMessage && message.isAudio == true
    }

    private var showUploadImage: Bool {
        let message = viewModel.message
        return message.isUploadMessage && message.isImage
    }

    private var showUploadFile: Bool {
        let message = viewModel.message
        return message.isUploadMessage && !message.isImage && message.isFileType
    }

    private var showTextMessageRow: Bool {
        let message = viewModel.message
        return !message.messageTitle.isEmpty && !viewModel.isPublicLink
    }

    private var showAvatar: Bool {
        return !viewModel.isMe && viewModel.isNextMessageTheSameUser
    }

    private var showRadio: Bool {
        return viewModel.isInSelectMode
    }
}

struct TextMessageTypeCellWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = TextMessageTypeCell()
        view.viewModel = viewModel
        view.configureView() /// only for preview
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

//struct SelectMessageRadio: View {
//    @EnvironmentObject var viewModel: MessageRowViewModel
//
//    var body: some View {
//        if viewModel.isInSelectMode {
//            VStack {
//                Spacer()
//                RadioButton(visible: $viewModel.isInSelectMode, isSelected: $viewModel.isSelected) { _ in
//                    viewModel.toggleSelection()
//                }
//            }
//            .padding(EdgeInsets(top: 0, leading: viewModel.isMe ? 8 : 0, bottom: 8, trailing: viewModel.isMe ? 8 : 0))
//        }
//    }
//}

public final class SelectMessageRadio: UIView {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 48),
            heightAnchor.constraint(equalToConstant: 48),
            imageView.widthAnchor.constraint(equalToConstant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let isSelected = viewModel.isSelected
        imageView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        imageView.tintColor = isSelected ? Color.App.whiteUIColor : UIColor.gray
    }
}

struct MutableMessageView: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        HStack {
            InnerMessage(viewModel: viewModel)
        }
        .frame(minWidth: 128, maxWidth: viewModel.imageWidth ?? ThreadViewModel.maxAllowedWidth, alignment: viewModel.isMe ? .trailing : .leading)
        .simultaneousGesture(TapGesture().onEnded { _ in }, including: message.isVideo ? .subviews : .all)
    }
}

struct InnerMessage: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        VStack(alignment: viewModel.isMe ? .trailing : .leading, spacing: 10) {
            Group {
                MessageRowFileDownloaderWapper(viewModel: viewModel)
                MessageRowImageDownloaderWapper(viewModel: viewModel)
                MessageRowVideoDownloaderWapper(viewModel: viewModel)
                MessageRowAudioDownloaderWapper(viewModel: viewModel)
            }
            LocationRowViewWapper(viewModel: viewModel)
            GroupParticipantNameViewWapper(viewModel: viewModel)
            ReplyInfoMessageRowWapper(viewModel: viewModel)
            ForwardMessageRowWapper(viewModel: viewModel)
            UploadMessageType()
            MessageTextViewWapper(viewModel: viewModel)
            JoinPublicLinkWapper(viewModel: viewModel)
            UnsentMessageViewWapper(viewModel: viewModel)
            Group {
                ReactionCountViewWapper(viewModel: viewModel)
                    .environmentObject(viewModel.reactionsVM)
                    .environmentObject(viewModel)
                MessageFooterUITableViewCellWapper(viewModel: viewModel)
            }
        }
        .padding(viewModel.paddingEdgeInset)
        .customContextMenu(id: message.id, self: SelfContextMenu(viewModel: viewModel), menus: { ContextMenuContent(viewModel: viewModel) })
        .overlay(alignment: .center) { SelectMessageInsideClickOverlay() }
    }
}

struct ContextMenuContent: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        VStack {
            ReactionMenuView()
                .environmentObject(viewModel.reactionsVM)
                .fixedSize()
            MessageActionMenu()
        }
        .id("SelfContextMenu\(viewModel.message.id ?? 0)")
        .environmentObject(viewModel)
        .onAppear {
            hideKeyboard()
        }
    }
}

struct SelfContextMenu: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        HStack {
            InnerMessage(viewModel: viewModel)
                .environmentObject(viewModel)
                .environmentObject(AppState.shared.objectsContainer.audioPlayerVM)
        }
        .id("SelfContextMenu\(viewModel.message.id ?? 0)")
        .frame(maxWidth: ThreadViewModel.maxAllowedWidth)
    }
}

struct TextMessageType_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            ThreadViewModel.maxAllowedWidth = 340
            self._viewModel = StateObject(wrappedValue: viewModel)
            Task {
                await viewModel.performaCalculation()
                await viewModel.asyncAnimateObjectWillChange()
            }
        }

        var body: some View {
            TextMessageTypeCellWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.viewModels.first(where: {$0.message.replyInfo != nil })!)
            .previewDisplayName("Reply")
        Preview(viewModel: MockAppConfiguration.viewModels.first(where: {$0.message.forwardInfo != nil })!)
            .previewDisplayName("Forward")
    }
}

class MockAppConfiguration: ChatDelegate {

    static let imageMetaData = FileMetaData(file:
            .init(fileExtension: "jpg",
                  link: "https://media.gcflearnfree.org/ctassets/topics/246/share_size_large.jpg",
                  mimeType: "image/jpeg",
                  name: "Image",
                  originalName: "image",
                  size: 2044,
                  actualHeight: 500, actualWidth: 500)
    )
    static let forwardInfo = ForwardInfo(
        conversation: .init(id: 2, title: "Forwarded thread title"),
        participant: .init(name: "Apple Seed")
    )
    static let replyInfo = ReplyInfo(
        repliedToMessageId: 1,
        message: "TEST Reply ",
        messageType: .podSpacePicture,
        metadata: try? JSONEncoder().encode(imageMetaData).utf8String,
        repliedToMessageTime: 155600555
    )
    static let longText = """
This is a very long text to test how it would react to size change\n
In this new line we are going to test if it can break the line.
"""

    static let messages: [Message] = [
        .init(
            id: 1,
            message: longText,
            messageType: .text,
            ownerId: 1,
            seen: true,
            time: UInt(Date().millisecondsSince1970),
            participant: Participant(id: 0, name: "John Doe"),
            replyInfo: replyInfo
        ),
        .init(
            id: 1,
            message: longText,
            messageType: .text,
            ownerId: 1,
            seen: true,
            time: UInt(Date().millisecondsSince1970),
            forwardInfo: forwardInfo,
            participant: Participant(id: 0, name: "John Doe")
        )
    ]

    static var viewModels: [MessageRowViewModel] = {
        _ = MockAppConfiguration.shared
        let conversation = Conversation(id: 1)
        let conversationVM = ThreadViewModel(thread: conversation)
        var vms: [MessageRowViewModel] = []
        messages.forEach { message in
            let viewModel = MessageRowViewModel(message: message, viewModel: conversationVM)
            vms.append(viewModel)
        }
        return vms
    }()

    static var shared: ChatDelegate = MockAppConfiguration()

    private init () {
        AppState.shared.objectsContainer = .init(delegate: self)
        AppState.shared.objectsContainer.audioPlayerVM = .init()
    }

    func chatState(state: ChatCore.ChatState, currentUser: ChatModels.User?, error: ChatCore.ChatError?) {

    }

    func chatEvent(event: ChatEventType) {

    }

    func onLog(log: Log) {

    }
}
