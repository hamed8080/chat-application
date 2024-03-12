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

final class MessageRowFileDownloaderView: UIView {
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        layer.cornerRadius = 5
        layer.masksToBounds = true

        translatesAutoresizingMaskIntoConstraints = false
        progressButton.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1

        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor

        addSubview(progressButton)
        addSubview(fileNameLabel)
        addSubview(fileTypeLabel)
        addSubview(fileSizeLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 52),
            progressButton.widthAnchor.constraint(equalToConstant: 52),
            progressButton.heightAnchor.constraint(equalToConstant: 52),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            fileNameLabel.topAnchor.constraint(equalTo: progressButton.topAnchor, constant: 8),
            fileNameLabel.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: 8),
            fileTypeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 2),
            fileTypeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: fileTypeLabel.topAnchor),
            fileSizeLabel.leadingAnchor.constraint(equalTo: fileTypeLabel.trailingAnchor, constant: 8),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let metaData = viewModel.fileMetaData
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
        progressButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)

        let message = viewModel.message
        let canShow = !message.isUploadMessage && message.isFileType && !viewModel.isMapType && !message.isImage && !message.isAudio && !message.isVideo
        isHidden = !canShow
        heightAnchor.constraint(equalToConstant: canShow ? 52 : 0 ).isActive = true
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
        print("tapped")
        guard let downloadVM = downloadVM else { return }
        if downloadVM.state == .completed {
            shareFile()
        } else {
            manageDownload()
        }
    }

    private func manageDownload() {
        guard let viewModel = downloadVM else { return }
        if viewModel.state == .paused {
            viewModel.resumeDownload()
        } else if viewModel.state == .downloading {
            viewModel.pauseDownload()
        } else {
            viewModel.startDownload()
        }
    }

    private func shareFile() {
        Task {
            _ = await message?.makeTempURL()
            await MainActor.run {
//                shareDownloadedFile.toggle()
            }
        }
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
            MessageRowFileDownloaderWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.isFileType == true && !$0.message.isImage})!)
            .previewDisplayName("FileDownloader")
    }
}
