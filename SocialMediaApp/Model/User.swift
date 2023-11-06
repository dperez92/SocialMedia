//
//  User.swift
//  SocialMediaApp
//
//  Created by Daniel Perez Olivares on 04-11-23.
//

import Foundation
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var userBio: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    
    private enum CodingKeys: CodingKey {
        case id
        case username
        case userBio
        case userUID
        case userEmail
        case userProfileURL
    }
}
