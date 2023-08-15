//
//  ContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ContactRow: View {
    @Binding public var isInSelectionMode: Bool
    @EnvironmentObject var viewModel: ContactsViewModel
    @State public var showActionViews: Bool = false
    @EnvironmentObject var appState: AppState
    var contact: Contact
    var contactImageURL: String? { contact.image ?? contact.user?.image }
    @State var navigateToAddOrEditContact = false

    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 0) {
                    selectRadio
                    ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: contact.image ?? contact.user?.image, userName: contact.firstName)
                        .id("\(contact.image ?? "")\(contact.id ?? 0)")
                        .font(.iransansBody)
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                            .padding(.leading, 16)
                            .lineLimit(1)
                            .font(.iransansBoldSubtitle)
                        if let notSeenDuration = contact.notSeenString {
                            Text(notSeenDuration)
                                .padding(.leading, 16)
                                .font(.iransansCaption)
                                .foregroundColor(Color.gray)
                        }
                    }
                    Spacer()
                    if contact.blocked == true {
                        Text("General.blocked")
                            .font(.iransansCaption2)
                            .padding(4)
                            .foregroundColor(Color.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.red)
                            )
                    }
                }
                if showActionViews {
                    actionsViews
                } else {
                    EmptyView()
                }
            }
            .modifier(AnimatingCellHeight(height: self.showActionViews ? 148 : 64))
            .padding(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
            .background(Color.primary.opacity(0.08))
            .cornerRadius(16)
        }
        .animation(.easeInOut, value: showActionViews)
        .animation(.easeInOut, value: contact.blocked)
        .animation(.easeInOut, value: navigateToAddOrEditContact)
        .animation(.easeInOut, value: contact)
        .onTapGesture {
            withAnimation {
                showActionViews.toggle()
            }
        }
        .sheet(isPresented: $navigateToAddOrEditContact) {
            AddOrEditContactView(editContact: contact).environmentObject(viewModel)
        }
    }

    @ViewBuilder var actionsViews: some View {
        Divider()
        HStack {
            Group {
                Spacer()
                if appState.isLoading {
                    ProgressView()
                } else {
                    ActionButton(iconSfSymbolName: "message") {
                        appState.openThread(contact: contact)
                    }
                }
                Spacer()
                ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: contact.blocked == true ? .red : .blue) {
                    viewModel.blockOrUnBlock(contact)
                }
            }
            Group {
                Spacer()
                ActionButton(iconSfSymbolName: "pencil") {
                    navigateToAddOrEditContact.toggle()
                }
                Spacer()
            }
        }
    }

    @ViewBuilder var selectRadio: some View {
        let isSelected = viewModel.isSelected(contact: contact)
        ZStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .scaleEffect(x: isSelected ? 1 : 0.001, y: isSelected ? 1 : 0.001, anchor: .center)
                .foregroundColor(Color.blue)

            Image(systemName: "circle")
                .font(.title)
                .foregroundColor(Color.blue)
        }
        .frame(width: isInSelectionMode ? 22 : 0.001, height: isInSelectionMode ? 22 : 0.001, alignment: .center)
        .padding(isInSelectionMode ? 24 : 0.001)
        .scaleEffect(x: isInSelectionMode ? 1.0 : 0.001, y: isInSelectionMode ? 1.0 : 0.001, anchor: .center)
        .onTapGesture {
            withAnimation(!isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
                viewModel.toggleSelectedContact(contact: contact)
            }
        }
    }
}

struct ActionButton: View {
    var iconSfSymbolName: String
    var height: CGFloat = 22
    var iconColor: Color = .blue
    var taped: (() -> Void)?

    var body: some View {
        Button(action: {
            taped?()
        }, label: {
            Image(systemName: iconSfSymbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: height)
                .foregroundColor(iconColor)
        })
        .buttonStyle(BorderlessButtonStyle()) // don't remove this line click happen in all veiws
        .padding(16)
    }
}

struct ContactRow_Previews: PreviewProvider {
    @State static var isInSelectionMode = false

    static var previews: some View {
        Group {
            ContactRow(isInSelectionMode: $isInSelectionMode, contact: MockData.contact)
                .environmentObject(ContactsViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
