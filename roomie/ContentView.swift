//
//  ContentView.swift
//  roomie
//
//  Created by Sydney Schrader on 2/24/25.
//

import SwiftUI


struct ContentView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(alignment: .center) {
            Text("roomie")
                .bold()
                .font(.system(size: 50))
            Text("the place for roommates")
                .font(.system(size: 20))
            TextField("username", text: $username)
                .padding(.horizontal, 20)
            TextField("password", text: $password)
                .padding(.horizontal, 20)
            Button("login", action: {
                print("login")
            })
                .padding(.horizontal, 40)
                .background(.purple)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .textFieldStyle(.roundedBorder)
        .padding()
    }
}

#Preview {
    ContentView()
}
