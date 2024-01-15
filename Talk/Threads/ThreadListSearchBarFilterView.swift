//
//  ThreadListSearchBarFilterView.swift
//  Talk
//
//  Created by hamed on 12/13/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import ActionableContextMenu
import TalkUI

struct ThreadListSearchBarFilterView: View {
    @State private var showPopover = false
    @Binding var isInSearchMode: Bool
    @EnvironmentObject var viewModel: ThreadsSearchViewModel
    enum Field: Hashable {
        case saerch
    }
    @FocusState var searchFocus: Field?

    var body: some View {
        HStack {
            if isInSearchMode {
                TextField(String(localized: String.LocalizationValue("General.searchHere")), text: $viewModel.searchText)
                    .font(.iransansBody)
                    .textFieldStyle(.clear)
                    .focused($searchFocus, equals: .saerch)
                    .frame(minWidth: 0, maxWidth: nil, minHeight: 0, maxHeight: 38)
                    .clipped()
                    .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top).combined(with: .opacity)))
                    .foregroundStyle(viewModel.searchText.count == 0 ? Color.App.textPrimary.opacity(0.7) : Color.App.textPrimary)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.clear)
                            .background(Color.App.bgSendInput.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

//                Button {
//                    showPopover.toggle()
//                } label: {
//                    HStack {
//                        Text(String(localized: .init(viewModel.searchType.rawValue)))
//                            .font(.iransansBoldCaption3)
//                            .foregroundColor(Color.App.textSecondary)
//                        Image(systemName: "chevron.down")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 8, height: 12)
//                            .fontWeight(.medium)
//                            .foregroundColor(Color.App.textSecondary)
//                    }
//                }
//                .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
//                    VStack(alignment: .leading, spacing: 0) {
//                        ForEach(SearchParticipantType.allCases.filter({ $0 != .admin })) { item in
//                            ContextMenuButton(title: String(localized: .init(item.rawValue)), image: "") {
//                                withAnimation {
//                                    showPopover.toggle()
//                                    viewModel.searchType = item
//                                }
//                            }
//                        }
//                    }
//                    .foregroundColor(.primary)
//                    .frame(width: 196)
//                    .background(MixMaterialBackground())
//                    .clipShape(RoundedRectangle(cornerRadius:((12))))
//                    .presentationCompactAdaptation(horizontal: .popover, vertical: .popover)
//                }
            }
        }
        .animation(.easeInOut.speed(2), value: isInSearchMode)
        .padding(EdgeInsets(top: isInSearchMode ? 4 : 0, leading: 4, bottom: isInSearchMode ? 6 : 0, trailing: 4))
        .onChange(of: viewModel.searchText) { newValue in
            AppState.shared.objectsContainer.contactsVM.searchContactString = newValue
            viewModel.searchText = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .forceSearch)) { newValue in
            if newValue.object as? String == "Tab.chats" {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    isInSearchMode.toggle()
                    searchFocus = .saerch
                }
            }
        }
    }
}

struct ThreadListSearchBarFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListSearchBarFilterView(isInSearchMode: .constant(true))
    }
}
