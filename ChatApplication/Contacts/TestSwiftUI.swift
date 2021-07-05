//
//  TestSwiftUI.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI


struct Grid: View {
    
    let namespace: Namespace.ID
    
    var body: some View {
        HStack{
            Image(systemName: "phone")
                .resizable()
                .frame(width: 50, height: 50)
                .cornerRadius(4)
                .padding()
                .matchedGeometryEffect(id: "animation", in: namespace)
        }
    }
}

struct Detail: View {
    
    let namespace: Namespace.ID
    
    var body: some View {
        
        Image(systemName:"phone")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(10)
            .padding(40)
            .matchedGeometryEffect(id: "animation", in: namespace)
            .ignoresSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(#colorLiteral(red: 0.234857142, green: 0.043259345, blue: 0.04711621255, alpha: 1)).ignoresSafeArea(.all))
    }
}

struct ContentView: View {
    
    @Namespace private var ns
    @State private var showDetails: Bool = false
    
    var body: some View {
        ZStack {
            Spacer()
            if showDetails {
                Detail(namespace: ns)
            }
            else {
                Grid(namespace: ns)
            }
        }
        .ignoresSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green.ignoresSafeArea(.all))
        .onTapGesture {
            withAnimation(.spring()) {
                showDetails.toggle()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
