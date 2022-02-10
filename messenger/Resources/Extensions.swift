//
//  Extensions.swift
//  messenger
//
//  Created by TechnoMac6 on 28/01/22.
//

import Foundation
import UIKit

extension UIView{
    public var width: CGFloat{
        return self.frame.size.width
    }
    public var height: CGFloat{
        return self.frame.size.height
    }
    public var top: CGFloat{
        return self.frame.origin.y
    }
    public var bottom: CGFloat{
        return self.frame.size.height + self.frame.origin.y
    }
    public var left: CGFloat{
        return self.frame.origin.x
    }
    public var right: CGFloat{
        return self.frame.size.width + self.frame.origin.x
    }
    
}

extension UIViewController{
    
    func alert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

extension Notification.Name {
    static let didLogInNotification = Notification.Name("didLogInNotification")
    static let didOpenTheApp = Notification.Name("didOpenTheApp")
}
