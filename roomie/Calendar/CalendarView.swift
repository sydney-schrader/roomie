//////
//////  CalendarView.swift
//////  roomie
//////
//////  Created by Sydney Schrader on 4/8/25.
//////
////
////import SwiftUI
////import FirebaseFirestore
////import FirebaseAuth
////
////struct CalendarView: UIViewRepresentable {
////  var calendarIdentifier: Calendar.Identifier = .gregorian
////  var canSelect: Bool = false
////  @Binding var selectedDate: Date?
////  
////  func makeCoordinator() -> CalendarCoordinator {
////    CalendarCoordinator(calendarIdentifier: calendarIdentifier, canSelect: canSelect, selectedDate: $selectedDate)
////  }
////  
////  func makeUIView(context: Context) -> UICalendarView {
////    let view = UICalendarView()
////    view.calendar = Calendar(identifier: calendarIdentifier)
////    if canSelect {
////      view.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
////    }
////    view.delegate = context.coordinator
////    return view
////  }
////  
////  func updateUIView(_ uiView: UICalendarView, context: Context) {
////    let calendar = Calendar(identifier: calendarIdentifier)
////    uiView.calendar = calendar
////    context.coordinator.calendarIdentifier = calendarIdentifier
////    if !canSelect, let selectedDate {
////      context.coordinator.pickedDate = selectedDate
////    }
////  }
////}
////
////final class CalendarCoordinator: NSObject, UICalendarSelectionSingleDateDelegate, UICalendarViewDelegate {
////  var calendarIdentifier: Calendar.Identifier
////  let canSelect: Bool
////  @Binding var selectedDate: Date?
////  var pickedDate: Date?
////  var calendar: Calendar {
////    Calendar(identifier: calendarIdentifier)
////  }
////  
////  init(calendarIdentifier: Calendar.Identifier, canSelect: Bool, selectedDate: Binding<Date?>) {
////    self.calendarIdentifier = calendarIdentifier
////    self.canSelect = canSelect
////    self._selectedDate = selectedDate
////  }
////  
////  func dateSelection(_ selection: UICalendarSelectionSingleDate,
////                     didSelectDate dateComponents: DateComponents?) {
////    guard
////      let dateComponents,
////      let date = calendar.date(from: dateComponents)
////    else { return }
////    self.selectedDate = date
////  }
////  
////}
////
////struct CalendarScene: View {
////    @State private var selectedDate: Date? = Date()
////    @State private var eventManager = EventManager()
////    @State private var householdManager = HouseholdManager()
////    @State private var household: Household?
////    @State private var showAddEventSheet = false
////    @State private var isLoading = true
////    
////    private var textDate: String {
////        guard let selectedDate else { return "Date not selected" }
////        let formatter = DateFormatter()
////        formatter.dateStyle = .full
////        return formatter.string(from: selectedDate)
////    }
////    
////    private var eventsForSelectedDate: [Event] {
////        guard let selectedDate = selectedDate else { return [] }
////        
////        return eventManager.getEventsForDate(date: selectedDate)
////    }
////    
////    var body: some View {
////        NavigationStack {
////            ScrollView {
////                VStack {
////                    Text("\(household?.name ?? "household") calendar")
////                        .font(.title)
////                        .fontWeight(.bold)
////                    CalendarView(canSelect: true, selectedDate: $selectedDate)
////                        .scaledToFit()
////                }
////                
////                VStack(alignment: .leading) {
////                    Text(textDate)
////                        .font(.headline)
////                        .padding(.top, 8)
////                        .padding(.horizontal)
////                    if eventManager.isLoading {
////                        ProgressView("Loading Evnts...")
////                            .frame(maxWidth: .infinity, alignment: .center)
////                            .padding()
////                    }else if eventsForSelectedDate.isEmpty {
////                        Text("No events for this day")
////                            .foregroundColor(.gray)
////                            .frame(maxWidth: .infinity, alignment: .center)
////                            .padding()
////                    } else {
////                        ScrollView {
////                            VStack(spacing: 8) {
////                                ForEach(eventsForSelectedDate) { event in
////                                    EventRow(event: event)
////                                }
////                                .padding(.horizontal)
////                            }
////                        }
////                    }
////                    Spacer()
//////                    // Add event button
//////                    Button(action: {
//////                        showAddEventSheet = true
//////                    }) {
//////                        Text("add event")
//////                            .foregroundColor(.blue)
//////                            .frame(maxWidth: .infinity)
//////                            .padding(.vertical, 12)
//////                            .background(Color.blue.opacity(0.1))
//////                            .cornerRadius(20)
//////                    }
//////                    .padding()
//////                    Spacer()
////                }
////                .navigationBarTitleDisplayMode(.inline)
////                .toolbar {
////                    ToolbarItem(placement: .navigationBarTrailing) {
////                        Button(action: {
////                            showAddEventSheet = true
////                        }) {
////                            Image(systemName: "plus")
////                        }
////                    }
////                }
////                .sheet(isPresented: $showAddEventSheet) {
////                    AddEventView(selectedDate: selectedDate ?? Date()) { event in
////                        eventManager.addEvent(event: event) { success, error in
////                            if success {
////                                showAddEventSheet = false
////                            }
////                        }
////                    }
////                }
////                .task {
////                    isLoading = true
////                    household = await householdManager.fetchCurrentHousehold()
////                    
////                    isLoading = false
////                }
////            }
////            
////        }
////    }
////}
////
////struct EventRow: View {
////    let event: Event
////    
////    var body: some View {
////        HStack {
////            VStack(alignment: .leading, spacing: 4) {
////                Text(event.name)
////                    .font(.headline)
////                
////                if !event.location.isEmpty {
////                    Text(event.location)
////                        .font(.subheadline)
////                        .foregroundColor(.secondary)
////                }
////            }
////            .padding(.vertical, 10)
////            .padding(.horizontal)
////            .frame(maxWidth: .infinity, alignment: .leading)
////            
////            Text(event.timeDisplay)
////                .font(.subheadline)
////                .foregroundColor(.secondary)
////                .padding(.trailing)
////        }
////        .background(event.color)
////        .cornerRadius(8)
////        .overlay(
////            RoundedRectangle(cornerRadius: 8)
////                .stroke(Color.black, lineWidth: 0.5)
////        )
////    }
////}
////
//
//
////
////  CalendarView.swift
////  roomie
////
////  Created by Sydney Schrader on 4/8/25.
////
//
//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//
//struct CalendarView: UIViewRepresentable {
//  var calendarIdentifier: Calendar.Identifier = .gregorian
//  var canSelect: Bool = false
//  @Binding var selectedDate: Date?
//  
//  func makeCoordinator() -> CalendarCoordinator {
//    CalendarCoordinator(calendarIdentifier: calendarIdentifier, canSelect: canSelect, selectedDate: $selectedDate)
//  }
//  
//  func makeUIView(context: Context) -> UICalendarView {
//    let view = UICalendarView()
//    view.calendar = Calendar(identifier: calendarIdentifier)
//    if canSelect {
//      view.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
//    }
//    view.delegate = context.coordinator
//    return view
//  }
//  
//  func updateUIView(_ uiView: UICalendarView, context: Context) {
//    let calendar = Calendar(identifier: calendarIdentifier)
//    uiView.calendar = calendar
//    context.coordinator.calendarIdentifier = calendarIdentifier
//    if !canSelect, let selectedDate {
//      context.coordinator.pickedDate = selectedDate
//    }
//  }
//}
//
//final class CalendarCoordinator: NSObject, UICalendarSelectionSingleDateDelegate, UICalendarViewDelegate {
//  var calendarIdentifier: Calendar.Identifier
//  let canSelect: Bool
//  @Binding var selectedDate: Date?
//  var pickedDate: Date?
//  var calendar: Calendar {
//    Calendar(identifier: calendarIdentifier)
//  }
//  
//  init(calendarIdentifier: Calendar.Identifier, canSelect: Bool, selectedDate: Binding<Date?>) {
//    self.calendarIdentifier = calendarIdentifier
//    self.canSelect = canSelect
//    self._selectedDate = selectedDate
//  }
//  
//  func dateSelection(_ selection: UICalendarSelectionSingleDate,
//                     didSelectDate dateComponents: DateComponents?) {
//    guard
//      let dateComponents,
//      let date = calendar.date(from: dateComponents)
//    else { return }
//    self.selectedDate = date
//  }
//}
//
//struct CalendarScene: View {
//    @State private var selectedDate: Date? = Date()
//    @StateObject private var eventManager = EventManager()
//    @StateObject private var householdManager = HouseholdManager()
//    @State private var household: Household?
//    @State private var showAddEventSheet = false
//    @State private var showEventDetailSheet = false
//    @State private var isLoading = true
//    @State private var selectedEvent: Event?
//    
//    
//    private var textDate: String {
//        guard let selectedDate else { return "Date not selected" }
//        let formatter = DateFormatter()
//        formatter.dateStyle = .full
//        return formatter.string(from: selectedDate)
//    }
//    
//    private func showEventDetail(_ event: Event) {
//        selectedEvent = event
//        showEventDetailSheet = true
//    }
//    
//    private var eventsForSelectedDate: [Event] {
//        guard let selectedDate = selectedDate else { return [] }
//        return eventManager.getEventsForDate(date: selectedDate)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack {
//                    Text("\(household?.name ?? "household") calendar")
//                        .font(.title)
//                        .fontWeight(.bold)
//                    
//                    CalendarView(canSelect: true, selectedDate: $selectedDate)
//                        .scaledToFit()
//                }
//                .padding()
//                
//                VStack(alignment: .leading) {
//                    Text(textDate)
//                        .font(.headline)
//                        .padding(.top, 8)
//                        .padding(.horizontal)
//                    
//                    if eventManager.isLoading {
//                        ProgressView("Loading events...")
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            .padding()
//                    } else if eventsForSelectedDate.isEmpty {
//                        Text("No events for this day")
//                            .foregroundColor(.gray)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            .padding()
//                    } else {
//                        ScrollView {
//                            VStack(spacing: 8) {
//                                ForEach(eventsForSelectedDate) { event in
//                                    EventRow(event: event)
//                                        .onTapGesture {
//                                            // Show event detail view when tapped
//                                            showEventDetail(event)
//                                        }
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
//                    
//                    Spacer()
//                }
//                Spacer()
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        showAddEventSheet = true
//                    }) {
//                        Image(systemName: "plus")
//                    }
//                }
//            }
//            .sheet(isPresented: $showAddEventSheet) {
//                AddEventView(selectedDate: selectedDate ?? Date()) { event in
//                    eventManager.addEvent(event: event) { success, error in
//                        if success {
//                            showAddEventSheet = false
//                        }
//                    }
//                }
//            }
//            .task {
//                // Load household info
//                isLoading = true
//                household = await householdManager.fetchCurrentHousehold()
//                isLoading = false
//            }
//        }
//    }
//}
//
//struct EventRow: View {
//    let event: Event
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(event.name)
//                    .font(.headline)
//                
//                HStack{
//                    if !event.host.isEmpty {
//                        Text(event.host)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    Text("-")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    if !event.location.isEmpty {
//                        Text(event.location)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                
//            }
//            .padding(.vertical, 10)
//            .padding(.horizontal)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Text(event.timeDisplay)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .padding(.trailing)
//        }
//        .background(event.color)
//        .cornerRadius(8)
//        .overlay(
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(Color.black, lineWidth: 1)
//        )
//    }
//}
//
//struct CalendarScene_Previews: PreviewProvider {
//    static var previews: some View {
//        CalendarScene()
//    }
//}
//
//  CalendarView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//
//
//  CalendarView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CalendarView: UIViewRepresentable {
  var calendarIdentifier: Calendar.Identifier = .gregorian
  var canSelect: Bool = false
  @Binding var selectedDate: Date?
  
  func makeCoordinator() -> CalendarCoordinator {
    CalendarCoordinator(calendarIdentifier: calendarIdentifier, canSelect: canSelect, selectedDate: $selectedDate)
  }
  
  func makeUIView(context: Context) -> UICalendarView {
    let view = UICalendarView()
    view.calendar = Calendar(identifier: calendarIdentifier)
    if canSelect {
      view.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
    }
    view.delegate = context.coordinator
    return view
  }
  
  func updateUIView(_ uiView: UICalendarView, context: Context) {
    let calendar = Calendar(identifier: calendarIdentifier)
    uiView.calendar = calendar
    context.coordinator.calendarIdentifier = calendarIdentifier
    if !canSelect, let selectedDate {
      context.coordinator.pickedDate = selectedDate
    }
  }
}

final class CalendarCoordinator: NSObject, UICalendarSelectionSingleDateDelegate, UICalendarViewDelegate {
  var calendarIdentifier: Calendar.Identifier
  let canSelect: Bool
  @Binding var selectedDate: Date?
  var pickedDate: Date?
  var calendar: Calendar {
    Calendar(identifier: calendarIdentifier)
  }
  
  init(calendarIdentifier: Calendar.Identifier, canSelect: Bool, selectedDate: Binding<Date?>) {
    self.calendarIdentifier = calendarIdentifier
    self.canSelect = canSelect
    self._selectedDate = selectedDate
  }
  
  func dateSelection(_ selection: UICalendarSelectionSingleDate,
                     didSelectDate dateComponents: DateComponents?) {
    guard
      let dateComponents,
      let date = calendar.date(from: dateComponents)
    else { return }
    self.selectedDate = date
  }
}

struct CalendarScene: View {
    @State private var selectedDate: Date? = Date()
    @StateObject private var eventManager = EventManager()
    @StateObject private var householdManager = HouseholdManager()
    @State private var household: Household?
    @State private var showAddEventSheet = false
    @State private var showEventDetailSheet = false
    @State private var selectedEvent: Event?
    @State private var isLoading = true
    
    private var textDate: String {
        guard let selectedDate else { return "Date not selected" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    private var eventsForSelectedDate: [Event] {
        guard let selectedDate = selectedDate else { return [] }
        return eventManager.getEventsForDate(date: selectedDate)
    }
    
   
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("\(household?.name ?? "household") calendar")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    CalendarView(canSelect: true, selectedDate: $selectedDate)
                        .scaledToFit()
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text(textDate)
                        .font(.headline)
                        .padding(.top, 8)
                        .padding(.horizontal)
                    
                    if eventManager.isLoading {
                        ProgressView("Loading events...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if eventsForSelectedDate.isEmpty {
                        Text("No events for this day")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(eventsForSelectedDate) { event in
                                    EventRow(event: event)
                                        .onTapGesture {
                                            selectedEvent = event
                                            showEventDetailSheet = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddEventSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEventSheet) {
                AddEventView(selectedDate: selectedDate ?? Date()) { event in
                    eventManager.addEvent(event: event) { success, error in
                        if success {
                            showAddEventSheet = false
                        }
                    }
                }
            }
            .sheet(isPresented: $showEventDetailSheet) {
                if let event = selectedEvent {
                    EventDetailView(event: event)
                }
            }
            .task {
                // Load household info
                isLoading = true
                household = await householdManager.fetchCurrentHousehold()
                isLoading = false
            }
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                
                if !event.location.isEmpty {
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(event.timeDisplay)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.trailing)
        }
        .background(event.color)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}
