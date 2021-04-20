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
        var wrappers = [String: FileWrapper]()
        
        var trackWrappers = [String: FileWrapper]()
        for trackURL in trackURLs ?? [] {
            let fileName = trackURL.lastPathComponent
            do {
                let wrapper = try FileWrapper(url: trackURL, options: [])
                trackWrappers[fileName] = wrapper
            } catch {
                print("error", error)
            }
        }
        let trackDirectory = FileWrapper(directoryWithFileWrappers: trackWrappers)
        wrappers["Tracks"] = trackDirectory

        return FileWrapper(directoryWithFileWrappers: wrappers)
    }
}
