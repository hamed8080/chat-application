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
    private let btnSend = UIButton(type: .system)
    private let btnMic = UIButton(type: .system)
    private let btnCamera = UIButton(type: .system)
    private let multilineTextField = SendContainerTextView()
    private let threadVM: ThreadViewModel
    private var viewModel: SendContainerViewModel { threadVM.sendContainerViewModel }
    private var cancellableSet = Set<AnyCancellable>()

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

        axis = .horizontal
        spacing = 8
        alignment = .bottom
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        btnToggleAttachmentButtons.imageView?.contentMode = .scaleAspectFit
        btnToggleAttachmentButtons.tintColor = Color.App.accentUIColor
        btnToggleAttachmentButtons.layer.masksToBounds = true
        btnToggleAttachmentButtons.layer.cornerRadius = 22
        btnToggleAttachmentButtons.backgroundColor = Color.App.bgSendInputUIColor

        btnMic.setImage(.init(systemName: "mic"), for: .normal)
        btnMic.imageView?.contentMode = .scaleAspectFit
        btnMic.tintColor = Color.App.textSecondaryUIColor

        btnCamera.setImage(.init(systemName: "camera"), for: .normal)
        btnCamera.imageView?.contentMode = .scaleAspectFit
        btnCamera.tintColor = Color.App.textSecondaryUIColor
        btnCamera.isHidden = true


        btnSend.setImage(.init(systemName: "arrow.up.circle.fill"), for: .normal)
        btnSend.imageView?.contentMode = .scaleAspectFit
        btnSend.tintColor = Color.App.accentUIColor
        btnSend.layer.masksToBounds = true
        btnSend.layer.cornerRadius = 22

        addArrangedSubviews([btnToggleAttachmentButtons, multilineTextField, btnMic, btnCamera])

        NSLayoutConstraint.activate([
            btnToggleAttachmentButtons.widthAnchor.constraint(equalToConstant: 48),
            btnSend.widthAnchor.constraint(equalToConstant: 48),
            btnMic.widthAnchor.constraint(equalToConstant: 48),
            btnCamera.widthAnchor.constraint(equalToConstant: 48),
            btnToggleAttachmentButtons.heightAnchor.constraint(equalToConstant: 48),
            btnSend.heightAnchor.constraint(equalToConstant: 48),
            btnMic.heightAnchor.constraint(equalToConstant: 48),
            btnCamera.heightAnchor.constraint(equalToConstant: 48),
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
        viewModel.isVideoRecordingSelected.toggle()
    }

    @objc private func onBtnSendTapped(_ sender: UIButton) {
        if viewModel.showSendButton {
            threadVM.sendMessageViewModel.sendTextMessage()
        }
        threadVM.mentionListPickerViewModel.text = ""
        threadVM.sheetType = nil
        threadVM.animateObjectWillChange()
    }

    @objc private func onBtnToggleAttachmentButtonsTapped(_ sender: UIButton) {
        viewModel.showActionButtons.toggle()
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

        viewModel.$showActionButtons.sink { newValue in
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                let attImage = UIImage(systemName: newValue ? "chevron.down" : "paperclip")
                btnToggleAttachmentButtons.setImage(attImage, for: .normal)
            }
        }
        .store(in: &cancellableSet)
    }

    private func onViewModelChanged() {
        btnMic.isHidden = viewModel.showCamera
        btnCamera.isHidden = !viewModel.showCamera
        btnSend.isHidden = !viewModel.showSendButton
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
