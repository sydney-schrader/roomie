//
//  CreateAccountView.swift
//  roomie
//
//  Created by Sydney Schrader on 2/25/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateAccountView: View {
    
    @State private var email: String = ""
    @State private var firstName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToSetup = false
    
    func createUser() {
        guard !email.isEmpty, !firstName.isEmpty, !confirmPassword.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
                        return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }
                
            guard let user = authResult?.user else {
                errorMessage = "Unknown error occurred"
                return
            }
            
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = firstName
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Error updating display name: \(error.localizedDescription)")
                    errorMessage = "Account created but could not save name: \(error.localizedDescription)"
                    return
                }
            }
            
            let userData: [String: Any] = [
                "firstName": firstName,
                "email": email,
                "householdIds": [],
                "currentHouseholdId": ""
            ]
            
            Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    print("Error creating user document: \(error.localizedDescription)")
                    return
                }
            }
            
            //on success
            errorMessage = nil
            print("\(firstName)'s account has been created")
//            let newRoommate = Roommate(userId: user.uid, firstName: firstName, email: email)
//            let roommateManager = RoommateManager()
//            roommateManager.addRoommate(newRoommate)
            navigateToSetup = true
            email = ""
            firstName = ""
            password = ""
            confirmPassword = ""
        }
    }
    
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Text("create account")
                    .bold()
                    .font(.system(size: 50))
                Spacer().frame(height: 50)
                TextField("e-mail", text: $email)
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
                TextField("first name", text: $firstName)
                    .autocorrectionDisabled()
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
                TextField("confirm password", text: $confirmPassword)
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
                Spacer().frame(height: 50)
                Button("create", action: createUser)
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
            .fullScreenCover(isPresented: $navigateToSetup) {
                SetupView()
            }
            Spacer()
        }
    }
}




#Preview {
    CreateAccountView()
}
