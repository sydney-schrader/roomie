//
//  SettingsView.swift
//  roomie
//
//  Created by Sydney Schrader on 3/7/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct SettingsView: View {
    @StateObject private var householdManager = HouseholdManager()
    @State private var household: Household?
    @State private var isLoading = true
    @State private var userDisplayName = Auth.auth().currentUser?.displayName ?? "user"
    @State private var navigateSignOut = false
    @State private var showRentSheet = false
    @State private var showLaundrySheet = false
    @State private var showChoreSheet = false
    @State private var userLaundryDay: DayOfWeek? =  nil
    @State private var userChoreDay: DayOfWeek? =  nil
    @State private var userRentAmount: Double? =  nil
    
    var userInitials: String {
        return String(userDisplayName.prefix(1))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("settings")
                .bold()
                .font(.system(size: 50))
                .padding(.horizontal)
            
            List {
                Section {
                    // User profile row
                    HStack {
                        // User initials in a circle
                        ZStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 60, height: 60)
                            
                            Text(userInitials.uppercased())
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userDisplayName)
                                .font(.headline)
                            
                            //                            Text("Account & Personal Settings")
                            //                                .font(.subheadline)
                            //                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.footnote)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color(UIColor.systemGray6))
                
                Section {
                    // Household row
                    if isLoading {
                        HStack {
                            Text("Loading household...")
                            Spacer()
                            ProgressView()
                        }
                    } else if let household = household {
                        HStack {
                            // Household icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.7, green: 0.7, blue: 1.0))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "house.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            
                            Text(household.name)
                                .font(.headline)
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    } else {
                        Text("No household found")
                    }
                }
                .listRowBackground(Color(UIColor.systemGray6))
                
                Section {
                    Button(action: {
                        showRentSheet = true
                    }){
                        HStack {
                            Text("rent")
                            Spacer()
                            if userRentAmount == nil {
                                Text("incomplete")
                                    .opacity(0.5)
                            } else {
                                Text("\(Int(userRentAmount!))")
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                                .font(.footnote)
                        }
                    }
                    .foregroundStyle(.black)
                    .sheet(isPresented: $showRentSheet) {
                        RentDetailView(onSave: { updateAmount in
                            userRentAmount = updateAmount
                        })
                    }
                    
                    Button(action: {
                        showLaundrySheet = true
                    }){
                        HStack {
                            Text("laundry")
                            Spacer()
                            if userLaundryDay == nil {
                                Text("incomplete")
                                    .opacity(0.5)
                            }else{
                                Text(userLaundryDay!.rawValue)
                                    .opacity(0.5)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                                .font(.footnote)
                        }
                    }
                    .foregroundStyle(.black)
                    .sheet(isPresented: $showLaundrySheet) {
                        LaundryDetailView(onSave: { updatedDay in
                            userLaundryDay = updatedDay
                        })
                    }
                    
                    Button(action: {
                        showChoreSheet = true
                    }) {
                        HStack {
                            Text("chores")
                            Spacer()
                            if userChoreDay == nil {
                                Text("incomplete")
                                    .opacity(0.5)
                            } else {
                                Text(userChoreDay!.rawValue)
                                    .opacity(0.5)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                                .font(.footnote)
                        }
                    }
                    .foregroundStyle(.black)
                    .sheet(isPresented: $showChoreSheet){
                        ChoreDetailView(onSave: { updatedDay in
                            userChoreDay = updatedDay
                        })
                    }
                }
                .listRowBackground(Color(UIColor.systemGray6))
                
                
                
                Section {
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            navigateSignOut = true
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }) {
                        Text("sign out")
                            .foregroundColor(.red)
                    }
                }
                .listRowBackground(Color(UIColor.systemGray6))
                
            }
            .scrollContentBackground(.hidden)
        }
        .task {
            // Using async/await instead of completion handler
            isLoading = true
            household = await householdManager.fetchCurrentHousehold()
            isLoading = false
            fetchUserInfo()
        }
        .fullScreenCover(isPresented: $navigateSignOut) {
            WelcomeView()
        }
    }
    
    private func fetchUserInfo() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user info: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let laundryDayString = data["laundryDay"] as? String,
                   let laundryDay = DayOfWeek(rawValue: laundryDayString) {
                    DispatchQueue.main.async {
                        self.userLaundryDay = laundryDay
                    }
                }
            
                if let data = snapshot?.data(),
                   let choreDayString = data["choreDay"] as? String,
                   let choreDay = DayOfWeek(rawValue: choreDayString) {
                    DispatchQueue.main.async {
                        self.userChoreDay = choreDay
                    }
                }
            
                if let data = snapshot?.data(),
                   let rentInfo = data["rentInfo"] as? [String: Any],
                   !rentInfo.isEmpty,
                   let amount = rentInfo["amount"] as? Double,
                   amount > 0 {
                    DispatchQueue.main.async {
                        self.userRentAmount = amount
                    }
                }
            }
    }
}

