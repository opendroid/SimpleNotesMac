//
//  AddAttachmentVC.swift
//  SimpleNotes
//
//  Created by Ajay Thakur on 7/2/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

import Cocoa

protocol AddAttachmentDelegate {
    func addAttachment()
}

class AddAttachmentVC: NSViewController {

    // Process the add button click in Document.swift
    var delegate : AddAttachmentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    

    @IBAction func addFileAttachmentHandler(sender: NSButton) {
        if let delegateMe = self.delegate {
            delegateMe.addAttachment()
        }
    }
}
