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
        
        // Uzun basma için gestureRecognizeri oluşturma
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        notesTableView.addGestureRecognizer(longPress)

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "NoteCell")
        let note = notesArray[indexPath.row]
        cell.textLabel?.text = note.content
        
        if note.is_pinned == true {
            cell.imageView?.image = UIImage(systemName: "pin.fill")
            cell.imageView?.tintColor = .systemBlue
        } else {
            cell.imageView?.image = nil
        }
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
                            content: note, is_pinned: false // *
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
                    .order("is_pinned", ascending: false)
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
            
            // İlk olarak silinecek notun satırını alacağız    notes -> notları kaydettiğimiz liste
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
    
    // Notu Detaylı Görüntüleme
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let note = notesArray[indexPath.row]
        
        let noteDetailAlert = UIAlertController(
                title: "Note Detail",
                message: note.content,
                preferredStyle: .alert
            )
        
        noteDetailAlert.addAction(UIAlertAction(title: "Exit Note Detail", style: .default))
        present(noteDetailAlert, animated: true)
    }
    
    // Notu Düzenleme
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let editAction = UIContextualAction(style: .normal, title: "Düzenle") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            // Düzenlenecek notun satırını alır
            let noteToEdit = self.notesArray[indexPath.row]
            
            // Düzenleme alert alanı
            let editAlert = UIAlertController(title: "Edit Note", message: nil, preferredStyle: .alert)
            editAlert.addTextField { textField in
                textField.text = noteToEdit.content
                textField.placeholder = "Note Content"
            }
            
            // Düzenlenen notun kaydolması için basılacak buton
            let saveAction = UIAlertAction(title: "SAVE", style: .default) { _ in
                if let newNoteContent = editAlert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !newNoteContent.isEmpty {
                    
                    Task {
                        do {
                            try await SupabaseManager.shared.client
                                .from("notes")
                                .update(["content": newNoteContent])
                                .eq("id", value: noteToEdit.id)
                                .execute()
                            
                            // Notları yeniden yükle
                            self.loadNotes()
                            
                        } catch {
                            self.makeAlert(titleInput: "Update Error!", messageInput: error.localizedDescription)
                        }
                    }
                }
            }
            
            editAlert.addAction(saveAction)
            editAlert.addAction(UIAlertAction(title: "CANCEL", style: .cancel))
            
            self.present(editAlert, animated: true)
            completionHandler(true)
        }
        
        // Sağa kaydırıldığında görünecek butonu rengi mavi ve iconu kalem şeklinde ayarlamak
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        // Satır kaydırıldığında gösterilecek butonu işaret eder
        return UISwipeActionsConfiguration(actions: [editAction])
    }
    
    // Uzun basılan satırdaki notu alır ve togglePin (pin değiştirme) fonksiyonuna gönderir
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: notesTableView)
            if let indexPath = notesTableView.indexPathForRow(at: point) {
                let note = notesArray[indexPath.row]
                togglePin(for: note)
            }
        }
    }
    
    // Pin durumunu tersine çevirir
    func togglePin(for note: Note) {
        let currentPinStatus = note.is_pinned ?? false
        let newPinStatus = !currentPinStatus
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("notes")
                    .update(["is_pinned": newPinStatus])
                    .eq("id", value: note.id)
                    .execute()
                
                await MainActor.run {
                    loadNotes()
                }
                
            } catch {
                await MainActor.run {
                    makeAlert(titleInput: "Error", messageInput: error.localizedDescription)
                }
            }
        }
    }
    
}
