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

struct UserProfile {
    var id: String
    var firstName: String
    var email: String
    var householdIds: [String]
    var currentHouseholdId: String?
    
    func toDicttionary() -> [String: Any] {
        var dict: [String: Any] = [
            "firstName": firstName,
            "email": email,
            "householdIds": householdIds
        ]
        
        if let currentHouseholdId = currentHouseholdId {
            dict["currentHouseholdId"] = currentHouseholdId
        }
        
        return dict
    }
}

struct Roommate: Identifiable{
    var id = UUID()
    var userId: String
    var firstName: String
    var email: String
    var choreDay: DayOfWeek?
    var laundryDay: DayOfWeek?
    var rentInfo: RentInfo?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "firstName": firstName,
            "email": email
        ]
        
        if let choreDay = choreDay {
            dict["choreDay"] = choreDay.rawValue
        }
        
        if let laundryDay = laundryDay {
            dict["laundryDay"] = laundryDay.rawValue
        }
        
        if let rentInfo = rentInfo {
            dict["rentInfo"] = rentInfo.toDictionary()
        }
        
        return dict
    }
    
//    static func fromDictionary(_ dict: [String: Any], id: String) -> Roommate? {
//        guard let firstName = dict["firstName"] as? String,
//              let email = dict["email"] as? String else {
//            return nil
//        }
//        
//        
//        var choreDay: DayOfWeek? = nil
//        if let choreDayString = dict["choreDay"] as? String {
//            choreDay = DayOfWeek(rawValue: choreDayString)
//        }
//        
//        var laundryDay: DayOfWeek? = nil
//        if let laundryDayString = dict["laundryDay"] as? String {
//            laundryDay = DayOfWeek(rawValue: laundryDayString)
//        }
//        
//        return Roommate(id: id, firstName: firstName, email: email, choreDay: choreDay, laundryDay: laundryDay)
//    }
}

class UserManager: ObservableObject {
    private let db = Firestore.firestore()
    
    func createUserProfile(userId: String, firstName: String, email: String, completion: @escaping (Bool, String?) -> Void) {
        let userData: [String: Any] = [
            "firstName": firstName,
            "email": email,
            "householdIds": [],
            "currentHouseholdId": ""
        ]
        
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                completion(false, "Error creating user profile: \(error.localizedDescription)")
                return
            }
            completion(true, nil)
        }
    }
    
    func addHouseholdToUser(userId: String, householdId: String, setAsCurrent: Bool = true, completion: @escaping (Bool, String?) -> Void) {
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { document, error in
            if let error = error {
                completion(false, "Error fetching user: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                completion(false, "User document does not exist")
                return
            }
            
            var householdIds = document.data()?["householdIds"] as? [String] ?? []
            if !householdIds.contains(householdId) {
                householdIds.append(householdId)
            }
            
            var updateData: [String: Any] = ["householdIds": householdIds]
            
            // Set as current household if requested
            if setAsCurrent {
                updateData["currentHouseholdId"] = householdId
                UserDefaults.standard.set(householdId, forKey: "currentHouseholdID")
            }
            
            userRef.updateData(updateData) { error in
                if let error = error {
                    completion(false, "Error updating user: \(error.localizedDescription)")
                    return
                }
                completion(true, nil)
            }
        }
    }
    
    func fetchCurrentUserProfile(completion: @escaping (UserProfile?, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, "No authenticated user")
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(nil, "Error fetching user: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(nil, "User document not found")
                return
            }
            
            let firstName = data["firstName"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let householdIds = data["householdIds"] as? [String] ?? []
            let currentHouseholdId = data["currentHouseholdId"] as? String
            
            let profile = UserProfile(
                id: userId,
                firstName: firstName,
                email: email,
                householdIds: householdIds,
                currentHouseholdId: currentHouseholdId
            )
            
            completion(profile, nil)
        }
    }
}

class RoommateManager: ObservableObject {
    @Published var roommates: [Roommate] = []
    private let db = Firestore.firestore()
    
    func updateUserSettings(userId: String, userData: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").document(userId).updateData(userData) { error in
            if let error = error {
                completion(false, "Error updating user settings: \(error.localizedDescription)")
                return
            }
            completion(true, nil)
        }
    }
    
    func fetchRoommates() {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            print("No household ID found")
            return
        }
        
        print("Fetching household data: \(currentHouseholdID)")
        
        // First get the roommates array from the household
        db.collection("households").document(currentHouseholdID).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), let roommates = data["roommates"] as? [String] else {
                print("Error loading household roommates: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            print("Found \(roommates.count) roommates in household")
            
            if roommates.isEmpty {
                DispatchQueue.main.async {
                    self.roommates = []
                }
                return
            }
            
            // Then fetch each user's data from the users collection
            let group = DispatchGroup()
            var fetchedRoommates: [Roommate] = []
            
            for userId in roommates {
                group.enter()
                self.db.collection("users").document(userId).getDocument { userSnapshot, userError in
                    defer { group.leave() }
                    
                    if let userData = userSnapshot?.data(), let firstName = userData["firstName"] as? String, let email = userData["email"] as? String {
                        print("Found user: \(firstName)")
                        
                        var choreDay: DayOfWeek? = nil
                        if let choreDayString = userData["choreDay"] as? String {
                            choreDay = DayOfWeek(rawValue: choreDayString)
                        }
                        
                        var laundryDay: DayOfWeek? = nil
                        if let laundryDayString = userData["laundryDay"] as? String {
                            laundryDay = DayOfWeek(rawValue: laundryDayString)
                        }
                        
                        let roommate = Roommate(userId: userId, firstName: firstName, email: email, choreDay: choreDay, laundryDay: laundryDay)
                        fetchedRoommates.append(roommate)
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("Finished fetching \(fetchedRoommates.count) roommates")
                self.roommates = fetchedRoommates
            }
        }
    }
    

    
//    func addRoommate(_ roommate: Roommate) {
//        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
//            print("No household ID found")
//            return
//        }
//        
//        let roommateData = roommate.toDictionary()
//        
//        db.collection("households").document(currentHouseholdID).collection("roommates")
//            .document(roommate.id)
//            .setData(roommateData) { error in
//                if let error = error {
//                    print("Error adding roommate: \(error.localizedDescription)")
//                } else {
//                    print("Roommate added successfully")
//                }
//            }
//    }
//    
//    
//    func removeRoommate(id: String) {
//        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
//            print("No household ID found")
//            return
//        }
//        
//        db.collection("households").document(currentHouseholdID).collection("roommates")
//            .document(id)
//            .delete() { error in
//                if let error = error {
//                    print("Error removing roommate: \(error.localizedDescription)")
//                } else {
//                    print("Roommate removed successfully")
//                }
//            }
//    }
//    
    func addRentInfo(userId: String, rentInfo: RentInfo, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").document(userId).updateData(["rentInfo": rentInfo.toDictionary()]) { error in
            if let error = error {
                print("Error saving rent info: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("Rent info saved successfully")
                completion(true, nil)
            }
        }
    }
    
    func addLaundryDay(userId: String, laundryDay: DayOfWeek, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").document(userId).updateData(["laundryDay": laundryDay.rawValue]) { error in
            if let error = error {
                print("Error updating laundry day: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("Laundry day updated successfully")
                completion(true, nil)
            }
        }
    }
    
    func addChoreDay(userId: String, choreDay: DayOfWeek, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").document(userId).updateData(["choreDay": choreDay.rawValue]) { error in
            if let error = error {
                print("Error updating chore day: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("Chore day updated successfully")
                completion(true, nil)
            }
        }
    }
    
    func checkUserSettings(completion: @escaping (Bool, Bool, Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, false, false)
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error getting user settings: \(error.localizedDescription)")
                completion(false, false, false)
                return
            }
            
            guard let data = document?.data() else {
                completion(false, false, false)
                return
            }
            
            let hasRentInfo = data["rentInfo"] != nil
            let hasLaundryDay = data["laundryDay"] != nil
            let hasChoreDay = data["choreDay"] != nil
            
            completion(hasRentInfo, hasLaundryDay, hasChoreDay)
        }
    }
}

struct Household: Identifiable, Codable {
    var id: String
    var name: String
    var joinCode: String
    var roommates: [String]
    var essentialsOption: Int // 0=rotate, 1=split, 2=individual
    var hostingOption: Int // 0=all approve all, 1=approve certain, 2=no approval
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "joinCode": joinCode,
            "roommates": roommates,
            "essentialsOption": essentialsOption,
            "hostingOption": hostingOption
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Household? {
        guard let name = dict["name"] as? String,
              let joinCode = dict["joinCode"] as? String,
              let roommates = dict["roommates"] as? [String] else {
            return nil
        }
        
        let essentialsOption = dict["essentialsOption"] as? Int ?? -1
        let hostingOption = dict["hostingOption"] as? Int ?? -1
        
        return Household(
            id: id,
            name: name,
            joinCode: joinCode,
            roommates: roommates,
            essentialsOption: essentialsOption,
            hostingOption: hostingOption
        )
    }
}

class HouseholdManager: ObservableObject {
    @Published var households: [Household] = []
    @Published var currentHousehold: Household?
    private let db = Firestore.firestore()
    private let userManager = UserManager()
    
    func createHousehold(name: String, completion: @escaping (String?, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid,
              let firstName = Auth.auth().currentUser?.displayName,
              let email = Auth.auth().currentUser?.email else {
            completion(nil, "No user logged in or missing user information")
            return
        }
        
        let joinCode = generateJoinCode()
        
        let householdId = UUID().uuidString
        let newHousehold = Household(
            id: householdId,
            name: name,
            joinCode: joinCode,
            roommates: [userId],
            essentialsOption: -1,
            hostingOption: -1
        )
        
        // First, ensure user document exists
        userManager.fetchCurrentUserProfile { profile, error in
            if profile == nil {
                // Create user document if it doesn't exist
                self.userManager.createUserProfile(userId: userId, firstName: firstName, email: email) { success, error in
                    if !success {
                        completion(nil, error)
                        return
                    }
                    // Continue with household creation
                    self.createHouseholdAndUpdate(userId, householdId, newHousehold, completion)
                }
            } else {
                // User exists, continue with household creation
                self.createHouseholdAndUpdate(userId, householdId, newHousehold, completion)
            }
        }
    }

    private func createHouseholdAndUpdate(_ userId: String, _ householdId: String, _ household: Household, _ completion: @escaping (String?, String?) -> Void) {
        db.collection("households").document(householdId).setData(household.toDictionary()) { [weak self] error in
            if let error = error {
                completion(nil, "Error creating household: \(error.localizedDescription)")
                return
            }
            
            // Add household to user
            self?.userManager.addHouseholdToUser(userId: userId, householdId: householdId) { success, error in
                if !success {
                    completion(nil, error)
                    return
                }
                completion(householdId, nil)
            }
        }
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
            
            var roommates = data["roommates"] as? [String] ?? []
            if !roommates.contains(userId) {
                roommates.append(userId)
                
                self.db.collection("households").document(householdId).updateData(["roommates": roommates]) { error in
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


