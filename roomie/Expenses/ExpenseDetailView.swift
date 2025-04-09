//
//  ExpenseDetailView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header with title and close button
            HStack {
                Text(expense.title)
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
            
            // Expense details
            Group {
                HStack {
                    Text("amount")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", expense.cost))")
                        .font(.headline)
                }
                Divider()
                
                HStack {
                    Text("paid by")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(expense.paidBy)
                        .font(.headline)
                }
                Divider()
                
                // We'll add placeholders for future fields that might be added later
                
                // Date field (commented out for now)
                // HStack {
                //     Text("date")
                //         .fontWeight(.medium)
                //
                //     Spacer()
                //
                //     Text(formatDate(expense.date))
                //         .font(.headline)
                // }
                // Divider()
                
                // Split with (commented out for now)
                // VStack(alignment: .leading, spacing: 10) {
                //     Text("split with")
                //         .fontWeight(.medium)
                //
                //     ForEach(expense.splitWith, id: \.self) { userId in
                //         Text(getUserName(userId))
                //             .padding(.leading)
                //     }
                // }
                // Divider()
                
                // Notes (commented out for now)
                // if let notes = expense.notes, !notes.isEmpty {
                //     VStack(alignment: .leading, spacing: 10) {
                //         Text("notes")
                //             .fontWeight(.medium)
                //
                //         Text(notes)
                //             .padding(.leading)
                //     }
                // }
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Spacer()
                
                Button(action: {
                    // Edit action (to be implemented)
                    dismiss()
                }) {
                    Text("edit")
                        .foregroundColor(.blue)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.9, green: 0.95, blue: 1.0))
                        .cornerRadius(20)
                }
                
                Spacer()
                
                Button(action: {
                    // Delete action (to be implemented)
                    dismiss()
                }) {
                    Text("delete")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(20)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // Helper method to format date (commented out for now)
    // private func formatDate(_ date: Date) -> String {
    //     let formatter = DateFormatter()
    //     formatter.dateStyle = .medium
    //     return formatter.string(from: date)
    // }
    
    // Helper method to get user name (commented out for now)
    // private func getUserName(_ userId: String) -> String {
    //     // Implement logic to get user name from userId
    //     return "User Name"
    // }
}

#Preview {
    ExpenseDetailView(expense: Expense(id: "123", title: "Groceries", cost: 45.50, paidBy: "John"))
}
