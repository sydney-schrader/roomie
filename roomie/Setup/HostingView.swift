//
//  HostingView.swift
//  roomie
//
//  Created by Sydney Schrader on 3/6/25.
//

import SwiftUI

struct HostingView: View {
    var householdManager: HouseholdManager
    var essentialsOption: Int
    @State private var hostingSelection: Int = -1
    @State private var currentStep = 1
    
    var body: some View {
        VStack(alignment: .center) {
            NavigationStack {
                VStack() {
                    Text("hosting")
                        .font(.system(size: 50))
                        .bold()
                    
                    
                    Text("choose an option for hosting guests and events")
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
                    
                    Button("every roomie approves every event", action: {
                        hostingSelection = 0 //every event
                    })
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 375)
                        .background(hostingSelection == 0 ? Color(red: 0.9, green: 0.85, blue: 1.0) : Color(red: 0.7, green: 0.9, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    Button("every roomie approves certain events", action: {
                        hostingSelection = 1 //certain events
                    })
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 375)
                        .background(hostingSelection == 1 ? Color(red: 0.9, green: 0.85, blue: 1.0) : Color(red: 0.7, green: 0.9, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    Button("no need for approval", action: {
                        hostingSelection = 2 //none
                    })
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 375)
                        .background(hostingSelection == 2 ? Color(red: 0.9, green: 0.85, blue: 1.0) : Color(red: 0.7, green: 0.9, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    PageIndicator(currentStep: 3, nextPage: HouseholdName(householdManager: householdManager, essentialsOption: essentialsOption, hostingOption: hostingSelection))
                }
            }
        }
    }
}

//#Preview {
//    HostingView()
//}
