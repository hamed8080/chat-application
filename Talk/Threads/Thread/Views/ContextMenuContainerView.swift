//
//  ContextMenuContainerView.swift
//  Talk
//
//  Created by hamed on 6/28/24.
//

import Foundation
import UIKit

class ContextMenuContainerView: UIView {
    private weak var vc: UIViewController?
    private let scrollView: UIScrollView

    init(viewController: UIViewController) {
        let frame = viewController.navigationController?.view.frame ?? .zero
        vc = viewController
        self.scrollView = UITableView(frame: frame)
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func setupView() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = bounds
        addSubview(effectView)
        self.isHidden = true
        alpha = 0.0
        isUserInteractionEnabled = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hide))
        scrollView.addGestureRecognizer(tapGesture)
        scrollView.backgroundColor = .clear
        addSubview(scrollView)
    }

    public func setContentView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.widthAnchor.constraint(equalTo: widthAnchor),
            view.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    public func show() {
        self.vc?.view.addSubview(self)
        isUserInteractionEnabled = true
        self.isHidden = false
        alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        } completion: { compelted in
            self.isHidden = false
        }
    }

    @objc public func hide() {
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0.0
        } completion: { completed in
            if completed {
                self.isHidden = true
                self.scrollView.subviews.forEach { subview in
                    subview.removeFromSuperview()
                }
                self.removeFromSuperview()
            }
        }
    }
}
