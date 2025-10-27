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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notesTableView.dataSource = self
        notesTableView.delegate = self

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "Deneme"
        return cell
    }
    
    @IBAction func addNoteButtonClicked(_ sender: Any) {
        
        let addNoteAlert = UIAlertController(title: "Adding Notes Form", message: nil, preferredStyle: .alert)
        addNoteAlert.addTextField { noteTextField in
            noteTextField.placeholder = "Write a note"
        }
        
        let noteSaveButton = UIAlertAction(title: "Save Note", style: .default) { action in
            if let note = addNoteAlert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                do{
                    try print("Note Recorded")
                } catch {
                    print("Note Could Not Be Saved")
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
    
}
