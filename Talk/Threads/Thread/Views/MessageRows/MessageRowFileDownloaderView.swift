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

final class MessageRowFileDownloaderView: UIStackView {
    private let vStack = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let progressButton = CircleProgressButton(color: Color.App.textPrimaryUIColor, iconTint: Color.App.textPrimaryUIColor)
    private var viewModel: MessageRowViewModel?
    private var downloadVM: DownloadFileViewModel? { viewModel?.downloadFileVM }
    private var message: Message? { viewModel?.message }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
        progressButton.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 8

        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 4

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle

        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor

        let typeSizeHStack = UIStackView()
        typeSizeHStack.axis = .horizontal
        typeSizeHStack.spacing = 4

        typeSizeHStack.addArrangedSubview(fileTypeLabel)
        typeSizeHStack.addArrangedSubview(fileSizeLabel)

        vStack.addArrangedSubview(fileNameLabel)
        vStack.addArrangedSubview(typeSizeHStack)

        progressButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        progressButton.isUserInteractionEnabled = true

        addArrangedSubview(progressButton)
        addArrangedSubview(vStack)

        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: 52),
            progressButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        semanticContentAttribute = viewModel.calculatedMessage.isMe ? .forceRightToLeft : .forceLeftToRight
        let metaData = viewModel.calculatedMessage.fileMetaData
        let progress = CGFloat(viewModel.downloadFileVM?.downloadPercent ?? 0)
        progressButton.animate(to: progress, systemIconName: stateIcon())
        if progress >= 1 {
            progressButton.removeProgress()
        }

        if let fileSize = metaData?.file?.size?.toSizeString(locale: Language.preferredLocale)  {
            fileSizeLabel.text = fileSize
        }

        if let fileName = metaData?.file?.name {
            fileNameLabel.text = fileName
        }

        let split = metaData?.file?.originalName?.split(separator: ".")
        let ext = metaData?.file?.extension
        let lastSplit = String(split?.last ?? "")
        let extensionName = (ext ?? lastSplit)
        fileTypeLabel.text = extensionName.uppercased()

        let message = viewModel.message
        let canShow = !message.isUploadMessage && message.isFileType && !viewModel.rowType.isMap && !message.isImage && !message.isAudio && !message.isVideo
        isHidden = !canShow
    }

    private func stateIcon() -> String {
        guard let state = downloadVM?.state else { return "arrow.down" }
        if let iconName = message?.iconName, state == .completed {
            return iconName
        } else if state == .downloading {
            return "pause.fill"
        } else if state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    @objc private func onTap() {
        viewModel?.onTap()
    }
}

struct MessageRowFileDownloaderWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = MessageRowFileDownloaderView()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct MessageRowFileDownloader_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            ThreadViewModel.maxAllowedWidth = 340
            self.viewModel = viewModel
        }

        var body: some View {
            MessageRowFileDownloaderWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.isFileType == true && !$0.message.isImage})!)
            .previewDisplayName("FileDownloader")
    }
}
