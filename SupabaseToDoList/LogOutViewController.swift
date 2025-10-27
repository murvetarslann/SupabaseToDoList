//
//  LogOutViewController.swift
//  SupabaseToDoList
//
//  Created by Mürvet Arslan on 22.10.2025.
//

import UIKit
import Supabase

class LogOutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func makeAlert(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: UIAlertController.Style.alert)
        let okeButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okeButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logOutButtonClicked(_ sender: Any) {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
                
                await MainActor.run {
                    // Notification gönder
                    NotificationCenter.default.post(name: NSNotification.Name("userLoggedOut"), object: nil)
                }
            } catch {
                await MainActor.run {
                    makeAlert(titleInput: "ERROR!", messageInput: "Çıkış yapılamadı: \(error.localizedDescription)")
                }
            }
        }
    }
    
}

