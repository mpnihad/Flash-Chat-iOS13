//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase


class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var message : [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        loadMessages()
        messageTextfield.delegate = self
        
    }
    
    @IBAction func chatLogoutPressed(_ sender: UIBarButtonItem) {
        
        do {
            try Auth.auth().signOut()
            
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            
        }
        
    }
     func sendMessage() {
        if let messageBody = messageTextfield.text, let email = Auth.auth().currentUser?.email{
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField : email,
                K.FStore.bodyField : messageBody,
                K.FStore.dateField : NSDate().timeIntervalSince1970
                
            ]) { error in
                if let e = error {
                    print("Error : \(e.localizedDescription)")
                }
                else
                {
                    print("Message send Succesfully")
                    
                }
            }
            
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        sendMessage()
        messageTextfield.text = ""
        messageTextfield.endEditing(true)
    }
    
    func loadMessages(){
        
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { querySnapShort, error in
            
            
            if let e = error {
                print("Downloading messages unsuccesfull : \(e.localizedDescription)")
            }
            else
            {
                self.message = []
                if let snapshotDoc = querySnapShort?.documents{
                    
                   
                    for doc  in  snapshotDoc {
                        let data = doc.data()
                        if let messageSender =  data[K.FStore.senderField] as? String, let messageBody =  data[K.FStore.bodyField] as? String, let date = data[K.FStore.dateField] as? Double {
                            self.message.append(Message(body: messageBody, sender: messageSender, date: date))
                            
                            
                        }
                        
                    }
                    
                    
                }
                print("Successfully downloaded messages")
                
//                self.message.sort { message1, message2 in
//                    message1.date < message2.date
//                }
                DispatchQueue.main.async {
                
                    self.tableView.reloadData()
                    
                    let indexPath =  IndexPath(row: self.message.count-1, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
        }
    }
    
    
}


//MARK: - Table Contents
extension ChatViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath)
        
        let currentUser = Auth.auth().currentUser?.email ?? "Not Logged in"
        if let cellMessage  = cell as? MessageCell {
            
            if(currentUser == message[indexPath.row].sender){
                cellMessage.rightImageView.isHidden = false
                cellMessage.leftImageView.isHidden = true
                cellMessage.messageBuble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
                
                cellMessage.messageLabel.textColor = UIColor(named: K.BrandColors.purple)

            }
            else
            {
                
                    cellMessage.rightImageView.isHidden = true
                    cellMessage.leftImageView.isHidden = false
                cellMessage.messageBuble.backgroundColor = UIColor(named: K.BrandColors.purple)
                cellMessage.messageLabel.textColor = UIColor(named: K.BrandColors.lightPurple)
            }
            cellMessage.messageLabel.text = message[indexPath.row].body
            return cellMessage
            
        }
        return cell
        
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return   message.count
    }
    
    
}

extension ChatViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}


//MARK: - UITextFieldDelegate


extension ChatViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print(messageTextfield.text ?? "")
        messageTextfield.endEditing(true)
        return true
    }
    
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text == "" || textField.text == nil {
            return false
        }
        
        else
        {
            textField.placeholder = "Type Something"
            return true
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        sendMessage()
        
        
        self.messageTextfield.text = ""
        
    }
    
}
