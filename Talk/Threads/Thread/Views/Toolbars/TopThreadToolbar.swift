//
//  TopThreadToolbar.swift
//  Talk
//
//  Created by hamed on 3/25/24.
//

import Foundation
import UIKit
import TalkViewModels

public final class TopThreadToolbar: UIStackView {
    private var pinMessageView: ThreadPinMessageView!
    
    init(viewModel: ThreadViewModel) {
        self.pinMessageView = .init(viewModel: viewModel.threadPinMessageViewModel)
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

        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(effectView)

        NSLayoutConstraint.activate([
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        configurePinMessageView()
    }

    private func configurePinMessageView() {
        addArrangedSubview(pinMessageView)
    }
}
