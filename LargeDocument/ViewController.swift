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
        
        try? FileManager.default.removeItem(at: fileURL)
        
        let doc = Document(fileURL: fileURL)
        doc.trackURLs = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "LargeLibraryTest")
        
        doc.save(to: fileURL, for: .forCreating) {
            success in
            guard success else {
              fatalError("Failed to create file.")
            }
            
            print("File created at: \(fileURL)")
        }
    }
    
    @IBAction func loadTouched(_ sender: Any) {
        let filename = "archive.showOne"
        guard let fileURL = localRoot?.appendingPathComponent(filename, isDirectory: false) else { return }
        guard let destinationURL = localRoot else { return }
        
        let doc = Document(fileURL: fileURL)
        doc.open { success in
            guard success else {
                fatalError("Failed to open doc.")
            }
            
            doc.writeFilesTo(destinationURL)
            
            doc.close() { success in
                guard success else {
                    fatalError("Failed to close doc.")
                }
            }
        }
    }
}

class Document: UIDocument {
    var fileWrapper: FileWrapper?
    var trackURLs: [URL]?
    var trackMeta: [[String: Any]]?
    var setlistMeta: [[String: Any]]?
    var setTrackMeta: [[String: Any]]?
    
    override func contents(forType typeName: String) throws -> Any {
        let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        var library = [String: Any]()
        library["Tracks"] = [["a trackname": "track data"]]
        library["Setlists"] = [["a setlist": "setlist data"]]
        library["SetTracks"] = [["a track in a set": "set track data"]]
        
        let libraryData: Data = try! NSKeyedArchiver.archivedData(withRootObject: library, requiringSecureCoding: false)
        
        fileWrapper.addRegularFile(withContents: libraryData, preferredFilename: "Library.meta")
        
        return fileWrapper
    }
    
    override func save(to url: URL, for saveOperation: UIDocument.SaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        super.save(to: url, for: saveOperation) { (success) in
            let fileCoordinator = NSFileCoordinator(filePresenter: self)
            fileCoordinator.coordinate(writingItemAt: self.fileURL, options: .forMerging, error: nil) { newURL in
                let success = self.fulfillUnsavedChanges()
                if let completionHandler = completionHandler {
                    DispatchQueue.main.async {
                        completionHandler(success)
                    }
                }
            }
        }
    }
    
    private func fulfillUnsavedChanges() -> Bool {
        let fileManager = FileManager.default
        var success = true
        
        let tracksDirectory = fileURL.appendingPathComponent("Tracks", isDirectory: true)
        try! fileManager.createDirectory(at: tracksDirectory, withIntermediateDirectories: true, attributes: nil)

        for trackURL in trackURLs ?? [] {
            let targetURL = fileURL.appendingPathComponent("Tracks", isDirectory: true).appendingPathComponent(trackURL.lastPathComponent)
            do {
                print("copying at: ", trackURL)
                print("copying to: ", targetURL)
                try fileManager.copyItem(at: trackURL, to: targetURL)
            } catch {
                print("Failed to copy a file: \(error)")
                success = false
            }
        }
        
        return success
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let contents = contents as? FileWrapper else { return }
        
        fileWrapper = contents
        
        let data = contents.fileWrappers!["Library.meta"]!.regularFileContents!
        let obj = NSKeyedUnarchiver.unarchiveObject(with: data) as! [String : Any]
        if let meta = obj["Tracks"] as? [[String: Any]] {
            trackMeta = meta
        }
        if let meta = obj["Setlists"] as? [[String: Any]] {
            setlistMeta = meta
        }
        if let meta = obj["SetTracks"] as? [[String: Any]] {
            setTrackMeta = meta
        }
    }
    
    func writeFilesTo(_ url: URL) {
        performAsynchronousFileAccess {
            let fileCoordinator = NSFileCoordinator(filePresenter: self)
            fileCoordinator.coordinate(writingItemAt: url, options: .forMerging, error: nil) { newURL in
                _ = self.writeAllTracksTo(url)
            }
        }
    }
    
    func writeAllTracksTo(_ targetURL: URL) -> Bool {
        guard let trackWrappers = fileWrapper?.fileWrappers?["Tracks"]?.fileWrappers else { return false }
        
        let fileManager = FileManager.default
        var success = true
        
        let names = Array(trackWrappers.keys)

        for trackName in names {
            let trackFileURL = self.fileURL.appendingPathComponent("Tracks", isDirectory: true).appendingPathComponent(trackName)
            let targetURL = URL(fileURLWithPath: targetURL.appendingPathComponent(trackName).path)
            do {
                try fileManager.copyItem(at: trackFileURL, to: targetURL)
                print("Track Copied:", trackName)
            } catch {
                print("Failed:", error)
                success = false
            }
        }
        
        return success
    }
}
