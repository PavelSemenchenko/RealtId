//
//  CallerData.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 24.03.2025.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CallKit

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
