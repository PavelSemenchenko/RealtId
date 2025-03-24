//
//  AddEntryView.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 24.03.2025.
//

import SwiftUI

struct AddEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var data: CallerData
    let isEditing: Bool
    @Binding var entry: CallerEntry?
    
    @State private var phoneNumber: String = ""
    @State private var label: String = "Агент"
    @State private var isSpam: Bool = false
    
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
                        let normalizedNumber = data.normalizePhoneNumber(phoneNumber)
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
                }
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
    
    // Форматирование номера телефона для отображения при загрузке (из записи)
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        guard digits.count >= 10 else { return digits } // Минимально 10 цифр: +38 (068) 888 0168
        let countryCode = String(digits.prefix(2)) // +38
        let areaCode = String(digits.dropFirst(2).prefix(3)) // (068)
        let firstPart = String(digits.dropFirst(5).prefix(3)) // 888
        let secondPart = String(digits.dropFirst(8)) // 0168
        return "+\(countryCode) (\(areaCode)) \(firstPart) \(secondPart)"
    }
    
    // Форматирование номера телефона по мере ввода
    private func formatPhoneNumberAsYouType(_ input: String) -> String {
        let digits = input.filter { $0.isNumber } // Извлекаем только цифры
        var formatted = ""
        
        if digits.isEmpty {
            return ""
        }
        
        // Ограничиваем количество цифр до 12 (например, +380688880168)
        let maxDigits = min(digits.count, 12)
        let digitArray = Array(digits.prefix(maxDigits))
        
        // Добавляем "+"
        formatted += "+"
        
        // Добавляем первые 2 цифры (код страны)
        if digitArray.count >= 1 {
            let countryCode = String(digitArray.prefix(2))
            formatted += countryCode
        }
        
        // Добавляем пробел и скобки для кода оператора (3 цифры)
        if digitArray.count > 2 {
            formatted += " ("
            let areaCode = String(digitArray[2..<min(5, digitArray.count)])
            formatted += areaCode
            if digitArray.count >= 5 {
                formatted += ")"
            }
        }
        
        // Добавляем пробел и первые 3 цифры номера
        if digitArray.count > 5 {
            formatted += " "
            let firstPart = String(digitArray[5..<min(8, digitArray.count)])
            formatted += firstPart
        }
        
        // Добавляем пробел и последние 4 цифры номера
        if digitArray.count > 8 {
            formatted += " "
            let secondPart = String(digitArray[8..<digitArray.count])
            formatted += secondPart
        }
        
        return formatted
    }
}
