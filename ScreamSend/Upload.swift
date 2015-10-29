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
import Just

public class Upload: NSObject {
    let boundary: String = "---------------------\(arc4random())\(arc4random())"; // Random boundary;
    var filePath: NSURL;
    var successCallback: Array<((String)->())> = [];
    var errorCallback: Array<((String)->())> = [];
    var progressCallback: Array<((Double)->())> = [];
    var startingCallback: Array<(()->())> = [];
    
    public init(filePath: NSURL) {
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
        Just.post(
            uploaderUrl,
            files: ["image": HTTPFile.URL(filePath, nil)],
            asyncProgressHandler: {(p) in
                for callback in self.progressCallback{
                    callback(Double(p.percent)/100.0);
                }
            },
            asyncCompletionHandler: {(r) in
                if (r.ok) {
                    let JSON = r.json as! NSDictionary!
                    print("Received response: \(JSON)");
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
                }else{
                    print(r.error, terminator: "");
                    if r.error != nil {
                        NSLog(r.error!.localizedDescription);
                        let message = r.error?.localizedDescription;
                        for callback in self.errorCallback{
                            callback(message!);
                        }
                    }
                }
            }
        );
    }
}