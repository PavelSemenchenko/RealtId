
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
            .offset(y: -40)
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
                            // Явно устанавливаем showingSplash после signOut
                            DispatchQueue.main.async {
                                showingSplash = true
                            }
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
            .fullScreenCover(isPresented: $showingSplash, onDismiss: {
                // Опционально: можно добавить логику после закрытия сплеш-скрина
            }) {
                SplashScreen()
            }
        }
    }
    private func formatPhoneNumber(_ number: String) -> String {
            let digits = number.filter { $0.isNumber }
            guard digits.count >= 10 else { return digits } // Минимально 10 цифр: +38 (068) 888 0168
            let countryCode = String(digits.prefix(2)) // +38
            let areaCode = String(digits.dropFirst(2).prefix(3)) // (068)
            let firstPart = String(digits.dropFirst(5).prefix(3)) // 888
            let secondPart = String(digits.dropFirst(8)) // 0168
            return "+\(countryCode) (\(areaCode)) \(firstPart) \(secondPart)"
        }
}


#Preview {
    ContentView()
}
