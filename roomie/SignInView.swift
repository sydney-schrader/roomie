//
//  SignInView.swift
//  roomie
//
//  Created by Sydney Schrader on 2/25/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var navToSettings: Bool = false
    @State private var navToHome: Bool = false
    private let db = Firestore.firestore()
    
    func signInUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }
                
            guard (authResult?.user) != nil else {
                errorMessage = "Unknown error occurred"
                return
            }
            
            //on success
            errorMessage = nil
            print("\(Auth.auth().currentUser?.displayName ?? "") has signed in")
            
            // user should go to settings if rent, laundry, or chores DNE in firebase.
            self.db.collection("users").document(Auth.auth().currentUser?.uid ?? "").getDocument { document, error in
                if let document = document, document.exists,
                   let householdIds = document.data()?["householdIds"] as? [String],
                   !householdIds.isEmpty {
                    var currentHouseholdId = ""
                    if let id = document.data()?["currentHouseholdId"] as? String, !id.isEmpty {
                        currentHouseholdId = id
                    } else {
                        // If no current household is set but they have households, use the first one
                        currentHouseholdId = householdIds[0]
                    }
                    
                    // Set current household ID in UserDefaults
                    UserDefaults.standard.set(currentHouseholdId, forKey: "currentHouseholdID")
                    
                    let roommateManager = RoommateManager()
                    // Check user settings after setting the household
                    roommateManager.checkUserSettings { hasRent, hasLaundry, hasChore in
                        DispatchQueue.main.async {
                            // If any setting is missing, go to settings page
                            if !hasRent || !hasLaundry || !hasChore {
                                self.navToSettings = true
                            } else {
                                // All settings complete, go to home
                                self.navToHome = true
                            }
                            
                            self.email = ""
                            self.password = ""
                        }
                    }
                } else {
                    // If no household data exists, navigate directly to setup
                    DispatchQueue.main.async {
                        self.navToSettings = true
                        self.email = ""
                        self.password = ""
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("sign in")
                .bold()
                .font(.system(size: 50))
            Spacer().frame(height: 50)
            TextField("email", text: $email)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .padding()
                .frame(width: 350)
                .background(Color(red: 0.8, green: 0.8, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
            TextField("password", text: $password)
                .autocorrectionDisabled()
                .autocapitalization(.none)
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
            Button("sign in", action: signInUser)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color(red: 0.6, green: 0.6, blue: 1.0))
                .foregroundStyle(.black)
                .cornerRadius(20)
                .font(.system(size: 25))
                .frame(width: 130)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
                .fullScreenCover(isPresented: $navToHome){
                    TabBarView(selectedTab: 0)
                }
                .fullScreenCover(isPresented: $navToSettings){
                    TabBarView(selectedTab: 3)
                }
            
            Spacer()
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.bottom)
            } else {
                Text("")
                    .frame(height: 0)
            }
        }
    }
}

#Preview {
    SignInView()
}
