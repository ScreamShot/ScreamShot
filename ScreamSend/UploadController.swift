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

class UploadController {
    var uploadUrl: String!
    var uploadQueue: [Upload]
    var uploading = false
    
    init(uploadUrl: String) {
        self.uploadQueue = []
        self.uploadUrl = uploadUrl
    }
    
    func setUploadUrl(uploadUrl: String){
        self.uploadUrl = uploadUrl;
    }
    
    func addToQueue(upload: Upload) {
        uploadQueue.append(upload)
        if !uploading{
            next()
        }
    }
    
    func next(){
        uploading = false
        if uploadQueue.count == 0 {
            uploadQueue.removeAll(keepCapacity: false)
        } else {
            uploading = true
            let upload = uploadQueue[uploadQueue.count-1]
            uploadQueue.removeAtIndex(uploadQueue.count-1)
            upload.attemptUpload(uploadUrl)
        }
    }
}