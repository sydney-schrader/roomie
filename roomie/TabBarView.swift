//
//  TabBarView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/6/25.
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
            ChoresView()
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
