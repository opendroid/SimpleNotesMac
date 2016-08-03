//
//  SimpleNoteCVI.swift
//  SimpleNotes
//
//  Created by Ajay Thakur on 7/2/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

import Cocoa

class SimpleNoteCVI: NSCollectionViewItem {

    // Delegate that will process double click on attachment
    weak var delegate: SimpleNoteCVIDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // Track double tap to open attachment
    override func mouseDown(theEvent: NSEvent) {
        if theEvent.clickCount == 2, let delegateMe = self.delegate {
            delegateMe.openAttachment(self)
        }
    }
}
