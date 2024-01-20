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
    private let hStack = UIStackView()
    private let vStack = UIStackView()
    public var viewModel: MessageRowViewModel! {
        didSet {
            setupObservers()
        }
    }
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
    private let unsentMessageView = UnsentMessageView()
    private var cancellable = Set<AnyCancellable>()

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
        backgroundColor = .green
        registerGestures()

        hStack.axis = .horizontal
        hStack.alignment = .bottom
        hStack.distribution = .fill
        hStack.backgroundColor = .blue
        hStack.spacing = 4
        hStack.layoutMargins = .init(all: 8)
        hStack.isLayoutMarginsRelativeArrangement = true

        hStack.translatesAutoresizingMaskIntoConstraints = false
        avatar.translatesAutoresizingMaskIntoConstraints = false
        radio.translatesAutoresizingMaskIntoConstraints = false
        vStack.translatesAutoresizingMaskIntoConstraints = false

        vStack.axis = .vertical
        vStack.spacing = 10
        vStack.distribution = .fill
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.addArrangedSubviews([
            groupParticipantNameView,
            messageRowFileDownloader,
            messageRowImageDownloader,
            messageRowVideoDownloader,
            messageRowAudioDownloader,
            locationRowView,
            replyInfoMessageRow,
            forwardMessageRow,
            uploadImage,
            uploadFile,
            messageTextView,
            unsentMessageView
        ])

        hStack.addArrangedSubview(avatar)
        hStack.addArrangedSubview(radio)
        hStack.addArrangedSubview(vStack)
        addSubview(hStack)
        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),
            vStack.trailingAnchor.constraint(equalTo: hStack.trailingAnchor),
//            vStack.topAnchor.constraint(equalTo: hStack.topAnchor),
            vStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 128),
            vStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),

            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            hStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 128),
        ])
    }

    private func resetViews() {
        let message = viewModel.message
        contentView.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        messageRowFileDownloader.isHidden = false
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
        unsentMessageView.setValues(viewModel: viewModel)
        radio.setValues(viewModel: viewModel)
        vStack.layoutMargins = viewModel.paddingEdgeInset
        hStack.widthAnchor.constraint(lessThanOrEqualToConstant: viewModel.imageWidth ?? ThreadViewModel.maxAllowedWidth).isActive = true
    }

    private func registerGestures() {
        replyInfoMessageRow.isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)
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
        return !viewModel.message.messageTitle.isEmpty
    }

    private var showAvatar: Bool {
        return !viewModel.isMe && !viewModel.isNextMessageTheSameUser && viewModel.threadVM?.thread.group == true
    }

    private var showRadio: Bool {
        return viewModel.isInSelectMode
    }

    @objc func onTap(_ sender: UITapGestureRecognizer? = nil) {
        if viewModel.isInSelectMode == true {
            viewModel.isSelected.toggle()
            radio.setValues(viewModel: viewModel)
            backgroundColor = viewModel.isSelected ? Color.App.accentUIColor?.withAlphaComponent(0.2) : UIColor.clear
        }
    }

    override func draw(_ rect: CGRect) {
        let rect = CGRect(x: 0, y: 0, width: vStack.frame.width, height: vStack.frame.height)
        let shapeLayer = MessageRowBackground()
        let color = viewModel.isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        shapeLayer.drawPath(color: color.cgColor, rect: rect)
        vStack.layer.insertSublayer(shapeLayer, at: 0)
    }
}

class MessageTapGestureRecognizer: UITapGestureRecognizer {
    var viewModel: MessageRowViewModel?
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
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let isSelected = viewModel.isSelected
        let iconColor = (isSelected ? Color.App.whiteUIColor : UIColor.gray) ?? .clear
        let fillColor = (isSelected ? Color.App.accentUIColor : UIColor.clear) ?? .clear
        let config = UIImage.SymbolConfiguration(paletteColors: [iconColor, fillColor])
        imageView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle", withConfiguration: config)
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
//        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.isMe})!)
//            .previewDisplayName("IsMe")
//        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("Reply")
//        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.isImage == true})!)
//            .previewDisplayName("ImageDownloader")
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.isFileType == true && !$0.message.isImage})!)
            .previewDisplayName("FileDownloader")
//        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("Location")
//        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("MusicPlayer")
//        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.forwardInfo != nil })!)
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
