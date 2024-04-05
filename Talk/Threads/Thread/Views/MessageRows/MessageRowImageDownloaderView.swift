//
//  MessageRowImageDownloaderView.swift
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

final class MessageRowImageDownloaderView: UIImageView {
    private let stack = UIStackView()
    private let fileSizeLabel = UILabel()
    private let progressView = CircleProgressButton(color: Color.App.whiteUIColor, iconTint: Color.App.whiteUIColor)
    private var viewModel: MessageRowViewModel?
    private var effectView: UIVisualEffectView!

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
        layer.cornerRadius = 8
        layer.masksToBounds = true

        translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(effectView)

        bringSubviewToFront(effectView)

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

        stack.axis = .horizontal
        stack.spacing = 12
        stack.addArrangedSubview(progressView)
        stack.addArrangedSubview(fileSizeLabel)
        stack.backgroundColor = .white.withAlphaComponent(0.2)
        stack.layoutMargins = .init(horizontal: 4, vertical: 4)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layer.cornerRadius = 18

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tapGesture)

        addSubview(stack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 128),
            effectView.widthAnchor.constraint(equalTo: widthAnchor),
            effectView.heightAnchor.constraint(equalTo: heightAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 28),
            progressView.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        image = viewModel.image
        stack.isHidden = viewModel.downloadFileVM == nil
        effectView.isHidden = viewModel.downloadFileVM == nil
        isHidden = !viewModel.rowType.isImage

        let progress = CGFloat(viewModel.downloadFileVM?.downloadPercent ?? 0)
        progressView.animate(to: progress, systemIconName: stateIcon(viewModel: viewModel))
        if progress >= 1 {
            progressView.removeProgress()
        }

        if let fileSize = computedFileSize(viewModel: viewModel) {
            fileSizeLabel.text = fileSize
        }
    }

    @objc func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
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
        let view = MessageRowImageDownloaderView(frame: .zero)
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct MessageRowImageDownloader_Previews: PreviewProvider {
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
            MessageRowImageDownloaderWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.isImage})!)
            .previewDisplayName("FileDownloader")
    }
}
