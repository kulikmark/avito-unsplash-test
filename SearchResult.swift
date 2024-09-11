//
//  SearchResult.swift
//  avito-unsplash-test
//
//  Created by Марк Кулик on 07.09.2024.
//

import Foundation

struct SearchResult: Codable {
    let id: String
    let urls: [String: String]
    let description: String?
    let user: User
    
    struct User: Codable {
        let name: String
    }
}
