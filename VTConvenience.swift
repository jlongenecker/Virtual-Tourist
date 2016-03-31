//
//  VTConvenience.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/16/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension VTClient {
    

  
    
    func downloadImagesFromFlicker(latitude: Double, longitude: Double, page: Int?, pin: LocationPin, completionHandler: (success: Bool)->Void) {
            print("Received Location Lattitude\(pin.latitude)")
            self.beginFlickrSearch(latitude, longitude: longitude, page: page) {(success, photoResults, error) in
                if success {
                    
                    let privateMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                    privateMOC.parentContext = self.sharedContext
                    
                    privateMOC.performBlock {
                        print("VTClient extension: Pin does not contain photos: \(pin.photos)")
                        let newPhotosResults = photoResults as! [[String:AnyObject]]
                        if newPhotosResults == [] {
                            print("VTClient extension Photo Results: \(newPhotosResults)")
                        } else {
                            newPhotosResults.map() {(dictionary: [String:AnyObject]) -> Photo in
                                let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                photo.pin = pin
                                let imageCache = ImageCache()
                                imageCache.downloadImage(photo.photoID, url: photo.url_m)
                                return photo
                            }
                        }
                        pin.photoFinishedLoading = true
                        
                        do {
                            try privateMOC.save()
                        } catch {
                            fatalError("Failure to save context: \(error)")
                        }

                        completionHandler(success: true)
                    }

                    print("VTClient extension: Pin contains photos \(pin.photos)")
     
                }
            }
        
    }
    
    
  


    /*Helper Function: Given a raw JSON, return a usable Foundation object */
    class func parseJSON(data: NSData, completionHandler:(success: Bool, result: AnyObject?, error: NSError?)->Void) {
        var parsedResult: AnyObject!
        var photosResults: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String:AnyObject]
            photosResults = parsedResult[VTClient.JSONResponseKeys.photos] as? [String:AnyObject]
            if let photoResults = photosResults.valueForKey(VTClient.JSONResponseKeys.photo) as? [[String:AnyObject]] {
                //print("Test Results: \(photoResults)")
                completionHandler(success: true, result: photoResults, error: nil)
            }

        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]
            print("\(userInfo)")
            completionHandler(success: false, result: nil, error: NSError(domain: "parseJSON", code: 1, userInfo: userInfo))
        }

    }
    
}