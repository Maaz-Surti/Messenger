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
import MessageKit

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
   
}

extension DatabaseManager {
    public func getDataForPath(path: String, completion: @escaping (Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
}

// MARK: - Account Management

extension DatabaseManager{
    
    
    public func userExists(with email: String,
                           completion: @escaping((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            print(snapshot.value as? [String: Any])
            guard snapshot.value as? [String: Any] != nil else {
                print("User does not exist")
                completion(false)
                return
            }
            
            print("User exists")
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
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                  return
              }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
                "name":name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email":safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
                
            ]
            // Update the recipient user conversation
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value
                                                                                 , with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else{
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            // Update the current user conversation
            
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                //conversations array exists for user
                //you should append
                conversations.append(newConversationData)
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                 completion(false)
                        return
                    }
                    self?.finishedCreatingConversation(name: name, conversationID: conversationID,
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
                    self?.finishedCreatingConversation(name: name, conversationID: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                })
                
            }
        })
    }
    
    private func finishedCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
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
        case .photo(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString {
                message = targetUrlString
            }
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
            "is_read": false,
            "name":name
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
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                          print("could not save conversations to the model object")
                          return nil
                      }
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationID ,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
        })
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void){
        
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                          print("couldnt assign messages to messages object")
                          return nil
                      }
                var kind: MessageKind?
                if type == "Photo"{
                    // photo
                    guard let imageUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "Video"{
                    // video
                    guard let videoUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(senderId: senderEmail,
                                    displayName: name,
                                    photoURL: "")
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
            })
            
            completion(.success(messages))
        })
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void ){
        // add new message to messages
        //update sender's latest message
        //update receipient's latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        
        
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self = self else { return }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return }
            
            
            let messageDate =  newMessage.sentDate
            
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
            
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
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
            
            let newMessageEntry: [String: Any] = [
                "id":newMessage.messageId,
                "type":newMessage.kind.messageKindString,
                "content":message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name":name
            ]
            
            currentMessages.append(newMessageEntry)
            
            self.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    print("Failed to append new message")
                    return
                }
                
                self.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    var position = 0
                    var targetConversation: [String: Any]?
                    
                    for conversationDictionary in currentUserConversations{
                        if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    
                    currentUserConversations[position] = finalConversation
                    self.database.child("\(currentEmail)/conversations").setValue(currentUserConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // Update latest message for recipient user
                        
                        self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            var position = 0
                            var targetConversation: [String: Any]?
                            
                            for conversationDictionary in otherUserConversations{
                                if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            
                            otherUserConversations[position] = finalConversation
                            self.database.child("\(otherUserEmail )/conversations").setValue(otherUserConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    print(error as Any)
                                    completion(false)
                                    return
                                }
                                
                                // Update latest message for recipient user
                                
                                
                                
                                completion(true)
                            })
                        })
                    })
                })
            })
        })
    }
    
    public func deleteConversation(conversationID: String, completion: @escaping (Bool)-> Void ){
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        // Get all conversations for current user
        // Delete conversation in collection with target id
        // Reset those conversations for the user in the database
        
        print("Deleting conversation with the ID: ", conversationID)
        
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value){ snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationID {
                        print("Found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error,_ in
                    guard error == nil else {
                        print("Failed to write the deletion changes")
                        completion(false)
                        return
                    }
                    print("Delete the conversation")
                    completion(true)
                })
            }
        }
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


