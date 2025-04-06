//
//  WelcomeView.swift
//  roomie
//
//  Created by Sydney Schrader on 2/25/25.
//
import SwiftUI


struct WelcomeView: View {
    @State private var navigateToCreateAccount = false
    @State private var navigateToSignIn = false
    
    var body: some View {
        NavigationStack{
            VStack(alignment: .center) {
                Text("roomie")
                    .bold()
                    .font(.system(size: 50))
                Text("the place for roommates")
                    .font(.system(size: 20))
                Spacer().frame(height: 50)
                NavigationLink(destination: SignInView()) {
                    Text("sign in")
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
                NavigationLink(destination: CreateAccountView()) {
                    Text("create account")
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
    WelcomeView()
}
