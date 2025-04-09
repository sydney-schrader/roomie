//
//  AddChoreView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddChoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var roommateManager = RoommateManager()
    @State private var title: String = ""
    @State private var assignedTo: String = ""
    @State private var isDone: Bool = false
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    let onSave: (Chore) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("chore details")) {
                    TextField("title", text: $title)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("assigned to")) {
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
                        if assignedTo.isEmpty {
                            TextField("enter name", text: $assignedTo)
                        } else {
                            Picker("assigned to", selection: $assignedTo) {
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
            .navigationTitle("new chore")
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
                self.assignedTo = displayName
                print("Setting default assigned to to current user: \(displayName)")
            } else if !roommateManager.roommates.isEmpty {
                self.assignedTo = roommateManager.roommates[0].firstName
                print("Setting default assigned to first roommate: \(roommateManager.roommates[0].firstName)")
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
        
        
        guard !assignedTo.isEmpty else {
            errorMessage = "please enter assignment"
            return
        }
        
        // Create expense object
        let newChore = Chore(
            id: UUID().uuidString,
            title: title,
            assignedTo: assignedTo,
            isDone: false
        )
        
        // Call save callback
        onSave(newChore)
        dismiss()
    }
}
