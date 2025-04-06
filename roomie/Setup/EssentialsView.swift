//
//  EssentialsView.swift
//  roomie
//
//  Created by Sydney Schrader on 3/6/25.
//

import SwiftUI

struct EssentialsView: View {
    var householdManager: HouseholdManager
    @State private var essentialsSelection: Int = -1
    @State private var currentStep = 1
    
    var body: some View {
        VStack(alignment: .center) {
            NavigationStack {
                VStack() {
                    Text("essentials")
                        .font(.system(size: 50))
                        .bold()
                    
                    
                    Text("choose an option for the division of community supplies (i.e. dish soap, paper towels, spices)")
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
                    
                    Button("rotate who buys supplies when needed", action: {
                        essentialsSelection = 0 //rotate
                    })
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 375)
                        .background(essentialsSelection == 0 ? Color(red: 0.9, green: 0.85, blue: 1.0) : Color(red: 0.7, green: 0.9, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    Button("split supplies equally each time", action: {
                        essentialsSelection = 1 //split
                    })
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 375)
                        .background(essentialsSelection == 1 ? Color(red: 0.9, green: 0.85, blue: 1.0) : Color(red: 0.7, green: 0.9, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    Button("all supplies are individually bought", action: {
                        essentialsSelection = 2 //individual
                    })
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 375)
                        .background(essentialsSelection == 2 ? Color(red: 0.9, green: 0.85, blue: 1.0) : Color(red: 0.7, green: 0.9, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    PageIndicator(currentStep: 2, nextPage: HostingView(householdManager: householdManager, essentialsOption: essentialsSelection))
                }
            }
        }
    }
}

//#Preview {
//    EssentialsView()
//}
