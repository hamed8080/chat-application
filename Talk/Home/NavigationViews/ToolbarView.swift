//
//  ToolbarView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import AdditiveUI

struct ToolbarView<LeadingContentView: View, CenterContentView: View, TrailingContentView: View>: View {
    @ViewBuilder let leadingNavigationViews: LeadingContentView?
    @ViewBuilder let centerNavigationViews: CenterContentView?
    @ViewBuilder let trailingNavigationViews: TrailingContentView?
    var searchCompletion: ((String) -> ())?
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var ipadSidebarWidth: CGFloat = 400
    let title: String?
    let searchPlaceholder: String?
    var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    var maxWidth: CGFloat { sizeClass == .compact || !isIpad ? .infinity : ipadSidebarWidth }
    @State var searchText: String = ""
    @State var isInSearchMode: Bool = false
    let toolbarHeight: CGFloat = 36

    enum Field: Hashable {
        case saerch
    }

    @FocusState var searchFocus: Field?

    init(title: String? = nil,
         searchPlaceholder: String? = nil,
         leadingViews:  LeadingContentView? = nil,
         centerViews: CenterContentView? = nil,
         trailingViews: TrailingContentView? = nil,
         searchCompletion: ((String) -> ())? = nil
    ) {
        self.title = title
        self.searchPlaceholder = searchPlaceholder
        self.searchCompletion = searchCompletion
        self.leadingNavigationViews = leadingViews
        self.centerNavigationViews = centerViews
        self.trailingNavigationViews = trailingViews
    }

    var body: some View {
        HStack(spacing: isInSearchMode ? 0 : 8) {
            toolbars
        }
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: isInSearchMode)
        .frame(minWidth: 0, maxWidth: sizeClass == .compact ? nil : maxWidth)
        .padding([.bottom, .top], 8)
        .padding([.leading, .trailing], 8)
        .background(.ultraThinMaterial)
        .onChange(of: searchText) { newValue in
            searchCompletion?(newValue)
        }
        .overlay(alignment: .center) {
            VStack(spacing: 2) {
                if let title {
                    Text(String(localized: String.LocalizationValue(title)))
                        .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : 48)
                        .font(.iransansBoldTitle)
                        .clipped()
                }
                centerNavigationViews
                    .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : 48)
                    .clipped()
            }
        }
    }

    @ViewBuilder var toolbars: some View {
        leadingNavigationViews
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : toolbarHeight)
            .clipped()
        if !isInSearchMode {
            Spacer()
        }


        if !isInSearchMode {
            Spacer()
        }
        searchView
            .frame(minHeight: 0, maxHeight: toolbarHeight)
        trailingNavigationViews
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : toolbarHeight)
            .clipped()
    }

    @ViewBuilder var searchView: some View {
        if searchCompletion != nil {
            TextField(String(localized: String.LocalizationValue(searchPlaceholder ?? "" )), text: $searchText)
                .keyboardType(.phonePad)
                .font(.iransansSubtitle)
                .textFieldStyle(.clear)
                .focused($searchFocus, equals: .saerch)
                .frame(minWidth: 0, maxWidth: isInSearchMode ? nil : 0, minHeight: 0, maxHeight: isInSearchMode ? 32 : 0)
                .clipped()
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.2), style: .init(lineWidth: 0.3, lineCap: .round))
                }

            Button {
                withAnimation {
                    if isInSearchMode {
                        hideKeyboard()
                    }
                    isInSearchMode.toggle()
                    searchText = ""
                }
            } label: {
                Text("General.cancel")
                    .padding(.leading)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: 0, maxWidth: isInSearchMode ? nil : 0, minHeight: 0, maxHeight: isInSearchMode ? toolbarHeight : 0)
            .clipped()

            ToolbarButtonItem(imageName: "magnifyingglass", hint: "Search") {
                withAnimation {
                    isInSearchMode.toggle()
                    searchFocus = isInSearchMode ? .saerch : .none
                }
            }
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? 0 : toolbarHeight)
            .clipped()
        }
    }
}

public struct ToolbarButtonItem: View {
    let imageName: String
    let hint: String
    let action: () -> Void
    static let buttonWidth: CGFloat = 20

    init(imageName: String, hint: String = "", action: @escaping () -> Void) {
        self.imageName = imageName
        self.hint = hint
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(minWidth: 0, maxWidth: ToolbarButtonItem.buttonWidth)
                .accessibilityHint(hint)
        }
    }
}

struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView<EmptyView, EmptyView, Image>(trailingViews: Image(systemName: ""))
    }
}
