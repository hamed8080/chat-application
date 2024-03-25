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

public final class ThreadBottomToolbar: UIStackView {
    private let viewModel: ThreadViewModel
    private let mainSendButtons: MainSendButtons
    private let attachmentButtons: AttachmentButtonsView
    private var cancellableSet = Set<AnyCancellable>()

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        self.mainSendButtons = MainSendButtons(viewModel: viewModel)
        self.attachmentButtons = AttachmentButtonsView(viewModel: viewModel.sendContainerViewModel)
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
        attachmentButtons.translatesAutoresizingMaskIntoConstraints = false
        
        axis = .vertical
        alignment = .center
        spacing = 0

        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.layer.masksToBounds = true
        effectView.layer.cornerRadius = 8
        addSubview(effectView)

        attachmentButtons.isHidden = true
        addArrangedSubview(attachmentButtons)
        addArrangedSubview(mainSendButtons)

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: attachmentButtons.topAnchor, constant: -8),
            mainSendButtons.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainSendButtons.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainSendButtons.bottomAnchor.constraint(equalTo: bottomAnchor),
            attachmentButtons.bottomAnchor.constraint(equalTo: mainSendButtons.topAnchor),
            attachmentButtons.centerXAnchor.constraint(equalTo: centerXAnchor),
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
}
