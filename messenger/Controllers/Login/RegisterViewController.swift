//
//  RegisterViewController.swift
//  messenger
//
//  Created by TechnoMac6 on 28/01/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

enum Groups: String, CaseIterable {
    
    case UVCeed
    case FanPopz
    case SmokeDetector
    case SkyVue
}

class RegisterViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        
        return field
    }()
    
    private let pickerView = UIPickerView()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        
        return field
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password   "
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        field.textContentType = .oneTimeCode

        return field
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let groupField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Group"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.tintColor = UIColor.clear
        
        return field
    }()

    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.titleLabel?.textColor = .white
        return button
    }()
    
    private var groups: [String] {
        return Groups.allCases.map { $0.rawValue }
    }
    
    private var groupID = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Register"
        view.backgroundColor = .systemBackground
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
//                                                            style: .done,
//                                                            target: self,
//                                                            action: #selector(didTapRegister))
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        groupField.delegate = self
        pickerView.dataSource = self
        pickerView.delegate = self
        groupField.inputView = pickerView
        
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        scrollView.addSubview(groupField)
        
        imageView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        gesture.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(gesture)

        
    }
    
    @objc func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        
        // Closes keyboard when touched outside of the textField
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
        
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        imageView.layer.cornerRadius = imageView.width / 2.0
        
        firstNameField.frame = CGRect(x: 30,
                                 y: imageView.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        lastNameField.frame = CGRect(x: 30,
                                 y: firstNameField.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        
        groupField.frame = CGRect(x: 30,
                                 y: lastNameField.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        
        emailField.frame = CGRect(x: 30,
                                 y: groupField.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        passwordField.frame = CGRect(x: 30,
                                 y: emailField.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        registerButton.frame = CGRect(x: 30,
                                 y: passwordField.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        

    }
    
    @objc private func registerButtonTapped(){
        
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              password.count >= 6
        else {
            alertUserLoginError()
            return }
        
        spinner.show(in: view)
        
        // Firebase login
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            guard let self = self else {
                return }
            
            DispatchQueue.main.async {
                self.spinner.dismiss(animated: true)
            }
            guard !exists else {
                // user already exists
                self.alert(title: "uh oh..", message: "Looks like a user account for that email already exists")
                return }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] authResult, error in
                
                guard let result = authResult, error == nil else {
                    print("Error creating user", error as Any)
                    return
                }
                
                // Caching their username and email
                
                UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                UserDefaults.standard.set(email, forKey: "email")
                
                guard let groupID = self?.groupID else {
                    print("Could not get the group ID")
                    return
                }
                
                let chatUser =  chatAppUser(firstName: firstName,
                                            lastName: lastName,
                                            emailAdress: email, groupID: String(groupID))
                
                DatabaseManager.shared.insertUser(with: chatUser, completion: { [weak self] success in
                    if success {
                        // upload image
                        guard let image = self?.imageView.image,
                        let data = image.pngData() else {
                            print("Cannot get png data")
                            return }
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
                    }
                })
                
                let user = result.user
                print("User: ", user)
                
                
                
                self?.navigationController?.dismiss(animated: true, completion: nil)
                
            })
        })
        
    }
    
    
    @objc func alertUserLoginError(){
        alert(title: "Woops", message: "Please enter all the information to create a new account")
    }
    

}

// MARK: Image Picker Functions

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select your picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            
            return }
        
        self.imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: Pickerview

extension RegisterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return groups.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            groupID = 0
            groupField.text = Groups.UVCeed.rawValue
        } else if row == 1 {
            groupID = 1
            groupField.text = Groups.FanPopz.rawValue
        }  else if row == 2 {
            groupID = 2
            groupField.text = Groups.SmokeDetector.rawValue
        }  else if row == 3 {
            groupID = 3
            groupField.text = Groups.SkyVue.rawValue
        }
        self.view.endEditing(true)
        print(groupID)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return groups[row]
    }
    
    
}

// MARK: Text field extension

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
          registerButtonTapped()
        }
        
        return true
    }
                
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       
        if textField == groupField {
            return false
        }
        
        return true
    }
    
}
