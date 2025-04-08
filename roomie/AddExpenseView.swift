////
////  AddExpenseView.swift
////  roomie
////
////  Created by Sydney Schrader on 4/7/25.
////
//
//import SwiftUI
//
//struct AddExpenseView: View {
//    @Environment(\.dismiss) private var dismiss
//    @State private var amount: String = ""
//    @State private var title: String = ""
//    @StateObject private var roommateManager = RoommateManager()
//    @State var selectedRoommate: String
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 30) {
//            HStack {
//                Text("add expense")
//                    .font(.title2)
//                    .fontWeight(.medium)
//                
//                Spacer()
//                
//                Button(action: {
//                    dismiss()
//                }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(.gray)
//                        .font(.title2)
//                }
//            }
//            .padding(.bottom, 10)
//            
//            HStack {
//                Text("title")
//                    .fontWeight(.medium)
//                
//                Spacer()
//                
//                TextField("value", text: $title)
//                    .multilineTextAlignment(.trailing)
//                
//                
//            }
//            Divider()
//            
//            HStack {
//                Text("amount")
//                    .fontWeight(.medium)
//                
//                Spacer()
//                
//                TextField("$value", text: $amount)
//                    .multilineTextAlignment(.trailing)
//                    .keyboardType(.numberPad)
//                
//            }
//            Divider()
//            
//            HStack {
//                Text("paid by")
//                    .fontWeight(.medium)
//                
//                Spacer()
//                
//                TextField("value", text: $selectedRoommate)
//                    .multilineTextAlignment(.trailing)
////                Picker("Paid by", selection: $selectedRoommate) {
////                    ForEach(roommateManager.roommates) { roommate in
////                        Text(roommate.firstName).tag(roommate.id)
////                    }
////                }
////                .pickerStyle(MenuPickerStyle())
//                
//            }
//            Divider()
//            
//            
//            Spacer()
//            
//            HStack {
//                Spacer()
//                Button(action: {
//                    // Save action
//                    
//                }) {
//                    Text("save")
//                        .foregroundColor(.blue)
//                        .padding(.horizontal, 30)
//                        .padding(.vertical, 10)
//                        .background(Color(red: 0.9, green: 0.95, blue: 1.0))
//                        .cornerRadius(20)
//                }
//                Spacer()
//            }
//        }
//        .padding()
//        .background(Color(.systemBackground))
//        .onAppear {
//            roommateManager.fetchRoommates()
//        }
//    }
//    
//}
//
//#Preview() {
//    AddExpenseView(selectedRoommate: "")
//}

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var roommateManager = RoommateManager()
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var paidBy: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    let onSave: (Expense) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("expense details")) {
                    TextField("title", text: $title)
                    
                    TextField("amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("paid by")) {
                    if isLoading {
                        HStack {
                            Text("loading roommates...")
                            Spacer()
                            ProgressView()
                        }
                    } else if roommateManager.roommates.isEmpty {
                        Text("no roommates found")
                    } else {
                        // Text field as fallback if picker doesn't work
                        if paidBy.isEmpty {
                            TextField("enter name", text: $paidBy)
                        } else {
                            Picker("paid by", selection: $paidBy) {
                                ForEach(roommateManager.roommates) { roommate in
                                    Text(roommate.firstName).tag(roommate.firstName)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("new expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        saveExpense()
                    }
                }
            }
            .onAppear {
                loadRoommates()
            }
        }
    }
    
    private func loadRoommates() {
        isLoading = true
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            isLoading = false
            return
        }
        
        // Debug print to check the household ID
        print("Fetching roommates for household: \(householdId)")
        
        roommateManager.fetchRoommates()
        
        // Add a delay to ensure roommates are loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Debug print to check if roommates were loaded
            print("Found \(roommateManager.roommates.count) roommates")
            
            // Set default to current user's name if available
            if let currentUser = Auth.auth().currentUser,
               let displayName = currentUser.displayName,
               !displayName.isEmpty {
                self.paidBy = displayName
                print("Setting default paid by to current user: \(displayName)")
            } else if !roommateManager.roommates.isEmpty {
                self.paidBy = roommateManager.roommates[0].firstName
                print("Setting default paid by to first roommate: \(roommateManager.roommates[0].firstName)")
            }
            
            isLoading = false
        }
    }
    
    private func saveExpense() {
        // Validate inputs
        guard !title.isEmpty else {
            errorMessage = "please enter a title"
            return
        }
        
        guard !amount.isEmpty, let cost = Double(amount) else {
            errorMessage = "please enter a valid amount"
            return
        }
        
        guard !paidBy.isEmpty else {
            errorMessage = "please enter who paid"
            return
        }
        
        // Create expense object
        let newExpense = Expense(
            id: UUID().uuidString,
            title: title,
            cost: cost,
            paidBy: paidBy
        )
        
        // Call save callback
        onSave(newExpense)
        dismiss()
    }
}
