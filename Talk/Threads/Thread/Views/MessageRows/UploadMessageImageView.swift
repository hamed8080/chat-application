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

//public struct UploadMessageImageView: View {
//    let viewModel: MessageRowViewModel
//    var message: Message { viewModel.message }
//
//    public var body: some View {
//        ZStack {
//            if let data = message.uploadFile?.uploadImageRequest?.dataToSend, let image = UIImage(data: data) {
//                /// We use max to at least have a width, because there are times that maxWidth is nil.
//                let width = max(128, (ThreadViewModel.maxAllowedWidth)) - (8 + MessageRowBackground.tailSize.width)
//                /// We use max to at least have a width, because there are times that maxWidth is nil.
//                /// We use min to prevent the image gets bigger than 320 if it's bigger.
//                let height = min(320, max(128, (ThreadViewModel.maxAllowedWidth)))
//                
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: width, height: height)
//                    .blur(radius: 16, opaque: false)
//                    .clipped()
//                    .zIndex(0)
//                    .clipShape(RoundedRectangle(cornerRadius:(8)))
//            }
//            OverladUploadImageButton(messageRowVM: viewModel)
//                .environmentObject(viewModel.uploadViewModel!)
//        }
//        .onTapGesture {
//            if viewModel.uploadViewModel?.state == .paused {
//                viewModel.uploadViewModel?.resumeUpload()
//            } else if viewModel.uploadViewModel?.state == .uploading {
//                viewModel.uploadViewModel?.cancelUpload()
//            }
//        }
//        .task {
//            viewModel.uploadViewModel?.startUploadImage()
//        }
//    }
//}

struct OverladUploadImageButton: View {
    let messageRowVM: MessageRowViewModel
    @EnvironmentObject var viewModel: UploadFileViewModel
    var message: Message { messageRowVM.message }
    var percent: Int64 { viewModel.uploadPercent }
    var stateIcon: String {
        if viewModel.state == .uploading {
            return "xmark"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.up"
        }
    }

    var body: some View {
        if viewModel.state != .completed {
            HStack {
                ZStack {
                    Image(systemName: stateIcon)
                        .resizable()
                        .scaledToFit()
                        .font(.system(size: 8, design: .rounded).bold())
                        .frame(width: 8, height: 8)
                        .foregroundStyle(Color.App.textPrimary)

                    Circle()
                        .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.App.white)
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: 18, height: 18)
                }
                .frame(width: 26, height: 26)
                .background(Color.App.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius:(13)))

                let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
                let realServerFileSize = messageRowVM.fileMetaData?.file?.size
                if let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale) {
                    Text(fileSize)
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldCaption2)
                        .foregroundColor(Color.App.textPrimary)
                }
            }
            .frame(height: 30)
            .frame(minWidth: 76)
            .padding(4)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius:(18)))
            .animation(.easeInOut, value: stateIcon)
            .animation(.easeInOut, value: percent)
        }
    }
}

final class UploadMessageImageView: UIView {
    private let container = UIView()
    private let stack = UIStackView()
    private let fileSizeLabel = UILabel()
    private let uploadImage = UIImageView()
    private let progressView = CircleProgressView(color: Color.App.whiteUIColor, iconTint: Color.App.whiteUIColor)

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

        uploadImage.layer.cornerRadius = 8
        uploadImage.layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = uploadImage.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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

        stack.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
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

    public func setValues(viewModel: MessageRowViewModel) {
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
        let realServerFileSize = viewModel.fileMetaData?.file?.size
        if let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale) {
            fileSizeLabel.text = fileSize
        }
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
        view.setValues(viewModel: viewModel)
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
