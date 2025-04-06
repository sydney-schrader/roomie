//
//  SetupView.swift
//  roomie
//
//  Created by Sydney Schrader on 2/25/25.
//
import SwiftUI
import FirebaseAuth

struct SetupView: View {
    @StateObject private var householdManager = HouseholdManager()
    @State private var navigation: Bool = false
    
    var body: some View {
        NavigationStack{
            VStack(alignment: .center) {
                Text("setup")
                    .bold()
                    .font(.system(size: 50))
                Text("have you created a household yet?")
                    .font(.system(size: 20))
                Spacer().frame(height: 50)
                NavigationLink(destination: JoinView(householdManager: householdManager)){
                    Text("enter join code")
                        .padding()
                        .frame(width: 250)
                        .background(Color(red: 0.8, green: 0.8, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
                NavigationLink(destination: OtherRoomies(householdManager: householdManager)) {
                    Text("create new household")
                        .padding()
                        .frame(width: 250)
                        .background(Color(red: 0.6, green: 0.6, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
            }
        }
    }
}

#Preview {
    SetupView()
}
