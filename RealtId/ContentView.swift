//
//  ContentView.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 25.02.2025.
//

import SwiftUI
import FirebaseFirestore

// Структура для записи о номере телефона
struct CallerEntry: Identifiable, Codable {
    var id: String // Уникальный ID из Firestore
    var phoneNumber: String // Числовой формат для CallKit (например, "380996752879")
    var label: String
    var isSpam: Bool
}

// Класс для управления данными
class CallerData: ObservableObject {
    @Published var entries: [CallerEntry] = []
    private var db = Firestore.firestore()
    
    init() {
        loadEntries()
    }
    
    // Загрузка данных из Firebase с сортировкой по номеру телефона
    func loadEntries() {
        db.collection("callerEntries")
            .order(by: "phoneNumber") // Сортировка по номеру телефона
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Ошибка при загрузке данных: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                self.entries = documents.compactMap { document in
                    var entry = try? document.data(as: CallerEntry.self)
                    entry?.id = document.documentID // Устанавливаем правильный ID из Firestore
                    return entry
                }
            }
    }
    
    // Добавление записи в Firebase
    func addEntry(_ entry: CallerEntry) {
        do {
            let documentRef = try db.collection("callerEntries").addDocument(from: entry)
            var newEntry = entry
            newEntry.id = documentRef.documentID
            DispatchQueue.main.async {
                self.entries.append(newEntry)
                self.entries.sort { $0.phoneNumber < $1.phoneNumber } // Локальная сортировка
            }
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
        // Удаляем все символы, кроме цифр, включая "+"
        let digitsOnly = rawNumber.filter { $0.isNumber }
        return digitsOnly
    }
}

// Главный экран приложения
struct ContentView: View {
    @StateObject private var data = CallerData()
    @State private var showingAddView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(data.entries) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.label)
                            .font(.headline)
                        Text(formatPhoneNumber(entry.phoneNumber)) // Отображаем читаемый формат
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
            }
            .sheet(isPresented: $showingAddView) {
                AddEntryView(data: data)
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
    
    // Форматирование номера для отображения (например, "+380 (99) 675 28 79")
    private func formatPhoneNumber(_ number: String) -> String {
        guard number.count >= 9 else { return number } // Минимум для форматирования
        let countryCode = String(number.prefix(3)) // "380"
        let areaCode = String(number.dropFirst(3).prefix(2)) // "99"
        let firstPart = String(number.dropFirst(5).prefix(3)) // "675"
        let secondPart = String(number.dropFirst(8)) // "2879"
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
                TextField("Номер телефона (3801231234567)", text: $phoneNumber).keyboardType(UIKeyboardType.phonePad)
                TextField("Метка (например, Агент)", text: $label)
                Toggle("Спам", isOn: $isSpam)
            }
            .navigationTitle("Добавить запись")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let normalizedNumber = data.normalizePhoneNumber(phoneNumber)
                        let newEntry = CallerEntry(
                            id: UUID().uuidString, // Временный ID, будет заменён Firestore
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
