//
//  SupportView.swift
//  Talk
//
//  Created by hamed on 10/14/23.
//

import SwiftUI

struct SupportView: View {
    @Environment(\.colorScheme) var scheme
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Image("support_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
                .background(scheme == .dark ? Color.App.white.opacity(0.2) : Color.App.primary)
                .cornerRadius(64)
                .foregroundStyle(.white)
            Text("Support.aboutUsText")
                .frame(maxWidth: 320)
                .multilineTextAlignment(.center)
            let isIpad = UIDevice.current.userInterfaceIdiom  == .pad

            HStack(spacing: 8) {
                Link(destination: URL(string: "\(isIpad ? "facetime" : "tel"):021-91033000")!) {
                    Text("021-91033000")
                }

                Link(destination: URL(string: "\(isIpad ? "facetime" : "tel"):0903-4565089")!) {
                    Text("0903-4565089")
                }
            }
            .foregroundStyle(Color.App.hint)
            Spacer()
            let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
            Text(String(format: String(localized: "Support.version"), version))
                .foregroundStyle(Color.App.hint)
        }
        .font(.iransansBody)
        .padding(.horizontal, 24)
        .padding(.top, 100)
        .padding(.bottom, 30)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.App.bgPrimary)
    }
}

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        SupportView()
    }
}
