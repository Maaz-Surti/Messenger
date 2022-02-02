//
//  StorageManager.swift
//  messenger
//
//  Created by TechnoMac6 on 01/02/22.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
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
            })
        })
    }
    
    public enum StoragErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
}
