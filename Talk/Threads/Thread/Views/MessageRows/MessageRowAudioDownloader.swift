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

//struct MessageRowAudioDownloader: View {
//    let viewModel: MessageRowViewModel
//    private var message: Message { viewModel.message }
//    private var uploadCompleted: Bool { message.uploadFile == nil || viewModel.uploadViewModel?.state == .completed }
//    @EnvironmentObject var audioVM: AVAudioPlayerViewModel
//
//    var body: some View {
//        if uploadCompleted, message.isAudio == true, let downloadVM = viewModel.downloadFileVM {
//            AudioDownloadButton()
//                .environmentObject(viewModel)
//                .environmentObject(downloadVM)
//                .onTapGesture {
//                    onTap()
//                }
//                .task {
//                    if downloadVM.isInCache {
//                        downloadVM.state = .completed
//                        viewModel.animateObjectWillChange()
//                    }
//                }
//        }
//    }
//
//    private func onTap() {
//        if viewModel.downloadFileVM?.state == .completed {
//            togglePlaying()
//        } else {
//            manageDownload()
//        }
//    }
//
//    private func togglePlaying() {
//        if let fileURL = viewModel.downloadFileVM?.fileURL {
//            try? audioVM.setup(message: message,
//                               fileURL: fileURL,
//                               ext: viewModel.fileMetaData?.file?.mimeType?.ext,
//                               title: viewModel.fileMetaData?.file?.originalName ?? viewModel.fileMetaData?.name ?? "",
//                               subtitle: viewModel.fileMetaData?.file?.originalName ?? "")
//            audioVM.toggle()
//        }
//    }
//
//    private func manageDownload() {
//        if let downloadVM = viewModel.downloadFileVM {
//            if downloadVM.state == .paused {
//                downloadVM.resumeDownload()
//            } else if downloadVM.state == .downloading {
//                downloadVM.pauseDownload()
//            } else {
//                downloadVM.startDownload()
//            }
//        }
//    }
//}
//
//fileprivate struct AudioDownloadButton: View {
//    @EnvironmentObject var viewModel: DownloadFileViewModel
//    @EnvironmentObject var messageRowVM: MessageRowViewModel
//    @EnvironmentObject var audioVM: AVAudioPlayerViewModel
//    private var message: Message? { viewModel.message }
//    private var percent: Int64 { viewModel.downloadPercent }
//    private var isSameFile: Bool { audioVM.fileURL?.absoluteString == viewModel.fileURL?.absoluteString }
//    private var stateIcon: String {
//        if viewModel.state == .completed {
//            if audioVM.isPlaying {
//                return "pause.fill"
//            } else {
//                return "play.fill"
//            }
//        } else if viewModel.state == .downloading {
//            return "pause.fill"
//        } else if viewModel.state == .paused {
//            return "play.fill"
//        } else {
//            return "arrow.down"
//        }
//    }
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 8) {
//            ZStack {
//                iconView
//                progress
//            }
//            .frame(width: 46, height: 46)
//            .background(Color.App.btnDownload)
//            .clipShape(RoundedRectangle(cornerRadius:(46 / 2)))
//
//            VStack(alignment: .leading, spacing: 4) {
//                fileNameView
//                audioProgress
//                HStack {
//                    fileTypeView
//                    fileSizeView
//                }
//            }
//        }
//        .padding(4)
//    }
//
//    @ViewBuilder private var iconView: some View {
//        Image(systemName: stateIcon.replacingOccurrences(of: ".circle", with: ""))
//            .resizable()
//            .scaledToFit()
//            .frame(width: 16, height: 16)
//            .foregroundStyle(Color.App.bgPrimary)
//            .fontWeight(.medium)
//    }
//
//    @ViewBuilder private var progress: some View {
//        if viewModel.state == .downloading {
//            Circle()
//                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
//                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
//                .foregroundColor(Color.App.primary)
//                .rotationEffect(Angle(degrees: 270))
//                .frame(width: 42, height: 42)
//                .environment(\.layoutDirection, .leftToRight)
//                .fontWeight(.semibold)
//        }
//    }
//
//    @ViewBuilder private var fileNameView: some View {
//        if let fileName = message?.fileMetaData?.file?.name ?? message?.uploadFileName {
//            Text(fileName)
//                .foregroundStyle(Color.App.text)
//                .font(.iransansBoldCaption)
//        }
//    }
//
//    @ViewBuilder private var fileTypeView: some View {
//        let split = messageRowVM.fileMetaData?.file?.originalName?.split(separator: ".")
//        let ext = messageRowVM.fileMetaData?.file?.extension
//        let lastSplit = String(split?.last ?? "")
//        let extensionName = (ext ?? lastSplit)
//        if !extensionName.isEmpty {
//            Text(extensionName.uppercased())
//                .multilineTextAlignment(.leading)
//                .font(.iransansBoldCaption3)
//                .foregroundColor(Color.App.hint)
//        }
//    }
//
//    @ViewBuilder private var fileSizeView: some View {
//        if let fileZize = messageRowVM.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) {
//            Text(fileZize.replacingOccurrences(of: "٫", with: "."))
//                .multilineTextAlignment(.leading)
//                .font(.iransansCaption3)
//                .foregroundColor(Color.App.hint)
//        }
//    }
//
//    @ViewBuilder private var audioProgress: some View {
//        if message?.isAudio == true, viewModel.state == .completed, isSameFile {
//            VStack(alignment: .leading, spacing: 4) {
//                ProgressView(value: min(audioVM.currentTime / audioVM.duration, 1.0), total: 1.0)
//                    .progressViewStyle(.linear)
//                    .tint(Color.App.text)
//                    .frame(maxWidth: 172)
//                Text("\(audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? "") / \(audioVM.duration.timerString(locale: Language.preferredLocale) ?? "")")
//                    .foregroundColor(Color.App.white)
//            }
//        }
//    }
//}

final class MessageRowAudioDownloader: UIView {
    private let container = UIView()
    private let hStack = UIStackView()
    private let vStack = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let iconImageView = UIImageView()
    private let progressView = CircleProgressView(color: Color.App.uiprimary, iconTint: Color.App.uibgPrimary)
    private let timeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.uibgInput?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.uitext

        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.uitext

        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.uihint

        timeLabel.textColor = Color.App.uiwhite
        timeLabel.font = UIFont.uiiransansBoldCaption2

        let innerhStack = UIStackView()
        innerhStack.axis = .horizontal
        innerhStack.addArrangedSubview(fileTypeLabel)
        innerhStack.addArrangedSubview(fileSizeLabel)

        //    @ViewBuilder private var audioProgress: some View {
        //        if message?.isAudio == true, viewModel.state == .completed, isSameFile {
        //            VStack(alignment: .leading, spacing: 4) {
        //                ProgressView(value: min(audioVM.currentTime / audioVM.duration, 1.0), total: 1.0)
        //                    .progressViewStyle(.linear)
        //                    .tint(Color.App.text)
        //                    .frame(maxWidth: 172)
        //                Text("\(audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? "") / \(audioVM.duration.timerString(locale: Language.preferredLocale) ?? "")")
        //                    .foregroundColor(Color.App.white)
        //            }
        //        }
        //    }

        vStack.spacing = 4
        vStack.addArrangedSubview(fileNameLabel)
        vStack.addArrangedSubview(innerhStack)
        vStack.addArrangedSubview(timeLabel)

        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.addArrangedSubview(progressView)
        container.addSubview(hStack)
        addSubview(container)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = Color.App.uibgPrimary

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


        let audioVM = AppState.shared.objectsContainer.audioPlayerVM
        let time = "\(audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? "") / \(audioVM.duration.timerString(locale: Language.preferredLocale) ?? "")"
        timeLabel.text = time
    }

    private func stateIcon(viewModel: MessageRowViewModel) -> String {
        guard let downloadVM = viewModel.downloadFileVM else { return "" }
        if downloadVM.state == .completed {
            if AppState.shared.objectsContainer.audioPlayerVM.isPlaying {
                return "pause.fill"
            } else {
                return "play.fill"
            }
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

    private func togglePlaying(viewModel: MessageRowViewModel) {
        if let fileURL = viewModel.downloadFileVM?.fileURL {
            try? AppState.shared.objectsContainer.audioPlayerVM.setup(message: viewModel.message,
                               fileURL: fileURL,
                               ext: viewModel.fileMetaData?.file?.mimeType?.ext,
                               title: viewModel.fileMetaData?.file?.originalName ?? viewModel.fileMetaData?.name ?? "",
                               subtitle: viewModel.fileMetaData?.file?.originalName ?? "")
            AppState.shared.objectsContainer.audioPlayerVM.toggle()
        }
    }
}

struct MessageRowAudioDownloaderWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = MessageRowAudioDownloader()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct MessageRowAudioDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowAudioDownloaderWapper(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
