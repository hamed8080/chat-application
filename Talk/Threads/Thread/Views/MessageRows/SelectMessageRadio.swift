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
        translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "circle")
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        let iconColor = UIColor.gray
        let fillColor = UIColor.clear
        let config = UIImage.SymbolConfiguration(paletteColors: [iconColor, fillColor])
        imageView.image = UIImage(systemName: "circle", withConfiguration: config)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 48),
            heightAnchor.constraint(equalToConstant: 48),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    public func set(selected: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            let iconColor = (selected ? Color.App.whiteUIColor : UIColor.gray) ?? .clear
            let fillColor = (selected ? Color.App.accentUIColor : UIColor.clear) ?? .clear
            let config = UIImage.SymbolConfiguration(paletteColors: [iconColor, fillColor])
            self?.imageView.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle", withConfiguration: config)
        }
    }
}
