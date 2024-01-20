//
//  MessageRowAudioDownloader.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

final class MessageRowFileDownloader: UIView {
    private let container = UIView()
    private let hStack = UIStackView()
    private let vStack = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let iconImageView = UIImageView()
    private let progressView = CircleProgressView(color: Color.App.textPrimaryUIColor, iconTint: Color.App.bgPrimaryUIColor)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        hStack.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        layoutMargins = UIEdgeInsets(all: 8)
        layer.cornerRadius = 5
        layer.masksToBounds = true

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor

        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor

        let innerhStack = UIStackView()
        innerhStack.axis = .horizontal
        innerhStack.spacing = 4
        innerhStack.addArrangedSubview(fileTypeLabel)
        innerhStack.addArrangedSubview(fileSizeLabel)

        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.addArrangedSubview(fileNameLabel)
        vStack.addArrangedSubview(innerhStack)

        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.addArrangedSubview(progressView)
        hStack.addArrangedSubview(vStack)
        container.addSubview(hStack)
        addSubview(container)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = Color.App.bgPrimaryUIColor

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStack.topAnchor.constraint(equalTo: container.topAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 52),
            progressView.heightAnchor.constraint(equalToConstant: 52),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let metaData = viewModel.fileMetaData
        let progress = CGFloat(viewModel.downloadFileVM?.downloadPercent ?? 0)
        progressView.animate(to: progress, systemIconName: stateIcon(viewModel: viewModel))
        if progress >= 1 {
            progressView.removeProgress()
        }

        if let fileSize = metaData?.file?.size?.toSizeString(locale: Language.preferredLocale)  {
            fileSizeLabel.text = fileSize
        }

        if let fileName = metaData?.file?.name {
            fileNameLabel.text = fileName
        }

        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let config = UIImage.SymbolConfiguration(font: font)
        let icon = stateIcon(viewModel: viewModel).replacingOccurrences(of: ".circle", with: "")
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)

        let split = metaData?.file?.originalName?.split(separator: ".")
        let ext = metaData?.file?.extension
        let lastSplit = String(split?.last ?? "")
        let extensionName = (ext ?? lastSplit)
        fileTypeLabel.text = extensionName.uppercased()
        
        let tap = MessageTapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        vStack.isUserInteractionEnabled = true
        vStack.addGestureRecognizer(tap)
    }

    private func stateIcon(viewModel: MessageRowViewModel) -> String {
        let message = viewModel.message
        guard let downloadVM = viewModel.downloadFileVM else { return "" }
        if let iconName = message.iconName, downloadVM.state == .completed {
            return iconName
        } else if downloadVM.state == .downloading {
            return "pause.fill"
        } else if downloadVM.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    @objc func onTap(_ sender: MessageTapGestureRecognizer) {
        guard let viewModel = sender.viewModel?.downloadFileVM else { return }
        if viewModel.state == .paused {
            viewModel.resumeDownload()
        } else if viewModel.state == .downloading {
            viewModel.pauseDownload()
        } else {
            viewModel.startDownload()
        }
    }

    private func shareFile() {
//        Task {
//            _ = await message.makeTempURL()
//            await MainActor.run {
//                shareDownloadedFile.toggle()
//            }
//        }
    }
}

struct MessageRowFileDownloaderWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = MessageRowFileDownloader()
        view.setValues(viewModel: viewModel)
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
