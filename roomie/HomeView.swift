//
//  HomeView.swift
//  roomie
//
//  Created by Sydney Schrader on 3/5/25.
//

import SwiftUI
import FirebaseAuth

struct TabBarView: View {
    @State private var selectedTab: Int = 0
    
    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: selectedTab)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("home", systemImage: "house.fill")
                }
                .tag(0)
            
            ExpensesView()
                .tabItem {
                    Label("expenses", systemImage: "dollarsign")
                }
                .tag(1)
            
            CalendarView()
                .tabItem {
                    Label("calendar", systemImage: "calendar")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("settings", systemImage: "gear")
                }
                .tag(3)
        }
        .background(Color(UIColor.systemGray6))
    }
}

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

struct ExpensesView: View {
    var body: some View {
        Text("Expenses Screen Content")
    }
}



#Preview {
    TabBarView()
}
