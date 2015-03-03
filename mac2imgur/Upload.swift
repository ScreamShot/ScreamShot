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
        
        let fileURL: NSURL = NSURL(fileURLWithPath: pathToImage)!
        let imageData: NSData = NSData(contentsOfURL: fileURL, options: nil, error: nil)!
        
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: uploaderUrl)!)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue
        let uploadData = NSMutableData()
        let requestBody = NSMutableData()
        let contentType = "multipart/form-data; boundary=\(boundary)"
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Add image data
        requestBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBody.appendData("Content-Disposition: attachment; name=\"image\"; filename=\".\(pathToImage.lastPathComponent)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        requestBody.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBody.appendData(imageData)
        requestBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        requestBody.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        upload(mutableURLRequest, requestBody)
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                self.setProgress(Double(totalBytesWritten)/Double(totalBytesExpectedToWrite))
            }
            .responseJSON { (request, response, _JSON, error) in
                if error != nil {
                    NSLog(error!.localizedDescription);
                    self.delegate.uploadAttemptCompleted(false, isScreenshot: self.isScreenshot, link: "", pathToImage: self.pathToImage)
                } else {
                    var JSON = _JSON as NSDictionary!
                    println("Received response: \(JSON)")
                    if (JSON.valueForKey("success") != nil && JSON.valueForKey("success") as Bool) {
                        self.delegate.uploadAttemptCompleted(true, isScreenshot: self.isScreenshot, link: JSON.valueForKey("link") as String, pathToImage: self.pathToImage)
                    } else {
                        NSLog("An error occurred: %@", JSON);
                        self.delegate.uploadAttemptCompleted(false, isScreenshot: self.isScreenshot, link: "", pathToImage: self.pathToImage)
                    }
                }
            self.app.uploadController.next()
            self.app.updateStatusIcon(false)
            self.setProgress(0)
        }
    }
    func setProgress(progress: Double){
        self.app.menuView.setProgress(progress)
    }
}

protocol UploadControllerDelegate {
    func uploadAttemptCompleted(successful: Bool, isScreenshot: Bool, link: String, pathToImage: String)
}