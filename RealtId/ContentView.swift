/*
 давай теперь добавим чтобы при создании пользователя , было еще поле куда пользователь мог вводить секретный пароль = admin, если пароль ввел- то для него видна можножность добавлять контакты
 */


import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CallKit

// Структура для записи о номере телефона
struct CallerEntry: Identifiable, Codable {
    var id: String // Уникальный ID из Firestore
    var phoneNumber: String // Числовой формат для CallKit (например, "380996752879")
    var label: String
    var isSpam: Bool
}

// Класс для управления данными
class CallerData: ObservableObject {
    @Published var entries: [CallerEntry] = [] // Список записей
    private var db = Firestore.firestore() // Подключение к Firestore
    private let appGroup = "group.com.leksovich.RealtId" // App Group для обмена данными
    private var lastEntriesHash: Int? // Хэш предыдущего состояния данных

    init() {
        loadEntries()
    }

    // Загрузка данных из Firebase с сортировкой по номеру телефона
    func loadEntries() {
        db.collection("callerEntries")
            .order(by: "phoneNumber")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Ошибка при загрузке данных: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                let newEntries = documents.compactMap { document in
                    var entry = try? document.data(as: CallerEntry.self)
                    entry?.id = document.documentID
                    return entry
                }
                let newHash = self.hashEntries(newEntries)
                if newHash != self.lastEntriesHash {
                    self.entries = newEntries // Обновляем данные
                    self.lastEntriesHash = newHash
                    self.saveToAppGroup()
                    self.reloadCallKitExtension()
                }
            }
    }

    // Функция для вычисления хэша записей
    private func hashEntries(_ entries: [CallerEntry]) -> Int {
        return entries.map { $0.phoneNumber.hashValue }.reduce(0, ^)
    }

    // Сохранение данных в App Group
    private func saveToAppGroup() {
        if let sharedDefaults = UserDefaults(suiteName: appGroup),
           let encoded = try? JSONEncoder().encode(entries) {
            sharedDefaults.set(encoded, forKey: "callerEntries")
        }
    }

    // Перезагрузка расширения CallKit
    private func reloadCallKitExtension() {
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.leksovich.RealtId.CallerIDExtension") { error in
            if let error = error {
                print("Ошибка при перезагрузке расширения: \(error)")
            }
        }
    }

    // Добавление записи в Firebase
    func addEntry(_ entry: CallerEntry) {
        do {
            _ = try db.collection("callerEntries").addDocument(from: entry)
            // Локальное добавление не требуется, так как addSnapshotListener обновит entries
        } catch {
            print("Ошибка при добавлении: \(error.localizedDescription)")
        }
    }

    // Удаление записи из Firebase
    func deleteEntry(_ entry: CallerEntry) {
        print("Попытка удаления документа с ID: \(entry.id)")
        db.collection("callerEntries").document(entry.id).delete { error in
            if let error = error {
                print("Ошибка при удалении: \(error.localizedDescription)")
            } else {
                print("Документ успешно удален!")
            }
        }
    }

    // Преобразование номера телефона в формат CallKit
    func normalizePhoneNumber(_ rawNumber: String) -> String {
        let digitsOnly = rawNumber.filter { $0.isNumber }
        return digitsOnly
    }
}

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
