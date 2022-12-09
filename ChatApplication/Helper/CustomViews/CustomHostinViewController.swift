//
//  CustomUIHostinViewController.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI

class LocalStatusBarStyle { // style proxy to be stored in Environment
    fileprivate var getter: () -> UIStatusBarStyle = { .default }
    fileprivate var setter: (UIStatusBarStyle) -> Void = { _ in }

    var currentStyle: UIStatusBarStyle {
        get { getter() }
        set { setter(newValue) }
    }
}

// Custom Environment key, as it is set once, it can be accessed from anywhere
// of SwiftUI view hierarchy
struct LocalStatusBarStyleKey: EnvironmentKey {
    static let defaultValue: LocalStatusBarStyle = .init()
}

extension EnvironmentValues { // Environment key path variable
    var localStatusBarStyle: LocalStatusBarStyle {
        self[LocalStatusBarStyleKey.self]
    }
}

// Custom hosting controller that update status bar style
class CustomUIHostinViewController<Content>: UIHostingController<Content> where Content: View {
    private var internalStyle = UIStatusBarStyle.default

    @objc override open dynamic var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            internalStyle
        }
        set {
            internalStyle = newValue
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override init(rootView: Content) {
        super.init(rootView: rootView)

        LocalStatusBarStyleKey.defaultValue.getter = { self.preferredStatusBarStyle }
        LocalStatusBarStyleKey.defaultValue.setter = { self.preferredStatusBarStyle = $0 }
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
