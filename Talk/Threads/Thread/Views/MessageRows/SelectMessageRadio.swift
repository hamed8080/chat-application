//
//  SelectMessageRadio.swift
//  Talk
//
//  Created by hamed on 3/12/24.
//

import Foundation
import UIKit
import TalkViewModels
import SwiftUI

public final class SelectMessageRadio: UIView {
    private let imageView = UIImageView()
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        widthConstraint = widthAnchor.constraint(equalToConstant: 48)
        heightConstraint = heightAnchor.constraint(equalToConstant: 48)

        NSLayoutConstraint.activate([
            widthConstraint!,
            heightConstraint!,
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let isSelected = viewModel.isSelected
        let iconColor = (isSelected ? Color.App.whiteUIColor : UIColor.gray) ?? .clear
        let fillColor = (isSelected ? Color.App.accentUIColor : UIColor.clear) ?? .clear
        let config = UIImage.SymbolConfiguration(paletteColors: [iconColor, fillColor])
        imageView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle", withConfiguration: config)

        let canShow = viewModel.isInSelectMode
        isHidden = !canShow
        widthConstraint?.constant = canShow ? 48 : 0
        heightConstraint?.constant = canShow ? 48 : 0
    }
}
