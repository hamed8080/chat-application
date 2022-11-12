//
//  SettingsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject
    var viewModel: SettingViewModel

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.gray.opacity(0.08))
                            .frame(width: 128, height: 128)
                            .shadow(color: .black, radius: 20, x: 0, y: 0)
                            .overlay(
                                Avatar(
                                    url: viewModel.currentUser?.image,
                                    userName: viewModel.currentUser?.username?.uppercased() ?? "",
                                    style: .init(size: 128, textSize: 64)
                                )
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                    .onEnded { value in
                                        if value.translation.height != 0 {
                                            // TODO: Switch user with swipe action
//                                            viewModel.switchUser(isNext: value.translation.height < 0)
                                        }
                                    }
                            )
                        Spacer()
                    }
                    .noSeparators()

                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Text(viewModel.currentUser?.name ?? "")
                                .font(.title.bold())

                            Text(viewModel.currentUser?.cellphoneNumber ?? "")
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .padding([.top, .bottom], 25)
                    .noSeparators()
                }
                .padding()

                Section(header: Text("Manage Calls")) {
                    Group {
                        GroupItemInSlideMenu<EmptyView>(name: "gear", title: "Setting", color: .blue, destinationView: EmptyView())
                        GroupItemInSlideMenu<EmptyView>(name: "phone", title: "Calls", color: .green, destinationView: EmptyView())
                        GroupItemInSlideMenu<EmptyView>(name: "bookmark", title: "Saved Messages", color: Color.purple, destinationView: EmptyView())
                        GroupItemInSlideMenu<AnyView>(name: "note.text", title: "Logs", color: Color.yellow, destinationView: AnyView(LogView()))

                        Button(action: {
                            Chat.sharedInstance.logOut()
                            CacheFactory.write(cacheType: .deleteAllCacheData)
                            TokenManager.shared.clearToken()
                        }, label: {
                            HStack {
                                Image(systemName: "arrow.backward.circle")
                                    .foregroundColor(.red)
                                    .font(.body.weight(.bold))
                                Text("Logout")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.red)
                                Spacer()
                            }.padding([.top, .bottom], 12)
                        })
                        TokenExpireView()
                    }
                }
                .noSeparators()
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    // TODO: - Must be added after server fix the problem
                } label: {
                    Label {
                        Text("Edit")
                    } icon: {
                        Image(systemName: "square.and.pencil")
                            .font(.body.bold())
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                ConnectionStatusToolbar()
            }
        }
        .navigationTitle(Text("Settings"))
    }
}

struct TokenExpireView: View {
    @EnvironmentObject
    var viewModel: TokenManager

    var body: some View {
#if DEBUG
        HStack {
            Image(systemName: "key.fill")
                .foregroundColor(Color.yellow)
                .frame(width: 24, height: 24)
            Text("Token expire in: \(String(format: "%.0f", viewModel.secondToExpire))")
                .foregroundColor(Color.gray)
            Spacer()
        }
        .onAppear {
            viewModel.startTokenTimer()
        }
#endif
    }
}

struct GroupItemInSlideMenu<DestinationView: View>: View {
    var name: String
    var title: String
    var color: Color
    var destinationView: DestinationView? = nil

    @State var isActive = false

    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                Image(systemName: name)
                    .font(.body)
                    .foregroundColor(color)
                Text(title)
                    .font(.body)
            }.padding([.top, .bottom], 12)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsMenu_Previews: PreviewProvider {
    @State static var dark: Bool = false
    @State static var show: Bool = false
    @State static var showBlackView: Bool = false
    static var vm = SettingViewModel()

    static var previews: some View {
        Group {
            SettingsView()
                .environmentObject(vm)
                .environmentObject(AppState.shared)
                .onAppear {
                    vm.currentUser = User(
                        cellphoneNumber: "+98 936 916 1601",
                        email: "h.hosseini.co@gmail.com",
                        image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png",
                        name: "Hamed Hosseini",
                        username: "hamed8080"
                    )
                }
        }
    }
}
