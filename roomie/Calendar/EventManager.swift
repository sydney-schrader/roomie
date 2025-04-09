//
//  Event.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseFirestore

struct Event: Identifiable, Codable {
    var id: String
    var name: String
    var date: Date
    var startTime: String?
    var endTime: String?
    var isAllDay: Bool
    var location: String
    var description: String
    var createdBy: String // User ID who created the event
    var colorHex: String // Store color as hex string for Firestore compatibility
    var host: String
    var repeats: String? // e.g. "weekly", "monthly", etc.
    
    var color: Color {
        Color(hex: colorHex) ?? Color(red: 0.8, green: 0.8, blue: 1.0)
    }
    
    var timeDisplay: String {
        if isAllDay {
            return "all day"
        } else if let start = startTime {
            if let end = endTime {
                return "\(start) - \(end)"
            }
            return start
        } else {
            return ""
        }
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         date: Date,
         startTime: String? = nil,
         endTime: String? = nil,
         isAllDay: Bool = false,
         location: String = "",
         description: String = "",
         createdBy: String = "",
         colorHex: String = "#CCCCFF",
         host: String = "",
         repeats: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
        self.location = location
        self.description = description
        self.createdBy = createdBy
        self.colorHex = colorHex
        self.host = host
        self.repeats = repeats
    }
    
    // Convert to Dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "date": Timestamp(date: date),
            "isAllDay": isAllDay,
            "location": location,
            "description": description,
            "createdBy": createdBy,
            "colorHex": colorHex,
            "host": host
        ]
        
        if let startTime = startTime {
            dict["startTime"] = startTime
        }
        
        if let endTime = endTime {
            dict["endTime"] = endTime
        }
        
        if let repeats = repeats {
            dict["repeats"] = repeats
        }
        
        return dict
    }
    
    // Create from Firestore document
    static func fromDictionary(_ dict: [String: Any], id: String) -> Event? {
        guard let name = dict["name"] as? String,
              let timestamp = dict["date"] as? Timestamp,
              let isAllDay = dict["isAllDay"] as? Bool,
              let location = dict["location"] as? String,
              let description = dict["description"] as? String,
              let createdBy = dict["createdBy"] as? String,
              let colorHex = dict["colorHex"] as? String else {
            return nil
        }
        
        let date = timestamp.dateValue()
        let startTime = dict["startTime"] as? String
        let endTime = dict["endTime"] as? String
        let host = dict["host"] as? String ?? ""
        let repeats = dict["repeats"] as? String
        
        return Event(
            id: id,
            name: name,
            date: date,
            startTime: startTime,
            endTime: endTime,
            isAllDay: isAllDay,
            location: location,
            description: description,
            createdBy: createdBy,
            colorHex: colorHex,
            host: host,
            repeats: repeats
        )
    }
}

// Helper extension to convert hex color strings to Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}


//  EventManager.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class EventManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        self.events = []
        fetchEvents()
    }
    
    deinit {
        // Remove listener when the manager is deallocated
        stopListening()
    }
    
    // Helper method to sort events in a consistent way
    private func sortEvents() {
        self.events.sort { first, second in
            // First compare by date
            if !Calendar.current.isDate(first.date, inSameDayAs: second.date) {
                return first.date < second.date
            }
            
            // If same date and both have start times, compare by start time
            if let firstTime = first.startTime, let secondTime = second.startTime {
                // Convert time strings to comparable format
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                
                if let firstDate = formatter.date(from: firstTime),
                   let secondDate = formatter.date(from: secondTime) {
                    return firstDate < secondDate
                }
            }
            
            // All-day events come first
            if first.isAllDay && !second.isAllDay {
                return true
            } else if !first.isAllDay && second.isAllDay {
                return false
            }
            
            // If both are all-day or neither has a start time, sort by name
            return first.name < second.name
        }
    }
    
    func fetchEvents() {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            self.errorMessage = "No household ID found"
            return
        }
        
        isLoading = true
        
        // Remove any existing listener
        stopListening()
        self.events = []
        
        // Set up real-time listener for events
        listener = db.collection("households").document(currentHouseholdID).collection("events")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error fetching events: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                // Update the events array
                let fetchedEvents = documents.compactMap { document -> Event? in
                    return Event.fromDictionary(document.data(), id: document.documentID)
                }
                
                DispatchQueue.main.async {
                    self.events = fetchedEvents
                    self.sortEvents()
                    self.isLoading = false
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func getEventsForDate(date: Date) -> [Event] {
        let calendar = Calendar.current
        let filteredEvents = events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
        
        // Events are already sorted by the main events array sort,
        // so no need to sort again here
        return filteredEvents
    }
    
    func addEvent(event: Event, completion: @escaping (Bool, String?) -> Void) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            completion(false, "No household ID found")
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            completion(false, "No user logged in")
            return
        }
        
        // Create a new event with the current user as creator
        var newEvent = event
        newEvent.createdBy = currentUser.uid
        
        let eventData = newEvent.toDictionary()
        
        isLoading = true // Show loading indicator while adding
        
        db.collection("households").document(currentHouseholdID).collection("events")
            .document(newEvent.id)
            .setData(eventData) { [weak self] error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error adding event: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("Event added successfully")
                    
                    DispatchQueue.main.async {
                        // Check if the event is already in the array (by ID)
                        if !self.events.contains(where: { $0.id == newEvent.id }) {
                            // Add the event and re-sort the array
                            self.events.append(newEvent)
                            self.sortEvents()
                        }
                    }
                    
                    completion(true, nil)
                }
            }
    }
    
    func updateEvent(event: Event, completion: @escaping (Bool, String?) -> Void) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            completion(false, "No household ID found")
            return
        }
        
        let eventData = event.toDictionary()
        
        db.collection("households").document(currentHouseholdID).collection("events")
            .document(event.id)
            .updateData(eventData) { error in
                if let error = error {
                    print("Error updating event: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("Event updated successfully")
                    completion(true, nil)
                }
            }
    }
    
    func deleteEvent(eventId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let currentHouseholdID = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            completion(false, "No household ID found")
            return
        }
        
        db.collection("households").document(currentHouseholdID).collection("events")
            .document(eventId)
            .delete() { error in
                if let error = error {
                    print("Error deleting event: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("Event deleted successfully")
                    completion(true, nil)
                }
            }
    }
    
    // Predefined colors for events
    static let eventColors: [(name: String, hex: String)] = [
        ("Purple", "#CCCCFF"),
        ("Blue", "#CCE5FF"),
        ("Green", "#CCFFCC"),
        ("Pink", "#FFCCFF"),
        ("Yellow", "#FFFFCC"),
        ("Orange", "#FFE5CC")
    ]
}
