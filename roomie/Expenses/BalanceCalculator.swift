//
//  BalanceCalculator.swift
//  roomie
//
//  Created by Sydney Schrader on 4/26/25.
//

import Foundation

struct Balance: Identifiable {
    var id = UUID()
    var debtor: String // Now directly stores the roommate's name
    var creditor: String // Now directly stores the roommate's name
    var amount: Double
}

class BalanceCalculator {
    // Calculate all debts from a list of expenses
    static func calculateAllDebts(from expenses: [Expense]) -> [Debt] {
        var allDebts: [Debt] = []
        
        for expense in expenses {
            guard let split = expense.split else { continue }
            
            switch split {
            case .equally:
                if expense.participants.isEmpty { continue }
                let amountPerPerson = expense.cost / Double(expense.participants.count)
                
                for participant in expense.participants {
                    if participant != expense.paidBy {
                        allDebts.append(Debt(
                            debtor: participant,
                            creditor: expense.paidBy,
                            amount: amountPerPerson,
                            expenseId: expense.id
                        ))
                    }
                }
                
            case .exactly:
                guard let amounts = expense.customAmounts else { continue }
                
                for (userId, amount) in amounts {
                    if userId != expense.paidBy && amount > 0 {
                        allDebts.append(Debt(
                            debtor: userId,
                            creditor: expense.paidBy,
                            amount: amount,
                            expenseId: expense.id
                        ))
                    }
                }
            }
        }
        
        return allDebts
    }
    
    // Simplify debts by consolidating debtor-creditor relationships
    static func simplifyDebts(_ debts: [Debt]) -> [Balance] {
        // Group debts by debtor-creditor pairs
        var debtMap: [String: Double] = [:]
        
        for debt in debts {
            let key = "\(debt.debtor)|\(debt.creditor)"
            let reverseKey = "\(debt.creditor)|\(debt.debtor)"
            
            if debtMap[reverseKey] != nil {
                // There's an opposite debt, so reduce it
                debtMap[reverseKey]! -= debt.amount
                
                // If it became negative, flip the direction
                if debtMap[reverseKey]! < 0 {
                    debtMap[key] = -debtMap[reverseKey]!
                    debtMap[reverseKey] = 0
                }
            } else {
                // Add to existing debt or create new entry
                debtMap[key] = (debtMap[key] ?? 0) + debt.amount
            }
        }
        
        // Convert back to Balance objects, excluding zero amounts
        var simplifiedBalances: [Balance] = []
        
        for (key, amount) in debtMap {
            if amount > 0 {
                let parts = key.split(separator: "|")
                let debtor = String(parts[0])
                let creditor = String(parts[1])
                
                simplifiedBalances.append(Balance(
                    debtor: debtor,
                    creditor: creditor,
                    amount: amount
                ))
            }
        }
        
        return simplifiedBalances
    }
    
    // Calculate final balances (simplified since we're using names directly)
    static func calculateFinalBalances(from expenses: [Expense], roommates: [Roommate]) -> [Balance] {
        let allDebts = calculateAllDebts(from: expenses)
        let balances = simplifyDebts(allDebts)
        
        // Names are already stored in the balance objects
        return balances
    }
}

import SwiftUI

struct BalancesView: View {
    let balances: [Balance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("balances")
                .font(.headline)
                .padding(.bottom, 5)
            
            if balances.isEmpty {
                Text("All settled up! No balances to display.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.vertical, 10)
            } else {
                ForEach(balances) { balance in
                    HStack {
                        Text("\(balance.debtor) owes \(balance.creditor)")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", balance.amount))")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.9, green: 0.95, blue: 1.0))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Update ExpensesView.swift to include the BalancesView

//extension ExpensesView {
//    var balancesSection: some View {
//        VStack(alignment: .leading) {
//            let balances = BalanceCalculator.calculateFinalBalances(
//                from: expenseManager.expenses,
//                roommates: roommateManager.roommates
//            )
//            
//            BalancesView(balances: balances)
//                .padding(.horizontal)
//                .padding(.top, 10)
//        }
//    }
//}


