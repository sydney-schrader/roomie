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
            .sheet(item: $selectedEvent) { event in
                    EventDetailView(event: event)
            }
//            .sheet(isPresented: $showEventDetailSheet) {
//                if let event = selectedEvent {
//                    EventDetailView(event: event)
//                }
//            }
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
