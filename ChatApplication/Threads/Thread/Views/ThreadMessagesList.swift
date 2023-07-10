//
//  ThreadMessagesList.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import AdditiveUI
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ThreadMessagesList: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @State var scrollingUP = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ListLoadingView(isLoading: $viewModel.topLoading)
                        .id(-1)
                    ForEach(viewModel.messages) { message in
                        MessageRowFactory(viewModel: MessageRowViewModel(message: message, viewModel: viewModel))
                            .id(message.uniqueId)
                            .onAppear {
                                viewModel.onMessageAppear(message)
                            }
                    }
                    ListLoadingView(isLoading: $viewModel.bottomLoading)
                        .id(-2)
                }
                .background(
                    GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    }
                )
                .padding(.bottom)
                .padding([.leading, .trailing])
            }
            .overlay(alignment: .bottomTrailing) {
                MoveToBottomButton()
                    .offset(y: 48)
            }
            .safeAreaInset(edge: .top) {
                Spacer()
                    .frame(height: viewModel.thread.pinMessage != nil ? 48 : 0)
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: 96)
            }
            .background(background)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { originY in
                #if DEBUG
                    print("OriginY: \(originY)")
                #endif
                viewModel.setNewOrigin(newOriginY: originY)
            }
            .onAppear {
                viewModel.scrollProxy = scrollProxy
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var background: some View {
        Image("chat_bg")
            .resizable(resizingMode: .tile)
            .renderingMode(.template)
            .opacity(colorScheme == .dark ? 0.9 : 0.25)
            .colorInvert()
            .colorMultiply(colorScheme == .dark ? Color.white : Color.cyan)
            .overlay {
                let darkColors: [Color] = [.gray.opacity(0.5), .white.opacity(0.001)]
                let lightColors: [Color] = [.white.opacity(0.1), .gray.opacity(0.5)]
                LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? darkColors : lightColors),
                               startPoint: .top,
                               endPoint: .bottom)
            }
    }
}

struct ThreadMessagesList_Previews: PreviewProvider {
    struct Preview: View {
        @State var viewModel = ThreadViewModel(thread: Conversation())

        var body: some View {
            ThreadMessagesList()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.thread = Conversation(unreadCount: 1)
                    viewModel.objectWillChange.send()
                }
        }
    }

    static var previews: some View {
        Preview()
    }
}
