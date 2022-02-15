//
//  StorageManager.swift
//  messenger
//
//  Created by TechnoMac6 on 01/02/22.
//

import Foundation
import FirebaseStorage

/// Allows you to get, fetch and upload files to firebase storage
final class StorageManager {
    
    static let shared = StorageManager()
    
    private init () {}
    
    private let storage = Storage.storage().reference()
    
    /*
         /pictures/maaz-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
        
    ///Uploads picture to Firebase storage and returns completion with URL string to download
    public func uploadProfilePicture(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StoragErrors.failedToUpload))
                return
           }
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to download URL")
                    completion(.failure(StoragErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL returned: ", urlString)
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadURL(for path: String, completion:  @escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StoragErrors.failedToGetDownloadURL))
                return
            }
            
            completion(.success(url))
        })
    }
    
    /// Upload image will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion) {
        
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StoragErrors.failedToUpload))
                return
           }
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to download URL")
                    completion(.failure(StoragErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL returned: ", urlString)
                completion(.success(urlString))
            })
        })
    }
    
    /// Upload video  will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion) {
        
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload video file to firebase ")
                completion(.failure(StoragErrors.failedToUpload))
                return
           }
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to download URL")
                    completion(.failure(StoragErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL returned: ", urlString)
                completion(.success(urlString))
            })
        })
    }
    
    public enum StoragErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
}
