//
//  ViewController.swift
//  LargeDocument
//
//  Created by Greg Cerveny on 4/20/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private lazy var localRoot: URL? = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask).first

    private func getDocumentURL(for filename: String) -> URL? {
      return localRoot?.appendingPathComponent(filename, isDirectory: false)
    }

    @IBAction func saveTouched(_ sender: Any) {
        let filename = "archive.showOne"
        guard let fileURL = localRoot?.appendingPathComponent(filename, isDirectory: false) else { return }
        
        let doc = Document(fileURL: fileURL)
        doc.trackURLs = Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: "LargeLibraryTest")
        
        doc.save(to: fileURL, for: .forCreating) {
            success in
            guard success else {
              fatalError("Failed to create file.")
            }
            
            print("File created at: \(fileURL)")
        }
    }
    
}

class Document: UIDocument {
    var trackURLs: [URL]?
    
    override func contents(forType typeName: String) throws -> Any {
        let wrappers = [String: FileWrapper]()
        return FileWrapper(directoryWithFileWrappers: wrappers)
    }
    
    override func save(to url: URL, for saveOperation: UIDocument.SaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        let fileCoordinator = NSFileCoordinator(filePresenter: self)
        fileCoordinator.coordinate(writingItemAt: self.fileURL, options: .forMerging, error: nil) { newURL in
            let success = self.fulfillUnsavedChanges()
            self.fileModificationDate = Date()
            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler(success)
                }
            }
        }
        super.save(to: url, for: saveOperation, completionHandler: completionHandler)
    }
    
    private func fulfillUnsavedChanges() -> Bool {
        let fileManager = FileManager.default
        var success = true

        for trackURL in trackURLs ?? [] {
            let targetURL = fileURL.appendingPathComponent(trackURL.lastPathComponent)
            do {
                print("copying: ", targetURL)
                try fileManager.copyItem(at: trackURL, to: targetURL)
            } catch {
                print("Failed to copy a file: \(error)")
                success = false
            }
        }
        
        return success
    }
}
