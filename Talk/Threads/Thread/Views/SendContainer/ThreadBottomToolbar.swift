//
//  ThreadBottomToolbar.swift
//  Talk
//
//  Created by hamed on 3/24/24.
//

import Foundation
import UIKit
import TalkViewModels
import Combine
import TalkUI

public final class ThreadBottomToolbar: UIStackView {
    private let viewModel: ThreadViewModel
    private let mainSendButtons: MainSendButtons
    private let audioRecordingView: AudioRecordingView
    private let attachmentButtons: AttachmentButtonsView
    private let attachmentFilesTableView: AttachmentFilesTableView
    private let replyPrivatelyPlaceholderView: ReplyPrivatelyMessagePlaceholderView
    private let replyPlaceholderView: ReplyMessagePlaceholderView
    private let forwardPlaceholderView: ForwardMessagePlaceholderView
    private let editMessagePlaceholderView: EditMessagePlaceholderView
    private let mentionTableView: MentionTableView
    private let selectionView: SelectionView
    private let muteBarView: MuteChannelBarView
    private var cancellableSet = Set<AnyCancellable>()
    public var onUpdateHeight: ((CGFloat) -> Void)?

    public init(viewModel: ThreadViewModel, vc: UIViewController) {
        self.viewModel = viewModel
        self.mainSendButtons = MainSendButtons(viewModel: viewModel)
        self.audioRecordingView = AudioRecordingView(viewModel: viewModel)
        self.attachmentButtons = AttachmentButtonsView(viewModel: viewModel.sendContainerViewModel, vc: vc)
        self.attachmentFilesTableView = AttachmentFilesTableView(viewModel: viewModel)
        self.replyPlaceholderView = ReplyMessagePlaceholderView(viewModel: viewModel)
        self.replyPrivatelyPlaceholderView = ReplyPrivatelyMessagePlaceholderView(viewModel: viewModel)
        self.forwardPlaceholderView = ForwardMessagePlaceholderView(viewModel: viewModel)
        self.editMessagePlaceholderView = EditMessagePlaceholderView(viewModel: viewModel)
        self.selectionView = SelectionView(viewModel: viewModel)
        self.muteBarView = MuteChannelBarView(viewModel: viewModel)
        self.mentionTableView = MentionTableView(viewModel: viewModel)
        super.init(frame: .zero)
        configureViews()
        registerObservers()
    }
    
    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        mainSendButtons.translatesAutoresizingMaskIntoConstraints = false
        audioRecordingView.translatesAutoresizingMaskIntoConstraints = false
        attachmentButtons.translatesAutoresizingMaskIntoConstraints = false
        attachmentFilesTableView.translatesAutoresizingMaskIntoConstraints = false
        replyPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        forwardPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        editMessagePlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        muteBarView.translatesAutoresizingMaskIntoConstraints = false
        mentionTableView.translatesAutoresizingMaskIntoConstraints = false

        axis = .vertical
        alignment = .fill
        spacing = 0

        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.layer.masksToBounds = true
        effectView.layer.cornerRadius = 0
        effectView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        addSubview(effectView)

        attachmentButtons.isHidden = true
        attachmentFilesTableView.isHidden = true
        replyPrivatelyPlaceholderView.isHidden = true
        replyPlaceholderView.isHidden = true
        forwardPlaceholderView.isHidden = true
        editMessagePlaceholderView.isHidden = true
        selectionView.isHidden = true
        audioRecordingView.isHidden = true
        addArrangedSubview(attachmentFilesTableView)
        addArrangedSubview(attachmentButtons)
        addArrangedSubview(replyPlaceholderView)
        addArrangedSubview(replyPrivatelyPlaceholderView)
        addArrangedSubview(forwardPlaceholderView)
        addArrangedSubview(editMessagePlaceholderView)
        addArrangedSubview(selectionView)
        addArrangedSubview(audioRecordingView)
        addArrangedSubview(mentionTableView)
        if viewModel.sendContainerViewModel.canShowMute {
            addArrangedSubview(muteBarView)
        } else {
            addArrangedSubview(mainSendButtons)
        }
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: attachmentButtons.topAnchor, constant: -8),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func registerObservers() {
        viewModel.sendContainerViewModel.$showActionButtons.sink { showActionButtons in
            if showActionButtons {
                UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5, options: .curveEaseInOut) { [weak self] in
                    guard let self = self else { return }
                    attachmentButtons.isHidden = !showActionButtons
                }
            } else {
                UIView.animate(withDuration: 0.2) { [weak self] in
                    guard let self = self else { return }
                    attachmentButtons.isHidden = !showActionButtons
                }
            }
        }
        .store(in: &cancellableSet)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        onUpdateHeight?(bounds.height)
    }
}
