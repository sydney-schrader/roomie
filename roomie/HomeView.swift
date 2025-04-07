//
//  HomeView.swift
//  roomie
//
//  Created by Sydney Schrader on 3/5/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    var body: some View {
        Text("the current user is \(Auth.auth().currentUser?.displayName ?? "")")
    }
}

struct CalendarView: View {
    var body: some View {
        Text("Calendar Screen Content")
    }
}




#Preview {
    TabBarView()
}
