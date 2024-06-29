//
//  CustomMenu.swift
//  Talk
//
//  Created by hamed on 6/29/24.
//

import Foundation
import UIKit

public class ActionMenuItem: UIView {
    private let label = UILabel()
    private let imageView = UIImageView()
    private let separator = UIView()
    private let model: ActionItemModel
    private let action: () -> Void
    static let height: CGFloat = 36

    public init(model: ActionItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configureView() {
        backgroundColor = .clear

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = model.title
        label.textColor = model.color
        label.font = UIFont.uiiransansSubheadline
        addSubview(label)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: model.image ?? "")
        imageView.tintColor = model.color
        addSubview(imageView)

        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        addSubview(separator)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ActionMenuItem.height),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),

            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        addGestureRecognizer(tapGesture)
    }

    func removeSeparator() {
        separator.removeFromSuperview()
    }

    @objc private func onTapped(_ sender: UIGestureRecognizer) {
        action()
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.2
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
}

public struct ActionItemModel {
    let title: String
    let image: String?
    let color: UIColor

    public init(title: String, image: String?, color: UIColor = UIColor(named: "text_primary")!) {
        self.title = title.localized()
        self.image = image
        self.color = color
    }
}

public extension ActionItemModel {
    static let reply = ActionItemModel(title: "Messages.ActionMenu.reply", image:  "arrowshape.turn.up.left")
    static let replyPrivately = ActionItemModel(title: "Messages.ActionMenu.replyPrivately", image: "arrowshape.turn.up.left")
    static let forward = ActionItemModel(title: "Messages.ActionMenu.forward", image: "arrowshape.turn.up.right")
    static let edit = ActionItemModel(title: "General.edit", image: "pencil.circle")
    static let add = ActionItemModel(title: "General.addText", image: "pencil.circle")
    static let seenParticipants = ActionItemModel(title: "SeenParticipants.title", image: "info.bubble")
    static let saveImage = ActionItemModel(title: "Messages.ActionMenu.saveImage", image: "square.and.arrow.down")
    static let saveVideo = ActionItemModel(title: "Messages.ActionMenu.saveImage", image: "square.and.arrow.down")
    static let copy = ActionItemModel(title: "Messages.ActionMenu.copy", image: "doc.on.doc")
    static let deleteCache = ActionItemModel(title: "Messages.ActionMenu.deleteCache", image: "cylinder.split.1x2")
    static let pin = ActionItemModel(title: "Messages.ActionMenu.pinMessage", image: "pin")
    static let unpin = ActionItemModel(title: "Messages.ActionMenu.unpinMessage", image: "pin.slash")
    static let select = ActionItemModel(title: "General.select", image: "checkmark.circle")
    static let delete = ActionItemModel(title: "General.delete", image: "trash", color: .red)
}

public class CustomMenu: UIStackView {

    init() {
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configureView() {
        axis = .vertical
        spacing = 0
        alignment = .fill
        distribution = .fillEqually
        layer.cornerRadius = 8
        layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func addItem(_ item: ActionMenuItem) {
        addArrangedSubview(item)
    }

    public func addItems(_ children: [ActionMenuItem] ) {
        addArrangedSubviews(children)
    }

    public func removeLastSeparator() {
        (subviews.last as? ActionMenuItem)?.removeSeparator()
    }

    public func height() -> CGFloat {
        CGFloat(subviews.count) * ActionMenuItem.height
    }
}
