//
//  FooterView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import UIKit

final class FooterView: UIStackView {
    private let pinImage = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let timelabel = UILabel()
    private let editedLabel = UILabel()
    private let statusImage = UIImageView()
    private static let staticEditString = "Messages.Footer.edited".localized()

    private var shapeLayer = CAShapeLayer()
    private var rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        spacing = 4
        axis = .horizontal
        alignment = .firstBaseline
        layoutMargins = .init(top: 12, left: 2, bottom: 4, right: 2)
        isLayoutMarginsRelativeArrangement = true

        statusImage.translatesAutoresizingMaskIntoConstraints = false
        statusImage.translatesAutoresizingMaskIntoConstraints = false
        pinImage.translatesAutoresizingMaskIntoConstraints = false
        pinImage.translatesAutoresizingMaskIntoConstraints = false

        timelabel.font = UIFont.uiiransansBoldCaption2
        timelabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.5)
        editedLabel.font = UIFont.uiiransansCaption2
        editedLabel.textColor = Color.App.textSecondaryUIColor
        editedLabel.text = FooterView.staticEditString
        pinImage.tintColor = Color.App.accentUIColor
        statusImage.contentMode = .scaleAspectFit
        pinImage.contentMode = .scaleAspectFit

        addArrangedSubview(pinImage)
        addArrangedSubview(statusImage)
        addArrangedSubview(timelabel)
        addArrangedSubview(editedLabel)

        NSLayoutConstraint.activate([
            statusImage.widthAnchor.constraint(equalToConstant: 16),
            statusImage.heightAnchor.constraint(equalToConstant: 16),
            pinImage.widthAnchor.constraint(equalToConstant: 12),
            pinImage.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let message = viewModel.message
        let thread = viewModel.threadVM?.thread
        let isPin = message.id != nil && message.id == thread?.pinMessage?.id
        statusImage.image = message.uiFooterStatus.image
        statusImage.tintColor = message.uiFooterStatus.fgColor
        statusImage.setIsHidden(!viewModel.calMessage.isMe)
        timelabel.text = viewModel.calMessage.timeString
        editedLabel.setIsHidden(viewModel.message.edited != true)
        pinImage.setIsHidden(!isPin)
        let isSelfThread = thread?.type == .selfThread
        let isDelivered = message.id != nil
        if isDelivered, isSelfThread {
            statusImage.setIsHidden(false)
        } else if viewModel.calMessage.isMe, !isSelfThread {
            statusImage.setIsHidden(false)
        }

        if message is UploadProtocol {
            startSendingAnimation()
        } else {
            stopSendingAnimation()
        }
    }

    public func pinChanged(isPin: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.pinImage.alpha = isPin ? 1.0 : 0.0
            self.pinImage.setIsHidden(!isPin)
        }
    }

    public func seen(image: UIImage?) {
        UIView.transition(with: statusImage, duration: 0.2, options: .transitionCrossDissolve) {
            self.statusImage.image = image
            self.statusImage.setIsHidden(image == nil)
        }
    }

    private func startSendingAnimation() {

        rotateAnimation.repeatCount = .greatestFiniteMagnitude
        rotateAnimation.isCumulative = true
        rotateAnimation.toValue = 2 * CGFloat.pi
        rotateAnimation.duration = 1.5
        rotateAnimation.fillMode = .forwards

        statusImage.layer.add(rotateAnimation, forKey: "rotationAnimation")
    }

    private func stopSendingAnimation() {
        statusImage.layer.removeAllAnimations()
    }
}
