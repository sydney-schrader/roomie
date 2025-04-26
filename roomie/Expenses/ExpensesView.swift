//
//  ExpensesView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/6/25.
//

// ExpenseManager.swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Expense: Codable, Identifiable {
    var id: String
    let title: String
    let cost: Double
    let paidBy: String
//    let paidByName: String
    let date: Date
//    let splitWith: [String] // User IDs of people who should split this expense
//    let notes: String?
    
    func toDictionary() -> [String: Any] {
        let dict: [String: Any] = [
            "title": title,
            "cost": cost,
            "paidBy": paidBy,
//            "paidByName": paidByName,
            "date": date,
//            "splitWith": splitWith
        ]
        
//        if let notes = notes {
//            dict["notes"] = notes
//        }
        
        return dict
    }
    
    static func fromDictionary(id: String, data: [String: Any]) -> Expense? {
        guard let title = data["title"] as? String,
              let cost = data["cost"] as? Double,
              let paidBy = data["paidBy"] as? String,
//              let paidByName = data["paidByName"] as? String,
              let dateTimestamp = data["date"] as? Timestamp
//              let splitWith = data["splitWith"] as? [String]
        else {
            return nil
        }
        
        let date = dateTimestamp.dateValue()
//        let notes = data["notes"] as? String
        
        return Expense(
            id: id,
            title: title,
            cost: cost,
            paidBy: paidBy,
//            paidByName: paidByName,
            date: date,
//            splitWith: splitWith,
//            notes: notes
        )
    }
}

class ExpenseManager: ObservableObject {
    @Published var expenses: [Expense] = []
    private let db = Firestore.firestore()
    
    // Fetch expenses for the current household
    func fetchExpenses(for householdId: String) {
        db.collection("households").document(householdId).collection("expenses")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching expenses: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No expense documents found")
                    return
                }
                
                let fetchedExpenses = documents.compactMap { document -> Expense? in
                    return Expense.fromDictionary(id: document.documentID, data: document.data())
                }
                
                DispatchQueue.main.async {
                    self.expenses = fetchedExpenses
                }
            }
    }
    
    // Add a new expense
    func addExpense(householdId: String, expense: Expense, completion: @escaping (Bool, String?) -> Void) {
        let expenseData = expense.toDictionary()
        
        db.collection("households").document(householdId).collection("expenses")
            .document(expense.id).setData(expenseData) { error in
                if let error = error {
                    completion(false, "Error adding expense: \(error.localizedDescription)")
                    return
                }
                completion(true, nil)
            }
    }
    
    // Delete an expense
    func deleteExpense(householdId: String, expenseId: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("households").document(householdId).collection("expenses")
            .document(expenseId).delete() { error in
                if let error = error {
                    completion(false, "Error deleting expense: \(error.localizedDescription)")
                    return
                }
                completion(true, nil)
            }
    }
}

// ExpensesView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ExpensesView: View {
    @StateObject private var expenseManager = ExpenseManager()
    @StateObject private var roommateManager = RoommateManager()
    @State private var showingAddExpense = false
    @State private var showingExpenseDetail = false
    @State private var isLoading = true
    @State private var selectedExpense: Expense? = nil
    @State private var essentialsOption: Int = -1
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if expenseManager.expenses.isEmpty {
                    VStack {
                        Text("no expenses yet")
                            .font(.headline)
                            .padding()
                        
                        Text("add your first expense by tapping the + button")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            showingAddExpense = true
                        }) {
                            Text("add expense")
                                .padding()
                                .frame(width: 200)
                                .background(Color(red: 0.6, green: 0.6, blue: 1.0))
                                .foregroundStyle(.black)
                                .cornerRadius(20)
                                .font(.system(size: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        }
                    }
                    .padding()
                } else {
                    // Header
                    HStack {
                        Text("date")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
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
                    
                    // List of expenses
                    List {
                        ForEach(expenseManager.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .listRowInsets(EdgeInsets())
                                .padding(10)
                                .background(Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.7))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedExpense = expense
                                    showingExpenseDetail = true
                                }
                        }
                        .onDelete { indexSet in
                            deleteExpenses(at: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                if essentialsOption == 0 { //0 rotate, 1 split, 2 not at all
                    Text("essentials rotation")
                        .font(.title)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text("date")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("item")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("bought by")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    List {
                        ForEach(expenseManager.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .listRowInsets(EdgeInsets())
                                .padding(10)
                                .background(Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.7))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedExpense = expense
                                    showingExpenseDetail = true
                                }
                        }
                        .onDelete { indexSet in
                            deleteExpenses(at: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    Spacer()
                }
                
            }
            .navigationTitle("expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView() { newExpense in
                    addExpense(newExpense)
                }
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
            }
//            .sheet(isPresented: $showingExpenseDetail, onDismiss: {
//                selectedExpense = nil
//            }) {
//                if let expense = selectedExpense {
//                    ExpenseDetailView(expense: expense)
//                }
//            }
            .onAppear {
                loadData()
            }
            
        }
    }
    
    
    
    private func loadData() {
        isLoading = true
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            isLoading = false
            return
        }
        
        // Create a household manager and fetch the current household
        let householdManager = HouseholdManager()
        
        Task {
            if let household = await householdManager.fetchCurrentHousehold() {
                // Update the essentials option
                DispatchQueue.main.async {
                    self.essentialsOption = household.essentialsOption
                }
            }
            
            // Then fetch the roommates and expenses
            DispatchQueue.main.async {
                self.roommateManager.fetchRoommates()
                self.expenseManager.fetchExpenses(for: householdId)
                self.isLoading = false
            }
        }
    }
    
    private func addExpense(_ expense: Expense) {
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            return
        }
        
        expenseManager.addExpense(householdId: householdId, expense: expense) { success, error in
            if !success, let error = error {
                print("Failed to add expense: \(error)")
            }
        }
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            return
        }
        
        for index in offsets {
            let expense = expenseManager.expenses[index]
            expenseManager.deleteExpense(householdId: householdId, expenseId: expense.id) { _, _ in }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            Text(expense.date.formatted(date: .numeric, time: .omitted))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(expense.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("$\(String(format: "%.2f", expense.cost))")
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(expense.paidBy)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}



struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        ExpensesView()
    }
}
