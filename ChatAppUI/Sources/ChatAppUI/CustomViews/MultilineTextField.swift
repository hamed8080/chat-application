//
//  MultilineTextField.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI

private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    var textColor: Color
    @Binding var calculatedHeight: CGFloat
    var keyboardReturnType: UIReturnKeyType = .done
    var mention: Bool = false
    var onDone: ((String?) -> Void)?

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textField = UITextView()
        textField.delegate = context.coordinator

        textField.isEditable = true
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.isSelectable = true
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = false
        textField.backgroundColor = UIColor.clear
        textField.textColor = UIColor(cgColor: textColor.cgColor!)
        textField.returnKeyType = keyboardReturnType
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ uiView: UITextView, context _: UIViewRepresentableContext<UITextViewWrapper>) {
        if uiView.text != text {
            let attributes = NSMutableAttributedString(string: text)
            if mention {
                text.matches(char: "@")?.forEach { match in
                    attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: match.range)
                }
                uiView.attributedText = attributes
            } else {
                uiView.text = text
            }
            uiView.font = UIFont.systemFont(ofSize: 16)
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
    var textColor: Color?
    @Environment(\.colorScheme) var colorScheme
    var keyboardReturnType: UIReturnKeyType = .done
    var mention: Bool = false

    @Binding private var text: String
    private var internalText: Binding<String> {
        Binding {
            self.text
        } set: { newValue in
            self.text = newValue
            self.showingPlaceholder = newValue.isEmpty
        }
    }

    @State private var dynamicHeight: CGFloat = 64
    @State private var showingPlaceholder = false

    public init(_ placeholder: String = "",
         text: Binding<String>,
         textColor: Color? = nil,
         backgroundColor: Color = .white,
         keyboardReturnType: UIReturnKeyType = .done,
         mention: Bool = false,
         onDone: ((String?) -> Void)? = nil)
    {
        self.placeholder = placeholder
        self.onDone = onDone
        self.textColor = textColor
        _text = text
        self.backgroundColor = backgroundColor
        self.keyboardReturnType = keyboardReturnType
        self.mention = mention
        _showingPlaceholder = State<Bool>(initialValue: self.text.isEmpty)
    }

    public var body: some View {
        UITextViewWrapper(text: self.internalText,
                          textColor: textColor ?? (colorScheme == .dark ? Color.white : Color.black),
                          calculatedHeight: $dynamicHeight,
                          keyboardReturnType: keyboardReturnType,
                          mention: mention,
                          onDone: onDone)
            .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
            .background(placeholderView, alignment: .topLeading)
            .background(backgroundColor)
    }

    var placeholderView: some View {
        Group {
            if showingPlaceholder {
                Text(String(localized: .init(placeholder)))
                    .font(.iransansBody)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                    .padding(.top, 8)
            }
        }
    }
}

#if DEBUG
    struct MultilineTextField_Previews: PreviewProvider {
        static var test: String = "" // some very very very long description string to be initially wider than screen"
        static var testBinding = Binding<String>(get: { test }, set: {
//        print("New value: \($0)")
            test = $0
        })

        static var previews: some View {
            VStack(alignment: .leading) {
                Text("Description:")
                MultilineTextField("Enter some text here", text: testBinding, keyboardReturnType: .search, onDone: { _ in
                    print("Final text: \(test)")
                })
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black))
                Text("Something static here...")
                Spacer()
            }
//        .preferredColorScheme(.dark)
            .padding()
        }
    }
#endif
