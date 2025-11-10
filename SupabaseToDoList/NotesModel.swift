//
//  NotesModel.swift
//  SupabaseToDoList
//
//  Created by Mürvet Arslan on 29.10.2025.
//

import Foundation

// Supabase e not eklemek için 
struct Note: Codable, Identifiable {
    let id: Int
    let user_id: UUID
    let content: String
    let created_at: String?
    let updated_at: String?
    let is_pinned: Bool?
}

// Supabase e yazılan notları okumak için
struct NoteInsert: Encodable {
    let user_id: UUID
    let content: String
    let is_pinned: Bool?
}
