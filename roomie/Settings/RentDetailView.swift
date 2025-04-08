//
//  RentDetailView.swift
//  roomie
//
//  Created by Sydney Schrader on 3/9/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct RentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = ""
    //@State private var owedTo: RoommatePickerOption = RoommatePickerOption(id: Auth.auth().currentUser!.uid, name: (Auth.auth().currentUser?.displayName)!)
    @State private var dueDayOfMonth: Int = Calendar.current.component(.day, from: Date())
    @State private var dueTime: Date = Date()
    @State private var hasReminders: Bool = true
    //@StateObject private var householdRoommates = HouseholdRoommates()
    @State private var errorMessage: String? = ""
    
    var currentUser = Auth.auth().currentUser
    var onSave: ((Double) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header with title and close button
            HStack {
                Text("rent")
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

            
            // Amount
            HStack {
                Text("amount")
                    .fontWeight(.medium)
                
                Spacer()
                
                TextField("$value", text: $amount)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    //.frame(width: 120)
            }
//            Divider()
//            
//            // Paid by
//            HStack {
//                Text("owed to")
//                    .fontWeight(.medium)
//                
//                Spacer()
//                
//                if !householdRoommates.roommateOptions.isEmpty {
//                    Picker("day", selection: $owedTo) {
//                        ForEach(householdRoommates.roommateOptions) { option in
//                            Text(option.name).tag(option as RoommatePickerOption?)
//                        }
//                    }
//                } else {
//                    Text("no roommates found")
//                }
//                
//                
//            }
            Divider()
            
            // Due date
            HStack {
                Text("due date")
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack{
                    HStack() {
                        Text("on the")
                            .frame(width:50)
                        Picker("", selection: $dueDayOfMonth) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)\(ordinalSuffix(for: day))").tag(day)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 80)
                        
                        Text("at")
                            .frame(width: 15)
                        
                        DatePicker("", selection: $dueTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                        // date formatters
                    }
               }
            }
            Divider()
            
            // Reminders
            VStack {
                HStack {
                    Text("reminders")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasReminders)
                        .labelsHidden()
                }
                Text("reminders will occur 1 week, 1 day, and 2 hours before the set due date")
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                
            }
            
            
            Spacer()
            
            Text(errorMessage ?? "")
                .foregroundColor(.red)
            
            // Save button
            HStack {
                Spacer()
                Button(action: {
                    if amount.isEmpty {
                        errorMessage = "Please enter an amount"
                        return
                    }
                    
                    guard let amountValue = Double(amount) else {
                        errorMessage = "Please enter a valid amount"
                        return
                    }
//                    let calendar = Calendar.current
//                    let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
//                    print(calendar.date(from: timeComponents), type(of: calendar.date(from: timeComponents)))
                    // Save action
                    let rentInfo = RentInfo(
                        amount: Double(amount)!,
                        hasReminders: hasReminders,
                        dueDayOfMonth: dueDayOfMonth,
                        dueTime: dueTime
                        )
                    let roommateManager = RoommateManager()
                    guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
                        return
                    }
                    roommateManager.addRentInfo(userId: currentUser?.uid ?? "", rentInfo: rentInfo) { success, errorMessage in
                        if success {
                            DispatchQueue.main.async {
                                onSave?(amountValue)
                                dismiss()
                            }
                        } else {
                            print("Error saving rent info: \(errorMessage ?? "Unknown error")")
                        }
                    }
                }) {
                    Text("save")
                        .foregroundColor(.blue)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.9, green: 0.95, blue: 1.0))
                        .cornerRadius(10)
                }
                Spacer()
            }
            
        }
//        .onAppear {
//            guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
//                return
//            }
//            householdRoommates.startListening(householdId: currentHouseholdID)
//            
////            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
////                if let currentUserId = currentUser?.uid {
////                    owedTo = householdRoommates.roommateOptions.first(where: { $0.id == currentUserId })!
////                }
////            }
//        }
//        .onDisappear {
//            householdRoommates.stopListening()
//        }
        .onAppear {
            loadExistingRentInfo()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func loadExistingRentInfo() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") ?? ""
        
        db.collection("households").document(householdId).collection("roommates")
            .document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user rent info: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let rentInfo = data["rentInfo"] as? [String: Any] else {
                    return
                }
                
                DispatchQueue.main.async {
                    if let amount = rentInfo["amount"] as? Double {
                        self.amount = String(amount)
                    }
                    
                    if let dayOfMonth = rentInfo["dueDayOfMonth"] as? Int {
                        self.dueDayOfMonth = dayOfMonth
                    }
                    
                    if let dueTimeTimestamp = rentInfo["dueTime"] as? Timestamp {
                        self.dueTime = dueTimeTimestamp.dateValue()
                    }
                    
                    if let hasReminders = rentInfo["hasReminders"] as? Bool {
                        self.hasReminders = hasReminders
                    }
                }
            }
    }
}

private func ordinalSuffix(for number: Int) -> String {
    let lastDigit = number % 10
    let lastTwoDigits = number % 100
    
    if lastTwoDigits >= 11 && lastTwoDigits <= 13 {
        return "th"
    }
    
    switch lastDigit {
    case 1: return "st"
    case 2: return "nd"
    case 3: return "rd"
    default: return "th"
    }
}

#Preview {
    RentDetailView()
}
