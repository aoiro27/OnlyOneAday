//
//  StudyCategory.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import Foundation
import SwiftData

@Model
final class StudyCategory {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    init(name: String, color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
} 