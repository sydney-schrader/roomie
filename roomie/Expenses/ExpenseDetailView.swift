import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var roommateManager = RoommateManager()
    let expense: Expense
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header with title
                VStack(alignment: .leading, spacing: 8) {
                    Text(expense.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
                
                // Main details
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("total")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", expense.cost))")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.9, green: 0.9, blue: 1.0))
                    .cornerRadius(10)
                    
                    HStack {
                        Text("paid by")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(expense.paidBy)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.9, green: 0.9, blue: 1.0))
                    .cornerRadius(10)
                    
                    HStack {
                        Text("split")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(expense.split?.rawValue.capitalized ?? "Unknown")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.9, green: 0.9, blue: 1.0))
                    .cornerRadius(10)
                }
                
                // Participants section
                Text("participants")
                    .font(.headline)
                    .padding(.top, 10)
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(expense.participants, id: \.self) { participantId in
                            HStack {
                                Text(getRoommateName(id: participantId))
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                if expense.split == .equally {
                                    let amount = expense.cost / Double(expense.participants.count)
                                    Text("$\(String(format: "%.2f", amount))")
                                } else {
                                    if let amounts = expense.customAmounts,
                                       let amount = amounts[participantId] {
                                        Text("$\(String(format: "%.2f", amount))")
                                    } else {
                                        Text("$0.00")
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.95, green: 0.95, blue: 1.0))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
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
        roommateManager.fetchRoommates()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    // Since we're now storing names directly, these methods are simplified
    private func getPayer() -> String {
        return expense.paidBy
    }
    
    // This method is kept for backward compatibility if needed
    private func getRoommateName(id: String) -> String {
        return id // Now id is actually the name
    }
   
}
