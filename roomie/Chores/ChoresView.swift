//
//  ChoresView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/6/25.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CheckBoxView: View {
    @Binding var checked: Bool

    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
            .onTapGesture {
                self.checked.toggle()
            }
    }
}

struct Chore: Codable, Identifiable {
    var id: String
    let title: String
    let assignedTo: String
    var isDone: Bool = false
    
    func toDictionary() -> [String: Any] {
        let dict: [String: Any] = [
            "title": title,
            "assignedTo": assignedTo,
            "isDone": isDone
        ]
        return dict
    }
    
    static func fromDictionary(id: String, data: [String: Any]) -> Chore? {
        guard let title = data["title"] as? String,
              let assignedTo = data["assignedTo"] as? String,
              let isDone = data["isDone"] as? Bool else {
            return nil
        }
        
        return Chore(
            id: id,
            title: title,
            assignedTo: assignedTo,
            isDone: isDone
        )
        
    }
}

class ChoreManager: ObservableObject {
    @Published var chores: [Chore] = []
    private let db = Firestore.firestore()
    
    func fetchChores(for householdId: String) {
        db.collection("households").document(householdId)
            .collection("chores")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else {return}
                
                if let error = error {
                    print("error fetching chores: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("no chore documents found")
                    return
                }
                
                let fetchedChores = documents.compactMap { document ->
                    Chore? in
                    return Chore.fromDictionary(id: document.documentID, data: document.data())
                }
                
                DispatchQueue.main.async {
                    self.chores = fetchedChores
                }
            }
    }
    func addChore(householdId: String, chore: Chore, completion: @escaping (Bool, String?) -> Void) {
        let choreData = chore.toDictionary()
        
        db.collection("households").document(householdId).collection("chores")
            .document(chore.id).setData(choreData) { error in
                if let error = error {
                    completion(false, "Error adding chore: \(error.localizedDescription)")
                    return
                }
                completion(true, nil)
            }
    }
    
    func deleteChore(householdId: String, choreId: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("households").document(householdId).collection("chores")
            .document(choreId).delete() { error in
                if let error = error {
                    completion(false, "Error deleting chore: \(error.localizedDescription)")
                    return
                }
                completion(true, nil)
            }
    }
}

struct ChoresView: View {
//    @State private var chores: [Chore] = [
//        Chore(title: "take out the trash", assignedTo: "jac"),
//        Chore(title: "rent", assignedTo: "ava"),
//        Chore(title: "matts", assignedTo: "syd")
//    ]
    
    @StateObject private var choreManager = ChoreManager()
    @StateObject private var roommateManager = RoommateManager()
    @State private var showingAddChore = false
    @State private var showingChoreDetail = false
    @State private var isLoading = true
    @State private var selectedChore: Chore? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }else if choreManager.chores.isEmpty {
                    VStack {
                        Text("no chores yet")
                            .font(.headline)
                            .padding()
                        
                        Text("add your first chore by tapping the + button")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            showingAddChore = true
                        }) {
                            Text("add chore")
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
                    List {
                        ForEach(choreManager.chores) { chore in
                            ChoreRow(chore: chore)
                                .onTapGesture {
                                    selectedChore = chore
                                    showingChoreDetail = true
                                }
                        }
                        .onDelete { indexSet in
                            deleteChore(at: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("chores")
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        showingAddChore = true
                    }label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView() { newChore in
                    addChore(newChore)
                }
            }
            .sheet(item: $selectedChore) { chore in
                ChoreSettingsView(chore: chore)
            }
//            .sheet(isPresented: $showingChoreDetail, onDismiss: {
//                print("Sheet dismissed")
//                selectedChore = nil
//            }) {
//                if let chore = selectedChore {
//                    ChoreSettingsView(chore: chore)
//                        .onAppear {
//                            print("ChoreSettingsView sheet appeared with chore: \(chore.title)")
//                        }
//                } else {
//                    Text("No chore selected")
//                        .onAppear {
//                            print("Sheet appeared with no chore selected")
//                        }
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
        
        roommateManager.fetchRoommates()
        
        choreManager.fetchChores(for: householdId)
        
        isLoading = false
    }
    
    private func addChore(_ chore: Chore) {
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            return
        }
        
        choreManager.addChore(householdId: householdId, chore: chore) { success, error in
            if !success, let error = error {
                print("Failed to add chore: \(error)")
            }
        }
    }
    
    private func deleteChore(at offsets: IndexSet) {
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            return
        }
        
        for index in offsets {
            let chore = choreManager.chores[index]
            choreManager.deleteChore(householdId: householdId, choreId: chore.id) { _, _ in }
        }
    }
}


struct ChoreRow: View {
    @ObservedObject private var choreManager = ChoreManager()
    @State private var isDone: Bool
    let chore: Chore
    
    init(chore: Chore) {
        self.chore = chore
        _isDone = State(initialValue: chore.isDone)
    }
    
    var body: some View {
        HStack {
            CheckBoxView(checked: $isDone)
                .onChange(of: isDone) {
                    updateChoreStatus(isDone)
                }
            
            Text(chore.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .strikethrough(isDone, color: .black)
            
            Text(chore.assignedTo)
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
    
    private func updateChoreStatus(_ newStatus: Bool) {
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            return
        }
        
        let db = Firestore.firestore()
        db.collection("households").document(householdId)
            .collection("chores").document(chore.id)
            .updateData(["isDone": newStatus]) { error in
                if let error = error {
                    print("Error updating chore status: \(error.localizedDescription)")
                }
            }
    }
}
//#Preview {
//    ChoresView()
//}
