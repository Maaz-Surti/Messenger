//
//  ChatViewController.swift
//  messenger
//
//  Created by TechnoMac6 on 01/02/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "Photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Media: MediaItem{
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Sender: SenderType{
    
    public var senderId: String
    public var displayName: String
    public var photoURL: String
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter : DateFormatter  {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }
    
    public var isNewConversation = false
    
    public let otherUserEmail: String
    private let conversationID: String?

    private var messages = [Message]()
    
    private var selfSender: Sender?  {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        return Sender(senderId: safeEmail,
               displayName: "Me",
               photoURL: "")
        
    }
    
    init(with email: String, id: String?){
        self.conversationID = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversationID = conversationID {
            listenForMessages(id: conversationID)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        if let conversationID = conversationID {
            listenForMessages(id: conversationID)

        }
        setupButtonInput()
    }
    
    private func setupButtonInput(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({ [weak self] _  in
            self?.presentInputActionSheet()
        })
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet() {
        
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {  _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func presentPhotoInputActionSheet(){
        
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func presentVideoInputActionSheet(){
        
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func listenForMessages(id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("No messages found")
                    return
                }
                self?.messages = messages
                    
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
                
            case.failure(let error):
                print("Failed to get message: ", error)
            }
        })
    }
  
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let messageID = createMessageID(),
              let conversationID = conversationID,
              let name = self.title,
              let selfSender = selfSender  else {
                  return }
        
        let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".png"
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                
                guard let self = self else {
                    return
                }
                
                switch result {
                case.success(let UrlString):
                    // Ready to send message
                    
                    print("Uploaded message photo: ", UrlString)
                    
                    guard let url = URL(string: UrlString),
                          let placeholder = UIImage(systemName: "plus") else {
                              return }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender ,
                                          messageId: messageID,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: self.otherUserEmail, name: name, newMessage: message, completion: { success in
                        
                        if success{
                            print("Sent photo message")
                        }
                        else {
                            print("Failed to send photo message")
                        }
                    })
                    break
                    
                case.failure(let error):
                    print("message photo upload error: ", error)
                }
            })
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            // upload video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                
                guard let self = self else {
                    return
                }
                
                switch result {
                case.success(let UrlString):
                    // Ready to send message
                    
                    print("Uploaded message video: ", UrlString)
                    
                    guard let url = URL(string: UrlString),
                          let placeholder = UIImage(systemName: "plus") else {
                              return }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender ,
                                          messageId: messageID,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: self.otherUserEmail, name: name, newMessage: message, completion: { success in
                        
                        if success{
                            print("Sent photo message")
                        }
                        else {
                            print("Failed to send photo message")
                        }
                    })
                    break
                    
                case.failure(let error):
                    print("message photo upload error: ", error)
                }
            })
        }
        
        
        // upload image
        
        
        
        // send message
    }
    
    
}
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID() else {
                  return
              }
        
        let message = Message(sender: selfSender ,
                              messageId: messageID,
                              sentDate: Date(),
                              kind: .text(text))
        
        print("sending: \(text)")
        // Send message
        if isNewConversation {
           //create convo
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User",
                                                         firstMessage: message,
                                                         completion: { [weak self] success in
                if success{
                    print("message sent")
                    self?.isNewConversation = false
                }
                else {
                    print("Failed to send")
                }
            })
        }
        else {
            
            guard let conversationID = conversationID, let name = self.title else { return }
            //append to an existing conversation
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: otherUserEmail , name: name, newMessage: message, completion: { success in
                if success {
                    print("message sent")
                }
                else {
                    print("Failed to send")
                }
            })
        }
    }
    
    private func createMessageID() -> String? {
        //date, otherUserEmail, senderEmail, randomInt
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String 
        else {
            print("Current email not found")
            return nil
        }
        
        let safeCurrentEmail =  DatabaseManager.safeEmail(email: currentUserEmail)
        
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("created message ID: ", newIdentifier)
        
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("self sender is nil, email should be cached  ")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
            
        default:
            break
        }
    }
    
}
