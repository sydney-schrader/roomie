//
//  JoinView.swift
//  roomie
//
//  Created by Sydney Schrader on 2/25/25.
//

import SwiftUI


struct JoinView: View {
    var householdManager: HouseholdManager
    @State private var joinCode: String = ""
    @State private var errorMessage: String? = nil
    @State private var showHomeView = false
    
    var body: some View {
        VStack(alignment: .center) {
            Text("join code")
                .bold()
                .font(.system(size: 50))
            Spacer().frame(height: 50)
            TextField("household join code", text: $joinCode)
                .padding()
                .frame(width: 350)
                .background(Color(red: 0.6, green: 0.6, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
            Spacer().frame(height: 50)
            Button("join", action: {
                householdManager.joinHousehold(joinCode: joinCode) { success, message in
                        if success {
                            showHomeView = true
                        } else {
                            errorMessage = message
                        }
                    }
            })
                .padding()
                .frame(width: 100)
                .background(Color(red: 0.8, green: 0.8, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            Spacer()
        }
        .fullScreenCover(isPresented: $showHomeView) {
            TabBarView(selectedTab: 3)
        }
    }
}

