//
//  LaundryDetailView.swift
//  roomie
//
//  Created by Sydney Schrader on 3/9/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LaundryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: DayOfWeek = .monday
    @State private var hasReminders: Bool = true
    var onSave: ((DayOfWeek) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header with title and close button
            HStack {
                Text("laundry")
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
            
            // Day selection
            HStack {
                Text("day")
                    .fontWeight(.medium)
                
                Spacer()
                
                Picker("day", selection: $selectedDay) {
                    ForEach(DayOfWeek.allCases, id: \.self){ day in
                        Text(day.rawValue)
                    }
                }
            }
            Divider()
            
            // Reminders
            VStack{
                HStack {
                    Text("reminders")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasReminders)
                        .labelsHidden()
                }
                Text("reminders will occur the morning of your chosen day")
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Save button
            HStack {
                Spacer()
                Button(action: {
                    // Save action
                    let roommateManager = RoommateManager()
                    roommateManager.addLaundryDay(userId: Auth.auth().currentUser?.uid ?? "", laundryDay: selectedDay) { success, errorMessage in
                        if success {
                            DispatchQueue.main.async {
                                onSave?(selectedDay)
                                dismiss()
                            }
                        } else {
                            print("Error saving laundry info: \(errorMessage ?? "Unknown error")")
                        }
                    }
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
        .onAppear{
            loadExistingLaundryDay()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    
    private func loadExistingLaundryDay() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") ?? ""
        
        db.collection("households").document(householdId).collection("roommates")
            .document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user laundry day: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let laundryDayString = data["laundryDay"] as? String,
                      let laundryDay = DayOfWeek(rawValue: laundryDayString) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.selectedDay = laundryDay
                }
            }
    }
}


#Preview {
    LaundryDetailView()
}
