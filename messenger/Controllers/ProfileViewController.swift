//
//  ProfileViewController.swift
//  messenger
//
//  Created by TechnoMac6 on 28/01/22.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import CoreMedia
import SDWebImage

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    var data = [ProfileViewModel]()
    
    private var loginObserver: NSObjectProtocol?
    private var appOpenedObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                                     handler: nil ))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No email")",
                                     handler: nil ))
        data.append(ProfileViewModel(viewModelType: .logout,
                                     title: "Log Out",
                                     handler: { [weak self]  in
            guard let self = self else { return }
            
            UserDefaults.standard.setValue(nil, forKey: "email")
            UserDefaults.standard.setValue(nil, forKey: "name")
            
            // Log out button
            
            let actionSheet = UIAlertController(title: "Are you sure you want to Log Out ?", message: "", preferredStyle: .actionSheet)
            
            let logOut = UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                
                // Google Log Out
                GIDSignIn.sharedInstance().signOut()
                
                // Firebase Log Out
                do {
                    guard let self = self else { return }
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                    
                } catch {
                    print("Failed to log out")
                }
            })
            actionSheet.addAction(logOut)
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true)
            
        } ))
        
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = createTableHeader()
    
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main,
                                                               using: { [weak self] _ in
            guard let self = self else { return }
            
            self.tableView.tableHeaderView = self.createTableHeader()
        })
        
        appOpenedObserver = NotificationCenter.default.addObserver(forName: .didOpenTheApp, object: nil, queue: .main,
                                                               using: { [weak self] _ in
            guard let self = self else { return }
            
            self.tableView.tableHeaderView = self.createTableHeader()
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = appOpenedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    func createTableHeader()-> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
            
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/"+fileName
        
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0, width:
                                                self.view.width,
                                              height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (view.width-150)/2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path, completion: {  result in
                
            switch(result){
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download URL ", error )
            }
        })
        
        
        return headerView
    }
    
}



extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier,
                                                 for: indexPath) as! ProfileTableViewCell
        let viewModel = data[indexPath.row]
        cell.setup(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?()
        
      }
}

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    
    public func setup(with viewModel: ProfileViewModel){
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
            self.textLabel?.font = .systemFont(ofSize: 24, weight: .medium)
            
        }
    }
}
