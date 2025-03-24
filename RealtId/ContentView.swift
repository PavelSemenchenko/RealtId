
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CallKit


// Главный экран приложения
struct ContentView: View {
    @StateObject private var data = CallerData()
    @StateObject private var loginVM = LoginVM()
    @State private var showingAddView = false
    @State private var showingEditView = false
    @State private var showingSplash = false
    @State private var editingEntry: CallerEntry?
    
    var body: some View {
        NavigationStack { // Заменяем NavigationView на NavigationStack
            List {
                ForEach(data.entries) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.label)
                            .font(.headline)
                        Text(formatPhoneNumber(entry.phoneNumber))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if entry.isSpam {
                            Text("Спам")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            data.deleteEntry(entry)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        
                        Button {
                            editingEntry = entry
                            showingEditView = true
                        } label: {
                            Label("Редактировать", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .offset(y: -20)
            .navigationTitle("RealtId")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingAddView = true }) {
                            Image(systemName: "person.badge.plus")
                        }
                        Button(action: {
                            loginVM.signOut()
                            showingSplash = true
                        }) {
                            Image(systemName: "xmark.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddEntryView(data: data, isEditing: false, entry: .constant(nil))
            }
            .sheet(isPresented: $showingEditView) {
                AddEntryView(data: data, isEditing: true, entry: $editingEntry)
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        guard number.count >= 9 else { return number }
        let countryCode = String(number.prefix(3))
        let areaCode = String(number.dropFirst(3).prefix(2))
        let firstPart = String(number.dropFirst(5).prefix(3))
        let secondPart = String(number.dropFirst(8))
        return "+\(countryCode) (\(areaCode)) \(firstPart) \(secondPart)"
    }
}


#Preview {
    ContentView()
}
