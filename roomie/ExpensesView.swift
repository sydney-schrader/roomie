//
//  ExpensesView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/6/25.
//
import SwiftUI

struct Expense: Codable, Identifiable {
    var id = UUID()
    let cost: Double
    let title: String
    let paidBy: String
}

struct ExpensesView: View {
    @State private var expenses: [Expense] = [
        Expense(cost: 10, title: "cabo", paidBy: "jac"),
        Expense(cost: 650, title: "rent", paidBy: "ava"),
        Expense(cost: 30, title: "matts", paidBy: "syd")
    ]
    
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
                    //action
                }label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    ExpensesView()
}
