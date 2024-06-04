//
//  PartnerMessageCell.swift
//  Talk
//
//  Created by hamed on 6/6/24.
//

import Foundation
import UIKit
import TalkModels

public final class PartnerMessageCell: MessageBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let isRTL = Language.isRTL
        if isRTL {
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
        } else {
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
