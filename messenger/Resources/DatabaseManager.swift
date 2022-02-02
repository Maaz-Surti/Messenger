//
//  DatabaseManager.swift
//  messenger
//
//  Created by TechnoMac6 on 31/01/22.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
   
}

// MARK: - Account Management

extension DatabaseManager{
    
    
    public func userExists(with email: String,
                           completion: @escaping((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })

        
    }
    
    /// Inserts new user to database
    public func insertUser(with user: chatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to write to the database")
                return
            }
            completion(true)
        })
    }
}

struct chatAppUser {
    let firstName: String
    let lastName: String
    let emailAdress: String
    var safeEmail: String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFilename: String {
            //maaz-gmail-com_profile_picture.png
            return "\(safeEmail)_profile_picture.png"
    }
}
//        let profilePictureURL: String
