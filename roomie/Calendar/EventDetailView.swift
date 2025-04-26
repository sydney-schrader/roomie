//
//  EventDetailView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseAuth

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let event: Event
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private var timeDisplay: String {
        if event.isAllDay {
            return "all day"
        } else if let start = event.startTime, let end = event.endTime {
            return "\(start) - \(end)"
        } else if let start = event.startTime {
            return start
        } else {
            return ""
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    }
                    .padding(.trailing, 8)
                }
                
                Text("event details")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Event Title
                Text(event.name)
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal)
                
                // Date and Time
                VStack(alignment: .leading) {
                    let dateString = dateFormatter.string(from: event.date)
                    Text(dateString)
                        .font(.system(size: 16))
                    
                    if let startTime = event.startTime, let endTime = event.endTime {
                        Text("\(startTime) - \(endTime)")
                            .font(.system(size: 16))
                    } else if event.isAllDay {
                        Text("all day")
                            .font(.system(size: 16))
                    }
                    
//                    if let repeats = event.repeats {
//                        Text("repeats \(repeats)")
//                            .font(.system(size: 16))
//                            .foregroundColor(.red)
//                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Location
                if !event.location.isEmpty {
                    HStack(alignment: .top) {
                        Text("location:")
                            .font(.headline)
                        Text(event.location)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
                
                // Description
                if !event.description.isEmpty {
                    HStack(alignment: .top) {
                        Text("description:")
                            .font(.headline)
                        Text(event.description)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
                
                // Host
                if !event.host.isEmpty {
                    HStack(alignment: .top) {
                        Text("host:")
                            .font(.headline)
                        Text(event.host)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .background(Color(event.color))
        }
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEvent = Event(
            name: "ally's small group",
            date: Date(),
            startTime: "7:30pm",
            endTime: "9:30pm",
            isAllDay: false,
            location: "brown couch room",
            description: "my YL small group, don't need to be out of the house but would like it to be pretty quiet.",
            createdBy: "user123",
            colorHex: "#E6F2E6",
            host: "ally",
            repeats: "weekly"
        )
        
        return EventDetailView(event: sampleEvent)
    }
}
