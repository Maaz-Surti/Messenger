//
//  AppDelegate.swift
//  messenger
//
//  Created by TechnoMac6 on 28/01/22.
//

import UIKit
import Firebase
import FirebaseCore
import GoogleSignIn
import JGProgressHUD

@main
class AppDelegate: UIResponder {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.min)
        
        // App opened notification
        NotificationCenter.default.post(name: .didOpenTheApp, object: nil)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

  
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        return GIDSignIn.sharedInstance().handle(url)
    }
    
}

// MARK: Google Sign In Functions

extension AppDelegate: UIApplicationDelegate, GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with google: ", error)
            }
            return
        }
    
        
        print("Did sign in with Google: ", user ?? "no usr")
        
        guard let user = user else { return }
        
        guard let email = user.profile.email,
              let firstName = user.profile.givenName,
              let lastName = user.profile.familyName
        else {
                  return
        }
        
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        
        DatabaseManager.shared.userExists(with: email, completion: { exists in
            if !exists {
                // insert into database
                
                let chatUser = chatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAdress: email, groupID: nil)
                
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    
                    if success {
                        //upload image
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                guard let data = data else {
                                    return
                                }
                                
                                let fileName = chatUser.profilePictureFilename
                                StorageManager.shared.uploadProfilePicture(with: data,
                                                                           fileName: fileName,
                                                                           completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage Manager error", error)
                                    }
                                })
                            }).resume()
                        }
                    }
                })
            }
        })
        
        guard let authentication = user.authentication else {
            print("Missing auth object off of google user")
            return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
            guard authResult != nil, error == nil else {
                print("Failed to login with google credentials")
                return }
            print("successfully signed in with google credentials")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        })
        
        
    }

    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected")
    }
}
