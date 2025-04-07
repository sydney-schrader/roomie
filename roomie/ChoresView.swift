//
//  ChoresView.swift
//  roomie
//
//  Created by Sydney Schrader on 4/6/25.
//
import SwiftUI

struct CheckBoxView: View {
    @Binding var checked: Bool

    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
            .onTapGesture {
                self.checked.toggle()
            }
    }
}

struct Chore: Codable, Identifiable {
    var id = UUID()
    let title: String
    let assignedTo: String
    var isDone: Bool = false
}

struct ChoresView: View {
    @State private var chores: [Chore] = [
        Chore(title: "take out the trash", assignedTo: "jac"),
        Chore(title: "rent", assignedTo: "ava"),
        Chore(title: "matts", assignedTo: "syd")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                List {
                    ForEach(0..<chores.count, id: \.self) { index in
                        HStack {
                            CheckBoxView(checked: $chores[index].isDone)
                            
                            Text(chores[index].title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .strikethrough(chores[index].isDone, color: .black)
                            
                            Text(chores[index].assignedTo)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(10)
                        .background(chores[index].isDone ? Color.green.opacity(0.3) :
                            Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.7))
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("chores")
            .toolbar{
                Button{
                    //action
                }label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    ChoresView()
}
