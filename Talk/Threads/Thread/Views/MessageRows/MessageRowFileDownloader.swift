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

//struct MessageRowFileDownloader: View {
//    let viewModel: MessageRowViewModel
//    private var message: Message { viewModel.message }
//    private var uploadCompleted: Bool { message.uploadFile == nil || viewModel.uploadViewModel?.state == .completed }
//    private var isFileView: Bool { uploadCompleted && message.isFileType && !viewModel.isMapType && !message.isImage && !message.isAudio && !message.isVideo }
//
//    var body: some View {
//        if isFileView, let downloadVM = viewModel.downloadFileVM {
//            MessageRowFileDownloaderContent()
//                .environmentObject(downloadVM)
//                .task {
//                    if downloadVM.isInCache {
//                        downloadVM.state = .completed
//                        viewModel.animateObjectWillChange()
//                    }
//                }
//        }
//    }
//}

struct MessageRowFileDownloaderContent: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    private var message: Message { viewModel.message }
    @State var shareDownloadedFile: Bool = false

    var body: some View {
        HStack {
            FileDownloadButton()
        }
        .environmentObject(downloadVM)
        .sheet(isPresented: $shareDownloadedFile) {
            ActivityViewControllerWrapper(activityItems: [message.tempURL], title: viewModel.fileMetaData?.file?.originalName)
        }
        .onTapGesture {
            if downloadVM.state == .completed {
                shareFile()
            } else {
                manageDownload()
            }
        }
    }

    private func shareFile() {
        Task {
            _ = await message.makeTempURL()
            await MainActor.run {
                shareDownloadedFile.toggle()
            }
        }
    }

    private func manageDownload() {
        if downloadVM.state == .paused {
            downloadVM.resumeDownload()
        } else if downloadVM.state == .downloading {
            downloadVM.pauseDownload()
        } else {
            downloadVM.startDownload()
        }
    }
}

fileprivate struct FileDownloadButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @EnvironmentObject var messageRowVM: MessageRowViewModel
    @Environment(\.colorScheme) var scheme
    private var message: Message? { viewModel.message }
    private var percent: Int64 { viewModel.downloadPercent }
    private var stateIcon: String {
        if let iconName = message?.iconName, viewModel.state == .completed {
            return iconName
        } else if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                iconView
                progress
            }
            .frame(width: 46, height: 46)
            .background(scheme == .light ? Color.App.accent : Color.App.white)
            .clipShape(RoundedRectangle(cornerRadius:(46 / 2)))

            VStack(alignment: .leading, spacing: 4) {
                fileNameView
                HStack {
                    fileTypeView
                    fileSizeView
                }
            }
        }
        .padding(4)
    }

    @ViewBuilder private var iconView: some View {
        Image(systemName: stateIcon.replacingOccurrences(of: ".circle", with: ""))
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.black)
            .fontWeight(.medium)
    }

    @ViewBuilder private var progress: some View {
        if viewModel.state == .downloading {
            Circle()
                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.App.accent)
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 42, height: 42)
                .environment(\.layoutDirection, .leftToRight)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder private var fileNameView: some View {
        if let fileName = messageRowVM.fileName {
            Text(fileName)
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldCaption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder private var fileTypeView: some View {
        if let extName = messageRowVM.extName {
            Text(extName)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }

    @ViewBuilder private var fileSizeView: some View {
        if let fileZize = messageRowVM.computedFileSize {
            Text(fileZize)
                .multilineTextAlignment(.leading)
                .font(.iransansCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }
}

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
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
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
        innerhStack.addArrangedSubview(fileTypeLabel)
        innerhStack.addArrangedSubview(fileSizeLabel)

        vStack.spacing = 4
        vStack.addArrangedSubview(fileNameLabel)
        vStack.addArrangedSubview(innerhStack)

        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.addArrangedSubview(progressView)
        container.addSubview(hStack)
        addSubview(container)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = Color.App.bgPrimaryUIColor

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        hStack.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            hStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            hStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 42),
            progressView.heightAnchor.constraint(equalToConstant: 42),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let message = viewModel.message
        let progress = CGFloat(viewModel.downloadFileVM?.downloadPercent ?? 0)
        progressView.animate(to: progress, systemIconName: stateIcon(viewModel: viewModel))
        if progress >= 1 {
            progressView.removeProgress()
        }

        if let fileSize = viewModel.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale)  {
            fileSizeLabel.text = fileSize
        }

        if let fileName = message.fileMetaData?.file?.name {
            fileNameLabel.text = fileName
        }

        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let config = UIImage.SymbolConfiguration(font: font)
        iconImageView.image = UIImage(systemName: stateIcon(viewModel: viewModel).replacingOccurrences(of: ".circle", with: ""), withConfiguration: config)

        let split = viewModel.fileMetaData?.file?.originalName?.split(separator: ".")
        let ext = viewModel.fileMetaData?.file?.extension
        let lastSplit = String(split?.last ?? "")
        let extensionName = (ext ?? lastSplit)
        fileTypeLabel.text = extensionName
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

    private func manageDownload(downloadVM: DownloadFileViewModel) {
        if downloadVM.state == .paused {
            downloadVM.resumeDownload()
        } else if downloadVM.state == .downloading {
            downloadVM.pauseDownload()
        } else {
            downloadVM.startDownload()
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
    static var previews: some View {
        MessageRowFileDownloaderWapper(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
