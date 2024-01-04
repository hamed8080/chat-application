//
//  UploadMessageFileView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import SwiftUI
import TalkViewModels
import ChatModels
import TalkModels
import ChatDTO
import TalkUI
//
//public struct UploadMessageFileView: View {
//    let viewModel: MessageRowViewModel
//    var message: Message { viewModel.message }
//
//    public var body: some View {
//        HStack(spacing: 4) {
//            UploadImageButton(messageRowVM: viewModel)
//                .environmentObject(viewModel.uploadViewModel!)
//            if let fileName = message.uploadFileName ?? viewModel.fileMetaData?.file?.originalName {
//                Text("\(fileName)")
//                    .foregroundStyle(Color.App.text)
//                    .font(.iransansBoldCaption)
//            }
//        }
//        .task {
//            viewModel.uploadViewModel?.startUploadFile()
//        }
//    }
//}
//
//struct UploadImageButton: View {
//    let messageRowVM: MessageRowViewModel
//    @EnvironmentObject var viewModel: UploadFileViewModel
//    var message: Message { messageRowVM.message }
//    var percent: Int64 { viewModel.uploadPercent }
//    var stateIcon: String {
//        if viewModel.state == .uploading {
//            return "xmark"
//        } else if viewModel.state == .paused {
//            return "play.fill"
//        } else {
//            return "arrow.up"
//        }
//    }
//
//    var body: some View {
//        if viewModel.state != .completed {
//            HStack {
//                ZStack {
//                    Image(systemName: stateIcon)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 12, height: 12)
//                        .foregroundStyle(Color.App.bgPrimary)
//
//                    Circle()
//                        .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
//                        .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
//                        .foregroundColor(Color.App.bgPrimary)
//                        .rotationEffect(Angle(degrees: 270))
//                        .frame(width: 32, height: 32)
//                        .environment(\.layoutDirection, .leftToRight)
//                }
//                .frame(width: 42, height: 42)
//                .background(Color.App.btnDownload)
//                .clipShape(RoundedRectangle(cornerRadius:(42 / 2)))
//                .onTapGesture {
//                    if viewModel.state == .paused {
//                        viewModel.resumeUpload()
//                    } else if viewModel.state == .uploading {
//                        viewModel.cancelUpload()
//                    }
//                }
//
//                VStack(alignment: .leading, spacing: 8) {
//                    if let fileZize = messageRowVM.fileMetaData?.file?.size {
//                        Text(String(fileZize))
//                            .multilineTextAlignment(.leading)
//                            .font(.iransansBoldCaption2)
//                            .foregroundColor(.white)
//                    }
//                }
//            }
//        }
//    }
//}

final class UploadMessageFileView: UIView {
    private let container = UIView()
    private let stack = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let progressView = CircleProgressView(color: Color.App.uibgPrimary, iconTint: Color.App.uibgPrimary)

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

        stack.axis = .horizontal
        stack.spacing = 12
        stack.addArrangedSubview(progressView)
        stack.addArrangedSubview(fileSizeLabel)
        container.addSubview(stack)
        addSubview(container)

        stack.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 48),
            progressView.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let message = viewModel.message
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

        if let fileName = message.uploadFileName ?? viewModel.fileMetaData?.file?.originalName {
            fileNameLabel.text = fileName
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

struct UploadMessageFileViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

<<<<<<< HEAD
                    Circle()
                        .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.App.bgPrimary)
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: 32, height: 32)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .frame(width: 42, height: 42)
                .background(Color.App.white)
                .clipShape(RoundedRectangle(cornerRadius:(42 / 2)))
                .onTapGesture {
                    if viewModel.state == .paused {
                        viewModel.resumeUpload()
                    } else if viewModel.state == .uploading {
                        viewModel.cancelUpload()
                    }
                }
=======
    func makeUIView(context: Context) -> some UIView {
        let view = UploadMessageFileView()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
>>>>>>> 85cb740 (- Add progress view and refactor Upload file/image to UIKit)

    }
}

struct UploadMessageFileView_Previews: PreviewProvider {
    static var previews: some View {
        let message = UploadFileWithTextMessage(uploadFileRequest: UploadFileRequest(data: Data()), thread: MockData.thread)
        let messageViewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        let uploadFileVM = UploadFileViewModel(message: message)
        UploadMessageFileViewWapper(viewModel: messageViewModel)
            .environmentObject(uploadFileVM)
            .background(Color.black.ignoresSafeArea())
            .onAppear {
                uploadFileVM.startUploadFile()
            }
    }
}
