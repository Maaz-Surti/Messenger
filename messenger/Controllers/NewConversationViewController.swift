//
//  NewConversationViewController.swift
//  messenger
//
//  Created by TechnoMac6 on 28/01/22.
//

import UIKit
import JGProgressHUD
import RealmSwift

class NewConversationViewController: UIViewController {

    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]()
    
    private var results = [SearchResult]()
    
    private var hasFetched = false
    
    private let searchBar : UISearchBar = {
        let searchbar = UISearchBar()
        searchbar.placeholder = "Search for users"
        return searchbar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        table.isHidden = true
        
        return table
    }()
    
    private let noResulsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results"
        label.textAlignment = .center
        label.isHidden = true
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
        
        
        // Adding subviews
        view.addSubview(noResulsLabel)
        view.addSubview(tableView)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        noResulsLabel.frame = CGRect(x: view.width/4,
                                     y: (view.height-200)/2,
                                     width: view.width/2,
                                     height: 200)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier,
                                                 for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true, completion: { [weak self] in
            
            self?.completion?(targetUserData)
        })
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
 
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.isEmpty, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        
        spinner.show(in: view)
        
        self.searchUsers(Query: text)
    }
    
    func searchUsers(Query: String){
        
        //check if array has firebase results
        if hasFetched{
            filterUsers(with: Query)
        }
        else {
            DatabaseManager.shared.getAllUsers(completion: { [weak self] results in
                guard let self = self else { return }
                switch results {
                case .success(let userCollection):
                    self.users = userCollection
                    self.hasFetched = true
                    self.filterUsers(with: Query)
                    
                case .failure(let error):
                    print("Failed to get users: ", error )
                }
            })
        }
        //if it does: filter
        //if it doesnt: fetch and filter
        //update the UI, and show results or the no results label

    }
    
    func filterUsers(with term: String){
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        
        
        
        self.spinner.dismiss(animated: true )
        
        let results: [SearchResult] = self.users.filter({
            
            guard let email = $0["email"], email != safeEmail else {
                      return false  }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            
            guard let email = $0["email"], let name = $0["name"] else {
                      return nil
            }
            
            return SearchResult(name: name, email: email)
        })
        
        self.results = results
        
        updateUI()
        
    }
    
    func updateUI(){
        if results.isEmpty {
            self.noResulsLabel.isHidden = false
            self.tableView.isHidden = true
        }
        else {
            self.noResulsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

struct SearchResult {
    let name: String
    let email: String
    
}
