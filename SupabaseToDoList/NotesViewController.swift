//
//  NotesViewController.swift
//  SupabaseToDoList
//
//  Created by Mürvet Arslan on 22.10.2025.
//

import UIKit
import Supabase


class NotesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var notesTableView: UITableView!
    
    var notesArray: [Note] = [] // Notları tutmak için array    [Note] -> Structaki Note
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notesTableView.dataSource = self
        notesTableView.delegate = self
        
        loadNotes()

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "NoteCell")
        let note = notesArray[indexPath.row]
        cell.textLabel?.text = note.content
        return cell
    }
    
    func makeAlert(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: UIAlertController.Style.alert)
        let okeButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okeButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addNoteButtonClicked(_ sender: Any) {
        
        let addNoteAlert = UIAlertController(title: "Adding Notes Form", message: nil, preferredStyle: .alert)
        addNoteAlert.addTextField { noteTextField in
            noteTextField.placeholder = "Write a note"
        }
        
        let noteSaveButton = UIAlertAction(title: "Save Note", style: .default) { action in
            if let note = addNoteAlert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                Task {
                    do {
                        let user = try await SupabaseManager.shared.client.auth.session.user
                        let noteData = NoteInsert(
                            user_id: user.id,
                            content: note
                        )
                        
                        try await SupabaseManager.shared.client.from("notes").insert(noteData).execute()
                        print("Not eklendi")
                        self.loadNotes()
                        
                    } catch {
                        print("Note eklenemedi")
                    }
                }
            }
        }
        
        let noteCancelButton = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { action in
            self.view.endEditing(true)
        }
                
        addNoteAlert.addAction(noteSaveButton)
        addNoteAlert.addAction(noteCancelButton)
        self.present(addNoteAlert, animated: true, completion: nil)
    }
    
    func loadNotes() {
        Task {
            do {
                // Giriş yapan kullanıcı alıyoruz
                let user = try await SupabaseManager.shared.client.auth.session.user
                
                // Aldığımız bu kullanıcının notlarını çekiyoruz
                let response: [Note] = try await SupabaseManager.shared.client
                    .from("notes")
                    .select()
                    .eq("user_id", value: user.id)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                // TableView i güncelliyoruz
                await MainActor.run {
                    self.notesArray = response
                    self.notesTableView.reloadData()
                }
                
            } catch {
                print("Notlar yüklenemedi: \(error.localizedDescription)")
            }
        }
    }
    
    // Not Silem İşlemi
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // İlk olarak silinecek notun sütununu alacağız    notes -> notları kaydettiğimiz liste
            let noteToBeDelete = notesArray[indexPath.row]
            
            // Sonrasında seçilen notu supabaseden siliyoruz
            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("notes")
                        .delete()
                        .eq("id", value: noteToBeDelete.id)
                        .execute()
                    
                    // Notu supabaseden sildikten sonra ekranımızı güncelliyoruz
                    await MainActor.run {
                        self.notesArray.remove(at: indexPath.row)
                        notesTableView.deleteRows(at: [indexPath], with: .fade)
                    }
                } catch {
                    self.makeAlert(titleInput: "Delete Error!", messageInput: error.localizedDescription)
                }
            }
        }
    }
    
}
