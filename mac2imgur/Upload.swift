/* This file is part of mac2imgur.
*
* mac2imgur is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* mac2imgur is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with mac2imgur.  If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

class Upload {
    
    let boundary: String = "---------------------\(arc4random())\(arc4random())" // Random boundary
    var pathToImage: String
    var isScreenshot: Bool
    var delegate: UploadControllerDelegate
    var app: AppDelegate
    
    init(app: AppDelegate, pathToImage: String, isScreenshot: Bool, delegate: UploadControllerDelegate) {
        self.pathToImage = pathToImage
        self.isScreenshot = isScreenshot
        self.delegate = delegate
        self.app = app
    }
    
    func attemptUpload(uploaderUrl: String) {
        println("Uploading image.")
        app.updateStatusIcon(true)
        
        let url: NSURL = NSURL(fileURLWithPath: pathToImage)!
        let imageData: NSData = NSData(contentsOfURL: url, options: nil, error: nil)!
        
        let request = NSMutableURLRequest()
        request.URL = NSURL(string: uploaderUrl)
        request.HTTPMethod = "POST"
        
        let requestBody = NSMutableData()
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Add image data
        requestBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBody.appendData("Content-Disposition: attachment; name=\"image\"; filename=\".\(pathToImage.lastPathComponent)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        requestBody.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBody.appendData(imageData)
        requestBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        requestBody.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        request.HTTPBody = requestBody
        
        // Attempt request
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if error != nil {
                NSLog(error!.localizedDescription);
                self.delegate.uploadAttemptCompleted(false, isScreenshot: self.isScreenshot, link: "", pathToImage: self.pathToImage)
            } else {
                if let responseDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary {
                    println("Received response: \(responseDict)")
                    if (responseDict.valueForKey("success") != nil && responseDict.valueForKey("success") as Bool) {
                        self.delegate.uploadAttemptCompleted(true, isScreenshot: self.isScreenshot, link: responseDict.valueForKey("link") as String, pathToImage: self.pathToImage)
                    } else {
                        NSLog("An error occurred: %@", responseDict);
                        self.delegate.uploadAttemptCompleted(false, isScreenshot: self.isScreenshot, link: "", pathToImage: self.pathToImage)
                    }
                } else {
                    NSLog("An error occurred - the response was invalid: %@", response)
                    self.delegate.uploadAttemptCompleted(false, isScreenshot: self.isScreenshot, link: "", pathToImage: self.pathToImage)
                }
                self.app.updateStatusIcon(false)
            }
        })
    }
}

protocol UploadControllerDelegate {
    func uploadAttemptCompleted(successful: Bool, isScreenshot: Bool, link: String, pathToImage: String)
}