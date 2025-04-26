//
//  AddEventView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseAuth

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventName: String = ""
    @State private var eventDate: Date
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600) // Default to 1 hour later
    @State private var isAllDay: Bool = false
    @State private var location: String = ""
    @State private var description: String = ""
    @State private var selectedColorIndex: Int = 0
    @State private var host: String = ""
    @State private var repeats: String? = nil
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = true
    @StateObject private var roommateManager = RoommateManager()
    
    let onSave: (Event) -> Void
    
    init(selectedDate: Date, onSave: @escaping (Event) -> Void) {
        self._eventDate = State(initialValue: selectedDate)
        self.onSave = onSave
    }
    
    private var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    private var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: endTime)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("event name", text: $eventName)
                        .autocapitalization(.none)
                    
                    DatePicker("date", selection: $eventDate, displayedComponents: .date)
                    
                    Toggle("all day", isOn: $isAllDay)
                    
                    if !isAllDay {
                        DatePicker("start time", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("end time", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                    
                    TextField("location", text: $location)
                        .autocapitalization(.none)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("description")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .autocapitalization(.none)
                    }
                }
                
                Section(header: Text("Color")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(0..<EventManager.eventColors.count, id: \.self) { index in
                                let colorInfo = EventManager.eventColors[index]
                                Circle()
                                    .fill(Color(hex: colorInfo.hex) ?? Color.gray)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColorIndex == index ? Color.black : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColorIndex = index
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Repeating")) {
                    Picker("Repeats", selection: Binding(
                        get: { self.repeats ?? "none" },
                        set: { newValue in
                            self.repeats = newValue == "none" ? nil : newValue
                        }
                    )) {
                        Text("None").tag("none")
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Host")) {
                    if isLoading {
                        HStack {
                            Text("Loading roommates...")
                            Spacer()
                            ProgressView()
                        }
                    } else if roommateManager.roommates.isEmpty {
                        Text("No roommates found")
                    } else {
                        Picker("Host", selection: $host) {
                            ForEach(roommateManager.roommates) { roommate in
                                Text(roommate.firstName).tag(roommate.firstName)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("add event")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadRoommates()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save") {
                        saveEvent()
                    }
                }
            }
        }
    }
    
    private func loadRoommates() {
        isLoading = true
        guard let householdId = UserDefaults.standard.string(forKey: "currentHouseholdID") else {
            isLoading = false
            return
        }
        
        // Debug print to check the household ID
        print("Fetching roommates for household: \(householdId)")
        
        roommateManager.fetchRoommates()
        
        // Add a delay to ensure roommates are loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Debug print to check if roommates were loaded
            print("Found \(self.roommateManager.roommates.count) roommates")
            
            // Set default to current user's name if available
            if let currentUser = Auth.auth().currentUser,
               let displayName = currentUser.displayName,
               !displayName.isEmpty {
                self.host = displayName
                print("Setting default host to current user: \(displayName)")
            } else if !self.roommateManager.roommates.isEmpty {
                self.host = self.roommateManager.roommates[0].firstName
                print("Setting default host to first roommate: \(self.roommateManager.roommates[0].firstName)")
            }
            
            self.isLoading = false
        }
    }
    
    private func saveEvent() {
        // Validate input
        guard !eventName.isEmpty else {
            errorMessage = "Please enter an event name"
            return
        }
        
        // Make sure end time is after start time
        if !isAllDay && endTime < startTime {
            errorMessage = "End time must be after start time"
            return
        }
        
        // Format times as strings
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let startTimeString = isAllDay ? nil : timeFormatter.string(from: startTime)
        let endTimeString = isAllDay ? nil : timeFormatter.string(from: endTime)
        
        // Get selected color
        let colorInfo = EventManager.eventColors[selectedColorIndex]
        
        // Create event object
        let newEvent = Event(
            name: eventName,
            date: eventDate,
            startTime: startTimeString,
            endTime: endTimeString,
            isAllDay: isAllDay,
            location: location,
            description: description,
            createdBy: Auth.auth().currentUser?.uid ?? "",
            colorHex: colorInfo.hex,
            host: host,
            repeats: repeats
        )
        
        // Save the event
        onSave(newEvent)
    }
}

struct AddEventView_Previews: PreviewProvider {
    static var previews: some View {
        AddEventView(selectedDate: Date()) { _ in }
    }
}
