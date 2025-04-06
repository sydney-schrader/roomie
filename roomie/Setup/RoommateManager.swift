//
//  RoommateManager.swift
//  roomie
//
//  Created by Sydney Schrader on 2/25/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

enum DayOfWeek: String, Codable, CaseIterable {
    case sunday = "sunday",
         monday = "monday",
         tuesday = "tuesday",
         wednesday = "wednesday",
         thursday = "thursday",
         friday = "friday",
         saturday = "saturday"
}

struct RentInfo {
    var amount: Double
    //var owedTo: String
    var hasReminders: Bool
    var dueDayOfMonth: Int
    var dueTime: Date
    
    func toDictionary() -> [String: Any] {
        return [
            "amount": amount,
            //"owedTo": owedTo,
            "hasReminders": hasReminders,
            "dueDayOfMonth": dueDayOfMonth,
            "dueTime" : dueTime
        ]
    }
}

struct Roommate: Identifiable, Codable {
    var id: String
    var firstName: String
    var email: String
    var choreDay: DayOfWeek?
    var laundryDay: DayOfWeek?
    
    init(id: String = UUID().uuidString, firstName: String, email: String, choreDay: DayOfWeek? = nil, laundryDay: DayOfWeek? = nil) {
        self.id = id
        self.firstName = firstName
        self.email = email
        self.choreDay = choreDay
        self.laundryDay = laundryDay
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "firstName": firstName,
            "email": email
        ]
        
        if let choreDay = choreDay {
            dict["choreDay"] = choreDay.rawValue
        }
        
        if let laundryDay = laundryDay {
            dict["laundryDay"] = laundryDay.rawValue
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Roommate? {
        guard let firstName = dict["firstName"] as? String,
              let email = dict["email"] as? String else {
            return nil
        }
        
        
        var choreDay: DayOfWeek? = nil
        if let choreDayString = dict["choreDay"] as? String {
            choreDay = DayOfWeek(rawValue: choreDayString)
        }
        
        var laundryDay: DayOfWeek? = nil
        if let laundryDayString = dict["laundryDay"] as? String {
            laundryDay = DayOfWeek(rawValue: laundryDayString)
        }
        
        return Roommate(id: id, firstName: firstName, email: email, choreDay: choreDay, laundryDay: laundryDay)
    }
}

class RoommateManager: ObservableObject {
    @Published var roommates: [Roommate] = []
    private let db = Firestore.firestore()
    private var listenersRegistered = false
    
    init() {
        fetchRoommates()
    }
    
    func fetchRoommates() {
        guard UserDefaults.standard.string(forKey: "currentHouseholdID") != nil else {
            print("No household ID found")
            return
        }
        
        db.collection("roommates")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting roommates: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No roommate documents found")
                    return
                }
                
                let updatedRoommates = documents.compactMap { document in
                    Roommate.fromDictionary(document.data(), id: document.documentID)
                }
                
                DispatchQueue.main.async {
                    self.roommates = updatedRoommates
                }
            }
    }
    
    func addRoommate(_ roommate: Roommate) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            print("No household ID found")
            return
        }
        
        let roommateData = roommate.toDictionary()
        
        db.collection("households").document(currentHouseholdID).collection("roommates")
            .document(roommate.id)
            .setData(roommateData) { error in
                if let error = error {
                    print("Error adding roommate: \(error.localizedDescription)")
                } else {
                    print("Roommate added successfully")
                }
            }
    }
    
    
    func removeRoommate(id: String) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            print("No household ID found")
            return
        }
        
        db.collection("households").document(currentHouseholdID).collection("roommates")
            .document(id)
            .delete() { error in
                if let error = error {
                    print("Error removing roommate: \(error.localizedDescription)")
                } else {
                    print("Roommate removed successfully")
                }
            }
    }
    
    func saveRentInfo(userId: String, rentInfo: RentInfo, completion: @escaping (Bool, String?) -> Void) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            completion(false, "No current household found")
            return
        }
        
        let rentData = rentInfo.toDictionary()
        
        db.collection("households")
            .document(currentHouseholdID)
            .collection("roommates")
            .document(userId)
            .updateData(["rentInfo": rentData]) { error in
                if let error = error {
                    print("Error saving rent info: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("Rent info saved successfully")
                    completion(true, nil)
                }
            }
        
        // Also update the user's profile in the users collection
        db.collection("users")
            .document(userId)
            .updateData(["rentInfo": rentData]) { error in
                if let error = error {
                    print("Error updating user rent info: \(error.localizedDescription)")
                }
            }
    }
    
    func addLaundryDay(userId: String, laundryDay: DayOfWeek, completion: @escaping (Bool, String?) -> Void) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            completion(false, "No household ID found")
            return
        }
        
        db.collection("households").document(currentHouseholdID).collection("roommates")
            .document(userId)
            .updateData(["laundryDay": laundryDay.rawValue]) { error in
                if let error = error {
                    print("Error updating laundry day: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("Laundry day updated successfully")
                    completion(true, nil)
                }
            }
        // Also update the user's profile in the users collection
        db.collection("users")
            .document(userId)
            .updateData(["laundryDay": laundryDay.rawValue]) { error in
                if let error = error {
                    print("Error updating user laundry info: \(error.localizedDescription)")
                }
            }
    }
    
    func addChoreDay(userId: String, choreDay: DayOfWeek, completion: @escaping (Bool, String?) -> Void) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            completion(false, "No household ID found")
            return
        }
        
        db.collection("households").document(currentHouseholdID).collection("roommates")
            .document(userId)
            .updateData(["choreDay": choreDay.rawValue]) { error in
                if let error = error {
                    print("Error updating chore day: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("chore day updated successfully")
                    completion(true, nil)
                }
            }
        // Also update the user's profile in the users collection
        db.collection("users")
            .document(userId)
            .updateData(["choreDay": choreDay.rawValue]) { error in
                if let error = error {
                    print("Error updating user chore info: \(error.localizedDescription)")
                }
            }
    }
    
    func checkUserSettings(completion: @escaping (Bool, Bool, Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false, false, false)
            return
        }
        
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            completion(false, false, false)
            return
        }
        
        // Check for user settings in Firebase
        db.collection("users").document(currentUser.uid)
            .getDocument { document, error in
                // Initialize all as false
                var hasRentInfo = false
                var hasLaundryDay = false
                var hasChoreDay = false
                
                if let document = document, document.exists, let data = document.data() {
                    // Check for rent info
                    if let rentInfo = data["rentInfo"] as? [String: Any],
                       !rentInfo.isEmpty,
                       let amount = rentInfo["amount"] as? Double,
                       amount > 0 {
                        hasRentInfo = true
                    }
                    
                    // Check for laundry day
                    if let laundryDayString = data["laundryDay"] as? String,
                       !laundryDayString.isEmpty,
                       DayOfWeek(rawValue: laundryDayString) != nil {
                        hasLaundryDay = true
                    }
                    
                    // Check for chore day
                    if let choreDayString = data["choreDay"] as? String,
                       !choreDayString.isEmpty,
                       DayOfWeek(rawValue: choreDayString) != nil {
                        hasChoreDay = true
                    }
                }
                
                // Return results via completion handler
                completion(hasRentInfo, hasLaundryDay, hasChoreDay)
            }
    }
}

struct Household: Identifiable, Codable {
    var id: String
    var name: String
    var joinCode: String
    var members: [String]
    var essentialsOption: Int // 0=rotate, 1=split, 2=individual
    var hostingOption: Int // 0=all approve all, 1=approve certain, 2=no approval
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "joinCode": joinCode,
            "members": members,
            "essentialsOption": essentialsOption,
            "hostingOption": hostingOption
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Household? {
        guard let name = dict["name"] as? String,
              let joinCode = dict["joinCode"] as? String,
              let members = dict["members"] as? [String] else {
            return nil
        }
        
        let essentialsOption = dict["essentialsOption"] as? Int ?? -1
        let hostingOption = dict["hostingOption"] as? Int ?? -1
        
        return Household(
            id: id,
            name: name,
            joinCode: joinCode,
            members: members,
            essentialsOption: essentialsOption,
            hostingOption: hostingOption
        )
    }
}

class HouseholdManager: ObservableObject {
    @Published var households: [Household] = []
    @Published var currentHousehold: Household?
    private let db = Firestore.firestore()
    
    func createHousehold(name: String) -> String {
        guard let userId = Auth.auth().currentUser?.uid,
              let firstName = Auth.auth().currentUser?.displayName,
              let email = Auth.auth().currentUser?.email else {
            print("No user logged in or missing user information")
            return ""
        }
        
        let joinCode = generateJoinCode()
        
        let householdId = UUID().uuidString
        let newHousehold = Household(
            id: householdId,
            name: name,
            joinCode: joinCode,
            members: [userId],
            essentialsOption: -1, // Not set yet
            hostingOption: -1 // Not set yet
        )
        
        let batch = db.batch()
        let householdRef = db.collection("households").document(householdId)
        batch.setData(newHousehold.toDictionary(), forDocument: householdRef)
        let roommateRef = householdRef.collection("roommates").document(userId)
        
        let roommateData: [String: Any] = [
            "firstName": firstName,
            "email": email
        ]
        
        batch.setData(roommateData, forDocument: roommateRef)
        
        batch.commit { error in
            if let error = error {
                print("Error creating household: \(error)")
            } else {
                print("Household and roommate created successfully")
                
                self.addHouseholdToUser(userId: userId, householdId: householdId)
                
                UserDefaults.standard.set(householdId, forKey: "currentHouseholdID")
            }
        }
        
        return householdId
    }
    
    func joinHousehold(joinCode: String, completion: @escaping (Bool, String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "No user logged in")
            return
        }
        
        db.collection("households").whereField("joinCode", isEqualTo: joinCode).getDocuments { snapshot, error in
            if let error = error {
                completion(false, "Error: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(false, "Invalid join code")
                return
            }
            
            let householdId = documents[0].documentID
            let data = documents[0].data()
            
            var members = data["members"] as? [String] ?? []
            if !members.contains(userId) {
                members.append(userId)
                
                self.db.collection("households").document(householdId).updateData(["members": members]) { error in
                    if let error = error {
                        completion(false, "Error joining: \(error.localizedDescription)")
                    } else {
                        self.addHouseholdToUser(userId: userId, householdId: householdId)
                        
                        UserDefaults.standard.set(householdId, forKey: "currentHouseholdID")
                        completion(true, "Successfully joined household")
                    }
                }
            } else {
                completion(false, "You're already a member of this household")
            }
        }
    }
    
    func updateHouseholdSettings(householdId: String, essentialsOption: Int, hostingOption: Int) {
        db.collection("households").document(householdId).updateData([
            "essentialsOption": essentialsOption,
            "hostingOption": hostingOption
        ]) { error in
            if let error = error {
                print("Error updating settings: \(error)")
            } else {
                print("Household settings updated successfully")
            }
        }
    }
    
    private func addHouseholdToUser(userId: String, householdId: String) {
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                var householdIds = document.data()?["householdIds"] as? [String] ?? []
                if !householdIds.contains(householdId) {
                    householdIds.append(householdId)
                    userRef.updateData(["householdIds": householdIds])
                }
            } else {
                userRef.setData(["householdIds": [householdId]])
            }
        }
    }
    
    @MainActor
    func fetchCurrentHousehold() async -> Household? {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            print("No household ID found in UserDefaults")
            return nil
        }
        
        do {
            let document = try await db.collection("households").document(currentHouseholdID).getDocument()
            
            guard document.exists, let data = document.data() else {
                print("Household document not found")
                return nil
            }
            
            if let household = Household.fromDictionary(data, id: document.documentID) {
                self.currentHousehold = household
                return household
            } else {
                return nil
            }
        } catch {
            print("Error fetching household: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // Generate a random join code
    private func generateJoinCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map{ _ in letters.randomElement()! })
    }
}


//struct RoommatePickerOption: Identifiable, Hashable {
//    let id: String
//    let name: String
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//    
//    static func == (lhs: RoommatePickerOption, rhs: RoommatePickerOption) -> Bool {
//        return lhs.id == rhs.id
//    }
//}

//class HouseholdRoommates: ObservableObject {
//    @Published var roommateOptions: [RoommatePickerOption] = []
//    private let db = Firestore.firestore()
//    private var listener: ListenerRegistration?
//    
//    // Start real-time updates for a household
//    func startListening(householdId: String) {
//        // Remove any existing listener
//        stopListening()
//        
//        // Set up real-time listener
//        listener = db.collection("households").document(householdId).collection("roommates")
//            .addSnapshotListener { [weak self] snapshot, error in
//                guard let self = self else { return }
//                
//                if let error = error {
//                    print("Error listening for roommate updates: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else { return }
//                
//                // Update the roommate options
//                self.roommateOptions = documents.compactMap { doc -> RoommatePickerOption? in
//                    guard let name = doc.data()["firstName"] as? String else { return nil }
//                    return RoommatePickerOption(id: doc.documentID, name: name)
//                }
//            }
//    }
//    
//    // Stop listening for updates
//    func stopListening() {
//        listener?.remove()
//        listener = nil
//    }
//    
//    deinit {
//        stopListening()
//    }
//    
//    // Helper method to get name by ID
//    func getName(for id: String) -> String {
//        return roommateOptions.first(where: { $0.id == id })?.name ?? "Unknown"
//    }
//    
//    // Helper method to get ID by name
//    func getId(for name: String) -> String? {
//        return roommateOptions.first(where: { $0.name == name })?.id
//    }
//}
