//
//  ExpensesView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/6/25.
//
import SwiftUI
import FirebaseAuth

struct Expense: Identifiable, Codable {
    var id = UUID()
    let cost: Double
    let title: String
    let paidBy: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "cost": cost,
            "title": title,
            "paidBy" : paidBy
        ]
    }
}

struct ExpensesView: View {
    @State private var showAddExpensePage = false
    @State private var showExpenseDetailPage = false
    @State private var expenses: [Expense] = [
        Expense(cost: 10, title: "cabo", paidBy: "jac"),
        Expense(cost: 650, title: "rent", paidBy: "ava"),
        Expense(cost: 30, title: "matts", paidBy: "syd")
    ]
    @StateObject private var roommateManager = RoommateManager()
    @State private var selectedRoommateId: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("title")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
        
                    Text("amount")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("paid by")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                List(expenses) { expense in
                    HStack {
                        Text(expense.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("$\(String(format: "%.2f", expense.cost))")
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(expense.paidBy)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(10)
                    .background(Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.7))
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("expenses")
            .toolbar{
                Button{
                    if let currentUserId = Auth.auth().currentUser?.uid,
                       roommateManager.roommates.contains(where: { $0.id == currentUserId }) {
                        selectedRoommateId = currentUserId
                    } else if !roommateManager.roommates.isEmpty {
                        selectedRoommateId = roommateManager.roommates[0].id
                    }
                    showAddExpensePage = true
                }label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddExpensePage){
                AddExpenseView(selectedRoommate: selectedRoommateId)
            }
        }
    }
}

#Preview {
    ExpensesView()
}
