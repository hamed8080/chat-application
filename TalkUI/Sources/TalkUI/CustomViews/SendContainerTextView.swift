//
//  SendContainerTextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI
import UIKit

public final class SendContainerTextView: UITextView, UITextViewDelegate {
    public var mention: Bool = false
    public var onTextChanged: ((String?) -> Void)?
    public var onDone: ((String?) -> Void)?
    private let placeholderLabel = UILabel()
    private var heightConstraint: NSLayoutConstraint!
    private let initSize: CGFloat = 42

    public init() {
        super.init(frame: .zero, textContainer: nil)
        configureView()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureView() {
        translatesAutoresizingMaskIntoConstraints = true
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Locale.current.identifier.contains("fa") ? .forceRightToLeft : .forceLeftToRight
        textContainerInset = .init(top: 12, left: 0, bottom: 0, right: 0)
        delegate = self
        isEditable = true
        font = UIFont(name: "IRANSansX", size: 16)
        isSelectable = true
        isUserInteractionEnabled = true
        isScrollEnabled = true
        backgroundColor = Color.App.bgSendInputUIColor
        textColor = UIColor(named: "text_primary")
        returnKeyType = .done
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        placeholderLabel.text = "Thread.SendContainer.typeMessageHere".localized()
        placeholderLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        placeholderLabel.font = UIFont.uiiransansBody
        placeholderLabel.textAlignment = .left
        placeholderLabel.isUserInteractionEnabled = false
        addSubview(placeholderLabel)
        heightConstraint = heightAnchor.constraint(equalToConstant: initSize)

        NSLayoutConstraint.activate([
            heightConstraint,
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func recalculateHeight() {
        let fittedSize = sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        let minValue: CGFloat = initSize
        let maxValue: CGFloat = 192
        let newSize = min(max(fittedSize, minValue), maxValue)
        if frame.size.height != newSize {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.heightConstraint.constant = newSize // !! must be called asynchronously
                }
            }
        }
    }

    public func textViewDidChange(_ uiView: UITextView) {
        if uiView.text != text {
            let attributes = NSMutableAttributedString(string: text)
            text.matches(char: "@")?.forEach { match in
                attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "blue") ?? .blue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: match.range)
            }
            uiView.attributedText = attributes
        }
        recalculateHeight()
        onTextChanged?(text)
        placeholderLabel.isHidden = !isEmptyText()
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn _: NSRange, replacementText text: String) -> Bool {
        if let onDone = onDone, text == "\n" {
            textView.resignFirstResponder()
            onDone(textView.text)
            return false
        }
        return true
    }

//    text.wrappedValue.isEmpty || (text.wrappedValue.first == "\u{200f}" && text.wrappedValue.count == 1)
    private func isEmptyText() -> Bool {
        let isRTLChar = text.count == 1 && text.first == "\u{200f}"
        return text.isEmpty || isRTLChar
    }

    public func hidePlaceholder() {
        placeholderLabel.isHidden = true
    }
}

#if DEBUG
    struct SendContainerTextViewWrapper: UIViewRepresentable {
        func makeUIView(context: Context) -> some UIView {
            return SendContainerTextView()
        }

        func updateUIView(_ uiView: UIViewType, context: Context) {

        }
    }

    struct SendContainerTextView_Previews: PreviewProvider {
        static var test: String = "" // some very very very long description string to be initially wider than screen"
        static var testBinding = Binding<String>(get: { test }, set: {
            test = $0
        })

        static var previews: some View {
            VStack(alignment: .leading) {
                Text("Description:")
                SendContainerTextViewWrapper()
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.App.textPrimary))
                Text("Something static here...")
                Spacer()
            }
//        .preferredColorScheme(.dark)
            .padding()
        }
    }
#endif
