//
//  ThreadListSearchBarFilterView.swift
//  Talk
//
//  Created by hamed on 12/13/23.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct ThreadListSearchBarFilterView: View {
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
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.clear)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                Menu {
                    ForEach(SearchParticipantType.allCases.filter({ $0 != .admin })) { item in
                        Button {
                            withAnimation {
                                viewModel.searchType = item
                            }
                        } label: {
                            Text(String(localized: .init(item.rawValue)))
                                .font(.iransansBoldCaption3)
                        }
                    }
                } label: {
                    HStack {
                        Text(String(localized: .init(viewModel.searchType.rawValue)))
                            .font(.iransansBoldCaption3)
                            .foregroundColor(Color.App.hint)
                        Image(systemName: "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 8, height: 12)
                            .fontWeight(.medium)
                            .foregroundColor(Color.App.hint)
                    }
                }
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
