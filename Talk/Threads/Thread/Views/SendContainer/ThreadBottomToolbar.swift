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
import TalkModels

public final class ThreadBottomToolbar: UIStackView {
    private weak var viewModel: ThreadViewModel?
    private let mainSendButtons: MainSendButtons
    private let audioRecordingView: AudioRecordingView
    private let pickerButtons: PickerButtonsView
    private let attachmentFilesTableView: AttachmentFilesTableView
    private let replyPrivatelyPlaceholderView: ReplyPrivatelyMessagePlaceholderView
    private let replyPlaceholderView: ReplyMessagePlaceholderView
    private let forwardPlaceholderView: ForwardMessagePlaceholderView
    private let editMessagePlaceholderView: EditMessagePlaceholderView
    private let mentionTableView: MentionTableView
    public let selectionView: SelectionView
    private let muteBarView: MuteChannelBarView
    private var cancellableSet = Set<AnyCancellable>()
    public var onUpdateHeight: ((CGFloat) -> Void)?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        self.mainSendButtons = MainSendButtons(viewModel: viewModel)
        self.audioRecordingView = AudioRecordingView(viewModel: viewModel)
        self.pickerButtons = PickerButtonsView(viewModel: viewModel?.sendContainerViewModel)
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
    }
    
    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        mainSendButtons.translatesAutoresizingMaskIntoConstraints = false
        audioRecordingView.translatesAutoresizingMaskIntoConstraints = false
        pickerButtons.translatesAutoresizingMaskIntoConstraints = false
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

        pickerButtons.setIsHidden(true)
        attachmentFilesTableView.setIsHidden(true)
        replyPrivatelyPlaceholderView.setIsHidden(true)
        replyPlaceholderView.setIsHidden(true)
        editMessagePlaceholderView.setIsHidden(true)
        selectionView.setIsHidden(true)
        audioRecordingView.setIsHidden(true)

        addArrangedSubview(pickerButtons)
        addArrangedSubview(attachmentFilesTableView)
        addArrangedSubview(replyPlaceholderView)
        addArrangedSubview(replyPrivatelyPlaceholderView)
        addArrangedSubview(forwardPlaceholderView)
        addArrangedSubview(editMessagePlaceholderView)
        addArrangedSubview(selectionView)
        addArrangedSubview(audioRecordingView)
        addArrangedSubview(mentionTableView)
        if viewModel?.sendContainerViewModel.canShowMute == true {
            addArrangedSubview(muteBarView)
        } else {
            addArrangedSubview(mainSendButtons)
        }

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: pickerButtons.topAnchor, constant: -8),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func showMainButtons(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.mainSendButtons.alpha = !show ? 0.0 : 1.0
            self.mainSendButtons.setIsHidden(!show)
        }
    }

    public func showPickerButtons(_ show: Bool) {
        mainSendButtons.toggleAttchmentButton(show: show)
        showPicker(show: show)
    }

    public func showSendButton(_ show: Bool) {
        mainSendButtons.showSendButton(show)
    }

    public func showMicButton(_ show: Bool) {
        mainSendButtons.showMicButton(show)
    }

    public func showSelectionBar(_ show: Bool) {
        selectionView.update()
    }

    public func updateSelectionBar() {
        selectionView.update()
    }

    public func updateMentionList() {
        mentionTableView.updateMentionList()
    }

    private func showPicker(show: Bool) {
        pickerButtons.alpha = show ? 0.0 : 1.0
        UIView.animate(withDuration: show ? 0.3 : 0.2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            pickerButtons.setIsHidden(!show)
            pickerButtons.alpha = show ? 1.0 : 0.0
        }
    }

    public func updateHeightWithDelay() {
        guard let viewModel = viewModel else { return }
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if viewModel.audioRecoderVM.isRecording {
                onUpdateHeight?(audioRecordingView.frame.height)
            } else if viewModel.sendContainerViewModel.showPickerButtons {
                onUpdateHeight?(mainSendButtons.frame.height)
            } else {
                onUpdateHeight?(frame.height)
            }
        }
    }

    public func openEditMode(_ message: (any HistoryMessageProtocol)?) {
        editMessagePlaceholderView.set()
        viewModel?.sendContainerViewModel.setText(newValue: message?.message ?? "")
    }

    public func openReplyMode(_ message: (any HistoryMessageProtocol)?) {
        replyPlaceholderView.set()
    }
    
    public func focusOnTextView(focus: Bool) {
        mainSendButtons.focusOnTextView(focus: focus)
    }

    public func openRecording(_ show: Bool) {
        audioRecordingView.show(show) // Reset to show RecordingView again
        viewModel?.attachmentsViewModel.clear()
        // We have to be in showing mode to setup recording unless we will end up toggle isRecording inside the setupRecording method.
        if show {
            viewModel?.setupRecording()
        }
        showMainButtons(!show)
        showRecordingView(show)
    }

    private func showRecordingView(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.audioRecordingView.alpha = show ? 1.0 : 0.0
            self.audioRecordingView.setIsHidden(!show)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateHeightWithDelay()
    }
}
