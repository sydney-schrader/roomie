//
//  HouseholdName.swift
//  roomie
//
//  Created by Sydney Schrader on 3/6/25.
//

import SwiftUI


struct HouseholdName: View {
    var householdManager: HouseholdManager
    var essentialsOption: Int
    var hostingOption: Int
    @State private var householdName: String = ""
    @State private var showHomeView = false
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("all set!")
                .bold()
                .font(.system(size: 50))
            Text("set a name for your household if desired")
                .font(.system(size: 25))
                .multilineTextAlignment(.center)
                .padding()
                .frame(width: 375)
                .bold()
                .background(Color(red: 0.7, green: 0.9, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
                .padding(10)
            TextField("household name", text: $householdName)
                .padding()
                .frame(width: 375)
                .background(Color(red: 0.7, green: 0.9, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 1)
                )
                .padding(5)
            Button("set name", action: {
                let householdId = householdManager.createHousehold(name: householdName.isEmpty ? "Household" : householdName)
                householdManager.updateHouseholdSettings(
                    householdId: householdId,
                    essentialsOption: essentialsOption,
                    hostingOption: hostingOption
                )
                    
                showHomeView = true
            })
                .padding()
                .frame(width: 150)
                .background(Color(red: 0.8, green: 0.8, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
            Button("skip", action: {
                let householdId = householdManager.createHousehold(name: "Household")
                                
                householdManager.updateHouseholdSettings(
                    householdId: householdId,
                    essentialsOption: essentialsOption,
                    hostingOption: hostingOption
                )
                
                showHomeView = true
            })
                .padding()
                .frame(width: 75, height: 30)
                .background(Color(red: 0.8, green: 0.8, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 1)
                )
            Spacer()
        }
        .fullScreenCover(isPresented: $showHomeView) {
            TabBarView(selectedTab: 3)
        }
    }
}

//#Preview {
//    HouseholdName()
//}
