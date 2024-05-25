//
//  UploadMessageImageView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import CoreMedia
import SwiftUI
import TalkViewModels
import ChatModels
import ChatCore
import TalkModels
import ChatDTO
import TalkUI

final class UploadMessageImageView: UIView {
    private let container = UIView()
    private let stack = UIStackView()
    private let fileSizeLabel = UILabel()
    private let uploadImage = UIImageView()
    private let progressView = CircleProgressButton(color: Color.App.whiteUIColor, iconTint: Color.App.whiteUIColor)
    private var heightConstraint:NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true

        translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadImage.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false

        uploadImage.layer.cornerRadius = 8
        uploadImage.layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = uploadImage.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.translatesAutoresizingMaskIntoConstraints = false
        uploadImage.addSubview(blurView)
        container.addSubview(uploadImage)

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

        stack.axis = .horizontal
        stack.spacing = 12
        stack.addArrangedSubview(progressView)
        stack.addArrangedSubview(fileSizeLabel)
        stack.backgroundColor = .white.withAlphaComponent(0.2)
        stack.layoutMargins = .init(horizontal: 6, vertical: 6)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layer.cornerRadius = 30
        container.addSubview(stack)
        addSubview(container)

        heightConstraint = heightAnchor.constraint(equalToConstant: 128)

        NSLayoutConstraint.activate([
            heightConstraint!,
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            uploadImage.widthAnchor.constraint(equalToConstant: 128),
            uploadImage.heightAnchor.constraint(equalToConstant: 128),
            blurView.widthAnchor.constraint(equalTo: uploadImage.widthAnchor),
            blurView.heightAnchor.constraint(equalTo: uploadImage.heightAnchor),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 48),
            progressView.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let message = viewModel.message
        if let data = message.uploadFile?.uploadImageRequest?.dataToSend, let image = UIImage(data: data) {
            uploadImage.image = image
        }
        let progress = CGFloat(viewModel.uploadViewModel?.uploadPercent ?? 0)
        progressView.animate(to: progress, systemIconName: stateIcon(viewModel: viewModel))
        if progress >= 1 {
            progressView.removeProgress()
        }

        let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
        let realServerFileSize = viewModel.calculatedMessage.fileMetaData?.file?.size
        if let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale) {
            fileSizeLabel.text = fileSize
        }

        let canShow = message.isUploadMessage && message.isImage
        isHidden = !canShow
        heightConstraint?.constant = canShow ? 128 : 0
    }

    private func stateIcon(viewModel: MessageRowViewModel) -> String {
        guard let viewModel = viewModel.uploadViewModel else { return "" }
        if viewModel.state == .uploading {
            return "xmark"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.up"
        }
    }
}

struct UploadMessageImageViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = UploadMessageImageView()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct UploadMessageImageView_Previews: PreviewProvider {
    static var previews: some View {
        let message = UploadFileWithTextMessage(uploadFileRequest: UploadFileRequest(data: Data()), thread: MockData.thread)
        let messageViewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        let uploadFileVM = UploadFileViewModel(message: message)
        UploadMessageImageViewWapper(viewModel: messageViewModel)
            .environmentObject(uploadFileVM)
            .background(Color.black.ignoresSafeArea())
            .onAppear {
                uploadFileVM.startUploadFile()
            }
    }
}
