//
//  ExpandHeaderView.swift
//  Talk
//
//  Created by hamed on 4/3/24.
//

import UIKit
import TalkViewModels
import SwiftUI

public final class ExpandHeaderView: UIStackView {
    private let label = UILabel()
    private let btnClear = UIButton(type: .system)
    private let imageView = UIImageView()
    private let viewModel: ThreadViewModel

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4
        layoutMargins = .init(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor
        alignment = .center

        label.font = UIFont.uiiransansBoldBody

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Color.App.textSecondaryUIColor

        btnClear.setTitle("General.cancel".localized(), for: .normal)
        btnClear.titleLabel?.font = UIFont.uiiransansCaption
        btnClear.titleLabel?.textColor = Color.App.redUIColor

        addArrangedSubview(label)
        addArrangedSubview(btnClear)
        addArrangedSubview(imageView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 36),
            imageView.widthAnchor.constraint(equalToConstant: 12),
            imageView.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    public func set() {
        let localized = String(localized: .init("Thread.sendAttachments"))
        let value = viewModel.attachmentsViewModel.attachments.count.formatted(.number)
        label.text = String(format: localized, "\(value)")
        imageView.image = UIImage(systemName: viewModel.attachmentsViewModel.isExpanded ? "chevron.down" : "chevron.up")
    }

    private func expandTapped(_ sender: UIView) {
        viewModel.attachmentsViewModel.isExpanded.toggle()
    }

    private func clearTapped(_ sender: UIButton) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)) {
            viewModel.attachmentsViewModel.clear()
//            viewModel.animateObjectWillChange()
        }
    }
}
