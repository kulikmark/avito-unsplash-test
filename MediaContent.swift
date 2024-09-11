//
//  MediaContent.swift
//  avito-unsplash-test
//
//  Created by Марк Кулик on 07.09.2024.
//

import Foundation

struct MediaContent: Decodable {
    let id: String
    let urls: [String: String]
    let description: String?
    let user: User
    
    struct User: Decodable {
        let name: String
    }
}
