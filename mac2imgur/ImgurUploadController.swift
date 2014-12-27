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

class ImgurUploadController {
    var pref: PreferencesManager
    var uploadQueue: [ImgurUpload]
    var authenticationInProgress: Bool
    
    init(pref: PreferencesManager) {
        self.uploadQueue = []
        self.pref = pref
        self.authenticationInProgress = false
    }
    
    func addToQueue(upload: ImgurUpload) {
        uploadQueue.append(upload)
    }
    
    func processQueue(authenticated: Bool) {
        // Upload all images in queue
        let uploadUrl = pref.getString("url", def: "http://j.ungeek.fr/upload.php")!
        for upload in uploadQueue {
            upload.attemptUpload(uploadUrl)
        }
        // Clear queue
        uploadQueue.removeAll(keepCapacity: false)
    }
}