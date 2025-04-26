//
//  AddExpenseView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/7/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var roommateManager = RoommateManager()
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var paidBy: String = ""
    @State private var selectedParticipants: Set<String> = []
    @State private var customAmounts: [String: String] = [:]
    @State private var date: Date = Date()
    @State private var split: SplitType = .equally
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    let onSave: (Expense) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("expense details")) {
                    TextField("title", text: $title)
                        .autocapitalization(.none)
                    
                    TextField("amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("date", selection: $date, displayedComponents: [.date])
                        
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
                    
                    Picker("split", selection: $split) {
                        ForEach(SplitType.allCases, id: \.self){ type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("participants")) {
                    if roommateManager.roommates.isEmpty {
                        Text("Loading roommates...")
                    } else {
                        ForEach(roommateManager.roommates) { roommate in
                            HStack {
                                Text(roommate.firstName)
                                Spacer()
                                if split == .equally {
                                    Toggle("", isOn: Binding(
                                        get: { selectedParticipants.contains(roommate.firstName) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedParticipants.insert(roommate.firstName)
                                            } else {
                                                selectedParticipants.remove(roommate.firstName)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                } else { // exactly split
                                    TextField("$0", text: Binding(
                                        get: { customAmounts[roommate.firstName] ?? "" },
                                        set: { customAmounts[roommate.firstName] = $0 }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                }
                            }
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
        
        let participants = Array(selectedParticipants)
        guard !participants.isEmpty else {
            errorMessage = "Please select at least one participant"
            return
        }
        
        // For exact split, validate amounts
        var customAmountsDouble: [String: Double] = [:]
        if split == .exactly {
            for (id, amountStr) in customAmounts {
                if let amount = Double(amountStr) {
                    customAmountsDouble[id] = amount
                } else {
                    customAmountsDouble[id] = 0.0
                }
            }
            
            let cost = Double(amount)!
            // Check if sum matches total
            let sumOfAmounts = customAmountsDouble.values.reduce(0, +)
            if abs(sumOfAmounts - cost) > 0.01 { // Allow for small floating-point differences
                errorMessage = "The sum of amounts must equal the total expense"
                return
            }
        }
        
        // Create expense object
        let newExpense = Expense(
            id: UUID().uuidString,
            title: title,
            cost: cost,
            paidBy: paidBy,
            date: date,
            split: split,
            participants: participants,
            customAmounts: customAmountsDouble
        )
        
        // Call save callback
        onSave(newExpense)
        dismiss()
    }
}
