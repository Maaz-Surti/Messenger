//
//  ChatViewController.swift
//  messenger
//
//  Created by TechnoMac6 on 01/02/22.
//

import UIKit
import MessageKit


struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
}

struct sender: SenderType{
    
    var senderId: String
    var displayName: String
    var photoURL: String
}

class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    
    private let selfSender = sender(senderId: "1",
                                    displayName: "",
                                    photoURL: "Joe Smith")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello world message")))
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello world message, Hello world message Hello world message")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
  
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}
