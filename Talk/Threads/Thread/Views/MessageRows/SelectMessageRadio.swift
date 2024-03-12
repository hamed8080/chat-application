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

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 48),
            heightAnchor.constraint(equalToConstant: 48),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
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
        widthAnchor.constraint(equalToConstant: canShow ? 48 : 0 ).isActive = true
        heightAnchor.constraint(equalToConstant: canShow ? 48 : 0 ).isActive = true
    }
}
