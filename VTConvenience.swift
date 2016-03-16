//
//  VTConvenience.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/16/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import Foundation

extension VTClient {
    
    func downloadImagesFromFlicker(latitude: Double, longitude: Double, page: Int?) {
        beginFlickrSearch(latitude, longitude: longitude, page: page) {(success, parsedResult, error) in
            print("\(parsedResult)")
        }
        
    }
    
    
    
    /*Helper Function: Given a raw JSON, return a usable Foundation object */
    class func parseJSON(data: NSData, completionHandler:(success: Bool, result: AnyObject!, error: NSError?)->Void) {
        var parsedResult: AnyObject!
        var photosResults: AnyObject!
        var photoResults: AnyObject!
        var picture: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String:AnyObject]
            photosResults = parsedResult[VTClient.JSONResponseKeys.photos] as? [String:AnyObject]
            photoResults = photosResults[VTClient.JSONResponseKeys.photo] as? NSArray
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]
            print("\(userInfo)")
            completionHandler(success: false, result: nil, error: NSError(domain: "parseJSON", code: 1, userInfo: userInfo))
        }
        
        
        if photoResults != nil {
            picture = photoResults[0] as? [String:AnyObject]
            print("Picture \(picture)")
        } else {
            print("Parsing with Photos did not work")
        }


        completionHandler(success: true, result: parsedResult, error: nil)
    }
    
}