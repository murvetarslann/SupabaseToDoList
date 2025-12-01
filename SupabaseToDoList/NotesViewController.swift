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
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "NoteCell")
        let note = notesArray[indexPath.row]
        cell.textLabel?.text = note.content
        
        if note.is_pinned == true {
            cell.imageView?.image = UIImage(systemName: "pin.fill")
            cell.imageView?.tintColor = .systemBlue
        } else {
            cell.imageView?.image = nil
        }
        
        // Sağ taraf: Öncelik ikonu
        let priority = note.priority ?? "normal"
        
        switch priority {
        case "urgent":
            cell.detailTextLabel?.text = "🔴"
        case "important":
            cell.detailTextLabel?.text = "🟠"
        case "normal":
            cell.detailTextLabel?.text = "⚪"
        default:
            cell.detailTextLabel?.text = ""
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
        
        let nextButton = UIAlertAction(title: "Next", style: .default) { [weak self] action in // Buton ismini Save yerine Next olarak ayarladım
            if let note = addNoteAlert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                // Öncelik durumunu seçme ekranı açılacak
                self?.showPriorityPicker(content: note)
            }
        }
        
        let noteCancelButton = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { action in
            self.view.endEditing(true)
        }
                
        addNoteAlert.addAction(nextButton)
        addNoteAlert.addAction(noteCancelButton)
        self.present(addNoteAlert, animated: true, completion: nil)
    }
    
    func loadNotes() {
        Task {
            do {
                
                let user = try await SupabaseManager.shared.client.auth.session.user
                
                // Giriş yapan kullanıcının notlarını çekiyoruz
                let response: [Note] = try await SupabaseManager.shared.client
                    .from("notes")
                    .select()
                    .eq("user_id", value: user.id)
                    .execute()
                    .value
                
                // Manuel sıralama
                let sortedNotes = response.sorted { note1, note2 in
                    // 1. Pin durumu (pinliler en üstte olacak)
                    let pinned1 = note1.is_pinned ?? false
                    let pinned2 = note2.is_pinned ?? false
                    
                    if pinned1 != pinned2 {
                        return pinned1 && !pinned2
                    }
                    
                    // 2. Öncelik sırası (acil > önemli > normal)
                    let priority1 = self.priorityValue(note1.priority ?? "normal")
                    let priority2 = self.priorityValue(note2.priority ?? "normal")
                    if priority1 != priority2 {
                        return priority1 > priority2
                    }
                    
                    // 3. Tarih (en yeni üstte)
                    return (note1.created_at ?? "") > (note2.created_at ?? "")
                }

                
                // TableView i güncelliyoruz
                await MainActor.run {
                    self.notesArray = sortedNotes
                    self.notesTableView.reloadData()
                }
                
            } catch {
                print("Notlar yüklenemedi: \(error.localizedDescription)")
            }
        }
    }
    
    func priorityValue(_ priority: String) -> Int {
        switch priority {
            case "urgent": return 3
            case "important": return 2
            case "normal": return 1
            default: return 1
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
                        if let index = self.notesArray.firstIndex(where: { note in return note.id == noteToBeDelete.id }) {
                            self.notesArray.remove(at: index)
                            let indexPathToDelete = IndexPath(row: index, section:0)
                            notesTableView.deleteRows(at: [indexPathToDelete], with: .fade)
                        }
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
    
    func showPriorityPicker(content: String) {
        
        let prioritySheet = UIAlertController(
            title: "Choose Priority",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Normal butonu
        let normalAction = UIAlertAction(title: "⚪ Normal", style: .default) { [weak self] _ in
            self?.saveNote(content: content, priority: "normal")
        }
        
        // Önemli butonu
        let importantAction = UIAlertAction(title: "🟠 Important", style: .default) { [weak self] _ in
            self?.saveNote(content: content, priority: "important")
        }
        
        // Acil butonu
        let urgentAction = UIAlertAction(title: "🔴 Urgent", style: .default) { [weak self] _ in
            self?.saveNote(content: content, priority: "urgent")
        }
        
        // İptal butonu
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Butonları ekle
        prioritySheet.addAction(normalAction)
        prioritySheet.addAction(importantAction)
        prioritySheet.addAction(urgentAction)
        prioritySheet.addAction(cancelAction)
        
        // ActionSheet'i göster
        present(prioritySheet, animated: true)
    }
    
    func saveNote(content: String, priority: String) {
        Task {
            do {
                let user = try await SupabaseManager.shared.client.auth.session.user
                
                let noteData = NoteInsert(
                    user_id: user.id,
                    content: content,
                    is_pinned: false,
                    priority: priority
                )
                
                try await SupabaseManager.shared.client
                    .from("notes")
                    .insert(noteData)
                    .execute()
                
                
                self.loadNotes()
                
            } catch {
                print("Could not add note: \(error.localizedDescription)")
            }
        }
    }
    
}
