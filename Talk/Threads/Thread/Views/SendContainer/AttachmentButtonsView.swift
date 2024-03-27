//
//  AttachmentButtonsView.swift
//  Talk
//
//  Created by Hamed Hosseini on 11/23/21.
//

import AdditiveUI
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels
import UIKit

public final class AttachmentButtonsView: UIStackView {
    private let viewModel: SendContainerViewModel
    private let btnGallery = AttchmentButton(title: "General.gallery", image: "photo.fill")
    private let btnFile = AttchmentButton(title: "General.file", image: "doc.fill")
    private let btnLocation = AttchmentButton(title: "General.location", image: "location.fill")
    private let btnContact = AttchmentButton(title: "General.contact", image: "person.2.crop.square.stack.fill")
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    public init(viewModel: SendContainerViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        registerGestures()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        axis = .horizontal
        spacing = 8
        alignment = .center
        distribution = .fill

        addArrangedSubviews([btnGallery, btnFile, btnLocation])
    }

    private func registerGestures() {
        let galleryGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnGalleryTapped))
        galleryGesture.numberOfTapsRequired = 1
        btnGallery.addGestureRecognizer(galleryGesture)

        let fileGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnFileTapped))
        fileGesture.numberOfTapsRequired = 1
        btnFile.addGestureRecognizer(fileGesture)

        let locationGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnLocationTapped))
        locationGesture.numberOfTapsRequired = 1
        btnLocation.addGestureRecognizer(locationGesture)

        let contactGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnContactTapped))
        contactGesture.numberOfTapsRequired = 1
        btnContact.addGestureRecognizer(contactGesture)
    }

    @objc private func onBtnGalleryTapped(_ sender: UIGestureRecognizer) {
        threadVM?.sheetType = .galleryPicker
        viewModel.showActionButtons.toggle()
        threadVM?.animateObjectWillChange()
    }

    @objc private func onBtnFileTapped(_ sender: UIGestureRecognizer) {
        threadVM?.sheetType = .filePicker
        viewModel.showActionButtons.toggle()
        threadVM?.animateObjectWillChange()
    }

    @objc private func onBtnLocationTapped(_ sender: UIGestureRecognizer) {
        threadVM?.sheetType = .locationPicker
        viewModel.showActionButtons.toggle()
        threadVM?.animateObjectWillChange()
    }

    @objc private func onBtnContactTapped(_ sender: UIGestureRecognizer) {
        threadVM?.sheetType = .contactPicker
        viewModel.showActionButtons.toggle()
        threadVM?.animateObjectWillChange()
    }
}

public final class AttchmentButton: UIStackView {
    private let imageContainer = UIView()
    private let imageView: UIImageView
    private let label: UILabel
    private var imageContainerWidthConstraint: NSLayoutConstraint!
    private var imageContainerHeightConstraint: NSLayoutConstraint!

    public init(title: String, image: String) {
        let image = UIImage(systemName: image)
        self.imageView = UIImageView(image: image)
        self.label = UILabel()
        label.text = title.localized()
        super.init(frame: .zero)
        configureViews()
        registerGestures()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        axis = .vertical
        spacing = 4
        isUserInteractionEnabled = true

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = traitCollection.userInterfaceStyle == .dark ? Color.App.whiteUIColor : Color.App.accentUIColor

        imageContainer.layer.borderColor = Color.App.textSecondaryUIColor?.withAlphaComponent(0.5).cgColor
        imageContainer.layer.borderWidth = 1
        imageContainer.layer.masksToBounds = true
        imageContainer.layer.cornerRadius = 24
        imageContainer.addSubview(imageView)

        label.textColor = Color.App.textSecondaryUIColor
        label.font = UIFont.uiiransansCaption3
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true

        addArrangedSubviews([imageContainer, label])

        imageContainerWidthConstraint = imageContainer.widthAnchor.constraint(equalToConstant: 66)
        imageContainerHeightConstraint = imageContainer.heightAnchor.constraint(equalToConstant: 66)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            imageContainerWidthConstraint,
            imageContainerHeightConstraint,
        ])
    }

    private func registerGestures() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(onPressingDown))
        addGestureRecognizer(gesture)
    }

    @objc private func onPressingDown(_ sender: UILongPressGestureRecognizer) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            imageContainerWidthConstraint.constant = sender.state == .began ? 52 : 66
            imageContainerHeightConstraint.constant = sender.state == .began ? 52 : 66
            imageContainer.backgroundColor = sender.state == .began ? Color.App.textSecondaryUIColor?.withAlphaComponent(0.5) : .clear
        }
    }
}

struct AttachmentDialog_Previews: PreviewProvider {

    struct AttachmentButtonsViewWrapper: UIViewRepresentable {
        func makeUIView(context: Context) -> some UIView { AttachmentButtonsView(viewModel: .init(thread: .init(id: 1))) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        AttachmentButtonsViewWrapper()
    }
}
