//
//  AddEntryView.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 24.03.2025.
//
import SwiftUI
import FirebaseFirestore

struct AddEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var data: CallerData
    let isEditing: Bool
    @Binding var entry: CallerEntry?
    
    @State private var phoneNumber: String = ""
    @State private var label: String = "Агент"
    @State private var isSpam: Bool = false
    @State private var showingDuplicateAlert = false // Состояние для алерта
    
    private let db = Firestore.firestore() // Прямой доступ к Firestore
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Номер телефона (380688880168)", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: phoneNumber) { newValue in
                        phoneNumber = formatPhoneNumberAsYouType(newValue)
                    }
                TextField("Метка (например, Агент)", text: $label)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Toggle("Спам", isOn: $isSpam)
            }
            .navigationTitle(isEditing ? "Редактировать запись" : "Добавить запись")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        Task {
                            let normalizedNumber = data.normalizePhoneNumber(phoneNumber)
                            
                            // Проверка дубликата в Firebase
                            do {
                                let isDuplicate = try await checkForDuplicate(normalizedNumber)
                                if isDuplicate {
                                    showingDuplicateAlert = true
                                } else {
                                    if isEditing, let existingEntry = entry {
                                        let updatedEntry = CallerEntry(
                                            id: existingEntry.id,
                                            phoneNumber: normalizedNumber,
                                            label: label,
                                            isSpam: isSpam
                                        )
                                        data.deleteEntry(existingEntry)
                                        data.addEntry(updatedEntry)
                                        entry = nil
                                    } else {
                                        let newEntry = CallerEntry(
                                            id: UUID().uuidString,
                                            phoneNumber: normalizedNumber,
                                            label: label,
                                            isSpam: isSpam
                                        )
                                        data.addEntry(newEntry)
                                    }
                                    presentationMode.wrappedValue.dismiss()
                                }
                            } catch {
                                print("Ошибка при проверке дубликата: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            .alert("Пользователь существует", isPresented: $showingDuplicateAlert) {
                Button("ОК") {
                    showingDuplicateAlert = false
                }
            } message: {
                Text("Номер телефона уже зарегистрирован в базе данных.")
            }
            .onAppear {
                if isEditing, let currentEntry = entry {
                    phoneNumber = formatPhoneNumber(currentEntry.phoneNumber)
                    label = currentEntry.label
                    isSpam = currentEntry.isSpam
                }
            }
        }
    }
    
    // Проверка дубликата в Firebase
    private func checkForDuplicate(_ phoneNumber: String) async throws -> Bool {
        let querySnapshot = try await db.collection("callerEntries")
            .whereField("phoneNumber", isEqualTo: phoneNumber)
            .getDocuments()
        
        if isEditing, let currentEntry = entry {
            // Исключаем текущую запись при редактировании
            return querySnapshot.documents.contains { document in
                document.documentID != currentEntry.id
            }
        } else {
            // При добавлении новой записи проверяем, есть ли хоть один документ
            return !querySnapshot.isEmpty
        }
    }
    
    // Форматирование номера телефона для отображения при загрузке (из записи)
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        guard digits.count >= 10 else { return digits }
        let countryCode = String(digits.prefix(2))
        let areaCode = String(digits.dropFirst(2).prefix(3))
        let firstPart = String(digits.dropFirst(5).prefix(3))
        let secondPart = String(digits.dropFirst(8))
        return "+\(countryCode) (\(areaCode)) \(firstPart) \(secondPart)"
    }
    
    // Форматирование номера телефона по мере ввода
    private func formatPhoneNumberAsYouType(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var formatted = ""
        
        if digits.isEmpty {
            return ""
        }
        
        let maxDigits = min(digits.count, 12)
        let digitArray = Array(digits.prefix(maxDigits))
        
        formatted += "+"
        
        if digitArray.count >= 1 {
            let countryCode = String(digitArray.prefix(2))
            formatted += countryCode
        }
        
        if digitArray.count > 2 {
            formatted += " ("
            let areaCode = String(digitArray[2..<min(5, digitArray.count)])
            formatted += areaCode
            if digitArray.count >= 5 {
                formatted += ")"
            }
        }
        
        if digitArray.count > 5 {
            formatted += " "
            let firstPart = String(digitArray[5..<min(8, digitArray.count)])
            formatted += firstPart
        }
        
        if digitArray.count > 8 {
            formatted += " "
            let secondPart = String(digitArray[8..<digitArray.count])
            formatted += secondPart
        }
        
        return formatted
    }
}
