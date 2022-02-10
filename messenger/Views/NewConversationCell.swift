//
//  NewConversationCell.swift
//  messenger
//
//  Created by TechnoMac6 on 08/02/22.
//

import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {

    static let identifier = "NewConversationCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize:21, weight: .semibold)
        label.layer.masksToBounds = true
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style:style, reuseIdentifier: reuseIdentifier)
        
        super.layoutSubviews()
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
       
        userImageView.frame = CGRect(x: 10 ,
                                     y: 10,
                                     width: 50,
                                     height: 50)
        userNameLabel.frame = CGRect(x: userImageView.right + 10 ,
                                     y: 10,
                                     width: (contentView.width - 20 - userImageView.width),
                                     height: 50)

    }
    
    public func configure(with model: SearchResult){
        
        self.userNameLabel.text = model.name

        let path = "images/\(model.email)_profile_picture.png"
        
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
                
            case .failure(let error):
                print("failed to get image url: ", error)
            }
        })
    }

}

