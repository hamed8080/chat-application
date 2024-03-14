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

final class TextMessageContainer: UIStackView {
    private var viewModel: MessageRowViewModel!
    private let messageRowFileDownloader = MessageRowFileDownloaderView()
    private let messageRowImageDownloader = MessageRowImageDownloaderView(frame: .zero)
    private let messageRowVideoDownloader = MessageRowVideoDownloaderView()
    private let messageRowAudioDownloader = MessageRowAudioDownloaderView()
    private let locationRowView = LocationRowView(frame: .zero)
    private let groupParticipantNameView = GroupParticipantNameView()
    private let replyInfoMessageRow = ReplyInfoMessageRow()
    private let forwardMessageRow = ForwardMessageRow()
    private let uploadImage = UploadMessageImageView()
    private let uploadFile = UploadMessageFileView()
    private let messageTextView = MessageTextView()
    private let reactionView = ReactionCountView()
    private let fotterView = MessageFooterView()
    private let unsentMessageView = UnsentMessageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView() {
        axis = .vertical
        spacing = 0
        alignment = .leading
        distribution = .fill
        registerGestures()

        addArrangedSubview(groupParticipantNameView)
        addArrangedSubview(replyInfoMessageRow)
        addArrangedSubview(forwardMessageRow)
        addArrangedSubview(messageRowFileDownloader)
        addArrangedSubview(messageRowImageDownloader)
        addArrangedSubview(messageRowVideoDownloader)
        addArrangedSubview(messageRowAudioDownloader)
        addArrangedSubview(locationRowView)
//        addArrangedSubview(uploadImage)
//        addArrangedSubview(uploadFile)
        addArrangedSubview(messageTextView)
        addArrangedSubview(reactionView)
        addArrangedSubview(fotterView)
//        addArrangedSubview(unsentMessageView)
    }

    private func setVerticalSpacings(viewModel: MessageRowViewModel) {
//        let message = viewModel.message
//        let isReply = viewModel.message.replyInfo != nil
//        let isForward = viewModel.message.forwardInfo != nil
//        let isFile = message.isUploadMessage && !message.isImage && message.isFileType
//        let isImage = viewModel.canShowImageView
//        let isVideo = !message.isUploadMessage && message.isVideo == true
//        let isAudio = !message.isUploadMessage && message.isAudio == true
//        let isLocation = viewModel.isMapType
//        let isUploadImage = message.isUploadMessage && message.isImage
//        let isUploadFile = !message.isUploadMessage && message.isFileType && !viewModel.isMapType && !message.isImage && !message.isAudio && !message.isVideo
//        let isTextEmpty = message.messageTitle.isEmpty
//        let isUnsent = viewModel.message.isUnsentMessage
//        let hasReaction = viewModel.reactionsVM.reactionCountList.count > 0
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        setVerticalSpacings(viewModel: viewModel)
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
        uploadImage.set(viewModel)
        uploadFile.set(viewModel)
        fotterView.set(viewModel)
        setDebugColors()
    }

    private func registerGestures() {
        replyInfoMessageRow.isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc func onTap(_ sender: UITapGestureRecognizer? = nil) {
        if viewModel.isInSelectMode == true {
//            viewModel.isSelected.toggle()
//            radio.set(viewModel)
//            backgroundColor = viewModel.isSelected ? Color.App.accentUIColor?.withAlphaComponent(0.2) : UIColor.clear
        }
    }

    private func setDebugColors() {
#if DEBUG
        groupParticipantNameView.backgroundColor = .blue
        replyInfoMessageRow.backgroundColor = .systemPink
        forwardMessageRow.backgroundColor = .orange
        messageRowFileDownloader.backgroundColor = .brown
        messageRowImageDownloader.backgroundColor = .magenta
        messageRowVideoDownloader.backgroundColor = .purple
        messageRowAudioDownloader.backgroundColor = .green
        uploadImage.backgroundColor = .opaqueSeparator
        uploadFile.backgroundColor = .systemTeal
        messageTextView.backgroundColor = viewModel.isMe ? .green : .brown
        reactionView.backgroundColor = .blue.withAlphaComponent(0.5)
        fotterView.backgroundColor = .cyan
        locationRowView.backgroundColor = .magenta
        unsentMessageView.backgroundColor = .yellow.withAlphaComponent(0.2)
#endif
    }
}

final class TextMessageTypeCell: UITableViewCell {
    private var viewModel: MessageRowViewModel! {
        didSet {
            setupObservers()
        }
    }
    private let hStack = UIStackView()
    private let avatar = AvatarView()
    private let radio = SelectMessageRadio()
    private let messageContainer = TextMessageContainer()

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
        contentView.isUserInteractionEnabled = true
        hStack.translatesAutoresizingMaskIntoConstraints = false

        hStack.axis = .horizontal
        hStack.alignment = .bottom
        hStack.spacing = 8
        hStack.distribution = .fill

        hStack.addArrangedSubview(radio)
        hStack.addArrangedSubview(avatar)
        hStack.addArrangedSubview(messageContainer)

        contentView.addSubview(hStack)

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        contentView.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        messageContainer.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        avatar.set(viewModel)
        messageContainer.set(viewModel)
        radio.set(viewModel)
        setDebugColors()
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
        hStack.backgroundColor = .black
        avatar.backgroundColor = .yellow
        radio.backgroundColor = .systemMint
        messageContainer.backgroundColor = .lightGray
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
        Preview(viewModel: viewModels.first(where: {$0.message.replyInfo != nil })!)
            .previewDisplayName("Reply")
//        Preview(viewModel: viewModels.first(where: {$0.message.isImage == true})!)
//            .previewDisplayName("ImageDownloader")
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
