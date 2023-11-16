//
//  MapAddressTextView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct MapAddressTextView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    
    var body: some View {
        if let addressDetail = viewModel.addressDetail {
            Text(addressDetail)
                .foregroundStyle(Color.App.hint)
                .font(.iransansCaption)
                .padding(.horizontal, 6)
        }
    }
}

struct MapAddressTextView_Previews: PreviewProvider {
    static var previews: some View {
        MapAddressTextView()
    }
}
