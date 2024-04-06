//
//  MainSendButtons.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels
import UIKit
import Combine

public final class MainSendButtons: UIStackView {
    private let btnToggleAttachmentButtons = UIButton(type: .system)
    private let btnSend = UIImageButton(imagePadding: .init(all: 8))
    private let btnMic = UIButton(type: .system)
    private let btnCamera = UIButton(type: .system)
    private var btnEmoji = UIImageButton(imagePadding: .init(all: 8))
    private let multilineTextField = SendContainerTextView()
    private let threadVM: ThreadViewModel
    private var viewModel: SendContainerViewModel { threadVM.sendContainerViewModel }
    private var cancellableSet = Set<AnyCancellable>()
    public static let initSize: CGFloat = 42

    public init(viewModel: ThreadViewModel) {
        self.threadVM = viewModel
        super.init(frame: .zero)
        configureView()
        registerGestures()
        registerObserver()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        btnToggleAttachmentButtons.translatesAutoresizingMaskIntoConstraints = false
        btnSend.translatesAutoresizingMaskIntoConstraints = false
        btnMic.translatesAutoresizingMaskIntoConstraints = false
        btnCamera.translatesAutoresizingMaskIntoConstraints = false
        multilineTextField.translatesAutoresizingMaskIntoConstraints = false
        btnEmoji.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 8
        alignment = .center
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        btnToggleAttachmentButtons.imageView?.contentMode = .scaleAspectFit
        btnToggleAttachmentButtons.tintColor = Color.App.accentUIColor
        btnToggleAttachmentButtons.layer.masksToBounds = true
        btnToggleAttachmentButtons.layer.cornerRadius = MainSendButtons.initSize / 2
        btnToggleAttachmentButtons.backgroundColor = Color.App.bgSendInputUIColor
        btnToggleAttachmentButtons.setImage(UIImage(systemName: "paperclip"), for: .normal)

        btnMic.setImage(.init(systemName: "mic"), for: .normal)
        btnMic.imageView?.contentMode = .scaleAspectFit
        btnMic.tintColor = Color.App.textSecondaryUIColor

        btnCamera.setImage(.init(systemName: "camera"), for: .normal)
        btnCamera.imageView?.contentMode = .scaleAspectFit
        btnCamera.tintColor = Color.App.textSecondaryUIColor
        btnCamera.isHidden = true

        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold, scale: .medium)
        if #available(iOS 13.0, *) {
            btnSend.imageView.image = UIImage(systemName: "arrow.up", withConfiguration: config)
        } else {
            btnSend.imageView.image = UIImage(systemName: "arrow.up")
        }
        btnSend.imageView.contentMode = .scaleAspectFit
        btnSend.tintColor = Color.App.textPrimaryUIColor
        btnSend.layer.masksToBounds = true
        btnSend.layer.cornerRadius = (MainSendButtons.initSize - 8) / 2
        btnSend.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        btnSend.isHidden = true
        btnSend.action = { [weak self] in
            self?.onBtnSendTapped()
        }

        let emojiImage = UIImage(named: "emoji")
        btnEmoji.imageView.image = emojiImage
        btnEmoji.imageView.tintColor = Color.App.redUIColor
        btnEmoji.isHidden = true

        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.layer.masksToBounds = true
        hStack.layer.cornerRadius = MainSendButtons.initSize / 2
        hStack.backgroundColor = Color.App.bgSendInputUIColor
        hStack.alignment = .bottom
        hStack.layoutMargins = .init(top: 0, left: 8, bottom: 0, right: 8)
        hStack.isLayoutMarginsRelativeArrangement = true

        hStack.addArrangedSubview(multilineTextField)
        hStack.addArrangedSubview(btnEmoji)

        addArrangedSubviews([btnToggleAttachmentButtons, hStack, btnMic, btnCamera, btnSend])

        if !viewModel.isTextEmpty() {
            multilineTextField.text = viewModel.getText()
            multilineTextField.hidePlaceholder()
        }
        multilineTextField.onTextChanged = { [weak self] text in
            self?.viewModel.setText(newValue: text ?? "")
        }

        NSLayoutConstraint.activate([
            btnToggleAttachmentButtons.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnSend.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize - 8),
            btnMic.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnCamera.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnToggleAttachmentButtons.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnSend.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize - 8),
            btnMic.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnCamera.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnEmoji.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnEmoji.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
        ])
    }

    private func registerGestures() {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .up
        gesture.addTarget(self, action: #selector(onSwiped))
        btnMic.addGestureRecognizer(gesture)
        btnCamera.addGestureRecognizer(gesture)
        btnToggleAttachmentButtons.addTarget(self, action: #selector(onBtnToggleAttachmentButtonsTapped), for: .touchUpInside)
    }

    @objc private func onSwiped(_ sender: UIGestureRecognizer) {
        viewModel.toggleVideorecording()
    }

    @objc private func onBtnSendTapped() {
        if viewModel.showSendButton {
            threadVM.sendMessageViewModel.sendTextMessage()
        }
        threadVM.mentionListPickerViewModel.text = ""
        threadVM.animateObjectWillChange()
    }

    @objc private func onBtnToggleAttachmentButtonsTapped(_ sender: UIButton) {
        viewModel.toggleActionButtons()
    }

    @objc private func onBtnMicTapped(_ sender: UIButton) {
        threadVM.attachmentsViewModel.clear()
        threadVM.setupRecording()
    }

    @objc private func onBtnCameraTapped(_ sender: UIButton) {
        threadVM.setupRecording()
    }

    private func registerObserver() {
        viewModel.objectWillChange.sink { [weak self] _ in
            self?.onViewModelChanged()
        }
        .store(in: &cancellableSet)
    }

    private func onViewModelChanged() {
        animateMainButtons()
        animateActionButtonsIfNeeded()
    }

    private func animateMainButtons() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            if btnMic.isHidden != !viewModel.showAudio {
                btnMic.isHidden = !viewModel.showAudio
            }
            if btnCamera.isHidden != !viewModel.showCamera {
                btnCamera.isHidden = !viewModel.showCamera
            }
            if btnSend.isHidden != !viewModel.showSendButton {
                btnSend.isHidden = !viewModel.showSendButton
            }
        }
    }

    private func animateActionButtonsIfNeeded() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            let attImage = UIImage(systemName: viewModel.showActionButtons ? "chevron.down" : "paperclip")
            btnToggleAttachmentButtons.setImage(attImage, for: .normal)
        }
    }
}

struct MainSendButtons_Previews: PreviewProvider {
    struct MainSendButtonsWrapper: UIViewRepresentable {
        func makeUIView(context: Context) -> some UIView { MainSendButtons(viewModel: .init(thread: .init(id: 1))) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        MainSendButtonsWrapper()
    }
}
