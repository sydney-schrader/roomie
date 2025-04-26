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
import SwiftUI

enum SplitType: String, Codable, CaseIterable {
    case equally = "equally",
         exactly = "exactly"
}

struct Debt {
    var debtor: String
    var creditor: String
    var amount: Double
    var expenseId: String
}

struct Expense: Codable, Identifiable {
    var id: String
    var title: String
    var cost: Double
    var paidBy: String
    var date: Date
    var split: SplitType?
    var participants: [String]
    var customAmounts: [String: Double]?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "cost": cost,
            "paidBy": paidBy,
            "date": date,
            "participants": participants
        ]
        
        if let split = split {
            dict["split"] = split.rawValue
        }
        
        if let customAmounts = customAmounts {
            dict["customAmounts"] = customAmounts
        }
        
        
        return dict
    }
    
    static func fromDictionary(id: String, data: [String: Any]) -> Expense? {
        guard let title = data["title"] as? String,
              let cost = data["cost"] as? Double,
              let paidBy = data["paidBy"] as? String,
              let dateTimestamp = data["date"] as? Timestamp,
              let participants = data["participants"] as? [String],
              let customAmounts = data["customAmounts"] as? [String: Double]
        else {
            return nil
        }
        var split: SplitType? = nil
        if let splitString = data["split"] as? String {
            split = SplitType(rawValue: splitString)
        }
        let date = dateTimestamp.dateValue()
        
        return Expense(
            id: id,
            title: title,
            cost: cost,
            paidBy: paidBy,
            date: date,
            split: split,
            participants: participants,
            customAmounts: customAmounts
        )
    }
    
    func calculateDebts() -> [Debt] {
        var debts: [Debt] = []
        
        guard let splitType = self.split else { return [] }
        
        switch splitType {
        case .equally:
            if participants.isEmpty { return [] }
            let amountPerPerson = cost / Double(participants.count)
            
            for participant in participants {
                if participant != paidBy {
                    debts.append(Debt(
                        debtor: participant,
                        creditor: paidBy,
                        amount: amountPerPerson,
                        expenseId: id
                    ))
                }
            }
            
        case .exactly:
            guard let amounts = customAmounts else { return [] }
            
            for (userId, amount) in amounts {
                if userId != paidBy && amount > 0 {
                    debts.append(Debt(
                        debtor: userId,
                        creditor: paidBy,
                        amount: amount,
                        expenseId: id
                    ))
                }
            }
        }
        
        return debts
    }
    
    func simplifyDebts(_ debts: [Debt]) -> [Debt] {
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
        
        // Convert back to Debt objects, excluding zero amounts
        var simplifiedDebts: [Debt] = []
        
        for (key, amount) in debtMap {
            if amount > 0 {
                let parts = key.split(separator: "|")
                let debtor = String(parts[0])
                let creditor = String(parts[1])
                
                simplifiedDebts.append(Debt(
                    debtor: debtor,
                    creditor: creditor,
                    amount: amount,
                    expenseId: "" // Not tied to a specific expense
                ))
            }
        }
        
        return simplifiedDebts
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

struct ExpensesView: View {
    @StateObject private var expenseManager = ExpenseManager()
    @StateObject private var roommateManager = RoommateManager()
    @State private var showingAddExpense = false
    @State private var showingExpenseDetail = false
    @State private var isLoading = true
    @State private var selectedExpense: Expense? = nil
    @State private var essentialsOption: Int = -1
    @State private var showBalances = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        // Balances section
                        if showBalances {
                            let balances = BalanceCalculator.calculateFinalBalances(
                                from: expenseManager.expenses,
                                roommates: roommateManager.roommates
                            )
                            
                            BalancesView(balances: balances)
                                .padding(.horizontal)
                        }
                        
                        // Expenses section
                        VStack(spacing: 0) {
                            HStack {
                                Text("recent transactions")
                                    .font(.headline)
                                    .padding(.leading)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddExpense = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 1.0))
                                        .font(.title2)
                                }
                                .padding(.trailing)
                            }
                            .padding(.vertical, 10)
                            
                            if expenseManager.expenses.isEmpty {
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
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("title")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("amount")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    
                                    Text("paid by")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.systemGray6))
                                
                                // List of expenses
                                ForEach(expenseManager.expenses.prefix(5)) { expense in
                                    ExpenseRow(expense: expense)
                                        .padding(10)
                                        .background(Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.7))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                        .onTapGesture {
                                            selectedExpense = expense
                                        }
                                }
                                
                                if expenseManager.expenses.count > 5 {
                                    Button("View all expenses") {
                                        // Navigation logic to all expenses view
                                    }
                                    .padding()
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding()
                        
                        // Essentials section (if applicable)
                        if essentialsOption == 0 { // 0 = rotate
                            EssentialsRotationView()
                        }
                    }
                }
            }
            .navigationTitle("expenses")
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView() { newExpense in
                    addExpense(newExpense)
                }
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
            }
            .onAppear {
                loadData()
            }
            .refreshable {
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
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            Text(expense.date.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 14))
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

struct EssentialsRotationView: View {
    // Placeholder - implement the UI for essentials rotation
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("essentials rotation")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text("Coming soon: Track who's turn it is to buy household essentials.")
                .foregroundColor(.gray)
                .padding(.vertical, 10)
            
            Button("add essential item") {
                // Action
            }
            .padding()
            .background(Color(red: 0.7, green: 0.7, blue: 1.0))
            .foregroundColor(.black)
            .cornerRadius(10)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
    }
}

struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        ExpensesView()
    }
}

//// ExpensesView.swift
//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//
//struct ExpensesView: View {
//    @StateObject private var expenseManager = ExpenseManager()
//    @StateObject private var roommateManager = RoommateManager()
//    @State private var showingAddExpense = false
//    @State private var showingExpenseDetail = false
//    @State private var isLoading = true
//    @State private var selectedExpense: Expense? = nil
//    @State private var essentialsOption: Int = -1
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                if isLoading {
//                    ProgressView()
//                        .scaleEffect(1.5)
//                        .padding()
//                } else if expenseManager.expenses.isEmpty {
//                    VStack {
//                        Text("no expenses yet")
//                            .font(.headline)
//                            .padding()
//                        
//                        Text("add your first expense by tapping the + button")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                            .multilineTextAlignment(.center)
//                            .padding()
//                        
//                        Button(action: {
//                            showingAddExpense = true
//                        }) {
//                            Text("add expense")
//                                .padding()
//                                .frame(width: 200)
//                                .background(Color(red: 0.6, green: 0.6, blue: 1.0))
//                                .foregroundStyle(.black)
//                                .cornerRadius(20)
//                                .font(.system(size: 18))
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 20)
//                                        .stroke(Color.black, lineWidth: 2)
//                                )
//                        }
//                    }
//                    .padding()
//                } else {
//                    // Header
//                    HStack {
//                        Text("date")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text("title")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text("amount")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                        
//                        Text("paid by")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .trailing)
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical, 8)
//                    
//                    // List of expenses
//                    List {
//                        ForEach(expenseManager.expenses) { expense in
//                            ExpenseRow(expense: expense)
//                                .listRowInsets(EdgeInsets())
//                                .padding(10)
//                                .background(Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.7))
//                                .overlay(
//                                    Rectangle()
//                                        .stroke(Color.black, lineWidth: 2)
//                                )
//                                .onTapGesture {
//                                    selectedExpense = expense
//                                    showingExpenseDetail = true
//                                }
//                        }
//                        .onDelete { indexSet in
//                            deleteExpenses(at: indexSet)
//                        }
//                    }
//                    .listStyle(PlainListStyle())
//                }
//                
//                if essentialsOption == 0 { //0 rotate, 1 split, 2 not at all
//                    Text("essentials rotation")
//                        .font(.title)
//                        .multilineTextAlignment(.leading)
//                    
//                    HStack {
//                        Text("date")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text("item")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text("bought by")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .trailing)
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical, 8)
//                    
//                    List {
//                        ForEach(expenseManager.expenses) { expense in
//                            ExpenseRow(expense: expense)
//                                .listRowInsets(EdgeInsets())
//                                .padding(10)
//                                .background(Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.7))
//                                .overlay(
//                                    Rectangle()
//                                        .stroke(Color.black, lineWidth: 2)
//                                )
//                                .onTapGesture {
//                                    selectedExpense = expense
//                                    showingExpenseDetail = true
//                                }
//                        }
//                        .onDelete { indexSet in
//                            deleteExpenses(at: indexSet)
//                        }
//                    }
//                    .listStyle(PlainListStyle())
//                    
//                    Spacer()
//                }
//                
//            }
//            .navigationTitle("expenses")
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        showingAddExpense = true
//                    } label: {
//                        Image(systemName: "plus")
//                    }
//                }
//            }
//            .sheet(isPresented: $showingAddExpense) {
//                AddExpenseView() { newExpense in
//                    addExpense(newExpense)
//                }
//            }
//            .sheet(item: $selectedExpense) { expense in
//                ExpenseDetailView(expense: expense)
//            }
////            .sheet(isPresented: $showingExpenseDetail, onDismiss: {
////                selectedExpense = nil
////            }) {
////                if let expense = selectedExpense {
////                    ExpenseDetailView(expense: expense)
////                }
////            }
//            .onAppear {
//                loadData()
//            }
//            
//        }
//    }
//    
//    
//    
//    private func loadData() {
//        isLoading = true
//        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
//            isLoading = false
//            return
//        }
//        
//        // Create a household manager and fetch the current household
//        let householdManager = HouseholdManager()
//        
//        Task {
//            if let household = await householdManager.fetchCurrentHousehold() {
//                // Update the essentials option
//                DispatchQueue.main.async {
//                    self.essentialsOption = household.essentialsOption
//                }
//            }
//            
//            // Then fetch the roommates and expenses
//            DispatchQueue.main.async {
//                self.roommateManager.fetchRoommates()
//                self.expenseManager.fetchExpenses(for: householdId)
//                self.isLoading = false
//            }
//        }
//    }
//    
//    private func addExpense(_ expense: Expense) {
//        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
//            return
//        }
//        
//        expenseManager.addExpense(householdId: householdId, expense: expense) { success, error in
//            if !success, let error = error {
//                print("Failed to add expense: \(error)")
//            }
//        }
//    }
//    
//    private func deleteExpenses(at offsets: IndexSet) {
//        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
//            return
//        }
//        
//        for index in offsets {
//            let expense = expenseManager.expenses[index]
//            expenseManager.deleteExpense(householdId: householdId, expenseId: expense.id) { _, _ in }
//        }
//    }
//}
//
//struct ExpenseRow: View {
//    let expense: Expense
//    
//    var body: some View {
//        HStack {
//            Text(expense.date.formatted(date: .numeric, time: .omitted))
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Text(expense.title)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Text("$\(String(format: "%.2f", expense.cost))")
//                .frame(maxWidth: .infinity, alignment: .center)
//            
//            Text(expense.paidBy)
//                .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}
//
//
//
//struct ExpensesView_Previews: PreviewProvider {
//    static var previews: some View {
//        ExpensesView()
//    }
//}
