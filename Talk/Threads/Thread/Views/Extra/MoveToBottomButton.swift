//
//  MoveToBottomButton.swift
//  Talk
//
//  Created by hamed on 7/7/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkExtensions

public final class MoveToBottomButton: UIButton {
    public let viewModel: ThreadViewModel
    private var color: UIColor?
    private var bgColor: UIColor?
    private var shapeLayer = CAShapeLayer()
    private let imgCenter = UIImageView()
    private var iconTint: UIColor?
    private let lblUnreadCount = PaddingUILabel(frame: .zero, horizontal: 4, vertical: 4)

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
        updateUnreadCount()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layer.backgroundColor = Color.App.bgPrimaryUIColor?.cgColor
        layer.cornerRadius = 20

        imgCenter.image = UIImage(systemName: "chevron.down")
        imgCenter.translatesAutoresizingMaskIntoConstraints = false
        imgCenter.contentMode = .scaleAspectFit
        imgCenter.tintColor = Color.App.accentUIColor
        addSubview(imgCenter)

        lblUnreadCount.translatesAutoresizingMaskIntoConstraints = false
        lblUnreadCount.textColor = Color.App.whiteUIColor
        lblUnreadCount.font = .uiiransansBoldCaption
        lblUnreadCount.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        lblUnreadCount.layer.cornerRadius = 12
        lblUnreadCount.textAlignment = .center
        lblUnreadCount.numberOfLines = 1

        addSubview(lblUnreadCount)

        NSLayoutConstraint.activate([
            imgCenter.centerXAnchor.constraint(equalTo: centerXAnchor),
            imgCenter.centerYAnchor.constraint(equalTo: centerYAnchor),
            imgCenter.widthAnchor.constraint(equalToConstant: 16),
            imgCenter.heightAnchor.constraint(equalToConstant: 16),
            lblUnreadCount.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            lblUnreadCount.heightAnchor.constraint(equalToConstant: 24),
            lblUnreadCount.topAnchor.constraint(equalTo: topAnchor, constant: -16),
            lblUnreadCount.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        isHidden = true
        viewModel.scrollVM.scrollToBottom()
    }

    public func updateUnreadCount() {
        lblUnreadCount.isHidden = viewModel.thread.unreadCount == 0 || viewModel.thread.unreadCount == nil
        lblUnreadCount.text = viewModel.thread.unreadCountString ?? ""
    }
}

struct MoveToBottomButton_Previews: PreviewProvider {
    static var vm = ThreadViewModel(thread: .init(id: 1))

    struct MoveToBottomButtonWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel
        func makeUIView(context: Context) -> some UIView { MoveToBottomButton(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        MoveToBottomButtonWrapper(viewModel: vm)
    }
}
