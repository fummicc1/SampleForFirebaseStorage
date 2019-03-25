//
//  ViewController.swift
//  SampleForFirebaseStorage
//
//  Created by Fumiya Tanaka on 2019/03/25.
//  Copyright © 2019 Fumiya Tanaka. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    /// アイコンを格納するUIImageView
    @IBOutlet var iconImageView: UIImageView! {
        didSet {
            iconImageView.layer.cornerRadius = 30
            iconImageView.layer.masksToBounds = true
        }
    }
    /// ユーザーの名前を入力するUITextField
    @IBOutlet var userNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = UserDefaults.standard.value(forKey: "path") as? String {
            let userRef = Firestore.firestore().document(path)
            userRef.getDocument { (snap, error) in
                guard let snap = snap, let data = snap.data() else {
                    return print("did not fetch user")                    
                }
                guard let userName = data["userName"] as? String,
                    let iconPath = data["iconPath"] as? String else {
                        return
                }
                
                Storage.storage().reference().child(iconPath).downloadURL(completion: { (url, error) in
                    guard let url = url else {
                        return
                    }
                    guard let data = try? Data(contentsOf: url) else {
                        return
                    }
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.userNameTextField.text = userName
                        self.iconImageView.image = image
                    }
                })
            }
        }
        
    }
    
    @IBAction func didTapImageSelect() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    // 写真とユーザー情報をアップロードしていきます。
    @IBAction func uploadImage() {
        
        guard let image = iconImageView.image, let imageData = image.pngData() else {
            return
        }
        guard let userName = userNameTextField.text, !userName.isEmpty else {
            return
        }
        
        let userRef = Firestore.firestore().collection("Profiles").document()
        
        Storage.storage().reference().child("profiles").child(userName + ".png").putData(imageData, metadata: nil) { (metadata, error) in
            guard error == nil else {
                return print("detected error!")
            }
            guard let metadata = metadata else {
                return print("no metadata. error occurred.")
            }
            print(metadata.size)
            
            userRef.setData([
                "iconPath": metadata.path,
                "userName": userName
                ], merge: true, completion: { (error) in
                    guard error == nil else {
                        return print("error occurred while setting data to Firestore.")
                    }
                    // アップロードが完了したので情報を保存.
                    UserDefaults.standard.set(userRef.path, forKey: "path")
            })
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        DispatchQueue.main.async {
            self.iconImageView.image = image
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
