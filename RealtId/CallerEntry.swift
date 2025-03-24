//
//  CallerEntry.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 24.03.2025.
//

// Структура для записи о номере телефона
struct CallerEntry: Identifiable, Codable {
    var id: String // Уникальный ID из Firestore
    var phoneNumber: String // Числовой формат для CallKit (например, "380996752879")
    var label: String
    var isSpam: Bool
}
