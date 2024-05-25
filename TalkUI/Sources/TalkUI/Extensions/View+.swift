//
//  View+.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 12/12/21.
//

import SwiftUI
import TalkModels

extension View {
    @ViewBuilder
    func compatibleConfirmationDialog(_ isPresented: Binding<Bool>, message: String? = nil, title: String? = nil, _ buttons: [DialogButton]) -> some View {
        if #available(iOS 15, *) {
            self.confirmationDialog(title ?? "", isPresented: isPresented, titleVisibility: (title?.isEmpty ?? false) ? .hidden : .visible) {
                ForEach(buttons) { button in
                    Button {
                        withAnimation {
                            button.action()
                        }
                    } label: {
                        Text(button.title)
                    }
                }
            }
        } else {
            actionSheet(isPresented: isPresented) {
                let alertButtons = buttons.map { Alert.Button.default(Text($0.title), action: $0.action) }
                return ActionSheet(title: Text(title ?? ""), message: Text(message ?? ""), buttons: alertButtons)
            }
        }
    }
}

struct DialogButton: Hashable, Identifiable {
    static func == (lhs: DialogButton, rhs: DialogButton) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var title: String
    var action: () -> Void
    var id = UUID().uuidString
}

public extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { view in
            addArrangedSubview(view)
        }
    }
}

public extension Text {
    init(_ key: String) {
        self.init(.init(key), tableName: nil, bundle: Language.preferedBundle, comment: "")
    }
}
