//
//  SettingsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingViewModel

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
                                ImageLaoderView(url: viewModel.currentUser?.image, userName: viewModel.currentUser?.username ?? viewModel.currentUser?.name, size: .LARG)
                                    .font(.system(size: 16).weight(.heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 128, height: 128)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(64)
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

                Group {
                    Section {
                        NavigationLink {} label: {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.blue)
                                Text("Setting")
                            }
                        }
                    }

                    Section {
                        NavigationLink {} label: {
                            HStack {
                                Image(systemName: "phone")
                                    .foregroundColor(.green)
                                Text("Calls")
                            }
                        }
                    }

                    NavigationLink {} label: {
                        HStack {
                            Image(systemName: "bookmark")
                                .foregroundColor(.purple)
                            Text("Saved Messages")
                        }
                    }

                    NavigationLink {} label: {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.purple)
                            Text("Logs")
                        }
                    }

                    Section(header: Text("Manage Calls").font(.headline)) {
                        Button {
                            ChatManager.activeInstance?.logOut()
                            TokenManager.shared.clearToken()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.backward.circle")
                                    .foregroundColor(.red)
                                    .font(.body.weight(.bold))
                                Text("Logout")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.red)
                                Spacer()
                            }
                        }
                        TokenExpireView()
                    }
                }
                .font(.title3)
                .padding(8)
            }
        }
        .listStyle(.insetGrouped)
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
    @EnvironmentObject var viewModel: TokenManager

    var body: some View {
        #if DEBUG
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(Color.yellow)
                    .frame(width: 24, height: 24)
                if let secondToExpire = viewModel.secondToExpire.formatted(.number.precision(.fractionLength(0))) {
                    Text("Token expire in: \(secondToExpire)")
                        .foregroundColor(Color.gray)
                }
                Spacer()
            }
            .onAppear {
                viewModel.startTokenTimer()
            }
        #endif
    }
}

struct SettingsMenu_Previews: PreviewProvider {
    @State static var dark: Bool = false
    @State static var show: Bool = false
    @State static var showBlackView: Bool = false
    static var vm = SettingViewModel()

    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(vm)
                .environmentObject(TokenManager.shared)
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
