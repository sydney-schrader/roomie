//
//  AddExpenseView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/7/25.
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = ""
    @State private var title: String = ""
    @StateObject private var roommateManager = RoommateManager()
    @State var selectedRoommate: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Text("add expense")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.bottom, 10)
            
            HStack {
                Text("title")
                    .fontWeight(.medium)
                
                Spacer()
                
                TextField("value", text: $title)
                    .multilineTextAlignment(.trailing)
                
                
            }
            Divider()
            
            HStack {
                Text("amount")
                    .fontWeight(.medium)
                
                Spacer()
                
                TextField("$value", text: $amount)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                
            }
            Divider()
            
            HStack {
                Text("paid by")
                    .fontWeight(.medium)
                
                Spacer()
                
                TextField("value", text: $selectedRoommate)
                    .multilineTextAlignment(.trailing)
//                Picker("Paid by", selection: $selectedRoommate) {
//                    ForEach(roommateManager.roommates) { roommate in
//                        Text(roommate.firstName).tag(roommate.id)
//                    }
//                }
//                .pickerStyle(MenuPickerStyle())
                
            }
            Divider()
            
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    // Save action
                    
                }) {
                    Text("save")
                        .foregroundColor(.blue)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.9, green: 0.95, blue: 1.0))
                        .cornerRadius(20)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            roommateManager.fetchRoommates()
        }
    }
    
}

#Preview() {
    AddExpenseView(selectedRoommate: "")
}
