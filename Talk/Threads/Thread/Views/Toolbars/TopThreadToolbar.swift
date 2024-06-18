//
//  TopThreadToolbar.swift
//  Talk
//
//  Created by hamed on 3/25/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkUI
import SwiftUI
import Combine

public final class TopThreadToolbar: UIStackView {
    private let navBarView: CustomConversationNavigationBar
    private var pinMessageView: ThreadPinMessageView?
    private weak var viewModel: ThreadViewModel?

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        self.navBarView = .init(viewModel: viewModel)
        if let viewModel = viewModel {
            self.pinMessageView = .init(viewModel: viewModel.threadPinMessageViewModel)
        }
        super.init(frame: .zero)
        configureViews()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 0

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(effectView)

        NSLayoutConstraint.activate([
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        configureNavBarView()
        configurePinMessageView()
    }

    private func configureNavBarView() {
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(navBarView)
        NSLayoutConstraint.activate([
            navBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            navBarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            navBarView.heightAnchor.constraint(equalToConstant: 46),
        ])
    }

    private func configurePinMessageView() {
        if let pinMessageView = pinMessageView {
            addArrangedSubview(pinMessageView)
        }
    }

    public func updateTitleTo(_ title: String?) {
        navBarView.updateTitleTo(title)
    }

    public func updateSubtitleTo(_ subtitle: String?) {
        navBarView.updateSubtitleTo(subtitle)
    }

    public func updateImageTo(_ image: UIImage?) {
        navBarView.updateImageTo(image)
    }
}

public class CustomConversationNavigationBar: UIView {
    private weak var viewModel: ThreadViewModel?
    private let backButton = UIImageButton(imagePadding: .init(all: 6))
    private let titlebutton = UIButton(type: .system)
    private let subtitleLabel = UILabel()
    private var threadImageButton = UIImageButton(imagePadding: .init(all: 0))
    private var threadTitleSupplementary = UILabel()
    private let rightTitleImageView = UIImageView()
    private var centerYTitleConstraint: NSLayoutConstraint!
    private let gradientLayer = CAGradientLayer()
    private var cancellableSet: Set<AnyCancellable> = Set()
    private var imageLoader: ImageLoaderViewModel?

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        registerObservers()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureViews() {
        titlebutton.translatesAutoresizingMaskIntoConstraints = false
        titlebutton.setTitle(viewModel?.thread.titleRTLString, for: .normal)
        titlebutton.titleLabel?.font = UIFont.uiiransansBoldBody
        titlebutton.setTitleColor(Color.App.whiteUIColor, for: .normal)
        titlebutton.addTarget(self, action: #selector(navigateToDetailView), for: .touchUpInside)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        let subtitle = viewModel?.getParticipantCount()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = Color.App.toolbarSecondaryTextUIColor
        subtitleLabel.font = UIFont.uiiransansFootnote
        subtitleLabel.setIsHidden(subtitle == nil || subtitle?.isEmpty == true)


        let isSelfThread = viewModel?.thread.type == .selfThread
        if isSelfThread {
            threadImageButton = UIImageButton(imagePadding: .init(all: 8))
            let startColor = UIColor(red: 255/255, green: 145/255, blue: 98/255, alpha: 1.0)
            let endColor = UIColor(red: 255/255, green: 90/255, blue: 113/255, alpha: 1.0)
            gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
            gradientLayer.startPoint = .init(x: 0, y: 0)
            gradientLayer.endPoint = .init(x: 1.0, y: 1.0)
            threadImageButton.imageView.image = UIImage(named: "bookmark")
            threadImageButton.imageView.tintColor = Color.App.textPrimaryUIColor
            threadImageButton.layer.addSublayer(gradientLayer)
            threadImageButton.bringSubviewToFront(threadImageButton.imageView)
            threadTitleSupplementary.setIsHidden(true)
        }
        threadImageButton.translatesAutoresizingMaskIntoConstraints = false
        threadImageButton.layer.cornerRadius = 17
        threadImageButton.layer.masksToBounds = true
        threadImageButton.imageView.layer.cornerRadius = 8
        threadImageButton.imageView.layer.masksToBounds = true
        threadImageButton.imageView.contentMode  = .scaleAspectFill
        threadImageButton.action = { [weak self] in
            self?.navigateToDetailView()
        }

        threadTitleSupplementary.translatesAutoresizingMaskIntoConstraints = false
        threadTitleSupplementary.font = UIFont.uiiransansCaption3
        threadTitleSupplementary.textColor = .white

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.imageView.image = UIImage(systemName: "chevron.backward")
        backButton.imageView.tintColor = Color.App.toolbarButtonUIColor
        backButton.imageView.contentMode = .scaleAspectFit
        backButton.action = { [weak self] in
            (self?.viewModel?.delegate as? UIViewController)?.navigationController?.popViewController(animated: true)
        }

        rightTitleImageView.translatesAutoresizingMaskIntoConstraints = false
        rightTitleImageView.image = UIImage(named: "ic_approved")
        rightTitleImageView.contentMode = .scaleAspectFit
        rightTitleImageView.setIsHidden(viewModel?.thread.isTalk == false)

        addSubview(backButton)
        addSubview(threadImageButton)
        addSubview(threadTitleSupplementary)
        addSubview(titlebutton)
        addSubview(rightTitleImageView)
        addSubview(subtitleLabel)

        centerYTitleConstraint = titlebutton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
        NSLayoutConstraint.activate([
            threadImageButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            threadImageButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            threadImageButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            threadImageButton.widthAnchor.constraint(equalToConstant: 38),

            threadTitleSupplementary.centerXAnchor.constraint(equalTo: threadImageButton.centerXAnchor),
            threadTitleSupplementary.centerYAnchor.constraint(equalTo: threadImageButton.centerYAnchor),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            backButton.widthAnchor.constraint(equalToConstant: 36),

            titlebutton.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerYTitleConstraint,
            titlebutton.heightAnchor.constraint(equalToConstant: 16),

            subtitleLabel.centerXAnchor.constraint(equalTo: titlebutton.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titlebutton.bottomAnchor, constant: -4),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4),

            rightTitleImageView.widthAnchor.constraint(equalToConstant: 16),
            rightTitleImageView.heightAnchor.constraint(equalToConstant: 16),
            rightTitleImageView.centerYAnchor.constraint(equalTo: titlebutton.centerYAnchor, constant: -1),
            rightTitleImageView.leadingAnchor.constraint(equalTo: titlebutton.trailingAnchor, constant: 4),
        ])
    }

    @objc private func navigateToDetailView() {
        guard let viewModel = viewModel else { return }
        AppState.shared.objectsContainer.navVM.appendThreadDetail(threadViewModel: viewModel)
    }

    public func updateTitleTo(_ title: String?) {
        UIView.animate(withDuration: 0.2) {
            self.titlebutton.setTitle(title, for: .normal)
        }
        updateThreadImage()
    }

    public func updateSubtitleTo(_ subtitle: String?) {
        let hide = subtitle == nil || subtitle?.isEmpty == true
        subtitleLabel.setIsHidden(hide)
        self.subtitleLabel.text = subtitle
        self.centerYTitleConstraint.constant = hide ? 0 : -8
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    public func updateImageTo(_ image: UIImage?) {
        UIView.transition(with: threadImageButton.imageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.threadImageButton.imageView.image = image
            if image == nil {
                Task { [weak self] in
                    await self?.setSplitedText()
                }
            }
        }
    }

    private func setSplitedText() async {
        let splitedText = String.splitedCharacter(self.viewModel?.thread.title ?? "")
        let bg = String.getMaterialColorByCharCode(str: self.viewModel?.thread.computedTitle ?? "")
        await MainActor.run {
            self.threadImageButton.layer.backgroundColor = bg.cgColor
            self.threadTitleSupplementary.text = splitedText
        }
    }

    private func registerObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] newValue in
                if newValue != .connected {
                    self?.updateSubtitleTo(newValue.stringValue.localized())
                } else {
                    self?.updateSubtitleTo(self?.viewModel?.getParticipantCount())
                }
            }
            .store(in: &cancellableSet)


        // Initial image from avatarVMS inside the thread
        let image = viewModel?.thread.image
        if let image = image, let imageViewModel = viewModel?.threadsViewModel?.avatars(for: image, metaData: nil, userName: nil) {
            self.imageLoader = imageViewModel
            
            // Set first time opening the thread image from cahced version inside avatarVMS
            let image = imageViewModel.image
            updateImageTo(image)
            
            // Observe for new changes
            self.imageLoader?.$image.sink { [weak self] newImage in
                guard let self = self else { return }
                updateImageTo(newImage)
            }
            .store(in: &cancellableSet)
        } else {
            Task {
                await setSplitedText()
            }
        }
    }

    private func updateThreadImage() {
        let newImage = viewModel?.thread.image
        if let newImage = newImage, imageLoader?.config.url != newImage {
            imageLoader?.updateCondig(config: .init(url: newImage))
            imageLoader?.fetch()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = threadImageButton.bounds
    }
}
