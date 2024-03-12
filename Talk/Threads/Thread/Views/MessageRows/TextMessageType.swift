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

final class TextMessageTypeCell: UITableViewCell {
    private var viewModel: MessageRowViewModel! {
        didSet {
            setupObservers()
        }
    }
    private let avatar = AvatarView()
    private let radio = SelectMessageRadio()
    private let messageRowFileDownloader = MessageRowFileDownloaderView()
    private let messageRowImageDownloader = MessageRowImageDownloaderView()
    private let messageRowVideoDownloader = MessageRowVideoDownloaderView()
    private let messageRowAudioDownloader = MessageRowAudioDownloaderView()
    private let locationRowView = LocationRowView()
    private let groupParticipantNameView = GroupParticipantNameView()
    private let replyInfoMessageRow = ReplyInfoMessageRow()
    private let forwardMessageRow = ForwardMessageRow()
    private let uploadImage = UploadMessageImageView()
    private let uploadFile = UploadMessageFileView()
    private let messageTextView = MessageTextView()
    private let unsentMessageView = UnsentMessageView()
    private let reactionView = MessageReactionsView()
    private var cancellable = Set<AnyCancellable>()
    private var message: Message { viewModel.message }
    private var isEmptyMessage: Bool { message.message == nil || message.message?.isEmpty == true  }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupObservers() {
        viewModel.objectWillChange.sink { [weak self] _ in
            guard let self = self else { return }
            self.setValues(viewModel: viewModel)
        }
        .store(in: &cancellable)
    }

    public func configureView() {

        translatesAutoresizingMaskIntoConstraints = false
        avatar.translatesAutoresizingMaskIntoConstraints = false
        radio.translatesAutoresizingMaskIntoConstraints = false
        messageRowFileDownloader.translatesAutoresizingMaskIntoConstraints = false
        messageRowImageDownloader.translatesAutoresizingMaskIntoConstraints = false
        messageRowVideoDownloader.translatesAutoresizingMaskIntoConstraints = false
        messageRowAudioDownloader.translatesAutoresizingMaskIntoConstraints = false
        locationRowView.translatesAutoresizingMaskIntoConstraints = false
        groupParticipantNameView.translatesAutoresizingMaskIntoConstraints = false
        replyInfoMessageRow.translatesAutoresizingMaskIntoConstraints = false
        forwardMessageRow.translatesAutoresizingMaskIntoConstraints = false
        uploadImage.translatesAutoresizingMaskIntoConstraints = false
        uploadFile.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        reactionView.translatesAutoresizingMaskIntoConstraints = false
        unsentMessageView.translatesAutoresizingMaskIntoConstraints = false

        registerGestures()

//        setDebugColors()

        contentView.addSubview(avatar)
        contentView.addSubview(radio)
        contentView.addSubview(groupParticipantNameView)
        contentView.addSubview(replyInfoMessageRow)
        contentView.addSubview(forwardMessageRow)
        contentView.addSubview(messageRowFileDownloader)
        contentView.addSubview(messageRowImageDownloader)
        contentView.addSubview(messageRowVideoDownloader)
        contentView.addSubview(messageRowAudioDownloader)
        contentView.addSubview(locationRowView)
        contentView.addSubview(uploadImage)
        contentView.addSubview(uploadFile)
        contentView.addSubview(messageTextView)
        contentView.addSubview(reactionView)
        contentView.addSubview(unsentMessageView)

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            radio.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            radio.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            radio.widthAnchor.constraint(equalToConstant: 24),
            radio.heightAnchor.constraint(equalToConstant: 24),
            avatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            avatar.leadingAnchor.constraint(equalTo: radio.trailingAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),
            groupParticipantNameView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            groupParticipantNameView.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
//            groupParticipantNameView.heightAnchor.constraint(equalToConstant: 22),
            replyInfoMessageRow.topAnchor.constraint(equalTo: groupParticipantNameView.bottomAnchor, constant: 2),
            replyInfoMessageRow.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            replyInfoMessageRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            forwardMessageRow.topAnchor.constraint(equalTo: replyInfoMessageRow.bottomAnchor, constant: 2),
            forwardMessageRow.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            forwardMessageRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            messageRowFileDownloader.topAnchor.constraint(equalTo: forwardMessageRow.bottomAnchor, constant: 2),
            messageRowFileDownloader.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            messageRowFileDownloader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            messageRowImageDownloader.topAnchor.constraint(equalTo: messageRowFileDownloader.bottomAnchor, constant: 2),
            messageRowImageDownloader.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            messageRowImageDownloader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            messageRowVideoDownloader.topAnchor.constraint(equalTo: messageRowImageDownloader.bottomAnchor, constant: 2),
            messageRowVideoDownloader.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            messageRowVideoDownloader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageRowAudioDownloader.topAnchor.constraint(equalTo: messageRowVideoDownloader.bottomAnchor, constant: 2),
            messageRowAudioDownloader.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            messageRowAudioDownloader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            locationRowView.topAnchor.constraint(equalTo: messageRowAudioDownloader.bottomAnchor, constant: 2),
            locationRowView.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            locationRowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            uploadImage.topAnchor.constraint(equalTo: locationRowView.bottomAnchor, constant: 2),
            uploadImage.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            uploadImage.trailingAnchor.constraint(equalTo: contentView.leadingAnchor),
            uploadFile.topAnchor.constraint(equalTo: uploadImage.bottomAnchor, constant: 2),
            uploadFile.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            uploadFile.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageTextView.topAnchor.constraint(equalTo: uploadFile.bottomAnchor, constant: 2),
            messageTextView.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            messageTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            messageTextView.bottomAnchor.constraint(equalTo: reactionView.topAnchor),
            reactionView.bottomAnchor.constraint(equalTo: avatar.topAnchor, constant: -2),
            reactionView.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
            reactionView.heightAnchor.constraint(equalToConstant: 48),
            reactionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            unsentMessageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            unsentMessageView.topAnchor.constraint(equalTo: reactionView.bottomAnchor, constant: 2),
            unsentMessageView.leadingAnchor.constraint(equalTo: groupParticipantNameView.leadingAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        contentView.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        setLeadingWhenIsNotAvatarAndRadio()
        avatar.set(viewModel)
        messageTextView.set(viewModel)
        replyInfoMessageRow.set(viewModel)
        forwardMessageRow.set(viewModel)
        messageRowImageDownloader.set(viewModel)
        groupParticipantNameView.set(viewModel)
        locationRowView.set(viewModel)
        messageRowFileDownloader.set(viewModel)
        messageRowAudioDownloader.set(viewModel)
        messageRowVideoDownloader.set(viewModel)
        unsentMessageView.set(viewModel)
        reactionView.set(viewModel)
        radio.set(viewModel)
        uploadImage.set(viewModel)
        uploadFile.set(viewModel)
    }

    private func setLeadingWhenIsNotAvatarAndRadio() {
        if avatar.isHidden && radio.isHidden {
            groupParticipantNameView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        }
    }

    private func registerGestures() {
        replyInfoMessageRow.isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc func onTap(_ sender: UITapGestureRecognizer? = nil) {
        if viewModel.isInSelectMode == true {
            viewModel.isSelected.toggle()
            radio.set(viewModel)
            backgroundColor = viewModel.isSelected ? Color.App.accentUIColor?.withAlphaComponent(0.2) : UIColor.clear
        }
    }

    override func draw(_ rect: CGRect) {
//        let rect = CGRect(x: 0, y: 0, width: vStack.frame.width, height: vStack.frame.height)
//        let shapeLayer = MessageRowBackground()
//        let color = viewModel.isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
//        shapeLayer.drawPath(color: color.cgColor, rect: rect)
//        vStack.layer.insertSublayer(shapeLayer, at: 0)
    }

    private func setDebugColors() {
        #if DEBUG
        contentView.backgroundColor = .red
        avatar.backgroundColor = .yellow
        radio.backgroundColor = .systemMint
        groupParticipantNameView.backgroundColor = .blue
        replyInfoMessageRow.backgroundColor = .systemPink
        forwardMessageRow.backgroundColor = .orange
        messageRowFileDownloader.backgroundColor = .brown
        messageRowImageDownloader.backgroundColor = .magenta
        messageRowVideoDownloader.backgroundColor = .purple
        messageRowAudioDownloader.backgroundColor = .green
        locationRowView.backgroundColor = .systemTeal
        uploadImage.backgroundColor = .systemTeal
        uploadFile.backgroundColor = .systemTeal
        messageTextView.backgroundColor = .brown
        reactionView.backgroundColor = .blue.withAlphaComponent(0.5)
        unsentMessageView.backgroundColor = .yellow.withAlphaComponent(0.2)
        #endif
    }
}

class MessageTapGestureRecognizer: UITapGestureRecognizer {
    var viewModel: MessageRowViewModel?
}

struct TextMessageTypeCellWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = TextMessageTypeCell()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

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
        let viewModels = MockAppConfiguration.shared.viewModels
//        Preview(viewModel: viewModels.first(where: {$0.isMe})!)
//            .previewDisplayName("IsMe")
//        Preview(viewModel: viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("Reply")
        Preview(viewModel: viewModels.first(where: {$0.message.isImage == true})!)
            .previewDisplayName("ImageDownloader")
//        Preview(viewModel: viewModels.first(where: {$0.message.isFileType == true && !$0.message.isImage})!)
//            .previewDisplayName("FileDownloader")
//        let vm = viewModels.first(where: {$0.message.message != nil && !$0.message.isImage})!
//        _ = vm.threadVM = .init(thread: .init(group: false))
//       return Preview(viewModel: vm)
//            .previewDisplayName("NotGroup-NoAvatar")
//        let viewModelWithNoMwssage = viewModels.first(where: {$0.message.isFileType == true && !$0.message.isImage && $0.message.message == nil})!
//        Preview(viewModel: viewModelWithNoMwssage)
//            .previewDisplayName("FileWithNoMessage")

//        Preview(viewModel: viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("Location")
//        Preview(viewModel: viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("MusicPlayer")
//        Preview(viewModel: viewModels.first(where: {$0.message.forwardInfo != nil })!)
//            .previewDisplayName("Forward")
//        Preview(viewModel: MockAppConfiguration.shared.radioSelectVM)
//            .previewDisplayName("RadioSelect")
//        Preview(viewModel: MockAppConfiguration.shared.avatarVM)
//            .previewDisplayName("AvatarVM")
//        Preview(viewModel: MockAppConfiguration.shared.joinLinkVM)
//            .previewDisplayName("JoinLink")
//        Preview(viewModel: MockAppConfiguration.shared.groupParticipantNameVM)
//            .previewDisplayName("GroupParticipantName")
    }
}
