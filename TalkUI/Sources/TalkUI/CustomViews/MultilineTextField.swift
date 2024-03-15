//
//  MultilineTextField.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI

private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    var textColor: UIColor
    @Binding var calculatedHeight: CGFloat
    @Binding var focus: Bool
    var keyboardReturnType: UIReturnKeyType = .done
    var mention: Bool = false
    var onDone: ((String?) -> Void)?

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textField = UITextView()
        textField.delegate = context.coordinator

        textField.isEditable = true
        textField.font = UIFont(name: "IRANSansX", size: 16)
        textField.isSelectable = true
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = true
        textField.backgroundColor = UIColor.clear
        textField.textColor = textColor
        textField.returnKeyType = keyboardReturnType
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ uiView: UITextView, context _: UIViewRepresentableContext<UITextViewWrapper>) {
        if uiView.text != text {
            let attributes = NSMutableAttributedString(string: text)
            if mention {
                text.matches(char: "@")?.forEach { match in
                    attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "blue") ?? .blue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: match.range)
                }
                uiView.attributedText = attributes
            } else {
                uiView.text = text
            }
            uiView.font = UIFont(name: "IRANSansX", size: 16)
            uiView.textColor = textColor
        }
        if focus {
            uiView.becomeFirstResponder()
        }
        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height // !! must be called asynchronously
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $calculatedHeight, onDone: onDone)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var calculatedHeight: Binding<CGFloat>
        var onDone: ((String?) -> Void)?

        init(text: Binding<String>, height: Binding<CGFloat>, onDone: ((String?) -> Void)? = nil) {
            self.text = text
            calculatedHeight = height
            self.onDone = onDone
        }

        func textViewDidChange(_ uiView: UITextView) {
            text.wrappedValue = uiView.text
            UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn _: NSRange, replacementText text: String) -> Bool {
            if let onDone = onDone, text == "\n" {
                textView.resignFirstResponder()
                onDone(textView.text)
                return false
            }
            return true
        }
    }
}

public struct MultilineTextField: View {
    private var placeholder: String
    private var onDone: ((String?) -> Void)?
    var backgroundColor: Color = .white
    var placeholderColor: Color = Color.App.textPlaceholder
    var textColor: UIColor?
    @Environment(\.colorScheme) var colorScheme
    var keyboardReturnType: UIReturnKeyType = .done
    var mention: Bool = false

    @Binding private var text: String
    @Binding private var focus: Bool
    @State private var dynamicHeight: CGFloat = 64
    @State private var showingPlaceholder = false

    public init(_ placeholder: String = "",
         text: Binding<String>,
         textColor: UIColor? = nil,
         backgroundColor: Color = Color.App.white,
         placeholderColor: Color = Color.App.textPlaceholder,
         keyboardReturnType: UIReturnKeyType = .done,
         mention: Bool = false,
         focus: Binding<Bool> = .constant(false),
         onDone: ((String?) -> Void)? = nil)
    {
        self.placeholder = placeholder
        self.onDone = onDone
        self.textColor = textColor
        _text = text
        self.backgroundColor = backgroundColor
        self.keyboardReturnType = keyboardReturnType
        self.mention = mention
        self._focus = focus
        self.placeholderColor = placeholderColor
        let canShowPlaceHolder = text.wrappedValue.isEmpty || (text.wrappedValue.first == "\u{200f}" && text.wrappedValue.count == 1)
        _showingPlaceholder = State<Bool>(initialValue: canShowPlaceHolder)
    }

    public var body: some View {
        UITextViewWrapper(text: $text,
                          textColor: textColor ?? (colorScheme == .dark ? UIColor(named: "white") ?? .white : UIColor(named: "black") ?? .black),
                          calculatedHeight: $dynamicHeight,
                          focus: $focus,
                          keyboardReturnType: keyboardReturnType,
                          mention: mention,
                          onDone: onDone)
            .frame(minHeight: min(64, dynamicHeight), maxHeight: min(256, dynamicHeight))
            .background(placeholderView, alignment: .topLeading)
            .background(backgroundColor)
            .onChange(of: text) { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingPlaceholder = newValue.isEmpty || (newValue.first == "\u{200f}" && newValue.count == 1)
                }
            }
    }

    var placeholderView: some View {
        Group {
            if showingPlaceholder {
                Text(String(localized: .init(placeholder)))
                    .font(.iransansBody)
                    .foregroundColor(placeholderColor)
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 0))
                    .transition(.asymmetric(insertion: .push(from: .leading), removal: .move(edge: .leading)))
            }
        }
    }
}

#if DEBUG
    struct MultilineTextField_Previews: PreviewProvider {
        static var test: String = "" // some very very very long description string to be initially wider than screen"
        static var testBinding = Binding<String>(get: { test }, set: {
            test = $0
        })

        static var previews: some View {
            VStack(alignment: .leading) {
                Text("Description:")
                MultilineTextField("Enter some text here", text: testBinding, keyboardReturnType: .search, onDone: { _ in
                })
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.App.textPrimary))
                Text("Something static here...")
                Spacer()
            }
//        .preferredColorScheme(.dark)
            .padding()
        }
    }
#endif
