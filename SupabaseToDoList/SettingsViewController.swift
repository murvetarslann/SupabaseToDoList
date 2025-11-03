//
//  SettingsViewController.swift
//  SupabaseToDoList
//
//  Created by Mürvet Arslan on 30.10.2025.
//

import UIKit
import Supabase

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var fullNameText: UITextField!
    
    var selectedImage: UIImage? // Seçilen profil fotoğrafını saklayacağım değişken
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userProfileImage.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(chooseImage))
        userProfileImage.addGestureRecognizer(gestureRecognizer)
        
        loadUserInformation()
    }
    
    func makeAlert(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: UIAlertController.Style.alert)
        let okeButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okeButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logOutButtonClickedd(_ sender: Any) {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
                
                await MainActor.run {
                    // Notification gönder
                    NotificationCenter.default.post(name: NSNotification.Name("userLoggedOut"), object: nil)
                }
            } catch {
                await MainActor.run {
                    makeAlert(titleInput: "ERROR!", messageInput: "Could Not Exit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Veritabanından kullanıcı bilgilerini çekip ekrana yazdırır
    func loadUserInformation() {
        Task {
            do {
                let user = try await SupabaseManager.shared.client.auth.session.user
                
                let receivedEmail = user.email!
                let receivedFullName = user.userMetadata["full_name"]?.stringValue ?? "" // Kullanıcının tam ismini metadatadan alıp receivedFullName değişkenine atar
                let receivedCreatedAt = user.createdAt
                
                await MainActor.run {
                    fullNameText.text = receivedFullName
                    userEmailLabel.text = receivedEmail
                    creationDateLabel.text = formatDate(receivedCreatedAt)
                }
            } catch {
                makeAlert(titleInput: "ERROR!", messageInput: error.localizedDescription)
            }
        }
    }
    
    // Tarihi okunabilir hale getiren fonksiyon
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long // Tarih gösterme stili
        formatter.timeStyle = .none // Saat gösterme
        formatter.locale = Locale(identifier: "tr_TR") // Gösterilecek dil
        return formatter.string(from: date)
    }
    
    /*
     UserMetada Nedir?
        Supabase'de kullanıcı kayıt olurken email ve şifre zorunlu, ama başka bilgiler de eklenebilir. Bu ekstra bilgiler userMetadata'da saklanır. Çünkü Supabase Auth tablosu sadece kimlik
        doğrulama için tasarlanmıştır.
     */
    
    @objc func chooseImage() {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        userProfileImage.image = info[.originalImage] as? UIImage
        selectedImage = info[.originalImage] as? UIImage // Galeriden seçilen görseli "selectedImage" değişkenine atıyoruz
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveChangesButtonClicked(_ sender: Any) {
        guard let fullName = fullNameText.text?.trimmingCharacters(in: .whitespacesAndNewlines), !fullName.isEmpty else {
            makeAlert(titleInput: "ERROR!", messageInput: "Full Name Cannot Be Empty!")
            return
        }
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(
                        data: ["full_name": .string(fullName)]
                    )
                )
                makeAlert(titleInput: "SUCCESS", messageInput: "Full Name has been changed")
            } catch {
                makeAlert(titleInput: "ERROR!", messageInput: error.localizedDescription)
            }
        }
    }
    
    
}
