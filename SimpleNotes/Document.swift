//
//  Document.swift
//  SimpleNotes
//
//  Created by Ajay Thakur on 7/2/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//
//  To opt-in iCLoud set these up https://developer.apple.com/library/prerelease/content/documentation/General/Conceptual/ExtensibilityPG/FileProvider.html
//

import Cocoa


// Add extension to NSFileWrapper
extension NSFileWrapper {
    
    // Return extension of the file paris.img001.png would retrun type .png
    dynamic var fileExtension : String? {
        return preferredFilename?.componentsSeparatedByString(".").last
    }
    
    // Ask execution enviornment to take 'fileExtension' and provide a icon for it
    dynamic var thumbnailImage : NSImage {
        if let fileExtension = self.fileExtension {
            // Provide icon for  a file extension
            return NSWorkspace.sharedWorkspace().iconForFileType(fileExtension)
        } else { // extension is nil retuen generic icon
            return NSWorkspace.sharedWorkspace().iconForFileType("")
        }
    }
    
    // Does it conform to provided object identifier
    func conformsToType(type:CFString) -> Bool {
        guard let fileExtension = self.fileExtension else {
            return false
        }
        
        // Ask OS Type system (C Library) to provide an object for a file type
        guard let fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)?.takeRetainedValue() else {
            return false
        }
        // Take file type and check of confirms with 'type'
        return UTTypeConformsTo(fileType, type)
    }
}

// Define the enumerations
enum NoteDocumentFileNames : String {
    case TextFile = "Text.rtf"
    case AttachmentsDirectory = "Attachments"
}

enum NotesErrorCodes : Int {
    /// We could not access document
    case CannotAccessDocument
    /// We could not access file wrappers inside this document
    case CannotLoadWrapperFiles
    /// Could not load Text.rtf
    case CannotLoadText
    /// We could not access attachements
    case CannotAccessAttachments
    /// We could not save the text file
    case CannotSaveText
    /// We could not save the the attachments
    case CannotSaveAttachment
}

let ErrorDomain = "SimpleNotesErrorDomain"

//
// userInfo is optional with default value as nil if it is not specified
//

func err(code: NotesErrorCodes, _ userInfo:[NSObject:AnyObject]? = nil) -> NSError {
    // generate the NSError object
    return NSError (domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
}

//
// SimpleNoteCVIDelegate: Delegate that is called when double-click is pressed on a attachment
//
@objc protocol SimpleNoteCVIDelegate {
    func openAttachment(collectionViewItem: NSCollectionViewItem)
}

// Main document class
class Document: NSDocument {
    
    // Document.rtf text file.
    var documentText = NSAttributedString()
    
    // 'Attachments' directory wrapper
    var documentFileWrapper = NSFileWrapper(directoryWithFileWrappers:[:])
    
    
    // UX: Show the dictionary here
    @IBOutlet weak var attachmentList: NSCollectionView!

    // Represent folder "Attachments" inside documents package
    private var attachmentsDirectoryWrapper : NSFileWrapper? {
        // Ensure document Wrappers exist
        guard let fileWrappers = self.documentFileWrapper.fileWrappers else {
            return nil
        }
        
        // If attachments is already in pakage do nothing otherwise create it  and add to documents
        var wrapper = fileWrappers[NoteDocumentFileNames.AttachmentsDirectory.rawValue]
        if wrapper == nil {
            wrapper = NSFileWrapper(directoryWithFileWrappers: [:])
            wrapper?.preferredFilename = NoteDocumentFileNames.AttachmentsDirectory.rawValue
            self.documentFileWrapper.addFileWrapper(wrapper!)
        }
        return wrapper
    }
    // List of NSFileWrappers in current document
    dynamic var attachedFiles : [NSFileWrapper]? {
        if let attachedFileWrappers = self.attachmentsDirectoryWrapper?.fileWrappers {
            return Array(attachedFileWrappers.values)
        } else {
            return nil
        }
    }
    
    // add a popober Interface
    var popover : NSPopover?
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
        
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    
    // Register attachment list for drag and drop.
    override func windowControllerDidLoadNib(windowController: NSWindowController) {
        self.attachmentList.registerForDraggedTypes([NSURLPboardType])
    }
    // MARK: -
    // MARK: Storing and managing attachmens.
    // MARK: -

    func addAttachmentsAtURL (url:NSURL) throws {
        guard self.attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        guard url.path != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        self.willChangeValueForKey("attachedFiles")
        
        // If file is already in the package -- remove old one first.
        // New file may be a recent version of it.
        for wrapper in (self.attachmentsDirectoryWrapper?.fileWrappers)! {
            let (fileName, oldWrapper) = wrapper
            let inboundFile = url.path!.componentsSeparatedByString("/").last
            if  inboundFile == fileName {
                self.attachmentsDirectoryWrapper?.removeFileWrapper(oldWrapper)
                break
            }
        }
        // Place in new wrapper.
        let newAttachment = try NSFileWrapper(URL: url, options: NSFileWrapperReadingOptions.Immediate)
        self.attachmentsDirectoryWrapper?.addFileWrapper(newAttachment) // guard has passed

        
        self.updateChangeCount(.ChangeDone)
        self.didChangeValueForKey("attachedFiles")
    }
    // MARK: -
    // MARK: read/write methods for flat files. DO NOT IMPLEMENT.
    // MARK: -
    override func dataOfType(typeName: String) throws -> NSData {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    // MARK: -
    // MARK: read/write methods for collections
    // MARK: -
    // fileWrapperOfType: prepares and returns file wrapper to the systsm that saves it to the disk
    override func fileWrapperOfType(typeName: String) throws -> NSFileWrapper {
        // typename: typeName=com.plutoapps.simplenotes.note
        // Override old data if it exists ie. remove it then override it
        if let oldFileWrapper = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldFileWrapper) // remove it
        }
        
        // Extract attributed string data from the documentText. Then encode it  (in a NSData) for
        // 'NSDocumentTypeDocumentAttribute' as 'NSRTFTextDocumentType' ie encode it for RTF format
        //  to save in the file system. Ignore the error if any, notice the 'try' use
        // no  nil check required for'textRTFdata' as 'dataFromRange' returns a variable and throws an
        // error otherwise. That gets propogated it up.
        let textRTFdata = try self.documentText.dataFromRange(NSRange(0..<self.documentText.length),
                                   documentAttributes: [NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType])
        
        // Update the file wrapper with new NSData
        self.documentFileWrapper.addRegularFileWithContents(textRTFdata, preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
        
        return self.documentFileWrapper
    }
    
    // Read from 'fileWrapper' into the 'documentText'
    override func readFromFileWrapper(fileWrapper: NSFileWrapper, ofType typeName: String) throws {
        NSLog("Document:readFromFileWrapper: typeName=\(typeName)")
        
        // Ensure we have file wrappers
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(.CannotLoadWrapperFiles)
        }
        
        NSLog("Document:readFromFileWrapper: count of 'fileWrappers' dictionary =\(fileWrappers.count)")
        for key in fileWrappers.keys {
            NSLog("Document:readFromFileWrapper: key:\(key)")
        }
        
        // ensure we can access document data
        guard let documentTextData = fileWrappers[NoteDocumentFileNames.TextFile.rawValue]?.regularFileContents else {
            throw err(.CannotLoadText)
        }
        
        // Convert NSDATA to Attibuted string
        guard let documentTextAttributed = NSAttributedString(RTF:documentTextData, documentAttributes:nil) else {
            throw err(.CannotLoadText)
        }

        // Save text
        self.documentText = documentTextAttributed
        
        // Save file wrapper
        self.documentFileWrapper = fileWrapper
    }
    
    // MARK: -
    // MARK: Handle attachments
    // MARK: -
    @IBAction func addAttachmentHandler(sender: AnyObject) {
        if let vc = AddAttachmentVC(nibName:"AddAttachmentVC", bundle: NSBundle.mainBundle()) {
            self.popover = NSPopover()
            if (self.popover != nil) {
                vc.delegate = self
                self.popover?.behavior = .Transient
                self.popover?.contentViewController = vc
                self.popover?.showRelativeToRect(sender.bounds, ofView: sender as! NSView, preferredEdge: NSRectEdge.MaxY)
            }
            
        }
    }
}

// MARK: -
// MARK: Handle adding attachments
// MARK: -
extension Document : AddAttachmentDelegate {
    func addAttachment() {
        
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canDownloadUbiquitousContents = false
        panel.canResolveUbiquitousConflicts = true
        
        
        panel.beginWithCompletionHandler { (result:Int) in
            if result == NSModalResponseOK, let resultUrl = panel.URLs.first {
                do {
                    try self.addAttachmentsAtURL(resultUrl)
                    self.attachmentList?.reloadData()
                } catch let error as NSError {
                    NSLog("Document:addAttachment: error attaching: \(panel.URLs.first!)")

                    if let window = self.windowForSheet {
                        NSApp.presentError(error, modalForWindow: window, delegate: nil, didPresentSelector: nil, contextInfo: nil)
                    } else {
                        NSApp.presentError(error)
                    }
                } // end 'catch'
            } // end if == result 
        } // end 'panel.beginWithCompletionHandler'
        
    } // end 'addAttachment'
}

// MARK: -
// MARK: Handle double-click on attachments
// MARK: -
extension Document : SimpleNoteCVIDelegate {
    func openAttachment(collectionViewItem: NSCollectionViewItem)  {
        // Check index
        guard let selectedIndex = self.attachmentList.indexPathForItem(collectionViewItem)?.item else {
            return
        }
        // check attachment in question
        guard let attachment = self.attachedFiles?[selectedIndex] else {
            return
        }
        // make sure document is saved
        self.autosaveWithImplicitCancellability(false) { (error: NSError?) in
            // Url: file:///Users/username/Downloads/Sample-2.atn/
            var url = self.fileURL
            // Url: file:///Users/username/Downloads/Sample-2.atn/Attachments/
            url = url?.URLByAppendingPathComponent(NoteDocumentFileNames.AttachmentsDirectory.rawValue, isDirectory: true)
            // Url: file:///Users/username/Downloads/Sample-2.atn/Attachments/IMG_2026.jpg
            url = url?.URLByAppendingPathComponent(attachment.preferredFilename!)
            if let path = url?.path { // All well ask OS to open the attachment
                // Path: /Users/username/Downloads/Sample-2.atn/Attachments/IMG_2026.jpg
                NSWorkspace.sharedWorkspace().openFile(path, withApplication: nil, andDeactivate: true)
            }
        }
    }
}

// MARK: -
// MARK: Handle collection view data source
// MARK: -
extension Document: NSCollectionViewDataSource {
    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.attachedFiles?.count ?? 0
    }
    
    func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItemWithIdentifier("SimpleNoteCVI", forIndexPath: indexPath)
        guard let cvItem = item as? SimpleNoteCVI else {
            NSLog("Document:collectionView: No cvItem")
            return item
        }
        
        let attachment = self.attachedFiles![indexPath.item]
        cvItem.imageView?.image = attachment.thumbnailImage
        cvItem.textField?.stringValue = attachment.fileExtension ?? ""
        cvItem.delegate = self // delegate for opening attachment
        return cvItem
    }
}

// MARK: -
// MARK: Handle collection view drag and drop
// MARK: -
extension Document: NSCollectionViewDelegate {
    
    // validateDrop is called whenever user drops something over a collectionView.
    func collectionView(collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath?>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {
        // When user drops mouse button copy whatevery they are dropping
        return NSDragOperation.Copy
    }
    
    func collectionView(collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: NSIndexPath, dropOperation: NSCollectionViewDropOperation) -> Bool {
        let pasteboard = draggingInfo.draggingPasteboard() // pasteboard of info user just dropped
        if pasteboard.types?.contains(NSURLPboardType) == true,
            let url = NSURL(fromPasteboard:pasteboard) {
            do {
                try self.addAttachmentsAtURL(url) // try and add attachment
                attachmentList.reloadData()
                return true // all well
            } catch let error as NSError {
                self.presentError(error)
                return false
            }
        }
        
        return false
    }
}