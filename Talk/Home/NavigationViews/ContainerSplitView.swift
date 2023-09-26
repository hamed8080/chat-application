//
//  ContainerSplitView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkViewModels
import ChatModels

struct PreferenceNavigationValue: Hashable {}
struct AssistantNavigationValue: Hashable {}
struct LogNavigationValue: Hashable {}
struct BlockedContactsNavigationValue: Hashable {}

struct ContainerSplitView<SidebarView: View>: View {
    let sidebarView: SidebarView
    @Environment(\.horizontalSizeClass) var sizeClass
    let container: ObjectsContainer

    var body: some View {
        if sizeClass == .regular, UIDevice.current.userInterfaceIdiom == .pad {
            iPadStackContentView(sidebarView: sidebarView, container: container)
                .environmentObject(container.navVM)
        } else {
            iPhoneStackContentView(sidebarView: sidebarView, container: container)
                .environmentObject(container.navVM)
        }
    }
}

struct iPadStackContentView<Content: View>: View {
    let sidebarView: Content
    @EnvironmentObject var navVM: NavigationModel
    let container: ObjectsContainer
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var showSideBar: Bool = true
    let ipadSidebarWidth: CGFloat = 400
    let isIpad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    var maxWidth: CGFloat { sizeClass == .compact || !isIpad ? .infinity : ipadSidebarWidth }
    var maxComputed: CGFloat { min(maxWidth, ipadSidebarWidth) }

    var body: some View {
        HStack(spacing: 0) {
            sidebarView
                .frame(width: showSideBar ? maxComputed : 0)

            NavigationStack(path: $navVM.paths) {
                NothingHasBeenSelectedView(threadsVM: container.threadsVM)
                    .navigationDestination(for: Contact.self) { value in
                        Text(value.firstName ?? "")
                            .environmentObject(container.appOverlayVM)
                    }
                    .navigationDestination(for: PreferenceNavigationValue.self) { value in
                        PreferenceView()
                            .environmentObject(container.appOverlayVM)
                    }
                    .navigationDestination(for: Conversation.self) { thread in
                        if let viewModel = navVM.threadViewModel(threadId: thread.id ?? 0) {
                            ThreadView()
                                .environmentObject(container.appOverlayVM)
                                .environmentObject(viewModel)
                        }
                    }
                    .navigationDestination(for: DetailViewModel.self) { viewModel in
                        DetailView()
                            .environmentObject(container.appOverlayVM)
                            .environmentObject(viewModel)
                            .environmentObject(container.threadsVM)
                            .environmentObject(container.navVM.currentThreadVM!)
                    }
                    .navigationDestination(for: AssistantNavigationValue.self) { _ in
                        AssistantView()
                            .environmentObject(container.appOverlayVM)
                    }
                    .navigationDestination(for: LogNavigationValue.self) { _ in
                        LogView()
                            .environmentObject(container.appOverlayVM)
                    }
                    .navigationDestination(for: BlockedContactsNavigationValue.self) { _ in
                        BlockedContacts()
                            .environmentObject(container.appOverlayVM)
                    }
            }
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: showSideBar)
            .environment(\.layoutDirection, .leftToRight)
            .onReceive(NotificationCenter.default.publisher(for: .closeSideBar)) { newVlaue in
                showSideBar.toggle()
            }
            .onReceive(navVM.$paths) { newValue in
                if UIDevice.current.userInterfaceIdiom == .pad, newValue.count == 0 {
                    showSideBar = true
                }
            }
        }
    }
}

struct iPhoneStackContentView<Content: View>: View {
    let sidebarView: Content
    @EnvironmentObject var navVM: NavigationModel
    let container: ObjectsContainer

    var body: some View {
        NavigationStack(path: $navVM.paths) {
            sidebarView
                .navigationDestination(for: Contact.self) { value in
                    Text(value.firstName ?? "")
                }
                .navigationDestination(for: Conversation.self) { thread in
                    if let viewModel = navVM.threadViewModel(threadId: thread.id ?? 0) {
                        ThreadView()
                            .environmentObject(container.appOverlayVM)
                            .environmentObject(viewModel)
                    }
                }
                .navigationDestination(for: DetailViewModel.self) { viewModel in
                    DetailView()
                        .environmentObject(container.appOverlayVM)
                        .environmentObject(viewModel)
                        .environmentObject(container.threadsVM)
                        .environmentObject(container.navVM.currentThreadVM!)
                }
                .navigationDestination(for: PreferenceNavigationValue.self) { value in
                    PreferenceView()
                        .environmentObject(container.appOverlayVM)
                }
                .navigationDestination(for: AssistantNavigationValue.self) { _ in
                    AssistantView()
                        .environmentObject(container.appOverlayVM)
                }
                .navigationDestination(for: LogNavigationValue.self) { _ in
                    LogView()
                        .environmentObject(container.appOverlayVM)
                }
                .navigationDestination(for: BlockedContactsNavigationValue.self) { _ in
                    BlockedContacts()
                        .environmentObject(container.appOverlayVM)
                }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct ContainerSplitView_Previews: PreviewProvider {

    struct Preview: View {
        @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)

        var body: some View {
            ContainerSplitView(sidebarView: Image("gear"), container: container)
        }
    }

    static var previews: some View {
        Preview()
    }
}
