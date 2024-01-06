//
//  MessageRowImageDownloader.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import Chat

//struct MessageRowImageDownloader: View {
//    @EnvironmentObject var viewModel: MessageRowViewModel
//    private var message: Message { viewModel.message }
//
//    var body: some View {
//        if viewModel.canShowImageView {
//            ZStack {
//                Image(uiImage: viewModel.image)
//                    .resizable()
//                    .frame(maxWidth: viewModel.imageWidth, maxHeight: viewModel.imageHeight)
//                    .aspectRatio(contentMode: viewModel.imageScale)
//                    .clipped()
//                    .zIndex(0)
//                    .background(gradient)
//                    .blur(radius: viewModel.bulrRadius, opaque: false)
//                    .clipShape(RoundedRectangle(cornerRadius:(8)))
//                if let downloadVM = viewModel.downloadFileVM, downloadVM.state != .completed {
//                    OverlayDownloadImageButton(message: message)
//                        .environmentObject(downloadVM)
//                }
//            }
//            .onTapGesture {
//                viewModel.onTap()
//            }
//            .clipped()
//        }
//    }
//
//    private static let clearGradient = LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
//    private static let emptyImageGradient = LinearGradient(colors: [Color.App.bgInput, Color.App.bgInputDark], startPoint: .top, endPoint: .bottom)
//
//    private var gradient: LinearGradient {
//        let clearState = viewModel.downloadFileVM?.state == .completed || viewModel.downloadFileVM?.state == .thumbnail
//        return clearState ? MessageRowImageDownloader.clearGradient : MessageRowImageDownloader.emptyImageGradient
//    }
//}
//
//struct OverlayDownloadImageButton: View {
//    @EnvironmentObject var viewModel: DownloadFileViewModel
//    @EnvironmentObject var messageRowVM: MessageRowViewModel
//    let message: Message?
//    private var percent: Int64 { viewModel.downloadPercent }
//    private var stateIcon: String {
//        if viewModel.state == .downloading {
//            return "pause.fill"
//        } else if viewModel.state == .paused {
//            return "play.fill"
//        } else {
//            return "arrow.down"
//        }
//    }
//
//    var body: some View {
//        if viewModel.state != .completed {
//            HStack {
//                ZStack {
//                    iconView
//                    progress
//                }
//                .frame(width: 26, height: 26)
//                .background(Color.App.white.opacity(0.3))
//                .clipShape(RoundedRectangle(cornerRadius:(13)))
//                sizeView
//            }
//            .frame(height: 30)
//            .frame(minWidth: 76)
//            .padding(4)
//            .background(.thinMaterial)
//            .clipShape(RoundedRectangle(cornerRadius:(18)))
//            .animation(.easeInOut, value: stateIcon)
//            .animation(.easeInOut, value: percent)
//            .onTapGesture {
//                if viewModel.state == .paused {
//                    viewModel.resumeDownload()
//                } else if viewModel.state == .downloading {
//                    viewModel.pauseDownload()
//                } else {
//                    viewModel.startDownload()
//                }
//            }
//        }
//    }
//
//    private var iconView: some View {
//        Image(systemName: stateIcon)
//            .resizable()
//            .scaledToFit()
//            .font(.system(size: 8, design: .rounded).bold())
//            .frame(width: 8, height: 8)
//            .foregroundStyle(Color.App.text)
//    }
//
//    private var progress: some View {
//        Circle()
//            .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
//            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
//            .foregroundColor(Color.App.white)
//            .rotationEffect(Angle(degrees: 270))
//            .frame(width: 18, height: 18)
//    }
//
//    @ViewBuilder private var sizeView: some View {
//        if let fileSize = computedFileSize {
//            Text(fileSize)
//                .multilineTextAlignment(.leading)
//                .font(.iransansBoldCaption2)
//                .foregroundColor(Color.App.text)
//        }
//    }
//
//    private var computedFileSize: String? {
//        let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
//        let realServerFileSize = messageRowVM.fileMetaData?.file?.size
//        let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale)
//        return fileSize
//    }
//}

final class MessageRowImageDownloader: UIView {
    private let container = UIView()
    private let stack = UIStackView()
    private let fileSizeLabel = UILabel()
    private let imageView = UIImageView()
    private let progressView = CircleProgressView(color: Color.App.uiwhite, iconTint: Color.App.uiwhite)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.uibgInput?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true

        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = imageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.addSubview(blurView)
        container.addSubview(imageView)

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.uitext

        stack.axis = .horizontal
        stack.spacing = 12
        stack.addArrangedSubview(progressView)
        stack.addArrangedSubview(fileSizeLabel)
        stack.backgroundColor = .white.withAlphaComponent(0.2)
        stack.layoutMargins = .init(horizontal: 6, vertical: 6)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layer.cornerRadius = 20
        container.addSubview(stack)
        addSubview(container)

        NSLayoutConstraint.activate([            
            heightAnchor.constraint(equalToConstant: 128),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 128),
            imageView.heightAnchor.constraint(equalToConstant: 128),
            blurView.widthAnchor.constraint(equalTo: imageView.widthAnchor),
            blurView.heightAnchor.constraint(equalTo: imageView.heightAnchor),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 36),
            progressView.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        imageView.image = viewModel.image
        let progress = CGFloat(viewModel.downloadFileVM?.downloadPercent ?? 0)
        progressView.animate(to: progress, systemIconName: stateIcon(viewModel: viewModel))
        if progress >= 1 {
            progressView.removeProgress()
        }

        if let fileSize = computedFileSize(viewModel: viewModel) {
            fileSizeLabel.text = fileSize
        }
    }

    private func stateIcon(viewModel: MessageRowViewModel) -> String {
        guard let viewModel = viewModel.downloadFileVM else { return "" }
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    private func computedFileSize(viewModel: MessageRowViewModel) -> String? {
        let message = viewModel.message
        let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
        let realServerFileSize = viewModel.fileMetaData?.file?.size
        let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale)
        return fileSize
    }
}

struct MessageRowImageDownloaderWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = MessageRowImageDownloader()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct MessageRowImageDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageDownloaderWapper(viewModel: .init(message: .init(), viewModel: .init(thread: .init())))
    }
}
