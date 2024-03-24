//
//  ThreadBottomToolbar.swift
//  Talk
//
//  Created by hamed on 3/24/24.
//

import Foundation
import UIKit
import TalkViewModels

public final class ThreadBottomToolbar: UIStackView {
    private let mainSendButtons: MainSendButtons

    public init(viewModel: ThreadViewModel) {
        self.mainSendButtons = MainSendButtons(viewModel: viewModel)
        super.init(frame: .zero)
        configureViews()
    }
    
    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.layer.masksToBounds = true
        effectView.layer.cornerRadius = 8
        addSubview(effectView)

        mainSendButtons.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainSendButtons)

        backgroundColor = .red 

        NSLayoutConstraint.activate([
            mainSendButtons.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainSendButtons.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainSendButtons.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
            heightAnchor.constraint(lessThanOrEqualToConstant: 256),
            heightAnchor.constraint(equalToConstant: 64),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
