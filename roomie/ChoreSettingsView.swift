//
//  ChoreSettingsView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChoreSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let chore: Chore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header with title and close button
            HStack {
                Text(chore.title)
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
            
            // chore details
            Group {
                HStack {
                    Text("title")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(chore.title)
                        .font(.headline)
                }
                Divider()
                
                HStack {
                    Text("assigned to")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(chore.assignedTo)
                        .font(.headline)
                }
                Divider()
                
                
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Spacer()
                
                Button(action: {
                    // Edit action (to be implemented)
                    dismiss()
                }) {
                    Text("edit")
                        .foregroundColor(.blue)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.9, green: 0.95, blue: 1.0))
                        .cornerRadius(20)
                }
                
                Spacer()
                
                Button(action: {
                    // Delete action (to be implemented)
                    dismiss()
                }) {
                    Text("delete")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(20)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    

}


