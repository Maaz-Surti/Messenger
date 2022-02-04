//
//  DatabaseManager.swift
//  messenger
//
//  Created by TechnoMac6 on 31/01/22.
//

import Foundation
import FirebaseDatabase
import CoreMedia
import SwiftUI

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
   
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
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var userCollection = snapshot.value as? [[String:String]] {
                    //append to user dictionary
                    let newElement = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                    ]
                    
                    userCollection.append(newElement)
                    
                    self.database.child("users").setValue(userCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                     })
                        
                } else {
                    //create that array
                    let newCollection: [[String: String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                     })
                 }
             })
         })
      }
    
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void ){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

// MARK: - Sending Messages/Conversations

extension DatabaseManager {
    
    /*
         
     djkashfjkadhf{
           "messages": [
           {
               "id": String,
               "type": text, photo, video,
               "content": String,
               "date": String,
               "sender_email": String
               "isRead"; True/False
               
           }
        ]
     }
       
          conversation => [
     
               [
                   "conversation_id":"djkashfjkadhf"
                   "other_user_email:"
                   "latest_message": => {
                      "date":Date()
                      "latest_message":"message"
                      "is_read": true/false
                      }
            ]
      ]
     
     */
    
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found ")
                return
            }
            
            let messageDate =  firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email":otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                //conversations array exists for user
                //you should append
                conversations.append(newConversationData)
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                 completion(false)
                        return
                    }
                    self?.finishedCreatingConversation(conversationID: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                })
            }
            else {
                // Conversation array does NOT exist.
                // Create new conversation
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishedCreatingConversation(conversationID: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                })
                
            }
        })
    }
    
    private func finishedCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
        //        "id": String,
        //        "type": text, photo, video,
        //        "content": String,
        //        "date": String,
        //        "sender_email": String
        //        "isRead"; True/False
        
        var message = ""
        
        let messageDate =  firstMessage.sentDate
        
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let collectionMessage: [String: Any] = [
            "id":firstMessage.messageId,
            "type":firstMessage.kind.messageKindString,
            "content":message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read":false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding convo: ", conversationID)
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error,_  in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true )
        })
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void){
        

        
        
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void){
        
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void ){
        
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


