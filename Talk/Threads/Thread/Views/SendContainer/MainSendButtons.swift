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
    private let btnToggleAttachmentButtons = UIImageButton(imagePadding: .init(all: 8))
    private let btnSend = UIImageButton(imagePadding: .init(all: 10))
    private let btnMic = UIImageButton(imagePadding: .init(all: 8))
    private let btnCamera = UIImageButton(imagePadding: .init(all: 8))
    private var btnEmoji = UIImageButton(imagePadding: .init(all: 8))
    private let multilineTextField = SendContainerTextView()
    private weak var threadVM: ThreadViewModel?
    private var viewModel: SendContainerViewModel { threadVM?.sendContainerViewModel ?? .init() }
    private var cancellableSet = Set<AnyCancellable>()
    public static let initSize: CGFloat = 42

    public init(viewModel: ThreadViewModel?) {
        self.threadVM = viewModel
        super.init(frame: .zero)
        configureView()
        registerGestures()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        semanticContentAttribute = .forceLeftToRight
        btnToggleAttachmentButtons.translatesAutoresizingMaskIntoConstraints = false
        btnSend.translatesAutoresizingMaskIntoConstraints = false
        btnMic.translatesAutoresizingMaskIntoConstraints = false
        btnCamera.translatesAutoresizingMaskIntoConstraints = false
        multilineTextField.translatesAutoresizingMaskIntoConstraints = false
        btnEmoji.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 8
        alignment = .bottom
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        btnToggleAttachmentButtons.imageView.contentMode = .scaleAspectFit
        btnToggleAttachmentButtons.tintColor = Color.App.accentUIColor
        btnToggleAttachmentButtons.layer.masksToBounds = true
        btnToggleAttachmentButtons.layer.cornerRadius = MainSendButtons.initSize / 2
        btnToggleAttachmentButtons.backgroundColor = Color.App.bgSendInputUIColor

        btnMic.imageView.contentMode = .scaleAspectFit
        btnMic.tintColor = Color.App.textSecondaryUIColor

        btnCamera.imageView.contentMode = .scaleAspectFit
        btnCamera.tintColor = Color.App.textSecondaryUIColor
        btnCamera.isHidden = true

        btnSend.imageView.contentMode = .scaleAspectFit
        btnSend.tintColor = Color.App.textPrimaryUIColor
        btnSend.layer.masksToBounds = true
        btnSend.layer.cornerRadius = (MainSendButtons.initSize - 4) / 2
        btnSend.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        btnSend.isHidden = true
        btnSend.action = { [weak self] in
            self?.onBtnSendTapped()
        }

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
        hStack.layoutMargins = .init(top: -4, left: 8, bottom: 0, right: 8)//-4 to move textfield higher to make the cursor center in the textfield.
        hStack.isLayoutMarginsRelativeArrangement = true

        hStack.addArrangedSubview(multilineTextField)
        hStack.addArrangedSubview(btnEmoji)

        addArrangedSubviews([btnToggleAttachmentButtons, hStack, btnMic, btnCamera, btnSend])

        // Set draf text
        if !viewModel.isTextEmpty() {
            multilineTextField.text = viewModel.getText()
            multilineTextField.hidePlaceholder()
            animateBtnSendVisibility(multilineTextField.text)
        }
        multilineTextField.onTextChanged = { [weak self] text in
            self?.viewModel.setText(newValue: text ?? "")
        }

        viewModel.onTextChanged = { [weak self] newValue in
            self?.multilineTextField.text = newValue
            self?.animateBtnSendVisibility(newValue)
            if self?.viewModel.isTextEmpty() == false {
                self?.multilineTextField.hidePlaceholder()
            } else {
                self?.multilineTextField.showPlaceholder()
            }
        }

        NSLayoutConstraint.activate([
            btnToggleAttachmentButtons.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnToggleAttachmentButtons.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnSend.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize - 4),
            btnSend.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize - 4),
            btnMic.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnMic.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnCamera.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnCamera.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnEmoji.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnEmoji.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
        ])

        prepareUI()
    }

    private func prepareUI() {
        Task {
            let sendImage: UIImage?
            if #available(iOS 13.0, *) {
                let config = UIImage.SymbolConfiguration(pointSize: 8, weight: .medium, scale: .small)
                sendImage = UIImage(systemName: "arrow.up", withConfiguration: config)
            } else {
                sendImage = UIImage(systemName: "arrow.up")
            }
            let emojiImage = UIImage(named: "emoji")
            let cameraImage = UIImage(systemName: "camera")
            let micImage = UIImage(systemName: "mic")
            let toogleImage = UIImage(systemName: "paperclip")
            await MainActor.run {
                btnSend.imageView.image = sendImage
                btnEmoji.imageView.image = emojiImage
                btnCamera.imageView.image = cameraImage
                btnMic.imageView.image = micImage
                btnToggleAttachmentButtons.imageView.image = toogleImage
            }
        }
    }

    private func registerGestures() {
        let micTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMode))
        let cameraTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMode))
        btnMic.addGestureRecognizer(micTapGesture)
        btnCamera.addGestureRecognizer(cameraTapGesture)

        let micLongGesture = UILongPressGestureRecognizer(target: self, action: #selector(startRecording))
        micLongGesture.minimumPressDuration = 0.3
        let cameraLongGesture = UILongPressGestureRecognizer(target: self, action: #selector(showPopup))
        cameraLongGesture.minimumPressDuration = 0.3
        btnMic.addGestureRecognizer(micLongGesture)
        btnCamera.addGestureRecognizer(cameraLongGesture)

        btnToggleAttachmentButtons.action = { [weak self] in
            self?.onBtnToggleAttachmentButtonsTapped()
        }
    }

    @objc private func toggleMode(_ sender: UIGestureRecognizer) {
        btnMic.alpha = 0.0
        btnCamera.alpha = 0.0
        viewModel.toggleVideorecording()

        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            if viewModel.isVideoRecordingSelected {
                btnCamera.alpha = 1.0
                btnCamera.isHidden = false
                btnMic.alpha = 0.0
                btnMic.isHidden = true
            } else {
                btnCamera.alpha = 0.0
                btnCamera.isHidden = true
                btnMic.alpha = 1.0
                btnMic.isHidden = false
            }
        }
    }

    @objc private func startRecording(_ sender: UIGestureRecognizer) {
        // Update ThreadViewContorler delegate to show recordingUI
        // Check if it is began then show the UI unless we don't call it twice.
        if sender.state != .began { return }
        threadVM?.delegate?.showRecording(true)
    }

    @objc private func showPopup(_ sender: UIGestureRecognizer) {
        // Check if it is began then show the popover unless we don't call it twice.
        if sender.state != .began { return }
        let takeVideo  = UIAlertAction(title: "MessageType.video".localized(), style: .default) { (action) in
            // Respond to user selection of the action
            self.openTakeVideoPicker()
        }
        takeVideo.setValue(UIImage(systemName: "video"), forKey: "image")

        let takePhoto = UIAlertAction(title: "MessageType.picture".localized(), style: .default) { (action) in
            // Respond to user selection of the action
            self.openTakePicturePicker()
        }
        takePhoto.setValue(UIImage(systemName: "photo"), forKey: "image")

        let cancel = UIAlertAction(title: "General.cancel".localized(), style: .cancel) { (action) in
            // Respond to user selection of the action
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(takeVideo)
        alert.addAction(takePhoto)
        alert.addAction(cancel)

        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.sourceView = btnCamera

        (viewModel.viewModel?.delegate as? UIViewController)?.present(alert, animated: true) {
            // The alert was presented
        }
    }

    @objc private func onBtnSendTapped() {
        if viewModel.showSendButton {
            Task { [weak self] in
                guard let self = self else { return }
                await threadVM?.sendMessageViewModel.sendTextMessage()
                threadVM?.mentionListPickerViewModel.text = ""
                viewModel.viewModel?.delegate?.openReplyMode(nil)
                viewModel.viewModel?.delegate?.openEditMode(nil)
            }
        }
    }

    @objc private func onBtnToggleAttachmentButtonsTapped() {
        viewModel.toggleActionButtons()
    }

    private func onViewModelChanged() {
        if viewModel.getText() != multilineTextField.text {
            multilineTextField.text = viewModel.getText() // When sending a message and we want to clear out the txetfield
        }
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
            btnToggleAttachmentButtons.imageView.image = attImage
        }
    }

    private func openTakeVideoPicker() {
        let captureObject = CameraCapturer(isVideo: true) { [weak self] image, url, resources in
            guard let self = self, let videoURL = url, let data = try? Data(contentsOf: videoURL) else { return }
            let fileName = "video-\(Date().fileDateString).mov"
            let item = ImageItem(id: UUID(), isVideo: true, data: data, width: 0, height: 0, originalFilename: fileName)
            viewModel.viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
        }
        (viewModel.viewModel?.delegate as? UIViewController)?.present(captureObject.vc, animated: true)
    }

    private func openTakePicturePicker() {
        let captureObject = CameraCapturer(isVideo: false) { [weak self] image, url, resources in
            guard let self = self, let image = image else { return }
            let item = ImageItem(data: image.jpegData(compressionQuality: 80) ?? Data(),
                                 width: Int(image.size.width),
                                 height: Int(image.size.height),
                                 originalFilename: "image-\(Date().fileDateString).jpg")
            viewModel.viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
        }
        (viewModel.viewModel?.delegate as? UIViewController)?.present(captureObject.vc, animated: true)
    }

    public func focusOnTextView(focus: Bool) {
        if focus {
            multilineTextField.becomeFirstResponder()
        } else {
            multilineTextField.resignFirstResponder()
        }
    }

    private func animateBtnSendVisibility(_ newValue: String?) {
        if !btnSend.isHidden && newValue?.isEmpty == false { return }
        if btnSend.isHidden && newValue?.isEmpty == false {
            UIView.animate(withDuration: 0.2) {
                self.btnMic.alpha = 0.0
                self.btnMic.isHidden = true
                self.btnSend.alpha = 1.0
                self.btnSend.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.btnMic.alpha = 1.0
                self.btnMic.isHidden = false
                self.btnSend.alpha = 0.0
                self.btnSend.isHidden = true
            }
        }
    }
}
