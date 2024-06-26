//
//  MessageRowAudioDownloaderView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

final class MessageFileView: UIStackView {
    private let vStack = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.textPrimaryUIColor,
                                                      bgColor: Color.App.accentUIColor,
                                                      margin: 2
    )
    private weak var viewModel: MessageRowViewModel?
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = .init(top: 8, left: 8, bottom: 0, right: 0)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        isLayoutMarginsRelativeArrangement = true
        axis = .horizontal
        spacing = 8

        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        progressButton.isUserInteractionEnabled = true
        progressButton.accessibilityIdentifier = "progressButtonMessageFileView"
        addArrangedSubview(progressButton)

        let typeSizeHStack = UIStackView()
        typeSizeHStack.translatesAutoresizingMaskIntoConstraints = false
        typeSizeHStack.axis = .horizontal
        typeSizeHStack.spacing = 4
        typeSizeHStack.accessibilityIdentifier = "typeSizeHStackMessageFileView"

        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor
        fileTypeLabel.accessibilityIdentifier = "fileTypeLabelMessageFileView"
        typeSizeHStack.addArrangedSubview(fileTypeLabel)

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageFileView"
        typeSizeHStack.addArrangedSubview(fileSizeLabel)

        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 4
        vStack.accessibilityIdentifier = "vStackMessageFileView"

        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.accessibilityIdentifier = "fileNameLabelMessageFileView"

        vStack.addArrangedSubview(fileNameLabel)
        vStack.addArrangedSubview(typeSizeHStack)
        addArrangedSubview(vStack)

        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: 36),
            progressButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isFile {
            reset()
            return
        }
        setIsHidden(false)
        self.viewModel = viewModel
        setSemanticContent(viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight)
        updateProgress(viewModel: viewModel)
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileTypeLabel.text = viewModel.calMessage.extName
    }

    @objc private func onTap() {
        viewModel?.onTap()
    }
    
    func reset() {
        setIsHidden(true)
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.fileState.progress
        progressButton.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        progressButton.setProgressVisibility(visible: canShowProgress)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        updateProgress(viewModel: viewModel)
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        updateProgress(viewModel: viewModel)
    }

    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }
}
