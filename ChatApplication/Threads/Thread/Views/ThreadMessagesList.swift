//
//  ThreadMessagesList.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import AdditiveUI
import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct ThreadMessagesList: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @State var scrollingUP = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ListLoadingView(isLoading: $viewModel.isLoading)
                        .id(-1)
                    ForEach(viewModel.messages) { message in
                        MessageRowFactory(message: message)
                            .id(message.uniqueId)
                            .onAppear {
                                viewModel.lastVisibleUniqueId = message.uniqueId
                                viewModel.sendSeenMessageIfNeeded(message)
                            }
                    }
                    ListLoadingView(isLoading: $viewModel.isLoading)
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
//            .animation(.easeInOut, value: viewModel.messages.count)
            .animation(.easeInOut, value: viewModel.isLoading)
            .animation(.easeInOut, value: viewModel.sheetType)
            .animation(.easeInOut, value: viewModel.isInEditMode)
            .animation(.easeInOut, value: viewModel.selectedMessages.count)
            .overlay(alignment: .bottomTrailing) {
                moveToBottomButton
                    .offset(y: 48)
            }
            .safeAreaInset(edge: .top) {
                Spacer()
                    .frame(height: viewModel.thread?.pinMessage != nil ? 48 : 0)
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
                if originY < 72, viewModel.scrollingUP {
                    viewModel.getMoreTopHistory()
                }
            }
            .onAppear {
                viewModel.scrollProxy = scrollProxy
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var moveToBottomButton: some View {
        Button {
            viewModel.scrollToBottom()
        } label: {
            Image(systemName: "chevron.down")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding()
                .foregroundColor(Color.gray)
                .aspectRatio(contentMode: .fit)
                .contentShape(Rectangle())
        }
        .frame(width: 36, height: 36)
        .background(Color.white)
        .cornerRadius(36)
        .padding(.bottom, 16)
        .padding([.trailing], 8)
        .scaleEffect(x: viewModel.isAtBottomOfTheList ? 0.0 : 1.0, y: viewModel.isAtBottomOfTheList ? 0.0 : 1.0, anchor: .center)
        .overlay(alignment: .top) {
            let unreadCount = viewModel.thread?.unreadCount ?? 0
            let hide = unreadCount == 0
            Text(verbatim: unreadCount == 0 ? "" : "\(unreadCount)")
                .font(.system(size: 12))
                .fontDesign(.rounded)
                .padding(4)
                .frame(height: hide ? 0 : 18)
                .background(Color.textBlueColor)
                .foregroundColor(.white)
                .cornerRadius(hide ? 0 : 16)
                .offset(x: -2, y: -12)
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
    static var previews: some View {
        ThreadMessagesList()
            .environmentObject(ThreadViewModel())
    }
}
