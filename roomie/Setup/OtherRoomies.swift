//
//  OtherRoomies.swift
//  roomie
//
//  Created by Sydney Schrader on 2/25/25.
//

import SwiftUI

struct OtherRoomies: View {
    var householdManager: HouseholdManager
    @State private var emails: [String] = ["", "", ""]
    @State private var currentStep = 1
    
    var body: some View {
        VStack(alignment: .center) {
            NavigationStack {
                VStack() {
                    Text("roomies")
                        .font(.system(size: 50))
                        .bold()
                    
                    HStack {
                        Text("enter the emails of your other roommates to send them an invite")
                            .font(.system(size: 25))
                            .multilineTextAlignment(.center)
            
                    }
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
                    
                    
                    VStack(spacing: 10) {
                        ForEach(0..<emails.count, id: \.self) { index in
                            TextField("email", text: $emails[index])
                                .padding()
                                .background(Color(red: 0.7, green: 0.9, blue: 1.0))
                                .cornerRadius(10)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                        
                        // Add another row button
                        Button(action: {
                            emails.append("")
                        }) {
                            Text("add another row?")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.7, green: 0.9, blue: 1.0))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("send invites", action: {
                        print("Sending invites to: \(emails.filter { !$0.isEmpty })")
                    })
                        .padding()
                        .frame(width: 175)
                        .background(Color(red: 0.8, green: 0.8, blue: 1.0))
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .font(.system(size: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .padding(10)
                    
                    
                    Spacer()
                    
                    PageIndicator(currentStep: 1, nextPage: EssentialsView(householdManager: householdManager))
                }
            }
        }
    }
}

struct PageIndicator<Destination: View>: View {
    var currentStep: Int
    var nextPage: Destination
    
    var body: some View {
        HStack {
            Text("\(currentStep) of 3")
                .font(.system(size: 18))
            
            Spacer()
            
            NavigationLink {
                nextPage
            } label: {
                HStack {
                    Text("next")
                        .font(.system(size: 18))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18))
                }
            }
        }
        .padding()
        .background(Color(red: 0.9, green: 0.85, blue: 1.0))
    }
}


// Preview
//struct OtherRoomies_Previews: PreviewProvider {
//    static var previews: some View {
//        OtherRoomies()
//    }
//}
