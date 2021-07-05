//
//  LogCell.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/3/21.
//

import Foundation
import UIKit
import FanapPodChatSDK

public class LogCell:UITableViewCell{
    
    @IBOutlet weak var myContentView: UIView!
    let sendColor = UIColor.init(red: 108 / 255 , green: 255 / 255, blue: 107 / 255, alpha: 0.25)
    let receiveColor = UIColor.init(red: 255 / 255, green: 126 / 255, blue: 28 / 255, alpha: 0.25)
    
    @IBOutlet weak var tvHeighConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tvLog: UITextView!
    public var logResult:LogResult?{
        didSet{
            tvLog.text = logResult?.json.removeBackSlashes()
               
            tvHeighConstraint.constant = tvLog.sizeThatFits(CGSize(width: contentView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            let receive = logResult?.receive == true
            myContentView.backgroundColor = receive ? receiveColor : sendColor
        }
    }
}
