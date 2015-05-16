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
import ScreamUtils

public class Upload: NSObject {
    let boundary: String = "---------------------\(arc4random())\(arc4random())"; // Random boundary;
    var filePath = "";
    var successCallback: Array<((String)->())> = [];
    var errorCallback: Array<((String)->())> = [];
    var progressCallback: Array<((Double)->())> = [];
    var startingCallback: Array<(()->())> = [];
    
    public init(filePath: String) {
        self.filePath = filePath;
    }
    
    func addErrorCallback(callback: (String)->()){
        errorCallback.append(callback);
    }
    
    func addSuccessCallback(callback: (String)->()){
        successCallback.append(callback);
    }
    
    func addProgressCallback(callback: (Double)->()){
        progressCallback.append(callback);
    }
    
    func addStartingCallback(callback: ()->()){
        startingCallback.append(callback);
    }
    
    func attemptUpload(uploaderUrl: String) {
        let fileURL: NSURL = NSURL(fileURLWithPath: filePath)!;
        let imageData: NSData = NSData(contentsOfURL: fileURL, options: nil, error: nil)!;
        
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: uploaderUrl)!);
        mutableURLRequest.HTTPMethod = Method.POST.rawValue;
        let uploadData = NSMutableData();
        let requestBody = NSMutableData();
        let contentType = "multipart/form-data; boundary=\(boundary)";
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type");
        
        // Add image data
        requestBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!);
        requestBody.appendData("Content-Disposition: attachment; name=\"image\"; filename=\".\(filePath.lastPathComponent)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!);
        
        requestBody.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!);
        requestBody.appendData(imageData);
        requestBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!);
        
        requestBody.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        upload(mutableURLRequest, requestBody)
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                for callback in self.progressCallback{
                    callback(Double(totalBytesWritten)/Double(totalBytesExpectedToWrite));
                }
            }
            .responseJSON { (request, response, _JSON, error) -> () in
                print(error);
                if error != nil {
                    NSLog(error!.localizedDescription);
                    let message = error?.localizedDescription;
                    for callback in self.errorCallback{
                        callback(message!);
                    }
                } else {
                    var JSON = _JSON as! NSDictionary!
                    println("Received response: \(JSON)");
                    if (JSON.valueForKey("success") != nil && JSON.valueForKey("success") as! Bool) {
                        for callback in self.successCallback{
                            callback(JSON.valueForKey("link") as! String);
                        }
                    } else {
                        NSLog("An error occurred: %@", JSON);
                        for callback in self.errorCallback{
                            callback(String(format: "%@", JSON));
                        }
                    }
                }
        }
    }
}