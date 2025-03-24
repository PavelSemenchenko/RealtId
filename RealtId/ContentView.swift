/*
 давай теперь добавим чтобы при создании пользователя , было еще поле куда пользователь мог вводить секретный пароль = admin, если пароль ввел- то для него видна можножность добавлять контакты
 */


import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CallKit




// Главный экран приложения
struct ContentView: View {
    @StateObject private var data = CallerData()
    @StateObject private var loginVM = LoginVM()
    @State private var showingAddView = false
    @State private var showingSplash = false

    var body: some View {
        NavigationView {
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
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("RealtId")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddView = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loginVM.signOut()
                        showingSplash = true
                    }) {
                        Text("Выход")
                    }
                }

            }
            .sheet(isPresented: $showingAddView) {
                AddEntryView(data: data)
            }
            .fullScreenCover(isPresented: $showingSplash) {
                SplashScreen()
            }
        }
    }

    // Функция удаления записи
    private func deleteEntries(at offsets: IndexSet) {
        offsets.forEach { index in
            let entry = data.entries[index]
            data.deleteEntry(entry)
        }
    }

    // Форматирование номера для отображения
    private func formatPhoneNumber(_ number: String) -> String {
        guard number.count >= 9 else { return number }
        let countryCode = String(number.prefix(3))
        let areaCode = String(number.dropFirst(3).prefix(2))
        let firstPart = String(number.dropFirst(5).prefix(3))
        let secondPart = String(number.dropFirst(8))
        return "+\(countryCode) (\(areaCode)) \(firstPart) \(secondPart)"
    }
}

// Экран добавления новой записи
struct AddEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var data: CallerData
    @State private var phoneNumber = ""
    @State private var label = "Агент"
    @State private var isSpam = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Номер телефона (3801231234567)", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Метка (например, Агент)", text: $label)
                Toggle("Спам", isOn: $isSpam)
            }
            .navigationTitle("Добавить запись")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let normalizedNumber = data.normalizePhoneNumber(phoneNumber)
                        let newEntry = CallerEntry(
                            id: UUID().uuidString, // Временный ID
                            phoneNumber: normalizedNumber,
                            label: label,
                            isSpam: isSpam
                        )
                        data.addEntry(newEntry)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
