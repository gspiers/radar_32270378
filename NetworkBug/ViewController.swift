//
//  ViewController.swift
//  NetworkBug
//
//  Created by Greg Spiers on 17/05/2017.
//

import UIKit

class ViewController: UIViewController {

    // Both of these are static files in an S3 bucket. First one will be sent back with response header 'Content-Encoding: gzip'.
    // Second one will always be sent plain without any compression.
    private let gzippedUrl = URL(string: "http://ios-gzip-test.s3-eu-west-1.amazonaws.com/compressed-config.json")!
    private let plainUrl = URL(string: "http://ios-gzip-test.s3-eu-west-1.amazonaws.com/config.json")!
    
    fileprivate var fetchedData: Data = Data()
    @IBOutlet weak var gzipSwitch: UISwitch!
    @IBOutlet weak var textView: UITextView!

    var appUrlSession: URLSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gzipSwitch.isOn = true
        URLCache.shared.removeAllCachedResponses()
        appUrlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }

    @IBAction func fetchButtonTapped(_ sender: Any) {
        fetchedData = Data()
        
        let url = gzipSwitch.isOn ? gzippedUrl : plainUrl
        let task = appUrlSession.dataTask(with: url)
        task.resume()
    }
    
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        self.textView.text = nil
    }
}


extension ViewController: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        // Change bool below to enable/disable a work around for the bug.
        let enableWorkAround = false
        
        if enableWorkAround {
            let fixedResponse = TransferEncodingBugURLCacheHelper.fixedCachedUrlResponse(for: proposedResponse)
            completionHandler(fixedResponse)
        } else {
            completionHandler(proposedResponse)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        fetchedData = fetchedData + data
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error == nil else { return }
        
        let body = String(data: fetchedData, encoding: String.Encoding.utf8)!
        
        DispatchQueue.main.async {
            self.textView.text = "Body:\n\n\(body)"
        }
    }
}
