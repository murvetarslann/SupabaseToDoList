//
//  ViewController.swift
//  SupabaseToDoList
//
//  Created by Mürvet Arslan on 21.10.2025.
//

import UIKit
import Supabase

class ViewController: UIViewController {
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var userEmailText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        userEmailText.text = ""
        passwordText.text = ""
    }
    
    func makeAlert(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: UIAlertController.Style.alert)
        let okeButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okeButton)
        self.present(alert, animated: true, completion: nil)
    }

    // Giriş Yap
    @IBAction func signInButtonClicked(_ sender: Any) {
        if userEmailText.text != "" && passwordText.text != "" {
            Task {
                do {
                    try await SupabaseManager.shared.client.auth.signIn(
                        email: userEmailText.text!,
                        password: passwordText.text!
                    )

                    await MainActor.run {
                        performSegue(withIdentifier: "toNotesVC", sender: nil)
                    }
                    
                } catch {
                    await MainActor.run {
                        self.makeAlert(titleInput: "ERROR!", messageInput: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // Kayıt Ol
    @IBAction func signUpButtonClicked(_ sender: Any) {
        if userEmailText.text != "" && passwordText.text != "" {
            
            Task {
                do {
                    
                    try await SupabaseManager.shared.client.auth.signUp(
                        email: userEmailText.text!,
                        password: passwordText.text!
                    )
                    
                    //Kayıt olan kullanıcı direkt giriş yapsın
                    try await SupabaseManager.shared.client.auth.signIn(
                        email: userEmailText.text!,
                        password: passwordText.text!
                    )

                    await MainActor.run {
                        performSegue(withIdentifier: "toNotesVC", sender: nil)
                    }
                    
                } catch {
                    await MainActor.run {
                        self.makeAlert(titleInput: "ERROR!", messageInput: error.localizedDescription)
                    }
                }
            }
            
        } else {
            makeAlert(titleInput: "ERROR!", messageInput: "Username/Password?")
        }
    }
    
   
}

